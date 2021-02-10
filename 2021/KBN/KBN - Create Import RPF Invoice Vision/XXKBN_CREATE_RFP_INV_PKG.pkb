CREATE OR REPLACE PACKAGE BODY APPS.xxkbn_create_rfp_inv_pkg
AS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXKBN_CREATE_RFP_INV_PKG                                                              |
   REM |     Concurrent  :                                                                                       |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Planning Parameter New all in this Package                                            |
   REM |     History     : 31 DEC 2020  --Ardianto--                                                             |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */
   PROCEDURE logf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   PROCEDURE validate_invoice_rfp (p_rfp_num   IN     VARCHAR2,
                                   p_req_id       OUT NUMBER,
                                   errbuf         OUT VARCHAR2,
                                   retcode        OUT NUMBER)
   IS
      v_rfp_no          VARCHAR2 (1000);
      v_invoice_id      NUMBER;
      v_batch_id        NUMBER;
      l_request_id      NUMBER;
      v_error_message   VARCHAR2 (100);
      v_phase           VARCHAR2 (50);
      v_out_status      VARCHAR2 (50);
      v_devphase        VARCHAR2 (50);
      v_devstatus       VARCHAR2 (50);
      v_result          BOOLEAN;
      v_request_id      NUMBER DEFAULT 0;
      v_mode            BOOLEAN;
   BEGIN
      logf ('Concurrent Validate Start!');

      BEGIN
           SELECT ab.attribute1 rfp_no, ai.invoice_id, ab.batch_id
             INTO v_rfp_no, v_invoice_id, v_batch_id
             FROM ap.ap_invoices_all ai,
                  ap.ap_batches_all ab,
                  ar.hz_parties hp,
                  fnd_user fu,
                  ap_suppliers aps,
                  iby_ext_bank_accounts ieba,
                  iby_ext_banks_v ieb
            WHERE     ai.batch_id = ab.batch_id
                  AND ai.party_id = hp.party_id
                  AND ab.created_by = fu.user_id
                  AND ai.vendor_id = aps.vendor_id
                  AND ap_invoices_pkg.get_approval_status (
                         ai.invoice_id,
                         ai.invoice_amount,
                         ai.payment_status_flag,
                         ai.invoice_type_lookup_code) NOT IN ('CANCELLED')
                  AND ap_invoices_utility_pkg.get_approval_status (
                         ai.invoice_id,
                         ai.invoice_amount,
                         ai.payment_status_flag,
                         ai.invoice_type_lookup_code) NOT IN ('CANCELLED')
                  AND ieba.ext_bank_account_id(+) = ai.external_bank_account_id
                  AND ieba.bank_id = ieb.bank_party_id(+)
                  AND ab.attribute1 = p_rfp_num
                  AND ai.org_id = g_org_id
         GROUP BY ab.attribute1, ab.batch_id, ai.invoice_id
         ORDER BY ab.batch_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            errbuf := 'No RFP Data Found.';
      END;

      mo_global.set_policy_context ('M', g_org_id);

      fnd_global.apps_initialize (user_id        => 1138,         --g_user_id,
                                  resp_id        => 20639,        --g_resp_id,
                                  resp_appl_id   => 200);   --g_resp_appl_id);

      v_mode := fnd_submit.set_mode (TRUE);

      l_request_id :=
         fnd_request.submit_request ('SQLAP',
                                     'APPRVL',
                                     'Invoice Validation',
                                     SYSDATE,
                                     FALSE,
                                     NULL,
                                     'ALL',                          -- Option
                                     v_batch_id);

      COMMIT;

      logf ('Request ID= ' || l_request_id);

      v_result :=
         fnd_concurrent.wait_for_request (l_request_id,
                                          g_intval_time,
                                          0,
                                          v_phase,
                                          v_out_status,
                                          v_devphase,
                                          v_devstatus,
                                          v_error_message);

      IF v_devphase = 'COMPLETE' AND v_devstatus = 'NORMAL'
      THEN
         p_req_id := l_request_id;
         retcode := 0;
         errbuf := 'Validate Success :' || SQLCODE || ' ' || SQLERRM;
         logf ('Concurrent Validate Success :' || SQLCODE || ' ' || SQLERRM);
      ELSE
         p_req_id := l_request_id;
         retcode := 1;
         errbuf := 'Validate Error =>' || SQLCODE || ' ' || SQLERRM;
         logf ('Concurrent Validate Error =>' || SQLCODE || ' ' || SQLERRM);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_request_id := -1;
         p_req_id := l_request_id;
         errbuf := 'Validate Error =>' || SQLCODE || '**' || SQLERRM;
   END validate_invoice_rfp;

   PROCEDURE insert_iface_hdr (rec ap.ap_invoices_interface%ROWTYPE)
   AS
   BEGIN
      INSERT INTO ap_invoices_interface (invoice_id,
                                         invoice_num,
                                         invoice_type_lookup_code,
                                         invoice_date,
                                         vendor_id,
                                         vendor_site_id,
                                         invoice_amount,
                                         invoice_currency_code,
                                         terms_name,
                                         description,
                                         source,
                                         GROUP_ID,
                                         gl_date,
                                         org_id,
                                         terms_date,
                                         attribute1,
                                         attribute2,
                                         attribute3,
                                         attribute4,
                                         attribute5,
                                         attribute6,
                                         attribute7,
                                         attribute8,
                                         attribute9,
                                         attribute10,
                                         attribute11,
                                         attribute12,
                                         attribute13,
                                         attribute14,
                                         attribute15,
                                         created_by,
                                         creation_date,
                                         last_updated_by,
                                         last_update_date,
                                         last_update_login)
           VALUES (rec.invoice_id,
                   rec.invoice_num,
                   rec.invoice_type_lookup_code,
                   rec.invoice_date,
                   rec.vendor_id,
                   rec.vendor_site_id,
                   rec.invoice_amount,
                   rec.invoice_currency_code,
                   rec.terms_name,
                   rec.description,
                   rec.source,
                   rec.GROUP_ID,
                   rec.gl_date,
                   rec.org_id,
                   rec.terms_date,
                   rec.attribute1,
                   rec.attribute2,
                   rec.attribute3,
                   rec.attribute4,
                   rec.attribute5,
                   rec.attribute6,
                   rec.attribute7,
                   rec.attribute8,
                   rec.attribute9,
                   rec.attribute10,
                   rec.attribute11,
                   rec.attribute12,
                   rec.attribute13,
                   rec.attribute14,
                   rec.attribute15,
                   rec.created_by,
                   rec.creation_date,
                   rec.last_updated_by,
                   rec.last_update_date,
                   rec.last_update_login);
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('error insert to ap_invoices_interface : ' || SQLERRM);
   END insert_iface_hdr;

   PROCEDURE insert_iface_line (rec ap.ap_invoice_lines_interface%ROWTYPE)
   AS
   BEGIN
      INSERT INTO ap_invoice_lines_interface (invoice_id,
                                              invoice_line_id,
                                              line_number,
                                              line_type_lookup_code,
                                              amount,
                                              accounting_date,
                                              description,
                                              dist_code_concatenated,
                                              dist_code_combination_id,
                                              org_id,
                                              awt_group_name,
                                              tax_classification_code,
                                              attribute1,
                                              attribute2,
                                              attribute3,
                                              attribute4,
                                              attribute5,
                                              attribute6,
                                              attribute7,
                                              attribute8,
                                              attribute9,
                                              attribute10,
                                              attribute11,
                                              attribute12,
                                              attribute13,
                                              attribute14,
                                              attribute15,
                                              created_by,
                                              creation_date,
                                              last_updated_by,
                                              last_update_date,
                                              last_update_login)
           VALUES (rec.invoice_id,
                   rec.invoice_line_id,
                   rec.line_number,
                   rec.line_type_lookup_code,
                   rec.amount,
                   rec.accounting_date,
                   rec.description,
                   rec.dist_code_concatenated,
                   rec.dist_code_combination_id,
                   rec.org_id,
                   rec.awt_group_name,
                   rec.tax_classification_code,
                   rec.attribute1,
                   rec.attribute2,
                   rec.attribute3,
                   rec.attribute4,
                   rec.attribute5,
                   rec.attribute6,
                   rec.attribute7,
                   rec.attribute8,
                   rec.attribute9,
                   rec.attribute10,
                   rec.attribute11,
                   rec.attribute12,
                   rec.attribute13,
                   rec.attribute14,
                   rec.attribute15,
                   rec.created_by,
                   rec.creation_date,
                   rec.last_updated_by,
                   rec.last_update_date,
                   rec.last_update_login);
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('error insert to ap_invoice_lines_interface : ' || SQLERRM);
   END insert_iface_line;

   PROCEDURE call_api_import_invoice (errbuf    OUT VARCHAR2,
                                      retcode   OUT VARCHAR2)
   AS
      l_appl_name     VARCHAR2 (10) := 'SQLAP';
      l_prog_name     VARCHAR2 (10) := 'APXIIMPT';
      l_source_name   VARCHAR2 (10) := 'VISION';


      v_request_id    NUMBER;
      l_boolean       BOOLEAN;
      l_phase         VARCHAR2 (200);
      l_status        VARCHAR2 (200);
      l_dev_phase     VARCHAR2 (200);
      l_dev_status    VARCHAR2 (200);
      l_message       VARCHAR2 (200);
      v_req_id        NUMBER;
   BEGIN
      mo_global.init (l_appl_name);
      mo_global.set_policy_context ('M', 82);
      /*fnd_global.apps_initialize (user_id        => 1252,         --g_user_id,
                                  resp_id        => 20639, --g_resp_id, -- Payables Manager
                                  resp_appl_id   => 200);   --g_resp_appl_id);*/
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);
      --fnd_request.set_org_id (82);

      v_request_id :=
         fnd_request.submit_request (application   => l_appl_name,
                                     program       => l_prog_name,
                                     description   => 'Invoice Claim Vision',
                                     start_time    => NULL,
                                     sub_request   => FALSE,
                                     argument1     => 82,
                                     argument2     => l_source_name,
                                     argument3     => NULL,
                                     argument4     => NULL,
                                     argument5     => NULL,
                                     argument6     => NULL,
                                     argument7     => NULL,
                                     argument8     => 'N',
                                     argument9     => 'Y');
      COMMIT;

      IF v_request_id > 0
      THEN
         l_boolean :=
            fnd_concurrent.wait_for_request (v_request_id,
                                             g_intval_time,
                                             g_max_time,
                                             l_phase,
                                             l_status,
                                             l_dev_phase,
                                             l_dev_status,
                                             l_message);
         COMMIT;
      END IF;

      logf (
            'Please see the output of Payables OPEN Invoice Import program request id : '
         || v_request_id);
      logf ('success');

      IF (v_request_id = 0)
      THEN
         logf (' Returning false as request could not be submitted');
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error :' || SQLERRM);
         retcode := 2;
   END call_api_import_invoice;

   PROCEDURE create_rfp_invoice (errbuf           OUT VARCHAR2,
                                 retcode          OUT VARCHAR2,
                                 p_invoice_date       DATE)
   AS
      l_invoice_hdr            ap.ap_invoices_interface%ROWTYPE;
      l_invoice_line           ap.ap_invoice_lines_interface%ROWTYPE;


      lv_amount                NUMBER;
      lv_invoice_id            NUMBER;
      lv_invoice_line_id       NUMBER;
      lv_org_id                NUMBER;
      lv_vendor_id             NUMBER;
      lv_party_id              NUMBER;
      lv_vendor_site_id        NUMBER;
      lv_party_site_id         NUMBER;
      lv_source_line_type      VARCHAR2 (200);
      lv_invoice_type          VARCHAR2 (200);
      lv_payment_method_code   VARCHAR2 (200);
      lv_term_id               NUMBER;
      lv_period_name           VARCHAR2 (200);
      lv_terms_name            VARCHAR2 (200);
      lv_terms_date            DATE;
      lv_code_combination_id   VARCHAR2 (200);
      lv_set_of_books_id       NUMBER;
      lv_sum_amt               NUMBER;

      error_flag               VARCHAR2 (1);
      l_error_message          VARCHAR2 (32767);
      error_cnt                NUMBER := 0;
   BEGIN
      FOR i IN c_data_header (p_invoice_date)
      LOOP
         l_invoice_hdr := NULL;

         BEGIN
            SELECT SUM (amount)
              INTO lv_sum_amt
              FROM xxkbn_rfp_invoice_line
             WHERE invoice_id = i.invoice_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message := l_error_message || 'INVALID AMOUNT, ';
               logf ('INVALID AMOUNT' || lv_org_id);
               error_cnt := error_cnt + 1;
         END;

         IF lv_sum_amt <> i.invoice_amount
         THEN
            error_flag := 'E';
            l_error_message :=
               l_error_message || 'INVALID AMOUNT VALIDATION, ';
            logf ('INVALID AMOUNT' || lv_org_id);
            error_cnt := error_cnt + 1;
         END IF;

         --validate_invoice_rfp (p_rfp_num   => i.invoice_num,
         --p_req_id    => v_req_id,
         --errbuf      => errbuf,
         --retcode     => retcode);

         --IF v_req_id IS NOT NULL AND retcode = 0
         --THEN
         --------------*****ORGANIZATION NAME VALIDATION*****----------
         BEGIN
            SELECT organization_id
              INTO lv_org_id
              FROM org_organization_definitions
             WHERE organization_code = g_organization_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message :=
                  l_error_message || 'organization_name IS INVALID, ';
               logf ('organization_name IS INVALID' || lv_org_id);
               error_cnt := error_cnt + 1;
         END;

         --------------*****INVOICE TYPE VALIDATION******---------
         BEGIN
            SELECT lookup_code
              INTO lv_invoice_type
              FROM ap_lookup_codes
             WHERE     lookup_type = g_invoice_type
                   AND lookup_code = NVL(g_invoice_lookup_code,UPPER(i.invoice_type_lookup_code));
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message :=
                  l_error_message || 'INVOICE_TYPE  IS INVALID, ';
               logf ('INVOICE_TYPE  IS INVALID' || lv_invoice_type);
               error_cnt := error_cnt + 1;
         END;

         --------------******SUPPLIER VALIDATION******--------------
         BEGIN
            SELECT vendor_id, party_id
              INTO lv_vendor_id, lv_party_id
              FROM po_vendors
             WHERE vendor_name = i.vendor_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message := l_error_message || 'VENDOR_ID  IS INVALID, ';
               logf ('VENDOR_ID  IS INVALID' || lv_vendor_id);
               error_cnt := error_cnt + 1;
         END;

         --------------******SUPPLIER SITE VALIDATION******--------------
         BEGIN
            SELECT vendor_site_id, party_site_id
              INTO lv_vendor_site_id, lv_party_site_id
              FROM po_vendor_sites_all
             WHERE     vendor_site_code = i.vendor_site_code
                   AND vendor_id = lv_vendor_id
                   AND org_id = i.org_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message :=
                  l_error_message || 'SUPPLIER SITE  IS INVALID, ';
               logf ('SUPPLIER SITE  IS INVALID' || lv_vendor_site_id);
               error_cnt := error_cnt + 1;
         END;

         --------------------****TERMS VALIDATION******----------------------
         BEGIN
            SELECT term_id, name, start_date_active
              INTO lv_term_id, lv_terms_name, lv_terms_date
              FROM ap_terms
             WHERE name = NVL(g_terms,i.terms_name);
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message := l_error_message || 'TERM ID  IS INVALID, ';
               logf ('TERM ID  IS INVALID');
               error_cnt := error_cnt + 1;
         END;

         ------------------*********VALIDATION OF GL PERIODS *********------------------

         BEGIN
            SELECT period_name
              INTO lv_period_name
              FROM gl_periods
             WHERE period_name = TO_CHAR (i.invoice_date, 'MON-YY');
         EXCEPTION
            WHEN OTHERS
            THEN
               error_flag := 'E';
               l_error_message :=
                  l_error_message || 'PERIOD_NAME  IS INVALID, ';
               logf ('PERIOD_NAME  IS INVALID' || lv_period_name);
               error_cnt := error_cnt + 1;
         END;

         ----------------*******INSERT TO HEADER*********-------

         SELECT ap_invoices_interface_s.NEXTVAL INTO lv_invoice_id FROM DUAL;

         l_invoice_hdr.invoice_id := lv_invoice_id;
         l_invoice_hdr.invoice_num := i.invoice_num;
         l_invoice_hdr.invoice_type_lookup_code := lv_invoice_type;
         l_invoice_hdr.invoice_date := i.invoice_date;
         l_invoice_hdr.vendor_id := lv_vendor_id;
         l_invoice_hdr.vendor_site_id := lv_vendor_site_id;
         l_invoice_hdr.invoice_amount := i.invoice_amount;
         l_invoice_hdr.invoice_currency_code := i.invoice_currency_code;
         l_invoice_hdr.terms_name := lv_terms_name;
         l_invoice_hdr.description := i.description;
         l_invoice_hdr.source := i.source;
         l_invoice_hdr.GROUP_ID := i.GROUP_ID;
         l_invoice_hdr.gl_date := i.gl_date;
         l_invoice_hdr.org_id := i.org_id;
         l_invoice_hdr.terms_date := lv_terms_date;
         l_invoice_hdr.attribute1 := i.attribute1;
         l_invoice_hdr.attribute2 := i.attribute2;
         l_invoice_hdr.attribute3 := i.attribute3;
         l_invoice_hdr.attribute4 := i.attribute4;
         l_invoice_hdr.attribute5 := i.attribute5;
         l_invoice_hdr.attribute6 := i.attribute6;
         l_invoice_hdr.attribute7 := i.attribute7;
         l_invoice_hdr.attribute8 := i.attribute8;
         l_invoice_hdr.attribute9 := i.attribute9;
         l_invoice_hdr.attribute10 := i.attribute10;
         l_invoice_hdr.attribute11 := i.attribute11;
         l_invoice_hdr.attribute12 := i.attribute12;
         l_invoice_hdr.attribute13 := i.attribute13;
         l_invoice_hdr.attribute14 := i.attribute14;
         l_invoice_hdr.attribute15 := i.attribute15;
         l_invoice_hdr.created_by := g_user_id;
         l_invoice_hdr.creation_date := SYSDATE;
         l_invoice_hdr.last_updated_by := g_user_id;
         l_invoice_hdr.last_update_date := SYSDATE;
         l_invoice_hdr.last_update_login := g_login_id;

         insert_iface_hdr (l_invoice_hdr);


         FOR j IN c_data_line (i.invoice_id)
         LOOP
            l_invoice_line := NULL;

            ------------------------*****VALIDATION OF SET OF BOOKS******----------------
            BEGIN
               SELECT set_of_books_id
                 INTO lv_set_of_books_id
                 FROM gl_sets_of_books
                WHERE short_name = g_set_book_name;
            EXCEPTION
               WHEN OTHERS
               THEN
                  error_flag := 'E';
                  l_error_message :=
                     l_error_message || 'SET_OF_BOOKS_ID  IS INVALID, ';
                  logf ('SET_OF_BOOKS_ID  IS INVALID' || lv_set_of_books_id);
                  error_cnt := error_cnt + 1;
            END;

            --------------**********VALIDATION OF CHARGE ACCOUNT*****-----------
            BEGIN
               SELECT code_combination_id
                 INTO lv_code_combination_id
                 FROM gl_code_combinations_kfv gcc, gl_sets_of_books gsb
                WHERE     concatenated_segments = j.dist_code_concatenated
                      AND gcc.chart_of_accounts_id = gsb.chart_of_accounts_id
                      AND set_of_books_id = lv_set_of_books_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  error_flag := 'E';
                  l_error_message :=
                     l_error_message || 'CODE_COMBINATION_ID  IS INVALID, ';
                  logf (
                        'CODE_COMBINATION_ID  IS INVALID'
                     || lv_code_combination_id);
                  error_cnt := error_cnt + 1;
            END;


            ------------------*********VALIDATION OF SOURCE********------------
            BEGIN
               SELECT lookup_code
                 INTO lv_source_line_type
                 FROM ap_lookup_codes
                WHERE     lookup_type = g_invoice_line_type
                      AND displayed_field = g_displayed_item
                      AND lookup_code = j.line_type_lookup_code;
            EXCEPTION
               WHEN OTHERS
               THEN
                  error_flag := 'E';
                  l_error_message :=
                     l_error_message || 'INVOICE LINE TYPE  IS INVALID, ';
                  logf ('INVOICE LINE TYPE IS VALID' || lv_source_line_type);
                  error_cnt := error_cnt + 1;
            END;

            SELECT ap_invoice_lines_interface_s.NEXTVAL
              INTO lv_invoice_line_id
              FROM DUAL;

            l_invoice_line.invoice_id := lv_invoice_id;
            l_invoice_line.invoice_line_id := lv_invoice_line_id;
            l_invoice_line.line_number := j.line_number;
            l_invoice_line.line_type_lookup_code := lv_source_line_type;
            l_invoice_line.amount := j.amount;
            l_invoice_line.accounting_date := j.accounting_date;
            l_invoice_line.description := j.description;
            l_invoice_line.dist_code_concatenated := j.dist_code_concatenated;
            l_invoice_line.dist_code_combination_id := lv_code_combination_id;
            l_invoice_line.org_id := j.org_id;
            l_invoice_line.awt_group_name := j.awt_group_name;
            l_invoice_line.tax_classification_code := j.vat_code;
            l_invoice_line.attribute1 := j.attribute1;
            l_invoice_line.attribute2 := j.attribute2;
            l_invoice_line.attribute3 := j.attribute3;
            l_invoice_line.attribute4 := j.attribute4;
            l_invoice_line.attribute5 := j.attribute5;
            l_invoice_line.attribute6 := j.attribute6;
            l_invoice_line.attribute7 := j.attribute7;
            l_invoice_line.attribute8 := j.attribute8;
            l_invoice_line.attribute9 := j.attribute9;
            l_invoice_line.attribute10 := j.attribute10;
            l_invoice_line.attribute11 := j.attribute11;
            l_invoice_line.attribute12 := j.attribute12;
            l_invoice_line.attribute13 := j.attribute13;
            l_invoice_line.attribute14 := j.attribute14;
            l_invoice_line.attribute15 := j.attribute15;
            l_invoice_line.created_by := g_user_id;
            l_invoice_line.creation_date := SYSDATE;
            l_invoice_line.last_updated_by := g_user_id;
            l_invoice_line.last_update_date := SYSDATE;
            l_invoice_line.last_update_login := g_login_id;

            insert_iface_line (l_invoice_line);
         END LOOP;
      --ELSE
      --logf ('Period not Open');
      --END IF;
      END LOOP;

      IF error_cnt > 0
      THEN
         logf ('Error Insert');
         RAISE error_insert;
      END IF;

      COMMIT;

      call_api_import_invoice (errbuf, retcode);
      logf ('SUCCESS');
   EXCEPTION
      WHEN error_insert
      THEN
         logf ('Error :' || SQLERRM);
         ROLLBACK;
         logf ('update error ' || l_error_message);

         UPDATE xxkbn_rfp_invoice_hdr
            SET FLAG_PROCESS = error_flag, ERROR_MSG = l_error_message
          WHERE INVOICE_DATE = p_invoice_date;

         COMMIT;
      WHEN OTHERS
      THEN
         logf ('Error :' || SQLERRM);
         retcode := 2;
   END create_rfp_invoice;
END xxkbn_create_rfp_inv_pkg;
/