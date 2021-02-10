CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_TRX_SMPL_GIMMICK_UPL_PKG
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXSHP_TRX_SMPL_GIMMICK_UPL_PKG.pks                                                    |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Planning Parameter New all in this Package                                            |
   REM |     History     : 1 Juni 2020  --Ardianto--                                                             |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */

   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
      DBMS_OUTPUT.put_line (v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
      DBMS_OUTPUT.put_line (p_message);
   END;

   FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
      --this function is based on one by Connor McDonald
      --http://www.jlcomp.demon.co.uk/faq/base_convert.html

      RETURN NUMBER
   IS
      l_ndec   NUMBER;
      l_vhex   VARCHAR2 (16) := '0123456789ABCDEF';
   BEGIN
      l_ndec := 0;

      FOR indx IN 1 .. LENGTH (p_hex_str)
      LOOP
         l_ndec :=
              l_ndec * 16
            + INSTR (l_vhex, UPPER (SUBSTR (p_hex_str, indx, 1)))
            - 1;
      END LOOP;

      RETURN l_ndec;
   END hex_to_decimal;

   PROCEDURE delimstring_to_table (
      p_delimstring   IN     VARCHAR2,
      p_table            OUT VARCHAR2_TABLE,
      p_nfields          OUT INTEGER,
      p_a                OUT NUMBER,
      p_delim         IN     VARCHAR2 DEFAULT ';')
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER := 1;
      v_table      VARCHAR2_TABLE;
      v_delimpos   PLS_INTEGER := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0
      THEN
         logf ('Delimiter ''' || p_delim || ''' not Found');
      END IF;

      WHILE v_delimpos > 0
      LOOP
         v_table (v_nfields) := SUBSTR (v_string, 1, v_delimpos - 1);
         v_string := SUBSTR (v_string, v_delimpos + v_delimlen);
         v_nfields := v_nfields + 1;
         v_delimpos := INSTR (v_string, p_delim);
      END LOOP;

      v_table (v_nfields) := v_string;
      p_table := v_table;
      p_nfields := v_nfields;
   END delimstring_to_table;

   PROCEDURE print_result (p_file_id NUMBER)
   IS
      l_user_created_by   VARCHAR (50);
      l_creation_date     VARCHAR (50);
      l_file_name         VARCHAR (100);

      CURSOR c_data
      IS
           SELECT tsg.reference_no,
                  SUBSTR (tsg.description, 1, 50) description,
                  tsg.amount,
                  tsg.status,
                  tsg.quantity,
                  tsg.unit_selling_price,
                  SUBSTR (tsg.error_message, 1, 200) error_message
             FROM xxshp_trx_smpl_gimmick_stg tsg
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'N') = 'N'
                  AND file_id = p_file_id
         GROUP BY tsg.reference_no,
                  tsg.amount,
                  SUBSTR (tsg.description, 1, 50),
                  tsg.status,
                  tsg.quantity,
                  tsg.unit_selling_price,
                  SUBSTR (tsg.error_message, 1, 200);
   BEGIN
        SELECT file_name, user_created_by, creation_date
          INTO l_file_name, l_user_created_by, l_creation_date
          FROM (SELECT tsg.file_name,
                       (SELECT user_name
                          FROM fnd_user
                         WHERE 1 = 1 AND user_id = tsg.created_by)
                          user_created_by,
                       TO_CHAR (tsg.creation_date, 'DD-MON-RR HH24:MI:SS')
                          creation_date
                  FROM xxshp_trx_smpl_gimmick_stg tsg
                 WHERE     1 = 1
                       AND NVL (status, 'E') = 'E'
                       AND NVL (flag, 'N') = 'N'
                       AND file_id = p_file_id)
         WHERE 1 = 1 AND ROWNUM <= 1
      GROUP BY file_name, user_created_by, creation_date;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Sample Gimmick status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || l_user_created_by);
      outf ('      ' || 'Proceed Date on : ' || l_creation_date);
      outF (
            '      '
         || '------------ ---------------- --------------------------------------------------- ----------- --------------- ------- ------------------------------------------------------------------------------------------------------------------------');
      outF (
            '      '
         || 'REFERENCE    AMOUNT           DESCRIPTION                                         QUANTITY    UNIT SELL PRICE STATUS  ERROR MESSAGE                                                                                                           ');
      outF (
            '      '
         || '------------ ---------------- --------------------------------------------------- ----------- --------------- ------- ------------------------------------------------------------------------------------------------------------------------');

      FOR i IN c_data
      LOOP
         outF (
               '      '
            || RPAD (i.reference_no, 11, ' ')
            || '  '
            || RPAD (i.amount, 15, ' ')
            || '  '
            || RPAD (i.description, 50, ' ')
            || '  '
            || RPAD (i.quantity, 10, ' ')
            || '  '
            || RPAD (i.unit_selling_price, 14, ' ')
            || '  '
            || RPAD (i.status, 5, ' ')
            || '  '
            || RPAD (i.error_message, 200, ' '));
      END LOOP;

      outF (
            '      '
         || '------------ ---------------- --------------------------------------------------- ----------- --------------- ------- ------------------------------------------------------------------------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result;

   PROCEDURE print_invoice (p_batch_id NUMBER, p_file_id NUMBER)
   IS
      l_user_created_by   VARCHAR (50);
      l_creation_date     VARCHAR (50);
      l_file_name         VARCHAR (100);

      CURSOR c_data
      IS
         SELECT customer_trx_id,
                trx_number,
                trx_date,
                batch_id
           FROM ra_customer_trx_all
          WHERE 1 = 1 AND batch_id = p_batch_id;
   BEGIN
        SELECT file_name, user_created_by, creation_date
          INTO l_file_name, l_user_created_by, l_creation_date
          FROM (SELECT tsg.file_name,
                       (SELECT user_name
                          FROM fnd_user
                         WHERE 1 = 1 AND user_id = tsg.created_by)
                          user_created_by,
                       TO_CHAR (tsg.creation_date, 'DD-MON-RR HH24:MI:SS')
                          creation_date
                  FROM xxshp_trx_smpl_gimmick_stg tsg
                 WHERE 1 = 1 AND file_id = p_file_id)
         WHERE 1 = 1 AND ROWNUM <= 1
      GROUP BY file_name, user_created_by, creation_date;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Sample Gimmick status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || l_user_created_by);
      outf ('      ' || 'Proceed Date on : ' || l_creation_date);
      outF (
            '      '
         || '---------------- ---------------------- ------------- ---------------------------');
      outF (
            '      '
         || 'CUSTOMER TRX ID  TRX NUMBER             TRX DATE      BATCH ID                   ');
      outF (
            '      '
         || '---------------- ---------------------- ------------- ---------------------------');

      FOR i IN c_data
      LOOP
         outF (
               '      '
            || RPAD (i.customer_trx_id, 15, ' ')
            || '  '
            || RPAD (i.trx_number, 21, ' ')
            || '  '
            || RPAD (i.trx_date, 12, ' ')
            || '  '
            || RPAD (i.batch_id, 25, ' '));
      END LOOP;

      outF (
            '      '
         || '---------------- ---------------------- ------------- ---------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_invoice;

   PROCEDURE process_data (errbuf         OUT VARCHAR2,
                           retcode        OUT VARCHAR2,
                           p_file_id   IN     NUMBER)
   IS
      l_cust_trx_id            NUMBER;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type;
      l_trx_hdr_tbl            ar_invoice_api_pub.trx_header_tbl_type;
      l_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type;
      l_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type;
      l_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type;

      l_trx_header_id          NUMBER;
      l_trx_line_id            NUMBER;
      l_trx_dist_id            NUMBER;

      l_qty_invoiced           NUMBER := 0;
      l_unit_selling_price     NUMBER := 0;
      l_total_amount           NUMBER;

      l_coa_code               VARCHAR2 (50);
      l_batch_source_name      VARCHAR2 (50);
      l_batch_id               NUMBER;
      l_cnt                    NUMBER;

      l_ledger_id              NUMBER := 0;
      l_org_id                 NUMBER := 0;
      l_operating_unit         NUMBER := 0;
      l_chart_of_accounts_id   NUMBER := 0;
      l_code_combination_id    NUMBER := 0;
      l_set_of_books_id        NUMBER := 0;

      l_customer_trx_id        NUMBER;

      l_dummy_cnt              NUMBER;
      l_loop_cnt               NUMBER := 0;
      l_record_count           NUMBER := 0;

      l_msg_count              NUMBER;
      l_count                  NUMBER;
      l_msg_data               VARCHAR2 (2000);
      l_mesg                   VARCHAR2 (2000);
      l_chr_mesg               VARCHAR2 (2000);
      l_return_status          VARCHAR2 (10);

      l_request_id             NUMBER DEFAULT 0;
      l_process_notvalid       NUMBER := 0;

      l_bill_to_customer_id    NUMBER := 0;
      l_bill_to_site_use_id    NUMBER := 0;
      l_ship_to_customer_id    NUMBER := 0;
      l_ship_to_site_use_id    NUMBER := 0;

      l_batch_source_id        NUMBER := 0;
      l_term_id                NUMBER := 0;
      l_term_name              VARCHAR2 (240);

      l_cust_trx_type_id       NUMBER := 0;
      l_cust_trx_type_name     VARCHAR2 (80);
      l_tax_ppn                VARCHAR2 (90);

      l_header                 NUMBER := 0;
      l_line                   NUMBER := 0;
      l_dist                   NUMBER := 0;
      l_hdr_exists             NUMBER := 0;
      l_line_exists            NUMBER := 0;
      l_line_number            NUMBER := 0;

      l_error                  NUMBER := 0;
      l_trx_number             VARCHAR2 (20);
      l_trx_date               DATE;
      l_val                    NUMBER;
      l_val_rec                NUMBER;
      l_jml_data               NUMBER;
      l_nextproceed            BOOLEAN := FALSE;

      e_excp                   EXCEPTION;

      CURSOR cbatch
      IS
         SELECT customer_trx_id
           FROM ra_customer_trx_all
          WHERE batch_id = l_batch_id;

      CURSOR list_errors
      IS
         SELECT trx_header_id,
                trx_line_id,
                trx_salescredit_id,
                trx_dist_id,
                trx_contingency_id,
                error_message,
                invalid_value
           FROM ar_trx_errors_gt;

      CURSOR data_stg (p_file_id NUMBER)
      IS
           SELECT currency_code,
                  customer_name,
                  bill_to,
                  ship_to,
                  trx_date,
                  transaction_type,
                  interface_line_attribute3
             FROM xxshp_trx_smpl_gimmick_stg
            WHERE file_id = p_file_id AND NVL (flag, 'Y') = 'Y'
         GROUP BY currency_code,
                  customer_name,
                  bill_to,
                  ship_to,
                  trx_date,
                  transaction_type,
                  interface_line_attribute3;

      CURSOR data_ar_stg (
         p_file_id                  NUMBER,
         p_iface_line_attribute3    VARCHAR2,
         p_customer_name            VARCHAR2,
         p_transaction_type         VARCHAR2)
      IS
         SELECT reference_no,
                description,
                currency_code,
                amount,
                customer_name,
                bill_to,
                ship_to,
                trx_date,
                trx_number,
                line_number,
                quantity,
                unit_selling_price,
                interface_line_attribute3
           FROM xxshp_trx_smpl_gimmick_stg
          WHERE     file_id = p_file_id
                AND NVL (flag, 'Y') = 'Y'
                AND interface_line_attribute3 = interface_line_attribute3
                AND customer_name = p_customer_name
                AND transaction_type = p_transaction_type;
   BEGIN
      l_jml_data := 0;

      FOR i IN data_stg (p_file_id)
      LOOP
         EXIT WHEN data_stg%NOTFOUND;

         l_jml_data := l_jml_data + 1;
         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      ELSE
         logf ('Data has been proceed');
         retcode := 1;
      END IF;

      IF l_nextproceed
      THEN
         logf ('**/ STEP-02. Create Manual Invoice  **/');
         logf ('');

         retcode := 0;
         l_error := 0;
         l_org_id := NULL;
         l_operating_unit := NULL;

         -- /* Get set_of_books_id */
         BEGIN
            SELECT set_of_books_id
              INTO l_set_of_books_id
              FROM gl_sets_of_books
             WHERE 1 = 1 AND UPPER (name) = 'SHP_LEDGER_PROD';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_process_notvalid := l_process_notvalid + 1;
               logf ('Invalid set_of_books_id, ' || SQLERRM);
         END;

         -- /* Get chart_of_accounts_id */
         BEGIN
            SELECT ledger_id, chart_of_accounts_id
              INTO l_ledger_id, l_chart_of_accounts_id
              FROM gl_ledgers
             WHERE 1 = 1 AND UPPER (ledger_category_code) = 'PRIMARY';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_process_notvalid := l_process_notvalid + 1;
               logf ('Invalid chart_of_accounts_id, ' || SQLERRM);
         END;

         -- /* Get Operating unit */

         BEGIN
            SELECT organization_id
              INTO l_operating_unit
              FROM hr_all_organization_units
             WHERE 1 = 1 AND UPPER (name) LIKE '%OPERATING UNIT';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_process_notvalid := l_process_notvalid + 1;
               logf ('Invalid Operation Unit, ' || SQLERRM);
         END;


         -- /* Get Operating unit */

         BEGIN
            SELECT batch_source_id, name
              INTO l_batch_source_id, l_batch_source_name
              FROM ra_batch_sources_all
             WHERE 1 = 1 AND name = 'SHP UPLOAD';
         EXCEPTION
            WHEN OTHERS
            THEN
               l_process_notvalid := l_process_notvalid + 1;
               logf (
                     'Invalid Batch Source : '
                  || l_batch_source_name
                  || ','
                  || SQLERRM);
         END;


         -- /* Get TOP */

         --      BEGIN
         --         SELECT term_id, description
         --           INTO l_term_id, l_term_name
         --           FROM ra_terms_tl
         --          WHERE 1 = 1 AND name = 'KHD_14_NET';
         --      EXCEPTION
         --         WHEN OTHERS
         --         THEN
         --            l_process_notvalid := l_process_notvalid + 1;
         --            logf ('Invalid TOP : ' || l_term_name || ',' || SQLERRM);
         --      END;

         l_batch_source_rec.batch_source_id := l_batch_source_id;

         l_hdr_exists := 0;

         logf ('LOOP HDR START');

         FOR hdr IN data_stg (p_file_id)
         LOOP
            -- /* Get Customer Trx Types */

            BEGIN
               SELECT cust_trx_type_id, description, gl_id_rev
                 INTO l_cust_trx_type_id,
                      l_cust_trx_type_name,
                      l_code_combination_id
                 FROM ra_cust_trx_types_all
                WHERE 1 = 1 AND name LIKE hdr.transaction_type; --'Manual Sample%Gimmick';
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_notvalid := l_process_notvalid + 1;
                  logf (
                        'Invalid RA_CUST_TRX_TYPES : '
                     || l_cust_trx_type_name
                     || ','
                     || SQLERRM);
            END;


            /*BEGIN
               SELECT 1
                 INTO l_val
                 FROM RA_CUSTOMER_TRX_ALL
                WHERE trx_number = hdr.trx_number;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_val := 0;
            END;

            BEGIN
               SELECT 1
                 INTO l_val_rec
                 FROM ar_cash_receipts_all
                WHERE receipt_number = hdr.trx_number AND status <> 'APP';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_val_rec := 0;
            END;*/

            BEGIN
               SELECT ship_cus.cust_account_id ship_to_customer_id,
                      hcs_ship.site_use_id ship_to_site_use_id
                 INTO l_ship_to_customer_id, l_ship_to_site_use_id
                 FROM hz_cust_accounts_all ship_cus,
                      hz_parties ship_party,
                      hz_party_sites hps_ship,
                      hz_cust_site_uses_all hcs_ship,
                      hz_cust_acct_sites_all hca_ship
                WHERE     1 = 1
                      AND hps_ship.party_id = ship_party.party_id
                      AND ship_party.party_id = ship_cus.party_id
                      AND hcs_ship.site_use_code = 'SHIP_TO'
                      AND hca_ship.cust_acct_site_id =
                             hcs_ship.cust_acct_site_id
                      AND hps_ship.party_site_id = hca_ship.party_site_id
                      AND ship_party.party_name = hdr.ship_to;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_notvalid := l_process_notvalid + 1;
                  logf (
                     'Invalid Ship To : ' || hdr.ship_to || ',' || SQLERRM);
            END;

            BEGIN
               SELECT ship_cus.cust_account_id bill_to_customer_id,
                      hcs_ship.site_use_id bill_to_site_use_id
                 INTO l_bill_to_customer_id, l_bill_to_site_use_id
                 FROM hz_cust_accounts_all ship_cus,
                      hz_parties ship_party,
                      hz_party_sites hps_ship,
                      hz_cust_site_uses_all hcs_ship,
                      hz_cust_acct_sites_all hca_ship
                WHERE     1 = 1
                      AND hps_ship.party_id = ship_party.party_id
                      AND ship_party.party_id = ship_cus.party_id
                      AND hcs_ship.site_use_code = 'BILL_TO'
                      AND hca_ship.cust_acct_site_id =
                             hcs_ship.cust_acct_site_id
                      AND hps_ship.party_site_id = hca_ship.party_site_id
                      AND ship_party.party_name = hdr.bill_to;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_notvalid := l_process_notvalid + 1;
                  logf (
                     'Invalid Bill To : ' || hdr.bill_to || ',' || SQLERRM);
            END;

            --EXIT WHEN l_val = 1;

            l_header := l_header + 1;

            SELECT ra_customer_trx_s.NEXTVAL INTO l_trx_header_id FROM DUAL;

            l_hdr_exists := 0;


            /*logf ('');
            logf ('    Create RA Interface  ');
            logf ('');
            logf ('    RA trx header id   : ' || l_trx_header_id);
            logf ('    Customer Name      : ' || hdr.customer_name);*/


            l_trx_hdr_tbl (l_header).trx_header_id := l_trx_header_id;
            l_trx_hdr_tbl (l_header).cust_trx_type_id := l_cust_trx_type_id;
            l_trx_hdr_tbl (l_header).bill_to_customer_id :=
               l_bill_to_customer_id;

            l_trx_hdr_tbl (l_header).trx_date := hdr.trx_date;
            l_trx_hdr_tbl (l_header).bill_to_site_use_id :=
               l_bill_to_site_use_id;
            l_trx_hdr_tbl (l_header).ship_to_customer_id :=
               l_ship_to_customer_id;
            l_trx_hdr_tbl (l_header).term_id := 1000;
            l_trx_hdr_tbl (l_header).ship_to_site_use_id :=
               l_ship_to_site_use_id;
            l_trx_hdr_tbl (l_header).default_tax_exempt_flag := 'S';
            l_trx_hdr_tbl (l_header).status_trx := 'OP';
            l_trx_hdr_tbl (l_header).printing_option := 'PRI';

            l_hdr_exists := l_hdr_exists + 1;

            --l_line := 0;
            l_line_exists := 0;
            l_line_number := 0;

            FOR rec IN data_ar_stg (p_file_id,
                                    hdr.interface_line_attribute3,
                                    hdr.customer_name,
                                    hdr.transaction_type)
            LOOP
               BEGIN
                  SELECT attribute5
                    INTO l_tax_ppn
                    FROM ra_cust_trx_types_all
                   WHERE 1 = 1 AND name LIKE hdr.transaction_type;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_process_notvalid := l_process_notvalid + 1;
                     logf (
                           'Invalid RA_CUST_TRX_TYPES get Tax : '
                        || l_tax_ppn
                        || ','
                        || SQLERRM);
               END;

               SELECT ra_customer_trx_lines_s.NEXTVAL
                 INTO l_trx_line_id
                 FROM DUAL;

               SELECT ra_cust_trx_line_gl_dist_s.NEXTVAL
                 INTO l_trx_dist_id
                 FROM DUAL;

               l_line_number := l_line_number + 1;

               l_line := l_line + 1;
               l_dist := l_dist + 1;

               l_trx_lines_tbl (l_line).trx_header_id := l_trx_header_id;
               l_trx_lines_tbl (l_line).trx_line_id := l_trx_line_id;
               l_trx_lines_tbl (l_line).line_number := l_line_number;
               l_trx_lines_tbl (l_line).line_type := 'LINE';
               l_trx_lines_tbl (l_line).description := rec.description;
               l_trx_lines_tbl (l_line).quantity_invoiced := rec.quantity;
               l_trx_lines_tbl (l_line).unit_selling_price :=
                  rec.unit_selling_price;
               l_trx_lines_tbl (l_line).attribute1 := rec.trx_number;
               l_trx_lines_tbl (l_line).attribute2 := rec.reference_no;
               l_trx_lines_tbl (l_line).interface_line_context := 'SHP IMPORT';
               l_trx_lines_tbl (l_line).interface_line_attribute3 :=
                  rec.interface_line_attribute3;
               l_trx_lines_tbl (l_line).tax_classification_code := l_tax_ppn;

               l_trx_dist_tbl (l_dist).trx_dist_id := l_trx_dist_id;
               l_trx_dist_tbl (l_dist).trx_line_id := l_trx_line_id;
               l_trx_dist_tbl (l_dist).trx_header_id := l_trx_header_id;
               l_trx_dist_tbl (l_dist).account_class := 'REV';
               l_trx_dist_tbl (l_dist).percent := 100;
               l_trx_dist_tbl (l_dist).code_combination_id :=
                  l_code_combination_id;
               l_trx_dist_tbl (l_dist).amount := rec.amount;

               /*logf ('');
               logf ('line' || l_line);
               logf ('trx_header_id ' || l_trx_lines_tbl (l_line).trx_header_id);
               logf ('trx_line_id ' || l_trx_lines_tbl (l_line).trx_line_id);
               logf ('line_number ' || l_trx_lines_tbl (l_line).line_number);
               logf ('description ' || l_trx_lines_tbl (l_line).description);
               logf ('quantity_ordered ' || l_trx_lines_tbl (l_line).quantity_ordered);
               logf ('quantity_invoiced ' || l_trx_lines_tbl (l_line).quantity_invoiced);
               logf ('amount ' || l_trx_lines_tbl (l_line).amount);
               logf ('unit_selling_price ' || l_trx_lines_tbl (l_line).unit_selling_price);

               logf ('');
               logf ('Dist');
               logf ('trx_dist_id ' || l_trx_dist_tbl (l_line).trx_dist_id);
               logf ('code_combination_id ' || l_trx_dist_tbl (l_line).code_combination_id);
               logf ('amount ' || l_trx_dist_tbl (l_line).amount);*/

               l_line_exists := l_line_exists + 1;
            END LOOP;
         END LOOP;

         fnd_global.apps_initialize (g_user_id,
                                     g_resp_id,
                                     g_resp_appl_id,
                                     0);

         mo_global.init ('AR');
         mo_global.set_policy_context ('S', l_operating_unit);
         xla_security_pkg.set_security_context (g_ar_appl_id);


         IF l_hdr_exists > 0 AND l_line_exists > 0 AND l_process_notvalid = 0
         THEN
            ar_invoice_api_pub.create_invoice (
               p_api_version            => 1.0,
               p_batch_source_rec       => l_batch_source_rec,
               p_trx_header_tbl         => l_trx_hdr_tbl,
               p_trx_lines_tbl          => l_trx_lines_tbl,
               p_trx_dist_tbl           => l_trx_dist_tbl,
               p_trx_salescredits_tbl   => l_trx_salescredits_tbl,
               x_return_status          => l_return_status,
               x_msg_count              => l_msg_count,
               x_msg_data               => l_msg_data);

            COMMIT;

            logf ('l_return_status ' || l_return_status);
            logf ('l_msg_count ' || l_msg_count);

            IF l_msg_count = 1
            THEN
               logf ('Massage Data ' || l_msg_data);
            END IF;

            IF (l_return_status <> fnd_api.g_ret_sts_success)
            THEN
               logf ('Error Message Count :' || l_msg_count);
               l_error := l_error + 1;
            END IF;


            IF l_msg_count > 0
            THEN
               FOR l_loop_cnt IN 1 .. l_msg_count
               LOOP
                  fnd_msg_pub.get (p_msg_index       => l_loop_cnt,
                                   p_data            => l_msg_data,
                                   p_encoded         => fnd_api.g_false,
                                   p_msg_index_out   => l_dummy_cnt);
                  logf (l_loop_cnt || ':' || l_msg_data);
               END LOOP;
            END IF;

            IF    l_return_status = fnd_api.g_ret_sts_error
               OR l_return_status = fnd_api.g_ret_sts_unexp_error
            THEN
               logf ('');
               logf (
                  '    Return_status :' || l_return_status || ':' || SQLERRM);

               l_error := l_error + 1;

               UPDATE xxshp_trx_smpl_gimmick_stg
                  SET status = 'E',
                      error_message =
                         error_message || SUBSTR (l_msg_data, 1, 2000)
                WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;
            ELSE
               logf ('');
               logf (' Invoice suceessfully generated..!!');
               logf ('');

               --m.check batch/invoices created
               BEGIN
                  SELECT DISTINCT batch_id
                    INTO l_batch_id
                    FROM ar_trx_header_gt;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     NULL;
               END;

               IF l_batch_id IS NOT NULL
               THEN
                  logf (
                        'SUCCESS: Created batch_id = '
                     || l_batch_id
                     || ' containing the following customer_trx_id:');

                  -- Print Success Invoice
                  print_invoice (l_batch_id, p_file_id);

                  UPDATE xxshp_trx_smpl_gimmick_stg
                     SET status = 'S',
                         error_message =
                            error_message || SUBSTR (l_msg_data, 1, 2000)
                   WHERE     1 = 1
                         AND NVL (flag, 'Y') = 'Y'
                         AND file_id = p_file_id;

                  FOR c IN cBatch
                  LOOP
                     logf (' ' || c.customer_trx_id);
                  END LOOP;
               END IF;
            END IF;

            COMMIT;
         ELSE
            logf ('');
            logf (
                  '    Error validation : '
               || l_hdr_exists
               || '-'
               || l_line_exists
               || '-'
               || l_process_notvalid);
            l_error := l_error + 1;
         END IF;

         --n.Within the batch, check if some invoices raised errors
         BEGIN
            SELECT COUNT (*) INTO l_cnt FROM ar_trx_errors_gt;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         IF l_cnt > 0
         THEN
            logf ('FAILURE: Errors encountered, see list below:');

            FOR i IN list_errors
            LOOP
               logf ('');
               logf ('Header ID = ' || TO_CHAR (i.trx_header_id));
               logf ('Line ID = ' || TO_CHAR (i.trx_line_id));
               logf ('Sales Credit ID = ' || TO_CHAR (i.trx_salescredit_id));
               logf ('Dist Id = ' || TO_CHAR (i.trx_dist_id));
               logf ('Contingency ID = ' || TO_CHAR (i.trx_contingency_id));
               logf ('Message = ' || SUBSTR (i.error_message, 1, 80));
               logf ('Invalid Value = ' || SUBSTR (i.invalid_value, 1, 80));
               logf ('');
            END LOOP;
         END IF;

         IF l_error > 0
         THEN
            --print_result (file_id);
            retcode := 1;                                  -- complete warning
         ELSIF l_error = 0 AND l_val_rec = 0
         THEN
            NULL;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error in Create Invoice ..' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
         retcode := 2;
   END process_data;

   PROCEDURE final_validation (p_file_id NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;

      CURSOR c_notvalid_items
      IS
           SELECT file_id, status
             FROM xxshp_trx_smpl_gimmick_stg tsg
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'Y') = 'Y'
                  AND file_id = p_file_id
         GROUP BY file_id, status;
   BEGIN
      l_jml_data := 0;

      FOR i IN c_notvalid_items
      LOOP
         EXIT WHEN c_notvalid_items%NOTFOUND;

         l_jml_data := l_jml_data + 1;

         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      END IF;

      IF l_nextproceed
      THEN
         UPDATE xxshp_trx_smpl_gimmick_stg
            SET status = 'E', flag = 'N'
          WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

         COMMIT;
      END IF;

      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_trx_smpl_gimmick_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('Error validation count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         print_result (p_file_id);

         logf ('Error, for data all ..!!!');
      ELSE
         logf ('Successfully, for data all ..!!!');
      END IF;
   END final_validation;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER)
   IS
      v_filename             VARCHAR2 (50);
      v_blob_data            BLOB;
      v_blob_len             NUMBER;
      v_position             NUMBER;
      v_loop                 NUMBER;
      v_raw_chunk            RAW (10000);
      c_chunk_len            NUMBER := 1;
      v_char                 CHAR (1);
      v_line                 VARCHAR2 (32767) := NULL;
      v_tab                  VARCHAR2_TABLE;
      v_tablen               NUMBER;
      x                      NUMBER;
      l_err                  NUMBER := 0;

      l_line_attribute3      VARCHAR2 (240);
      l_transaction_type     VARCHAR2 (240);
      l_reference_no         VARCHAR2 (240);
      l_description          VARCHAR2 (240);
      l_currency_code        VARCHAR2 (240);
      l_amount               VARCHAR2 (240);
      l_customer_name        VARCHAR2 (240);
      l_bill_to              VARCHAR2 (240);
      l_ship_to              VARCHAR2 (240);
      l_trx_date             DATE;
      l_trx_number           VARCHAR2 (240);
      l_line_number          NUMBER;
      l_quantity             NUMBER;
      l_quantity_ordered     NUMBER;
      l_unit_selling_price   NUMBER;

      l_cust_ship_id         NUMBER;
      l_cust_bill_id         NUMBER;
      l_cust_id              NUMBER;
      l_amt                  NUMBER;

      l_status               VARCHAR2 (20);
      l_error_message        VARCHAR2 (32767);

      l_err_cnt              NUMBER;
      l_stg_cnt              NUMBER := 0;
      l_cnt_err_format       NUMBER := 0;

      l_set_process_id       NUMBER := 0;
   BEGIN
      BEGIN
         SELECT file_data, file_name
           INTO v_blob_data, v_filename
           FROM fnd_lobs
          WHERE 1 = 1 AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;

      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len)
      LOOP
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10)
         THEN
            IF v_position <> v_blob_len
            THEN
               v_line :=
                  REPLACE (
                     REPLACE (
                        SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1),
                        CHR (13),
                        ''),
                     CHR (10),
                     '');
            END IF;

            delimstring_to_table (p_delimstring   => v_line,
                                  p_table         => v_tab,
                                  p_nfields       => x,
                                  p_a             => v_tablen,
                                  p_delim         => ';');


            IF x = 13
            THEN
               IF v_loop >= 2
               THEN
                  FOR i IN 1 .. x
                  LOOP
                     IF i = 1
                     THEN
                        l_line_attribute3 := TRIM (v_tab (1));
                     ELSIF i = 2
                     THEN
                        l_transaction_type := TRIM (v_tab (2));
                     ELSIF i = 3
                     THEN
                        l_reference_no := TRIM (v_tab (3));
                     ELSIF i = 4
                     THEN
                        l_description := TRIM (v_tab (4));
                     ELSIF i = 5
                     THEN
                        l_currency_code := TRIM (v_tab (5));
                     ELSIF i = 6
                     THEN
                        l_amount := TRIM (v_tab (6));
                     ELSIF i = 7
                     THEN
                        l_customer_name := TRIM (v_tab (7));
                     ELSIF i = 8
                     THEN
                        l_bill_to := TRIM (v_tab (8));
                     ELSIF i = 9
                     THEN
                        l_ship_to := TRIM (v_tab (9));
                     ELSIF i = 10
                     THEN
                        l_trx_date := TRIM (v_tab (10));
                     ELSIF i = 11
                     THEN
                        l_line_number := TRIM (v_tab (11));
                     ELSIF i = 12
                     THEN
                        l_quantity := TRIM (v_tab (12));
                     ELSIF i = 13
                     THEN
                        l_unit_selling_price := TRIM (v_tab (13));
                     END IF;
                  END LOOP;

                  l_err_cnt := 0;
                  l_error_message := NULL;

                  /*IF l_line_attribute3 IS NULL
                  THEN
                     l_error_message :=
                           l_error_message
                        || ' Invalid Interface line attribute3, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;*/

                  IF l_transaction_type IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid transaction type, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_reference_no IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Reference No Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_amount IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Ammount Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_customer_name IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Customer Name Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  ELSE
                     BEGIN
                        SELECT ship_cus.cust_account_id
                          INTO l_cust_id
                          FROM hz_cust_accounts_all ship_cus,
                               hz_parties ship_party
                         WHERE     1 = 1
                               AND ship_party.party_id = ship_cus.party_id
                               AND ship_party.party_name = l_customer_name;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           l_error_message :=
                              l_error_message || ' Invalid Customer Name, ';
                           l_err_cnt := l_err_cnt + 1;
                     END;
                  END IF;

                  IF l_bill_to IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Bill To Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  ELSE
                     BEGIN
                        SELECT ship_cus.cust_account_id
                          INTO l_cust_bill_id
                          FROM hz_cust_accounts_all ship_cus,
                               hz_parties ship_party,
                               hz_party_sites hps_ship,
                               hz_cust_site_uses_all hcs_ship,
                               hz_cust_acct_sites_all hca_ship
                         WHERE     1 = 1
                               AND hps_ship.party_id = ship_party.party_id
                               AND ship_party.party_id = ship_cus.party_id
                               AND hcs_ship.site_use_code = 'BILL_TO'
                               AND hca_ship.cust_acct_site_id =
                                      hcs_ship.cust_acct_site_id
                               AND hps_ship.party_site_id =
                                      hca_ship.party_site_id
                               AND ship_party.party_name = l_bill_to;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           l_error_message :=
                              l_error_message || ' Invalid Bill To, ';
                           l_err_cnt := l_err_cnt + 1;
                     END;
                  END IF;

                  IF l_ship_to IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Ship To Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  ELSE
                     BEGIN
                        SELECT ship_cus.cust_account_id
                          INTO l_cust_ship_id
                          FROM hz_cust_accounts_all ship_cus,
                               hz_parties ship_party,
                               hz_party_sites hps_ship,
                               hz_cust_site_uses_all hcs_ship,
                               hz_cust_acct_sites_all hca_ship
                         WHERE     1 = 1
                               AND hps_ship.party_id = ship_party.party_id
                               AND ship_party.party_id = ship_cus.party_id
                               AND hcs_ship.site_use_code = 'SHIP_TO'
                               AND hca_ship.cust_acct_site_id =
                                      hcs_ship.cust_acct_site_id
                               AND hps_ship.party_site_id =
                                      hca_ship.party_site_id
                               AND ship_party.party_name = l_ship_to;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           l_error_message :=
                              l_error_message || ' Invalid Ship To, ';
                           l_err_cnt := l_err_cnt + 1;
                     END;
                  END IF;

                  IF l_trx_date IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Date Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_line_number IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Line Number Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_quantity IS NULL
                  THEN
                     l_error_message :=
                        l_error_message || ' Invalid Quantity Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_unit_selling_price IS NULL
                  THEN
                     l_error_message :=
                           l_error_message
                        || ' Invalid Unit Selling Price Null, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_amount IS NOT NULL
                  THEN
                     l_amt := l_quantity * l_unit_selling_price;

                     IF l_amount <> l_amt
                     THEN
                        l_error_message :=
                              l_error_message
                           || ' Invalid Amount Sum not equal (quantity * unit_selling_price), ';
                        l_err_cnt := l_err_cnt + 1;
                     END IF;
                  END IF;

                  --*/
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                    INTO l_status
                    FROM DUAL;

                  BEGIN
                     EXECUTE IMMEDIATE
                        'insert into xxshp_trx_smpl_gimmick_stg(
                                       file_id                      ,
                                       file_name                    ,
                                       set_process_id               ,
                                       interface_line_attribute3    ,
                                       transaction_type             ,
                                       reference_no                 ,
                                       description                  ,
                                       currency_code                ,
                                       amount                       ,
                                       customer_name                ,
                                       bill_to                      ,
                                       ship_to                      ,
                                       trx_date                     ,
                                       line_number                  ,
                                       quantity                     ,
                                       unit_selling_price           ,
                                       status                       ,
                                       error_message                ,
                                       created_by                   ,
                                       creation_date                ,
                                       last_updated_by              ,
                                       last_update_date             ,
                                       last_update_login            )
                         VALUES(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,:20,:21,:22,:23)'
                        USING p_file_id,
                              v_filename,
                              l_set_process_id,
                              l_line_attribute3,
                              l_transaction_type,
                              l_reference_no,
                              l_description,
                              l_currency_code,
                              l_amount,
                              l_customer_name,
                              l_bill_to,
                              l_ship_to,
                              l_trx_date,
                              l_line_number,
                              l_quantity,
                              l_unit_selling_price,
                              l_status,
                              l_error_message,
                              g_user_id,
                              SYSDATE,
                              g_user_id,
                              SYSDATE,
                              g_login_id;
                  --COMMIT;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf (SQLERRM);
                        l_err := l_err + 1;
                        retcode := 2;
                  END;
               END IF;

               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len
               THEN
                  logf ('Upload File Finished');
               ELSE
                  logf (
                        'Wrong file,please check the comma delimiter has '
                     || x
                     || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);

      IF l_err > 0
      THEN
         ROLLBACK;
         logf (
               'File: '
            || v_filename
            || ' has 0 rows inserting to staging table, ROLLBACK');

         retcode := 2;
      ELSE
         COMMIT;
         logf (
               'File: '
            || v_filename
            || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan

         final_validation (p_file_id);

         --/*
         SELECT COUNT (*)
           INTO l_stg_cnt
           FROM xxshp_trx_smpl_gimmick_stg
          WHERE 1 = 1 AND NVL (status, 'N') = 'N' AND file_id = p_file_id;

         IF NVL (l_stg_cnt, 0) > 0
         THEN
            process_data (errbuf, retcode, p_file_id);
         --NULL;
         END IF;

         UPDATE fnd_lobs
            SET expiration_date = SYSDATE, upload_date = SYSDATE
          WHERE 1 = 1 AND file_id = p_file_id;
      --*/

      END IF;
   --print_result(p_file_id);

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Error others : ' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data;
END XXSHP_TRX_SMPL_GIMMICK_UPL_PKG;
/
