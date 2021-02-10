CREATE OR REPLACE PACKAGE BODY APPS.XXVMT_INTF_INVOICE_PKG
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXVMT_INTF_INVOICE_PKG.pkb                                                            |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Planning Parameter New all in this Package                                            |
   REM |     History     : 1 Sep 2020  --Ardianto--                                                              |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */

   PROCEDURE logf (v_msg VARCHAR2)
   IS
   BEGIN
      FND_FILE.PUT_LINE (fnd_file.LOG, v_msg);
      DBMS_OUTPUT.put_line (v_msg);
   END logf;

   PROCEDURE outf (v_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, v_msg);
      DBMS_OUTPUT.put_line (v_msg);
   END outf;

   FUNCTION gl_code_descr (p_gl_code NUMBER)
      RETURN VARCHAR2
   IS
      v_description   VARCHAR2 (4000);
   BEGIN
      BEGIN
         SELECT REPLACE (
                   REPLACE (REPLACE (DESCR, CHR (10), ''), CHR (13), ''),
                   CHR (09),
                   '')
                   DESCRIPTION
           INTO v_description
           FROM (    SELECT TRIM (
                               SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, '/'), 2))
                               DESCR
                       FROM (SELECT DESCRIPTION,
                                    ROW_NUMBER () OVER (ORDER BY SEGMENT_NUM) RN,
                                    COUNT (*) OVER () CNT
                               FROM XXVMT_GL_CODE_DESCRIPTION_V
                              WHERE CODE_COMBINATION_ID = p_gl_code)
                      WHERE RN = CNT
                 START WITH RN = 1
                 CONNECT BY RN = PRIOR RN + 1);
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN NULL;
      END;

      RETURN (v_description);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END gl_code_descr;

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

      mo_global.set_policy_context ('S', g_org_id);

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

   FUNCTION chk_inv_cancellable (v_invoice_id IN NUMBER)
      RETURN BOOLEAN
   IS
      v_boolean      BOOLEAN;
      v_error_code   VARCHAR2 (100);
      v_debug_info   VARCHAR2 (1000);
   BEGIN
      logf ('Calling API to check whetehr the Invoice is canellable ');

      v_boolean :=
         ap_cancel_pkg.is_invoice_cancellable (p_invoice_id         => v_invoice_id,
                                               p_error_code         => v_error_code,
                                               p_debug_info         => v_debug_info,
                                               p_calling_sequence   => NULL);

      IF v_boolean = TRUE
      THEN
         RETURN TRUE;
         logf ('Invoice ' || v_invoice_id || ' is cancellable');
      ELSE
         RETURN FALSE;
         logf (
               'Invoice '
            || v_invoice_id
            || ' Debug : '
            || v_debug_info
            || ' '
            || ' is not cancellable :'
            || v_error_code);
      END IF;
   END chk_inv_cancellable;

   PROCEDURE cancel_invoice_rfp (p_rfp_num             IN     VARCHAR2,
                                 p_last_updated_by     IN     NUMBER,
                                 p_last_update_login   IN     NUMBER,
                                 errbuf                   OUT VARCHAR2,
                                 retcode                  OUT NUMBER)
   IS
      v_rfp_no                  VARCHAR2 (1000);
      v_invoice_id              NUMBER;
      v_batch_id                NUMBER;
      v_payment_status_flag     VARCHAR2 (1);
      v_accounting_date         DATE := SYSDATE;
      v_boolean                 BOOLEAN;
      v_cancellable_inv         BOOLEAN;

      v_error_code              VARCHAR2 (100);
      v_debug_info              VARCHAR2 (1000);

      x_message_name            VARCHAR2 (1000);
      x_invoice_amount          NUMBER;
      x_base_amount             NUMBER;
      x_tax_amount              NUMBER;
      x_temp_cancelled_amount   NUMBER;
      x_cancelled_by            VARCHAR2 (1000);
      x_cancelled_amount        NUMBER;
      x_cancelled_date          DATE;
      x_last_update_date        DATE;
      x_token                   VARCHAR2 (100);
      x_orig_prepay_amt         NUMBER;
      x_pay_cur_inv_amt         NUMBER;
   BEGIN
      BEGIN
           SELECT ab.attribute1 rfp_no,
                  ai.invoice_id,
                  ab.batch_id,
                  ai.payment_status_flag
             INTO v_rfp_no,
                  v_invoice_id,
                  v_batch_id,
                  v_payment_status_flag
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
            errbuf := 'RFP no data found.';
            retcode := 2;
      END;

      IF v_payment_status_flag = 'Y'
      THEN
         logf ('Invoice is already paid. Please void the payment first');
         errbuf := 'Invoice is already paid. Please void the payment first';
         retcode := 1;
      ELSE
         logf ('call package cancellable.');
         v_cancellable_inv := chk_inv_cancellable (v_invoice_id);

         IF v_cancellable_inv = TRUE
         THEN
            logf ('cancellable is true');
            fnd_global.apps_initialize (g_user_id,
                                        g_resp_id,
                                        g_resp_appl_id,
                                        0);
            mo_global.init ('SQLAP');
            mo_global.set_policy_context ('S', g_org_id);


            logf ('Calling API to Cancel Invoice');
            logf (
               '************************************************************');

            v_boolean :=
               ap_cancel_pkg.ap_cancel_single_invoice (
                  p_invoice_id                   => v_invoice_id,
                  p_last_updated_by              => p_last_updated_by,
                  p_last_update_login            => p_last_update_login,
                  p_accounting_date              => v_accounting_date,
                  p_message_name                 => x_message_name,
                  p_invoice_amount               => x_invoice_amount,
                  p_base_amount                  => x_base_amount,
                  p_temp_cancelled_amount        => x_temp_cancelled_amount,
                  p_cancelled_by                 => x_cancelled_by,
                  p_cancelled_amount             => x_cancelled_amount,
                  p_cancelled_date               => x_cancelled_date,
                  p_last_update_date             => x_last_update_date,
                  p_original_prepayment_amount   => x_orig_prepay_amt,
                  p_pay_curr_invoice_amount      => x_pay_cur_inv_amt,
                  p_token                        => x_token,
                  p_calling_sequence             => NULL);

            IF v_boolean
            THEN
               logf ('Successfully Cancelled the Invoice');
               COMMIT;

               errbuf := 'Successfully Cancelled the Invoice';
               retcode := 0;
            ELSE
               logf ('Failed to Cancel the Invoice');
               ROLLBACK;
               errbuf := 'Failed to Cancel the Invoice';
               retcode := 2;
            END IF;
         ELSE
            logf ('cancellable is false');
            errbuf := 'cancellable is false';
            retcode := 2;
         END IF;
      END IF;
   END cancel_invoice_rfp;
END XXVMT_INTF_INVOICE_PKG;
/