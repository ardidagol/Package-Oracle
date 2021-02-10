CREATE OR REPLACE PACKAGE APPS.xxkbn_create_rfp_inv_pkg
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
   g_resp_appl_id          NUMBER DEFAULT fnd_global.resp_appl_id;
   g_resp_id               NUMBER DEFAULT fnd_global.resp_id;
   g_conc_program_id       NUMBER DEFAULT fnd_global.conc_program_id;
   g_conc_request_id       NUMBER DEFAULT fnd_global.conc_request_id;
   g_org_id                NUMBER DEFAULT fnd_global.org_id;
   g_user_id               NUMBER DEFAULT fnd_global.user_id;
   g_username              VARCHAR2 (100) DEFAULT fnd_global.user_name;
   g_login_id              NUMBER DEFAULT fnd_global.login_id;
   g_end_date              DATE;

   g_invoice_type          VARCHAR2 (100) DEFAULT 'INVOICE TYPE';
   g_invoice_lookup_code   VARCHAR2 (100) DEFAULT 'STANDARD';
   g_set_book_name         VARCHAR2 (100) DEFAULT 'KBN LEDGER 2021(IDR)';
   g_source_type           VARCHAR2 (100) DEFAULT 'SOURCE';
   g_organization_code     VARCHAR2 (3) DEFAULT 'KBN';
   g_invoice_line_type     VARCHAR2 (100) DEFAULT 'INVOICE LINE TYPE';
   g_displayed_item        VARCHAR2 (100) DEFAULT 'Item';

   g_set_of_books_id       PLS_INTEGER
                              DEFAULT Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');
   g_max_time              PLS_INTEGER DEFAULT 3600;                 --3 hari.
   g_intval_time           PLS_INTEGER DEFAULT 5;

   error_insert            EXCEPTION;

   g_terms                 VARCHAR2 (250)
      DEFAULT 'KBN 14 DAYS AFTER RECEIVED COMPLETE INVOICE';

   PROCEDURE validate_invoice_rfp (p_rfp_num   IN     VARCHAR2,
                                   p_req_id       OUT NUMBER,
                                   errbuf         OUT VARCHAR2,
                                   retcode        OUT NUMBER);


   PROCEDURE create_rfp_invoice (errbuf           OUT VARCHAR2,
                                 retcode          OUT VARCHAR2,
                                 p_invoice_date       DATE);

   CURSOR c_data_header (p_invoice_date DATE)
   IS
      SELECT invoice_id,
             invoice_num,
             invoice_type_lookup_code,
             invoice_date,
             vendor_id,
             vendor_name,
             vendor_site_id,
             vendor_site_code,
             invoice_amount,
             invoice_currency_code,
             terms_name,
             description,
             source,
             GROUP_ID,
             gl_date,
             org_id,
             org_code,
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
             last_update_login
        FROM xxkbn_rfp_invoice_hdr
       WHERE invoice_date = p_invoice_date;

   CURSOR c_data_line (p_invoice_id NUMBER)
   IS
      SELECT invoice_id,
             invoice_line_id,
             line_number,
             line_type_lookup_code,
             amount,
             accounting_date,
             description,
             dist_code_concatenated,
             dist_code_combination_id,
             org_id,
             org_code,
             awt_group_name,
             vat_code,
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
             last_update_login
        FROM xxkbn_rfp_invoice_line
       WHERE invoice_id = p_invoice_id;
END xxkbn_create_rfp_inv_pkg;
/