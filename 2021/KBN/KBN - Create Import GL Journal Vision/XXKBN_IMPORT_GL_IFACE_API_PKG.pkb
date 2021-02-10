/* Formatted on 1/28/2021 4:12:43 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE BODY APPS.xxkbn_import_gl_iface_api_pkg
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXKBN_IMPORT_XFER_GL_IFACE_API                                                        |
   REM |     Concurrent  :                                                                                       |
   REM |     Parameters  :                                                                                       |
   REM |     Description : This package gives API for GL interface calls                                         |
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

   FUNCTION get_gl_application_id (p_appl_name IN VARCHAR2)
      RETURN INTEGER
   IS
      CURSOR c_check
      IS
         SELECT application_id
           FROM fnd_application_vl
          WHERE application_short_name = p_appl_name;

      p_check   c_check%ROWTYPE;
   BEGIN
      OPEN c_check;

      FETCH c_check INTO p_check;

      CLOSE c_check;

      RETURN p_check.application_id;
   END get_gl_application_id;

   FUNCTION check_ccid (p_sob_id IN INTEGER, p_ccid IN INTEGER)
      RETURN BOOLEAN
   IS
      CURSOR c_check
      IS
         SELECT 'x'
           FROM gl_code_combinations gcc, gl_sets_of_books gsob
          WHERE     gsob.set_of_books_id = p_sob_id
                AND gcc.code_combination_id = p_ccid
                AND gcc.chart_of_accounts_id = gsob.chart_of_accounts_id
                AND gcc.enabled_flag = 'Y';

      p_check   c_check%ROWTYPE;
   BEGIN
      logf ('check_ccid');
      logf ('p_sob_id=>' || p_sob_id || ' p_ccid=>' || p_ccid);

      OPEN c_check;

      FETCH c_check INTO p_check;

      IF c_check%NOTFOUND
      THEN
         CLOSE c_check;

         logf ('check_ccid() RETURNED FALSE;');
         RETURN FALSE;
      END IF;

      CLOSE c_check;

      logf ('check_ccid() RETURNED TRUE;');
      RETURN TRUE;
   END check_ccid;

   PROCEDURE populate_interface_control (
      p_user_je_source_name   IN     VARCHAR2,
      p_group_id              IN OUT NUMBER,
      p_set_of_books_id              NUMBER,
      p_interface_run_id      IN OUT NUMBER)
   IS
      re_use_gl_interface_control   EXCEPTION;
   BEGIN
      logf ('populate_interface_control');

      IF g_group_id IS NOT NULL AND g_interface_run_id IS NOT NULL
      THEN
         p_group_id := g_group_id;
         p_interface_run_id := g_interface_run_id;
         RAISE re_use_gl_interface_control;
      END IF;

      gl_journal_import_pkg.populate_interface_control (
         user_je_source_name   => p_user_je_source_name,
         GROUP_ID              => p_group_id,
         set_of_books_id       => p_set_of_books_id,
         interface_run_id      => p_interface_run_id);

      g_group_id := p_group_id;
      g_interface_run_id := p_interface_run_id;

      logf (
            'Returning New Group p_group_id=>'
         || p_group_id
         || ' p_interface_run_id=>'
         || p_interface_run_id);
   EXCEPTION
      WHEN re_use_gl_interface_control
      THEN
         logf (
               'Returning Global Group g_group_id=>'
            || g_group_id
            || ' g_interface_run_id=>'
            || g_interface_run_id);
   END populate_interface_control;

   PROCEDURE insert_statement (p_gl_int_rec IN OUT NOCOPY g_gl_int_type_rec)
   IS
   BEGIN
      logf ('insert_statement');

      INSERT INTO gl_interface (reference_date,
                                attribute20,
                                ledger_id,
                                CONTEXT,
                                context2,
                                invoice_date,
                                tax_code,
                                invoice_identifier,
                                invoice_amount,
                                context3,
                                ussgl_transaction_code,
                                descr_flex_error_message,
                                jgzz_recon_ref,
                                segment23,
                                segment24,
                                segment25,
                                segment26,
                                segment27,
                                segment28,
                                segment29,
                                segment30,
                                entered_dr,
                                entered_cr,
                                accounted_dr,
                                accounted_cr,
                                transaction_date,
                                reference1,
                                reference2,
                                reference3,
                                reference4,
                                reference5,
                                reference6,
                                reference7,
                                reference8,
                                reference9,
                                reference10,
                                reference11,
                                reference12,
                                reference13,
                                reference14,
                                reference15,
                                reference16,
                                reference17,
                                reference18,
                                reference19,
                                reference20,
                                reference21,
                                reference22,
                                reference23,
                                reference24,
                                reference25,
                                reference26,
                                reference27,
                                reference28,
                                reference29,
                                reference30,
                                je_batch_id,
                                period_name,
                                je_header_id,
                                je_line_num,
                                chart_of_accounts_id,
                                functional_currency_code,
                                code_combination_id,
                                date_created_in_gl,
                                warning_code,
                                status_description,
                                stat_amount,
                                GROUP_ID,
                                request_id,
                                subledger_doc_sequence_id,
                                subledger_doc_sequence_value,
                                attribute1,
                                attribute2,
                                gl_sl_link_id,
                                gl_sl_link_table,
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
                                attribute16,
                                attribute17,
                                attribute18,
                                attribute19,
                                status,
                                set_of_books_id,
                                accounting_date,
                                currency_code,
                                date_created,
                                created_by,
                                actual_flag,
                                user_je_category_name,
                                user_je_source_name,
                                currency_conversion_date,
                                encumbrance_type_id,
                                budget_version_id,
                                user_currency_conversion_type,
                                currency_conversion_rate,
                                average_journal_flag,
                                originating_bal_seg_value,
                                segment1,
                                segment2,
                                segment3,
                                segment4,
                                segment5,
                                segment6,
                                segment7,
                                segment8,
                                segment9,
                                segment10,
                                segment11,
                                segment12,
                                segment13,
                                segment14,
                                segment15,
                                segment16,
                                segment17,
                                segment18,
                                segment19,
                                segment20,
                                segment21,
                                segment22)
           VALUES (p_gl_int_rec.reference_date,
                   p_gl_int_rec.attribute20,
                   p_gl_int_rec.ledger_id,
                   p_gl_int_rec.CONTEXT,
                   p_gl_int_rec.context2,
                   p_gl_int_rec.invoice_date,
                   p_gl_int_rec.tax_code,
                   p_gl_int_rec.invoice_identifier,
                   p_gl_int_rec.invoice_amount,
                   p_gl_int_rec.context3,
                   p_gl_int_rec.ussgl_transaction_code,
                   p_gl_int_rec.descr_flex_error_message,
                   p_gl_int_rec.jgzz_recon_ref,
                   p_gl_int_rec.segment23,
                   p_gl_int_rec.segment24,
                   p_gl_int_rec.segment25,
                   p_gl_int_rec.segment26,
                   p_gl_int_rec.segment27,
                   p_gl_int_rec.segment28,
                   p_gl_int_rec.segment29,
                   p_gl_int_rec.segment30,
                   p_gl_int_rec.entered_dr,
                   p_gl_int_rec.entered_cr,
                   p_gl_int_rec.accounted_dr,
                   p_gl_int_rec.accounted_cr,
                   p_gl_int_rec.transaction_date,
                   p_gl_int_rec.reference1,
                   p_gl_int_rec.reference2,
                   p_gl_int_rec.reference3,
                   p_gl_int_rec.reference4,
                   p_gl_int_rec.reference5,
                   p_gl_int_rec.reference6,
                   p_gl_int_rec.reference7,
                   p_gl_int_rec.reference8,
                   p_gl_int_rec.reference9,
                   p_gl_int_rec.reference10,
                   p_gl_int_rec.reference11,
                   p_gl_int_rec.reference12,
                   p_gl_int_rec.reference13,
                   p_gl_int_rec.reference14,
                   p_gl_int_rec.reference15,
                   p_gl_int_rec.reference16,
                   p_gl_int_rec.reference17,
                   p_gl_int_rec.reference18,
                   p_gl_int_rec.reference19,
                   p_gl_int_rec.reference20,
                   p_gl_int_rec.reference21,
                   p_gl_int_rec.reference22,
                   p_gl_int_rec.reference23,
                   p_gl_int_rec.reference24,
                   p_gl_int_rec.reference25,
                   p_gl_int_rec.reference26,
                   p_gl_int_rec.reference27,
                   p_gl_int_rec.reference28,
                   p_gl_int_rec.reference29,
                   p_gl_int_rec.reference30,
                   p_gl_int_rec.je_batch_id,
                   p_gl_int_rec.period_name,
                   p_gl_int_rec.je_header_id,
                   p_gl_int_rec.je_line_num,
                   p_gl_int_rec.chart_of_accounts_id,
                   p_gl_int_rec.functional_currency_code,
                   p_gl_int_rec.code_combination_id,
                   p_gl_int_rec.date_created_in_gl,
                   p_gl_int_rec.warning_code,
                   p_gl_int_rec.status_description,
                   p_gl_int_rec.stat_amount,
                   p_gl_int_rec.GROUP_ID,
                   p_gl_int_rec.request_id,
                   p_gl_int_rec.subledger_doc_sequence_id,
                   p_gl_int_rec.subledger_doc_sequence_value,
                   p_gl_int_rec.attribute1,
                   p_gl_int_rec.attribute2,
                   p_gl_int_rec.gl_sl_link_id,
                   p_gl_int_rec.gl_sl_link_table,
                   p_gl_int_rec.attribute3,
                   p_gl_int_rec.attribute4,
                   p_gl_int_rec.attribute5,
                   p_gl_int_rec.attribute6,
                   p_gl_int_rec.attribute7,
                   p_gl_int_rec.attribute8,
                   p_gl_int_rec.attribute9,
                   p_gl_int_rec.attribute10,
                   p_gl_int_rec.attribute11,
                   p_gl_int_rec.attribute12,
                   p_gl_int_rec.attribute13,
                   p_gl_int_rec.attribute14,
                   p_gl_int_rec.attribute15,
                   p_gl_int_rec.attribute16,
                   p_gl_int_rec.attribute17,
                   p_gl_int_rec.attribute18,
                   p_gl_int_rec.attribute19,
                   p_gl_int_rec.status,
                   p_gl_int_rec.set_of_books_id,
                   p_gl_int_rec.accounting_date,
                   p_gl_int_rec.currency_code,
                   p_gl_int_rec.date_created,
                   p_gl_int_rec.created_by,
                   p_gl_int_rec.actual_flag,
                   p_gl_int_rec.user_je_category_name,
                   p_gl_int_rec.user_je_source_name,
                   p_gl_int_rec.currency_conversion_date,
                   p_gl_int_rec.encumbrance_type_id,
                   p_gl_int_rec.budget_version_id,
                   p_gl_int_rec.user_currency_conversion_type,
                   p_gl_int_rec.currency_conversion_rate,
                   p_gl_int_rec.average_journal_flag,
                   p_gl_int_rec.originating_bal_seg_value,
                   p_gl_int_rec.segment1,
                   p_gl_int_rec.segment2,
                   p_gl_int_rec.segment3,
                   p_gl_int_rec.segment4,
                   p_gl_int_rec.segment5,
                   p_gl_int_rec.segment6,
                   p_gl_int_rec.segment7,
                   p_gl_int_rec.segment8,
                   p_gl_int_rec.segment9,
                   p_gl_int_rec.segment10,
                   p_gl_int_rec.segment11,
                   p_gl_int_rec.segment12,
                   p_gl_int_rec.segment13,
                   p_gl_int_rec.segment14,
                   p_gl_int_rec.segment15,
                   p_gl_int_rec.segment16,
                   p_gl_int_rec.segment17,
                   p_gl_int_rec.segment18,
                   p_gl_int_rec.segment19,
                   p_gl_int_rec.segment20,
                   p_gl_int_rec.segment21,
                   p_gl_int_rec.segment22);

      logf (SQL%ROWCOUNT || ' records inserted into GL_INTERFACE');
   END insert_statement;

   PROCEDURE transfer_to_gl (p_date_created DATE)
   IS
      v_gl_appl_id                     NUMBER;
      l_gl_int_type_rec                g_gl_int_type_rec;
      v_conc_id                        INTEGER;
      conversion_rate_does_not_exist   EXCEPTION;
      invalid_conversion_type          EXCEPTION;
      invalid_dr_ccid                  EXCEPTION;
      invalid_cr_ccid                  EXCEPTION;
      invalid_currency_code            EXCEPTION;
      not_in_open_period               EXCEPTION;
      invalid_gl_source                EXCEPTION;
      v_func_curr                      VARCHAR2 (30);
      v_group_id                       NUMBER;
      v_interface_run_id               NUMBER;

      v_ret_val                        BOOLEAN;
      v_request_id                     INTEGER;
      phase                            VARCHAR2 (100);
      status                           VARCHAR2 (100);
      dev_phase                        VARCHAR2 (100);
      dev_status                       VARCHAR2 (100);
      v_message                        VARCHAR2 (100);
      v_bool                           BOOLEAN;
      v_old_status                     VARCHAR2 (30);
      l_msg                            VARCHAR2 (1000);
      l_error_stts                     VARCHAR2 (100);

      v_je_source_name                 VARCHAR2 (100);
      v_conversion_type                VARCHAR2 (100);
      v_cnt_gl_period_stts             NUMBER;
      v_count_curr                     NUMBER;
      v_cc_id                          NUMBER;
      v_start_date                     DATE;
      v_success_flag                   BOOLEAN;
   BEGIN
      /**************************************************
      Main code for gms_cost_xfer GL Interface begins here
      **************************************************/

      FOR dat IN source_data (p_date_created)
      LOOP
         --SAVEPOINT gms_cost_xfer_gl_int;

         /* Get the GL Application ID */
         BEGIN
            SELECT application_id
              INTO v_gl_appl_id
              FROM fnd_application_vl
             WHERE application_short_name = g_gl_appl_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid application id, ';
               l_error_stts := 'E';
         END;

         /* May be GL team forgets to create source for gms_cost_xfer, lets see...*/
         BEGIN
            SELECT JE_SOURCE_NAME
              INTO v_je_source_name
              FROM gl_je_sources
             WHERE user_je_source_name = dat.user_je_source_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid JE source name, ';
               l_error_stts := 'E';
               RAISE invalid_gl_source;
         END;

         BEGIN
            SELECT conversion_type
              INTO g_conversion_type_code
              FROM gl_daily_conversion_types
             WHERE user_conversion_type = g_conversion_type;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid conversion, ';
               l_error_stts := 'E';
               RAISE invalid_conversion_type;
         END;

         /* Lets validate the accounting date.
         Although gms_cost_xfer almost always passes the current date.
         But still this is a good to have validation. */
         BEGIN
            SELECT COUNT (*)
              INTO v_cnt_gl_period_stts
              FROM gl_period_statuses gps
             WHERE     gps.application_id = v_gl_appl_id
                   AND gps.set_of_books_id = dat.ledger_id
                   AND gps.closing_status IN ('O', 'F')
                   AND TRUNC (dat.accounting_date) BETWEEN NVL (
                                                              TRUNC (
                                                                 gps.start_date),
                                                              TRUNC (
                                                                 dat.accounting_date))
                                                       AND NVL (
                                                              TRUNC (
                                                                 gps.end_date),
                                                              TRUNC (
                                                                 dat.accounting_date));

            IF v_cnt_gl_period_stts > 0
            THEN
               logf ('validate_accounting_date true');
            ELSE
               logf (
                     'validate_accounting_date Cant find open Period for '
                  || dat.accounting_date);

               --try to find next available date now
               BEGIN
                    SELECT gps.start_date
                      INTO v_start_date
                      FROM gl_period_statuses gps
                     WHERE     gps.application_id = v_gl_appl_id
                           AND gps.set_of_books_id = dat.ledger_id
                           AND gps.closing_status IN ('O', 'F')
                           AND TRUNC (gps.start_date) > dat.accounting_date
                  ORDER BY TRUNC (gps.start_date);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_msg := l_msg || 'Invalid accounting date, ';
                     l_error_stts := 'E';
                     RAISE not_in_open_period;
               END;

               IF v_start_date IS NULL
               THEN
                  logf (
                        'Accounting Date '
                     || TO_CHAR (dat.accounting_date, 'DD-MON-YYYY')
                     || ' does not belong to a Open Period');
                  RAISE not_in_open_period;
               ELSE
                  logf (
                        'validate_accounting_date Using next available open date '
                     || v_start_date);
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid accounting date not open period, ';
               l_error_stts := 'E';
               RAISE not_in_open_period;
         END;

         /* Lets validate the currency code.
         Although gms_cost_xfer will certainly pass correct curr code*/
         BEGIN
            SELECT COUNT (*)
              INTO v_count_curr
              FROM fnd_currencies fc
             WHERE     fc.currency_code = dat.currency_code
                   AND enabled_flag = 'Y'
                   AND dat.accounting_date BETWEEN NVL (start_date_active,
                                                        dat.accounting_date)
                                               AND NVL (end_date_active,
                                                        dat.accounting_date);

            IF v_count_curr > 0
            THEN
               logf ('validate_currency true');
            ELSE
               l_msg := l_msg || 'Invalid currency code validate, ';
               l_error_stts := 'E';
               RAISE invalid_currency_code;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid currency code validate, ';
               l_error_stts := 'E';
               RAISE invalid_currency_code;
         END;

         BEGIN
            SELECT currency_code
              INTO v_func_curr
              FROM gl_sets_of_books
             WHERE set_of_books_id = dat.ledger_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid currency code, ';
               l_error_stts := 'E';
         END;

         BEGIN
            SELECT code_combination_id
              INTO v_cc_id
              FROM gl_code_combinations
             WHERE     1 = 1
                   AND segment1 = dat.segment1
                   AND segment2 = dat.segment2
                   AND segment3 = dat.segment3
                   AND segment4 = dat.segment4
                   AND segment5 = dat.segment5
                   AND segment6 = dat.segment6
                   AND segment7 = dat.segment7;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg := l_msg || 'Invalid combination segments, ';
               l_error_stts := 'E';
               RAISE invalid_cr_ccid;
         END;

         IF NVL (v_func_curr, 'XX') != NVL (dat.currency_code, 'XX')
         THEN
            IF 'N' = gl_currency_api.rate_exists (
                        x_from_currency     => dat.currency_code,
                        x_to_currency       => v_func_curr,
                        x_conversion_date   => dat.currency_conversion_date,
                        x_conversion_type   => g_conversion_type_code)
            THEN
               RAISE conversion_rate_does_not_exist;
            ELSE
               l_gl_int_type_rec.user_currency_conversion_type :=
                  g_conversion_type;
               l_gl_int_type_rec.currency_conversion_date :=
                  dat.currency_conversion_date;
            END IF;
         END IF;

         --set_sob_id (p_sob_id => p_sob_id);

         populate_interface_control (
            p_user_je_source_name   => dat.user_je_source_name,
            p_group_id              => dat.GROUP_ID,
            p_set_of_books_id       => dat.ledger_id,
            p_interface_run_id      => v_interface_run_id);

         --batch name; part of the je batch name
         l_gl_int_type_rec.reference1 := dat.reference1;

         --je batch description
         l_gl_int_type_rec.reference2 := NULL;

         --part of the je header name
         l_gl_int_type_rec.reference4 := dat.reference4;

         --je header description will be the description of the gms_cost_xfer receipt
         l_gl_int_type_rec.reference5 := NULL;

         --if the description is left blank, then use the Journal Name instead

         --je lines description will be the description of the gms_cost_xfer receipt
         l_gl_int_type_rec.reference10 := dat.reference10;

         l_gl_int_type_rec.reference25 := dat.reference25;
         l_gl_int_type_rec.reference26 := dat.reference26;
         l_gl_int_type_rec.reference27 := dat.reference27;
         l_gl_int_type_rec.reference28 := dat.reference28;
         l_gl_int_type_rec.reference29 := dat.reference29;
         l_gl_int_type_rec.reference30 := dat.reference30;
         l_gl_int_type_rec.reference_date := NULL;

         l_gl_int_type_rec.segment1 := dat.segment1;
         l_gl_int_type_rec.segment2 := dat.segment2;
         l_gl_int_type_rec.segment3 := dat.segment3;
         l_gl_int_type_rec.segment4 := dat.segment4;
         l_gl_int_type_rec.segment5 := dat.segment5;
         l_gl_int_type_rec.segment6 := dat.segment6;
         l_gl_int_type_rec.segment7 := dat.segment7;

         l_gl_int_type_rec.GROUP_ID := dat.GROUP_ID;
         --l_gl_int_type_rec.ledger_id := dat.ledger_id;
         l_gl_int_type_rec.set_of_books_id := dat.ledger_id;
         l_gl_int_type_rec.user_je_source_name := dat.user_je_source_name;
         l_gl_int_type_rec.user_je_category_name := dat.user_je_category_name;
         l_gl_int_type_rec.accounting_date := dat.accounting_date;
         l_gl_int_type_rec.transaction_date := NULL;
         l_gl_int_type_rec.currency_code := dat.currency_code;
         l_gl_int_type_rec.date_created := dat.date_created;
         l_gl_int_type_rec.created_by := g_user_id;
         l_gl_int_type_rec.actual_flag := 'A';
         l_gl_int_type_rec.status := 'S';
         l_gl_int_type_rec.attribute1 := dat.attribute1;
         l_gl_int_type_rec.attribute2 := dat.attribute2;
         l_gl_int_type_rec.attribute3 := dat.attribute3;
         l_gl_int_type_rec.attribute4 := dat.attribute4;
         l_gl_int_type_rec.attribute5 := dat.attribute5;
         l_gl_int_type_rec.attribute6 := dat.attribute6;
         l_gl_int_type_rec.attribute7 := dat.attribute7;
         l_gl_int_type_rec.attribute8 := dat.attribute8;
         l_gl_int_type_rec.attribute9 := dat.attribute9;
         l_gl_int_type_rec.attribute10 := dat.attribute10;
         l_gl_int_type_rec.attribute11 := dat.attribute11;
         l_gl_int_type_rec.attribute12 := dat.attribute12;
         l_gl_int_type_rec.attribute13 := dat.attribute13;
         l_gl_int_type_rec.attribute14 := dat.attribute14;
         l_gl_int_type_rec.attribute15 := dat.attribute15;

         IF     dat.entered_dr IS NOT NULL
            AND (NOT check_ccid (p_sob_id => dat.ledger_id, p_ccid => v_cc_id))
         THEN
            RAISE invalid_dr_ccid;
         END IF;

         IF     dat.entered_cr IS NOT NULL
            AND (NOT check_ccid (p_sob_id => dat.ledger_id, p_ccid => v_cc_id))
         THEN
            RAISE invalid_cr_ccid;
         END IF;

         /* First the gms_cost_xfer Debit Line */
         l_gl_int_type_rec.entered_dr := dat.entered_dr;
         l_gl_int_type_rec.entered_cr := dat.entered_cr;
         l_gl_int_type_rec.code_combination_id := v_cc_id;

         /*IF dat.entered_dr IS NOT NULL
         THEN
            insert_statement (p_gl_int_rec => l_gl_int_type_rec);
         END IF;

         l_gl_int_type_rec.entered_dr := dat.entered_dr;
         l_gl_int_type_rec.entered_cr := dat.entered_cr;
         l_gl_int_type_rec.code_combination_id := v_cc_id;*/

         /*IF dat.entered_cr IS NOT NULL
         THEN
            insert_statement (p_gl_int_rec => l_gl_int_type_rec);
         END IF;*/

         insert_statement (p_gl_int_rec => l_gl_int_type_rec);
      END LOOP;

      logf ('p_submit_gl_interface');
      --mo_global.init ('SQLGL');
      mo_global.set_policy_context ('S', 82);
      /*fnd_global.apps_initialize (user_id        => 1252,         --g_user_id,
                                  resp_id        => 20434, --g_resp_id, --General Ledger Super User
                                  resp_appl_id   => 101);   --g_resp_appl_id);*/
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);
      fnd_request.set_org_id (102);
      /* After inset, submit the request*/
      COMMIT;
      v_conc_id :=
         fnd_request.submit_request (application   => 'SQLGL',
                                     program       => 'GLLEZL',
                                     description   => NULL,
                                     start_time    => SYSDATE,
                                     sub_request   => FALSE,
                                     argument1     => v_interface_run_id,
                                     argument2     => 2021,
                                     argument3     => 'N',
                                     argument4     => NULL,
                                     argument5     => NULL,
                                     argument6     => 'N',
                                     argument7     => 'W');

      logf ('abcdef ' || v_conc_id);

      COMMIT;
      v_bool :=
         fnd_concurrent.wait_for_request (v_conc_id,
                                          5,
                                          1000,
                                          phase,
                                          status,
                                          dev_phase,
                                          dev_status,
                                          v_message);

      COMMIT;

      logf ('Request id is ' || v_conc_id);

      IF (v_conc_id = 0)
      THEN
         /* If request not submitted, return false */
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         logf (' Returning false as request could not be submitted');
         RETURN;
      END IF;

      v_success_flag := TRUE;
   EXCEPTION
      WHEN conversion_rate_does_not_exist
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('XTR', 'XTR_2207');
         fnd_message.set_token ('CURR1', v_func_curr);
         fnd_message.set_token ('C_TYPE', g_conversion_type);
         logf ('conversion_rate_does_not_exist');
      WHEN invalid_currency_code
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('SQLGL', 'R_PPOS0026');
         logf ('invalid_currency_code');
      WHEN invalid_gl_source
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('SQLGL', 'SHRD0152');
         logf ('invalid_gl_source');
      WHEN invalid_conversion_type
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('SQLGL', 'GL_JE_INVALID_CONVERSION_TYPE');
         logf ('invalid_conversion_type');
      WHEN not_in_open_period
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('SQLGL', 'GL_JE_NOT_OPEN_OR_FUTURE_ENT');
         logf ('not_in_open_period');
      WHEN invalid_cr_ccid
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('AR', 'AR_AAPI_INVALID_CCID');
         logf ('invalid_cr_ccid');
      WHEN invalid_dr_ccid
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('AR', 'AR_AAPI_INVALID_CCID');
         logf ('invalid_dr_ccid');
      WHEN OTHERS
      THEN
         --ROLLBACK TO gms_cost_xfer_gl_int;
         v_success_flag := FALSE;
         fnd_message.set_name ('FND', 'FS-UNKNOWN');
         fnd_message.set_token ('ERROR', SQLERRM);
         logf ('Unexpected error ' || SQLERRM);
   END transfer_to_gl;
END xxkbn_import_gl_iface_api_pkg;
/