CREATE OR REPLACE PACKAGE BODY APPS.XXKHD_AR_INVOICE_MOCHA_PKG
IS
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
      DBMS_OUTPUT.PUT_LINE (v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END;

   PROCEDURE GetShipToID_BillToID (p_bill_to_customer_id      OUT NUMBER,
                                   p_bill_to_site_use_id      OUT NUMBER,
                                   p_ship_to_customer_id      OUT NUMBER,
                                   p_ship_to_site_use_id      OUT NUMBER,
                                   p_vendor_name           IN     VARCHAR2)
   IS
   BEGIN
      SELECT SUM (REKAP.bill_to_customer_id) bill_to_customer_id,
             SUM (REKAP.bill_to_site_use_id) bill_to_site_use_id,
             SUM (REKAP.ship_to_customer_id) ship_to_customer_id,
             SUM (REKAP.ship_to_site_use_id) ship_to_site_use_id
        INTO p_bill_to_customer_id,
             p_bill_to_site_use_id,
             p_ship_to_customer_id,
             p_ship_to_site_use_id
        FROM (SELECT ship_party.party_id,
                     RTRIM (LTRIM (ship_party.party_name)) party_name,
                     0 bill_to_customer_id,
                     0 bill_to_site_use_id,
                     ship_cus.cust_account_id ship_to_customer_id,
                     hcs_ship.site_use_id ship_to_site_use_id
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
                     AND ship_party.party_name = p_vendor_name
              UNION ALL
              SELECT ship_party.party_id,
                     RTRIM (LTRIM (ship_party.party_name)) party_name,
                     ship_cus.cust_account_id bill_to_customer_id,
                     hcs_ship.site_use_id bill_to_site_use_id,
                     0 ship_to_customer_id,
                     0 ship_to_site_use_id
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
                     AND ship_party.party_name = p_vendor_name) REKAP
       WHERE 1 = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_bill_to_customer_id := 0;
         p_bill_to_site_use_id := 0;
         p_ship_to_customer_id := 0;
         p_ship_to_site_use_id := 0;

         logf (SQLCODE || ' Error in Get Ship_TO and Bill_TO :' || SQLERRM);
   END GetShipToID_BillToID;
   
   PROCEDURE process_data (errbuf          OUT VARCHAR2,
                           retcode         OUT VARCHAR2,
                           p_file_id    IN     NUMBER,
                           p_group_id   IN     VARCHAR2)
   IS
      l_cust_trx_id            NUMBER;
      l_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type;
      l_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type;
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

      l_line                   NUMBER := 0;
      l_hdr_exists             NUMBER := 0;
      l_line_exists            NUMBER := 0;

      l_error                  NUMBER := 0;
      l_trx_number             VARCHAR2 (20);
      l_trx_date               DATE;
      l_val                    NUMBER;
      l_val_rec                NUMBER;
      l_jml_data               NUMBER;
      l_nextproceed            BOOLEAN := FALSE;

      e_excp                   EXCEPTION;

      CURSOR data_grp_stg (
         p_file_id     NUMBER,
         p_group_id    VARCHAR2)
      IS
           SELECT interface_id,
                  invoice_num,
                  gl_date,
                  invoice_date,
                  currency_code,
                  GROUP_ID,
                  bill_to_customer_id,
                  bill_to_site_use_id,
                  ship_to_customer_id,
                  ship_to_site_use_id,
                  term_id,
                  transaction_type
             FROM XXKHD_AR_MOCHA_RCV_STG
            WHERE     file_id = p_file_id
                  AND GROUP_ID = p_group_id
                  AND NVL (process_status, 'N') = 'P1'
                  AND NVL (process_flag, 'N') = 'Y'
         GROUP BY interface_id,
                  invoice_num,
                  gl_date,
                  invoice_date,
                  currency_code,
                  GROUP_ID,
                  bill_to_customer_id,
                  bill_to_site_use_id,
                  ship_to_customer_id,
                  ship_to_site_use_id,
                  term_id,
                  transaction_type;

      CURSOR data_ar_stg (p_interface_id NUMBER)
      IS
         SELECT code_combination_id, amount, description
           FROM XXKHD_AR_MOCHA_DTL_STG
          WHERE interface_id = p_interface_id;
   BEGIN
      l_jml_data := 0;

      FOR i IN data_grp_stg (p_file_id, p_group_id)
      LOOP
         EXIT WHEN data_grp_stg%NOTFOUND;

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

         fnd_global.apps_initialize (g_user_id,
                                     g_resp_id,
                                     g_resp_appl_id,
                                     0);

         mo_global.init ('AR');
         mo_global.set_policy_context ('S', l_operating_unit);
         xla_security_pkg.set_security_context (g_ar_appl_id);


         -- /* Get set_of_books_id */
         BEGIN
            SELECT set_of_books_id
              INTO l_set_of_books_id
              FROM gl_sets_of_books
             WHERE 1 = 1 AND UPPER (name) = 'KHD_LEDGER_OPERATION';
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
             WHERE 1 = 1 AND name = 'MOCHA';
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

         /*
         logf('    Operating unit     : '||l_operating_unit);
         logf('    Batch source name  : '||l_batch_source_name);
         logf('    Term of Payment    : '||l_term_name);
         logf('    RA_Cust_Trx_Types  : '||l_cust_trx_type_name);
         logf('');
         */

         l_batch_source_rec.batch_source_id := l_batch_source_id;

         l_hdr_exists := 0;

         FOR grp IN data_grp_stg (p_file_id, p_group_id)
         LOOP
            logf ('LOOP HDR START');

            -- /* Get Customer Trx Types */

            BEGIN
               SELECT cust_trx_type_id, description
                 INTO l_cust_trx_type_id, l_cust_trx_type_name
                 FROM ra_cust_trx_types_all
                WHERE 1 = 1 AND UPPER (name) = grp.transaction_type;
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

            BEGIN
               SELECT 1
                 INTO l_val
                 FROM RA_CUSTOMER_TRX_ALL
                WHERE trx_number = grp.invoice_num;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_val := 0;
            END;

            BEGIN
               SELECT 1
                 INTO l_val_rec
                 FROM ar_cash_receipts_all
                WHERE receipt_number = grp.invoice_num AND status <> 'APP';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_val_rec := 0;
            END;

            EXIT WHEN l_val = 1;

            SELECT ra_customer_trx_s.NEXTVAL INTO l_trx_header_id FROM DUAL;

            --            l_process_notvalid := 0;
            l_hdr_exists := 0;

            /*
            logf('');
            logf('    Create RA Interface  ');
            logf('');
            logf('    RA trx header_id   : '||l_trx_header_id);
            logf('    Supplier_name      : '||grp.vendor_name);
            logf('    Supplier_site_code : '||grp.vendor_site_code);
            logf('    KHDex_code         : '||grp.khdex_code);
            */

            l_trx_header_tbl (1).trx_header_id := l_trx_header_id;
            l_trx_header_tbl (1).trx_number := grp.invoice_num;
            l_trx_header_tbl (1).trx_date := grp.invoice_date;
            l_trx_header_tbl (1).gl_date := grp.gl_date;
            --l_trx_header_tbl(1).legal_entity_id            := 23273;
            --l_trx_header_tbl(1).org_id                     := 82;
            --         l_trx_header_tbl (1).interface_header_attribute1 := grp.reference;
            l_trx_header_tbl (1).trx_currency := grp.currency_code;
            l_trx_header_tbl (1).cust_trx_type_id := l_cust_trx_type_id;
            l_trx_header_tbl (1).bill_to_customer_id :=
               grp.bill_to_customer_id;
            l_trx_header_tbl (1).bill_to_site_use_id :=
               grp.bill_to_site_use_id;
            l_trx_header_tbl (1).ship_to_customer_id :=
               grp.ship_to_customer_id;
            l_trx_header_tbl (1).ship_to_site_use_id :=
               grp.ship_to_site_use_id;
            l_trx_header_tbl (1).term_id := grp.term_id;
            l_trx_header_tbl (1).attribute3 := grp.GROUP_ID;
            l_trx_header_tbl (1).finance_charges := NULL;
            l_trx_header_tbl (1).default_tax_exempt_flag := 'S';
            l_trx_header_tbl (1).status_trx := 'OP';
            l_trx_header_tbl (1).printing_option := 'PRI';

            l_hdr_exists := l_hdr_exists + 1;

            l_line := 0;
            l_line_exists := 0;

            /*logf('trx_header_id '||l_trx_header_tbl (1).trx_header_id);
            logf('trx_number '||l_trx_header_tbl (1).trx_number);
            logf('trx_date '||l_trx_header_tbl (1).trx_date);
            logf('gl_date '||l_trx_header_tbl (1).gl_date);
            logf('trx_currency '||l_trx_header_tbl (1).trx_currency);
            logf('cust_trx_type_id '||l_trx_header_tbl (1).cust_trx_type_id);
            logf('bill_to_customer_id '||l_trx_header_tbl (1).bill_to_customer_id);
            logf('bill_to_site_use_id '||l_trx_header_tbl (1).bill_to_site_use_id);
            logf('ship_to_customer_id '||l_trx_header_tbl (1).ship_to_customer_id);
            logf('ship_to_site_use_id '||l_trx_header_tbl (1).ship_to_site_use_id);
            logf('term_id '||l_trx_header_tbl (1).term_id);
            logf('attribute3 '||l_trx_header_tbl (1).attribute3);*/

            FOR rec IN data_ar_stg (grp.interface_id)
            LOOP
               SELECT ra_customer_trx_lines_s.NEXTVAL
                 INTO l_trx_line_id
                 FROM DUAL;

               SELECT ra_cust_trx_line_gl_dist_s.NEXTVAL
                 INTO l_trx_dist_id
                 FROM DUAL;

               l_line := l_line + 1;

               l_trx_lines_tbl (l_line).trx_header_id := l_trx_header_id;
               l_trx_lines_tbl (l_line).trx_line_id := l_trx_line_id;
               l_trx_lines_tbl (l_line).line_number := l_line;
               l_trx_lines_tbl (l_line).line_type := 'LINE';
               l_trx_lines_tbl (l_line).inventory_item_id := NULL;
               l_trx_lines_tbl (l_line).description := rec.description;
               l_trx_lines_tbl (l_line).quantity_invoiced := rec.amount;
               l_trx_lines_tbl (l_line).unit_selling_price := 1;
               -- l_trx_lines_tbl(l_line).uom_code                 := 'IDR'; edit by ABP --> Request Devo 20181026

               l_trx_dist_tbl (l_line).trx_dist_id := l_trx_dist_id;
               l_trx_dist_tbl (l_line).trx_line_id := l_trx_line_id;
               l_trx_dist_tbl (l_line).account_class := 'REV';
               l_trx_dist_tbl (l_line).percent := 100;
               l_trx_dist_tbl (l_line).code_combination_id :=
                  rec.code_combination_id;
               l_trx_dist_tbl (l_line).amount := rec.amount;

               logf ('');
               logf (l_line);
               logf (
                  'trx_header_id ' || l_trx_lines_tbl (l_line).trx_header_id);
               logf ('trx_line_id ' || l_trx_lines_tbl (l_line).trx_line_id);
               logf ('line_number ' || l_trx_lines_tbl (l_line).line_number);
               logf (
                     'quantity_invoiced '
                  || l_trx_lines_tbl (l_line).quantity_invoiced);
               logf ('trx_dist_id ' || l_trx_dist_tbl (l_line).trx_dist_id);
               logf (
                     'code_combination_id '
                  || l_trx_dist_tbl (l_line).code_combination_id);
               logf ('amount ' || l_trx_dist_tbl (l_line).amount);



               l_line_exists := l_line_exists + 1;
            END LOOP;

            IF     l_hdr_exists > 0
               AND l_line_exists > 0
               AND l_process_notvalid = 0
            THEN
               ar_invoice_api_pub.create_single_invoice (
                  p_api_version            => 1.0,
                  p_batch_source_rec       => l_batch_source_rec,
                  p_trx_header_tbl         => l_trx_header_tbl,
                  p_trx_lines_tbl          => l_trx_lines_tbl,
                  p_trx_dist_tbl           => l_trx_dist_tbl,
                  p_trx_salescredits_tbl   => l_trx_salescredits_tbl,
                  x_customer_trx_id        => l_customer_trx_id,
                  x_return_status          => l_return_status,
                  x_msg_count              => l_msg_count,
                  x_msg_data               => l_msg_data);

               COMMIT;

               logf ('l_return_status ' || l_return_status);
               logf ('l_msg_count ' || l_msg_count);

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
                  END LOOP;                                  -- msg stack loop
               END IF;                            -- if count of msg stack > 0

               IF    l_return_status = fnd_api.g_ret_sts_error
                  OR l_return_status = fnd_api.g_ret_sts_unexp_error
               THEN
                  logf ('');
                  logf (
                        '    Return_status :'
                     || l_return_status
                     || ':'
                     || SQLERRM);

                  l_error := l_error + 1;

                  UPDATE XXKHD_AR_MOCHA_RCV_STG
                     SET process_status = 'E',
                         error_message =
                            error_message || SUBSTR (l_msg_data, 1, 2000)
                   WHERE     1 = 1
                         AND NVL (process_flag, 'N') = 'Y'
                         AND file_id = p_file_id
                         AND GROUP_ID = p_group_id;
               ELSE
                  logf ('');
                  logf ('     customer_trx_id : ' || l_customer_trx_id);


                  IF l_customer_trx_id IS NOT NULL
                  THEN
                     --                  UPDATE XXKHD_AR_MOCHA_RCV_STG
                     --                     SET process_status = 'S'
                     --                   --                         customer_trx_id = l_customer_trx_id
                     --                   WHERE     1 = 1
                     --                         AND NVL (process_flag, 'N') = 'Y'
                     --                         AND file_id = p_file_id
                     --                         AND GROUP_ID = p_group_id;

                     -- add ABP : 20181110
                     -- update invoice_num to MRC table staging

                     l_trx_number := NULL;
                     l_trx_date := NULL;

                     SELECT trx_number, trx_date
                       INTO l_trx_number, l_trx_date
                       FROM ra_customer_trx_all
                      WHERE 1 = 1 AND customer_trx_id = l_customer_trx_id;


                     UPDATE XXKHD_AR_MOCHA_RCV_STG
                        SET                      --invoice_num = l_trx_number,
                           process_date = l_trx_date,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE
                      WHERE     1 = 1
                            AND file_id = p_file_id
                            AND GROUP_ID = p_group_id;

                     --                         AND invoice_num IS NULL
                     --                         AND supplier_site_code = grp.vendor_site_code
                     --                         AND TP_Code = grp.khdex_code;

                     logf (' Invoice suceessfully generated..!!');
                     logf ('');
                  ELSE
                     UPDATE XXKHD_AR_MOCHA_RCV_STG
                        SET process_status = 'X',
                            --                         customer_trx_id = l_customer_trx_id,
                            error_message =
                                  'Error Interface - '
                               || SUBSTR (l_msg_data, 1, 2000)
                      WHERE     1 = 1
                            AND NVL (process_flag, 'N') = 'Y'
                            AND file_id = p_file_id
                            AND GROUP_ID = p_group_id;

                     logf (' Invoice failed to generate..!!');
                     logf ('');
                     l_error := l_error + 1;
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
         END LOOP;

         IF l_error > 0
         THEN
            --         print_finalresult (p_intface_id);
            --         print_result (p_intface_id);
            retcode := 1;                                  -- complete warning
         --      ELSE
         --         print_finalresult (p_intface_id);
         ELSIF l_error = 0 AND l_val_rec = 0
         THEN
            /*Now running receipt AR API*/
            XXKHD_AR_RECEIPT_MOCHA_PKG.main_process (errbuf,
                                                     retcode,
                                                     p_file_id,
                                                     p_group_id);
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error in Create Single Invoice ..' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         retcode := 2;
   END process_data;

   PROCEDURE final_validation (p_intface_id NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;


      CURSOR c_DataNotValid
      IS
           SELECT interface_id, process_status
             FROM XXKHD_AR_MOCHA_RCV_STG
            WHERE     1 = 1
                  AND NVL (process_status, 'E') = 'E'
                  AND NVL (process_flag, 'N') = 'N'
                  AND interface_id = p_intface_id
         GROUP BY interface_id, process_status;
   BEGIN
      l_jml_data := 0;

      FOR i IN c_DataNotValid
      LOOP
         EXIT WHEN c_DataNotValid%NOTFOUND;

         l_jml_data := l_jml_data + 1;
         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      END IF;

      IF l_nextproceed
      THEN
         UPDATE XXKHD_AR_MOCHA_RCV_STG
            SET process_status = 'E', process_flag = 'Y'
          WHERE     1 = 1
                AND NVL (process_flag, 'N') = 'N'
                AND interface_id = p_intface_id;
      ELSE
         UPDATE XXKHD_AR_MOCHA_RCV_STG
            SET process_status = 'P1', process_flag = 'Y'
          WHERE     1 = 1
                AND NVL (process_flag, 'N') = 'N'
                AND interface_id = p_intface_id;
      END IF;

      COMMIT;

      SELECT COUNT (1)
        INTO l_error
        FROM XXKHD_AR_MOCHA_RCV_STG
       WHERE     1 = 1
             AND NVL (process_status, 'E') = 'E'
             AND NVL (process_flag, 'N') = 'Y'
             AND interface_id = p_intface_id;


      logf ('');
      logf (
            'Err Record Count : '
         || LTRIM (RTRIM (TO_CHAR (l_error, '999G999')))
         || ' records');

      logf ('');
      logf ('**/ STEP-01. Upload Data staging  **/');
      logf ('');

      IF l_error > 0
      THEN
         --         print_result (p_intface_id);

         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         logf ('    Error, Upload data staging failed ..!!!');
      ELSE
         logf ('     **/ Upload data staging succeed..!!');
         logf ('');
      END IF;
   END final_validation;

   PROCEDURE insert_data (errbuf         OUT VARCHAR2,
                          retcode        OUT NUMBER,
                          p_file_id   IN     NUMBER)
   IS
      v_filename               VARCHAR2 (50);
      v_blob_data              BLOB;
      v_blob_len               NUMBER;
      v_position               NUMBER;
      v_loop                   NUMBER;
      v_raw_chunk              RAW (10000);
      c_chunk_len              NUMBER := 1;
      v_char                   CHAR (1);
      v_line                   VARCHAR2 (32767) := NULL;
      v_tab                    VARCHAR2_TABLE;
      v_tablen                 NUMBER;
      x                        NUMBER;
      l_err                    NUMBER := 0;

      v_baris                  NUMBER := 0;
      v_counter                NUMBER := 0;
      v_countermax             NUMBER := 0;


      l_status                 VARCHAR2 (20);
      l_error_message          VARCHAR2 (200);

      l_err_cnt                NUMBER;
      l_stg_cnt                NUMBER := 0;
      l_data_cnt               NUMBER := 0;
      l_file_cnt               NUMBER := 0;
      l_cnt_err_format         NUMBER := 0;
      l_sql                    VARCHAR2 (4000);


      l_ou_id                  NUMBER := 0;
      l_ledger_id              NUMBER := 0;
      l_chart_of_accounts_id   NUMBER := 0;
      l_code_combination_id    NUMBER := 0;
      l_inventory_item_id      NUMBER := 0;
      l_org_id                 NUMBER := 0;
      l_code_combination       VARCHAR2 (50);

      l_amount                 NUMBER := 0;


      l_vendor_id              NUMBER := 0;
      l_no_npwp                VARCHAR2 (50);
      l_order_no               VARCHAR2 (50);
      l_doc_date               VARCHAR2 (40);
      l_vendor_site_id         NUMBER := 0;
      l_vendor_name            VARCHAR2 (240);


      l_bill_to_customer_id    NUMBER := 0;
      l_bill_to_site_use_id    NUMBER := 0;
      l_ship_to_customer_id    NUMBER := 0;
      l_ship_to_site_use_id    NUMBER := 0;


      l_next_proceed           NUMBER := 0;

      l_jml_data               NUMBER := 0;
      l_period_ap              VARCHAR2 (10);

      l_nextproceed            BOOLEAN := FALSE;
      l_detail_nextproceed     BOOLEAN := FALSE;
      l_first                  BOOLEAN := TRUE;
      l_intface_id             NUMBER := 0;
      l_coa                    VARCHAR2 (50);
      l_coa_id                 NUMBER;
      l_new_coa                VARCHAR2 (50);
      l_coa_category           VARCHAR2 (50);

      l_expense_type           VARCHAR2 (50);
      l_conc_status            BOOLEAN;
      l_row_cnt                NUMBER;
   BEGIN
      BEGIN
         SELECT ledger_id, chart_of_accounts_id
           INTO l_ledger_id, l_chart_of_accounts_id
           FROM gl_ledgers
          WHERE 1 = 1 AND UPPER (ledger_category_code) = 'PRIMARY';
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;

      BEGIN
         SELECT organization_id
           INTO l_ou_id
           FROM hr_all_organization_units
          WHERE 1 = 1 AND UPPER (name) LIKE '%OPERATING UNIT';
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Operation Unit');
            RAISE NO_DATA_FOUND;
      END;


      FOR i IN c_DataHeader (p_file_id)
      LOOP
         EXIT WHEN c_DataHeader%NOTFOUND;

         l_jml_data := l_jml_data + 1;

         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      ELSE
         logf ('** No Data found..!!**');
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);
      END IF;

      IF l_nextproceed
      THEN
         FOR rec IN c_dataheader (p_file_id)
         LOOP
            SELECT rec.interface_id INTO l_intface_id FROM DUAL;

            l_err_cnt := 0;
            l_error_message := NULL;
            l_first := TRUE;

            -- validasi gl_date with open period AR
            BEGIN
               l_period_ap := NULL;

               SELECT gps.period_name
                 INTO l_period_ap
                 FROM gl_period_statuses gps
                WHERE     1 = 1
                      AND gps.ledger_id = l_ledger_id                   --2021
                      AND gps.period_name = TO_CHAR (rec.gl_date, 'MON-YY')
                      AND closing_status = 'O'
                      AND application_id = g_ar_appl_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_error_message :=
                        l_error_message
                     || ', Invalid period AR : '
                     || rec.gl_date;          --to_char(rec.gl_date,'MON-YY');
                  l_err_cnt := l_err_cnt + 1;
            END;

            l_row_cnt := 1;

            FOR det IN c_datadetail (p_file_id, rec.GROUP_ID)
            LOOP
               /***
               logf('New COA : ' ||l_new_coa);
               logf('Error Msg : ' ||l_error_message);
               ***/

               --find COA meaning
               BEGIN
                  SELECT ccid.code_combination_id, fsa.concatenated_segments
                    INTO l_coa_id, l_coa
                    FROM FND_ID_FLEX_STRUCTURES_VL FSV,
                         FND_SHORTHAND_FLEX_ALIASES FSA,
                         GL_CODE_COMBINATIONS_KFV CCID
                   WHERE     1 = 1
                         AND id_flex_structure_code =
                                'KHD_OPERATIONS_ACC_FLEXFIELD'
                         AND fsv.id_flex_num = fsa.id_flex_num
                         AND fsv.id_flex_code = fsa.id_flex_code
                         AND fsa.concatenated_segments =
                                ccid.concatenated_segments
                         AND UPPER (fsa.alias_name) = UPPER (det.coa);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_error_message :=
                           l_error_message
                        || ', Find COA meaning error : '
                        || rec.gl_date;       --to_char(rec.gl_date,'MON-YY');
                     l_err_cnt := l_err_cnt + 1;
               END;

               SELECT DECODE (l_err_cnt, 0, 'N', 'E') INTO l_status FROM DUAL;

               --                     IF l_amount <> 0
               --                     THEN
               --insert to staging

               l_sql :=
                     'INSERT INTO XXKHD_AR_MOCHA_DTL_STG(
                                                    interface_id               ,
                                                    line_num                   ,
                                                    code_combination_id        ,
                                                    code_combination           ,
                                                    amount                     ,
                                                    description                ,
                                                    created_by                 ,
                                                    last_updated_by            ,
                                                    creation_date              ,
                                                    last_update_date           ,
                                                    last_update_login  ) 
                                             VALUES('
                  || l_intface_id
                  || ','
                  || l_row_cnt
                  || ','
                  || l_coa_id
                  || ','''
                  || l_coa
                  || ''','
                  || det.amount
                  || ','''
                  || det.description_coa
                  --                  || ''','''
                  --                  || l_status
                  --                  || ''','''
                  --                  || l_error_message
                  || ''','
                  || g_user_id
                  || ','
                  || g_user_id
                  || ', SYSDATE'
                  || ', SYSDATE,'
                  || g_login_id
                  || ')';

               -- logf ('l_sql : ' || l_sql);
               BEGIN
                  EXECUTE IMMEDIATE l_sql;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf (SQLERRM);
                     l_err := l_err + 1;
               END;

               --                     END IF;
               --                  END LOOP;
               --               END;
               l_row_cnt := l_row_cnt + 1;
            END LOOP;

            logf ('v_err : ' || l_err);

            IF l_err > 0
            THEN
               ROLLBACK;
               logf (
                     'Interface ID : '
                  || l_intface_id
                  || ' has 0 rows inserting to staging table, ROLLBACK');

               retcode := 2;
            ELSE
               COMMIT;
               logf (
                     'Interface ID : '
                  || l_intface_id
                  || ' succesfully inserting to staging table,COMMIT');


               final_validation (l_intface_id);

               SELECT COUNT (1)
                 INTO l_stg_cnt
                 FROM XXKHD_AR_MOCHA_RCV_STG
                WHERE     1 = 1
                      AND NVL (process_status, 'N') = 'P1'
                      AND NVL (process_flag, 'N') = 'Y'
                      AND interface_id = l_intface_id;
            --            IF l_stg_cnt > 0
            --            THEN
            --               process_data (errbuf, retcode, p_file_id);
            --            END IF;
            END IF;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         logf ('error no data found');
         logf ('Error Line : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Error others : ' || SQLERRM);
         logf ('Error Line : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data;

   PROCEDURE insert_header (errbuf         OUT VARCHAR2,
                            retcode        OUT NUMBER,
                            p_file_id   IN     NUMBER)
   IS
      l_vendor_name           VARCHAR2 (500);
      l_bill_to_customer_id   NUMBER := 0;
      l_bill_to_site_use_id   NUMBER := 0;
      l_ship_to_customer_id   NUMBER := 0;
      l_ship_to_site_use_id   NUMBER := 0;
      l_error_message         VARCHAR2 (32756);
      l_iface_id              NUMBER;
      l_err_cnt               NUMBER := 0;
   BEGIN
      fnd_global.apps_initialize (g_user_id,
                                  g_resp_id,
                                  g_resp_appl_id,
                                  0);

      BEGIN
         BEGIN
            SELECT DISTINCT customer
              INTO l_vendor_name
              FROM XXKHD_UPLD_MOCCA_REC_STG
             WHERE file_id = p_file_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_message := l_error_message || ', Vendor not found ';
               l_err_cnt := l_err_cnt + 1;
         END;

         GetShipToID_BillToID (l_bill_to_customer_id,
                               l_bill_to_site_use_id,
                               l_ship_to_customer_id,
                               l_ship_to_site_use_id,
                               l_vendor_name);

         IF (  l_bill_to_customer_id
             + l_bill_to_site_use_id
             + l_ship_to_customer_id
             + l_ship_to_site_use_id) = 0
         THEN
            l_error_message :=
                  l_error_message
               || ', Invalid mapping supplier_name : '
               || l_vendor_name;
            l_err_cnt := l_err_cnt + 1;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_error_message :=
               l_error_message || ', Invalid mapping supplier_site_code : ';
            l_err_cnt := l_err_cnt + 1;
      END;

      FOR i IN (SELECT DISTINCT GROUP_ID
                  FROM XXKHD_UPLD_MOCCA_REC_STG
                 WHERE file_Id = p_file_id)
      LOOP
         BEGIN
            l_iface_id := XXKHD_AR_MOCHA_RCV_STG_S.NEXTVAL;

            INSERT INTO XXKHD_AR_MOCHA_RCV_STG (INTERFACE_ID,
                                                FILE_ID,
                                                BANK_ACCOUNT_NUM,
                                                BANK_ACCOUNT_NAME,
                                                ACCEPT_DATE,
                                                GL_DATE,
                                                INVOICE_DATE,
                                                CURRENCY_CODE,
                                                TOTAL_AMOUNT,
                                                STATUS,
                                                GROUP_ID,
                                                TRANSACTION_TYPE,
                                                VENDOR_ID,
                                                VENDOR_NAME,
                                                BILL_TO_CUSTOMER_ID,
                                                BILL_TO_SITE_USE_ID,
                                                SHIP_TO_CUSTOMER_ID,
                                                SHIP_TO_SITE_USE_ID,
                                                TERM_ID,
                                                INVOICE_NUM,
                                                PROCESS_DATE,
                                                PERIODE,
                                                PROCESS_STATUS,
                                                PROCESS_FLAG,
                                                CREATED_BY,
                                                LAST_UPDATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATE_DATE,
                                                LAST_UPDATE_LOGIN)
               (  SELECT l_iface_id,                            --INTERFACE_ID
                         FILE_ID,                                    --FILE_ID
                         BANK_ACCOUNT_NUMBER,               --BANK_ACCOUNT_NUM
                         BANK,                             --BANK_ACCOUNT_NAME
                         RECEIPT_DATE,                           --ACCEPT_DATE
                         GL_DATE_INVOICE,                            --GL_DATE
                         INVOICE_DATE,                          --INVOICE_DATE
                         CURRENCY,                             --CURRENCY_CODE
                         AMOUNT_RECEIPT,                        --TOTAL_AMOUNT
                         'DRAFT',                                     --STATUS
                         GROUP_ID,                                  --GROUP_ID
                         UPPER (TRANSACTION_TYPE),          --TRANSACTION_TYPE
                         (SELECT DISTINCT ARC.CUSTOMER_NUMBER
                            FROM AR_CUSTOMERS ARC,
                                 HZ_CUST_ACCOUNTS_ALL HCA,
                                 HZ_CUST_ACCT_SITES_ALL HCAS
                           WHERE     HCA.CUST_ACCOUNT_ID = HCAS.CUST_ACCOUNT_ID
                                 AND HCA.CUST_ACCOUNT_ID = ARC.CUSTOMER_ID
                                 AND HCAS.ORG_ID = 82
                                 AND LTRIM (RTRIM (UPPER (ARC.CUSTOMER_NAME))) =
                                        LTRIM (RTRIM (UPPER (CUSTOMER)))), --VENDOR_ID
                         CUSTOMER,                               --VENDOR_NAME
                         l_bill_to_customer_id,          --BILL_TO_CUSTOMER_ID
                         l_bill_to_site_use_id,          --BILL_TO_SITE_USE_ID
                         l_ship_to_customer_id,          --SHIP_TO_CUSTOMER_ID
                         l_ship_to_site_use_id,          --SHIP_TO_SITE_USE_ID
                         TERM_ID,                                    --TERM_ID
                         NO_INVOICE,                             --INVOICE_NUM
                         SYSDATE,                               --PROCESS_DATE
                         TO_CHAR (SYSDATE, 'MON-RR'),                --PERIODE
                         'Y',                                 --PROCESS_STATUS
                         'N',                                   --PROCESS_FLAG
                         g_user_id,                               --CREATED_BY
                         g_user_id,                          --LAST_UPDATED_BY
                         SYSDATE,                              --CREATION_DATE
                         SYSDATE,                           --LAST_UPDATE_DATE
                         g_login_id                        --LAST_UPDATE_LOGIN
                    FROM XXKHD_UPLD_MOCCA_REC_STG
                   WHERE file_Id = p_file_id AND GROUP_ID = i.GROUP_ID
                GROUP BY FILE_ID,
                         BANK,
                         BANK_ACCOUNT_NUMBER,
                         RECEIPT_DATE,
                         GL_DATE_INVOICE,
                         INVOICE_DATE,
                         CURRENCY,
                         AMOUNT_RECEIPT,
                         GROUP_ID,
                         TRANSACTION_TYPE,
                         CUSTOMER,
                         TERM_ID,
                         NO_INVOICE);

            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf (
                  'There is a problem when inserting header stg ' || SQLERRM);
               l_error_message :=
                     l_error_message
                  || ' | There is a problem when inserting header stg '
                  || SQLERRM;
               l_err_cnt := l_err_cnt + 1;
         END;
      END LOOP;

      IF l_err_cnt = 0
      THEN
         insert_data (errbuf, retcode, p_file_id);
      ELSE
         UPDATE XXKHD_AR_MOCHA_RCV_STG
            SET process_status = 'E', error_message = l_error_message
          WHERE file_Id = p_file_id;

         COMMIT;
         retcode := 2;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when insert_header procedure ' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

         l_error_message :=
               l_error_message
            || ' Error when insert_header procedure '
            || SQLERRM;

         UPDATE XXKHD_AR_MOCHA_RCV_STG
            SET process_status = 'E', error_message = l_error_message
          WHERE file_Id = p_file_id;

         COMMIT;

         retcode := 2;
   END insert_header;
END XXKHD_AR_INVOICE_MOCHA_PKG;
/