/* Formatted on 1/13/2021 9:53:36 AM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE APPS.xxkbn_import_gl_iface_api_pkg
   AUTHID CURRENT_USER
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXKBN_IMPORT_GL_IFACE_API_PKG                                                         |
   REM |     Concurrent  :                                                                                       |
   REM |     Parameters  :                                                                                       |
   REM |     Description : This package gives API for GL interface calls                                         |
   REM |     History     : 31 DEC 2020  --Ardianto--                                                             |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */
   g_sob_id                           INTEGER := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   g_source_name                      gl_je_headers.je_source%TYPE;
   g_error_flag                       VARCHAR2 (1) := NULL;

   g_xx_transaction_source   CONSTANT VARCHAR2 (80) := 'XX_COST_XFER';

   --move these three into the config screen.

   g_gl_appl_name            CONSTANT VARCHAR2 (30) := 'SQLGL';
   g_conversion_type_code             VARCHAR2 (30);
   g_conversion_type                  VARCHAR2 (30) DEFAULT 'Corporate';

   --Programming variables
   --g_group_id and g_interface_run_id will be set each time separately for a batch
   g_group_id                         NUMBER;
   g_interface_run_id                 NUMBER;

   g_resp_appl_id                     NUMBER DEFAULT fnd_global.resp_appl_id;
   g_resp_id                          NUMBER DEFAULT fnd_global.resp_id;
   g_conc_program_id                  NUMBER
                                         DEFAULT fnd_global.conc_program_id;
   g_conc_request_id                  NUMBER
                                         DEFAULT fnd_global.conc_request_id;
   g_org_id                           NUMBER DEFAULT fnd_global.org_id;
   g_user_id                          NUMBER DEFAULT fnd_global.user_id;
   g_username                         VARCHAR2 (100)
                                         DEFAULT fnd_global.user_name;
   g_login_id                         NUMBER DEFAULT fnd_global.login_id;

   g_max_time                         PLS_INTEGER DEFAULT 3600;      --3 hari.
   g_intval_time                      PLS_INTEGER DEFAULT 5;


   PROCEDURE populate_interface_control (
      p_user_je_source_name   IN     VARCHAR2,
      p_group_id              IN OUT NUMBER,
      p_set_of_books_id              NUMBER,
      p_interface_run_id      IN OUT NUMBER);

   TYPE g_gl_int_type_rec IS RECORD
   (
      reference_date                  DATE,
      attribute20                     VARCHAR2 (150),
      CONTEXT                         VARCHAR2 (150),
      ledger_id                       NUMBER,
      context2                        VARCHAR2 (150),
      invoice_date                    DATE,
      tax_code                        VARCHAR2 (15),
      invoice_identifier              VARCHAR2 (20),
      invoice_amount                  NUMBER,
      context3                        VARCHAR2 (150),
      ussgl_transaction_code          VARCHAR2 (30),
      descr_flex_error_message        VARCHAR2 (240),
      jgzz_recon_ref                  VARCHAR2 (240),
      segment23                       VARCHAR2 (25),
      segment24                       VARCHAR2 (25),
      segment25                       VARCHAR2 (25),
      segment26                       VARCHAR2 (25),
      segment27                       VARCHAR2 (25),
      segment28                       VARCHAR2 (25),
      segment29                       VARCHAR2 (25),
      segment30                       VARCHAR2 (25),
      entered_dr                      NUMBER,
      entered_cr                      NUMBER,
      accounted_dr                    NUMBER,
      accounted_cr                    NUMBER,
      transaction_date                DATE,
      reference1                      VARCHAR2 (100),
      reference2                      VARCHAR2 (240),
      reference3                      VARCHAR2 (100),
      reference4                      VARCHAR2 (100),
      reference5                      VARCHAR2 (240),
      reference6                      VARCHAR2 (100),
      reference7                      VARCHAR2 (100),
      reference8                      VARCHAR2 (100),
      reference9                      VARCHAR2 (100),
      reference10                     VARCHAR2 (240),
      reference11                     VARCHAR2 (100),
      reference12                     VARCHAR2 (100),
      reference13                     VARCHAR2 (100),
      reference14                     VARCHAR2 (100),
      reference15                     VARCHAR2 (100),
      reference16                     VARCHAR2 (100),
      reference17                     VARCHAR2 (100),
      reference18                     VARCHAR2 (100),
      reference19                     VARCHAR2 (100),
      reference20                     VARCHAR2 (100),
      reference21                     VARCHAR2 (240),
      reference22                     VARCHAR2 (240),
      reference23                     VARCHAR2 (240),
      reference24                     VARCHAR2 (240),
      reference25                     VARCHAR2 (240),
      reference26                     VARCHAR2 (240),
      reference27                     VARCHAR2 (240),
      reference28                     VARCHAR2 (240),
      reference29                     VARCHAR2 (240),
      reference30                     VARCHAR2 (240),
      je_batch_id                     NUMBER,
      period_name                     VARCHAR2 (15),
      je_header_id                    NUMBER,
      je_line_num                     NUMBER,
      chart_of_accounts_id            NUMBER,
      functional_currency_code        VARCHAR2 (15),
      code_combination_id             NUMBER,
      date_created_in_gl              DATE,
      warning_code                    VARCHAR2 (4),
      status_description              VARCHAR2 (240),
      stat_amount                     NUMBER,
      GROUP_ID                        NUMBER,
      request_id                      NUMBER,
      subledger_doc_sequence_id       NUMBER,
      subledger_doc_sequence_value    NUMBER,
      attribute1                      VARCHAR2 (150),
      attribute2                      VARCHAR2 (150),
      gl_sl_link_id                   NUMBER,
      gl_sl_link_table                VARCHAR2 (30),
      attribute3                      VARCHAR2 (150),
      attribute4                      VARCHAR2 (150),
      attribute5                      VARCHAR2 (150),
      attribute6                      VARCHAR2 (150),
      attribute7                      VARCHAR2 (150),
      attribute8                      VARCHAR2 (150),
      attribute9                      VARCHAR2 (150),
      attribute10                     VARCHAR2 (150),
      attribute11                     VARCHAR2 (150),
      attribute12                     VARCHAR2 (150),
      attribute13                     VARCHAR2 (150),
      attribute14                     VARCHAR2 (150),
      attribute15                     VARCHAR2 (150),
      attribute16                     VARCHAR2 (150),
      attribute17                     VARCHAR2 (150),
      attribute18                     VARCHAR2 (150),
      attribute19                     VARCHAR2 (150),
      status                          VARCHAR2 (50),
      set_of_books_id                 NUMBER,
      accounting_date                 DATE,
      currency_code                   VARCHAR2 (15),
      date_created                    DATE,
      created_by                      NUMBER,
      actual_flag                     VARCHAR2 (1),
      user_je_category_name           VARCHAR2 (25),
      user_je_source_name             VARCHAR2 (25),
      currency_conversion_date        DATE,
      encumbrance_type_id             NUMBER,
      budget_version_id               NUMBER,
      user_currency_conversion_type   VARCHAR2 (30),
      currency_conversion_rate        NUMBER,
      average_journal_flag            VARCHAR2 (1),
      originating_bal_seg_value       VARCHAR2 (25),
      segment1                        VARCHAR2 (25),
      segment2                        VARCHAR2 (25),
      segment3                        VARCHAR2 (25),
      segment4                        VARCHAR2 (25),
      segment5                        VARCHAR2 (25),
      segment6                        VARCHAR2 (25),
      segment7                        VARCHAR2 (25),
      segment8                        VARCHAR2 (25),
      segment9                        VARCHAR2 (25),
      segment10                       VARCHAR2 (25),
      segment11                       VARCHAR2 (25),
      segment12                       VARCHAR2 (25),
      segment13                       VARCHAR2 (25),
      segment14                       VARCHAR2 (25),
      segment15                       VARCHAR2 (25),
      segment16                       VARCHAR2 (25),
      segment17                       VARCHAR2 (25),
      segment18                       VARCHAR2 (25),
      segment19                       VARCHAR2 (25),
      segment20                       VARCHAR2 (25),
      segment21                       VARCHAR2 (25),
      segment22                       VARCHAR2 (25)
   );

   PROCEDURE insert_statement (p_gl_int_rec IN OUT NOCOPY g_gl_int_type_rec);

   PROCEDURE transfer_to_gl (p_date_created DATE);

   FUNCTION get_gl_application_id (p_appl_name IN VARCHAR2)
      RETURN INTEGER;

   CURSOR source_data (
      p_date_created    DATE)
   IS
      SELECT HDR.LEDGER_ID,
             USER_JE_CATEGORY_NAME,
             USER_JE_SOURCE_NAME,
             CURRENCY_CODE,
             ACCOUNTING_DATE,
             DATE_CREATED,
             ACTUAL_FLAG,
             JE_BATCH_ID,
             JE_HEADER_ID,
             RUNNING_TOTAL_DR,
             RUNNING_TOTAL_CR,
             RUNNING_TOTAL_ACCOUNTED_DR,
             RUNNING_TOTAL_ACCOUNTED_CR,
             CURRENCY_CONVERSION_RATE,
             CURRENCY_CONVERSION_DATE,
             LINE_NUM,
             PERIOD_NAME,
             EFECTIVE_DATE,
             CODE_COMBINATION_ID,
             SEGMENT1,
             SEGMENT2,
             SEGMENT3,
             SEGMENT4,
             SEGMENT5,
             SEGMENT6,
             SEGMENT7,
             ENTERED_DR,
             ENTERED_CR,
             ACCOUNTED_DR,
             ACCOUNTED_CR,
             LINE_TYPE_CODE,
             GROUP_ID,
             REFERENCE1,
             REFERENCE4,
             REFERENCE10,
             REFERENCE25,
             REFERENCE26,
             REFERENCE27,
             REFERENCE28,
             REFERENCE29,
             REFERENCE30,
             ATTRIBUTE1,
             ATTRIBUTE2,
             ATTRIBUTE3,
             ATTRIBUTE4,
             ATTRIBUTE5,
             ATTRIBUTE6,
             ATTRIBUTE7,
             ATTRIBUTE8,
             ATTRIBUTE9,
             ATTRIBUTE10,
             ATTRIBUTE11,
             ATTRIBUTE12,
             ATTRIBUTE13,
             ATTRIBUTE14,
             ATTRIBUTE15
        FROM XXKBN_GL_JOURNAL_HDR hdr, XXKBN_GL_JOURNAL_LINE line
       WHERE     1 = 1
             AND hdr.header_id = line.header_id
             AND hdr.date_created = p_date_created;
END xxkbn_import_gl_iface_api_pkg;
/