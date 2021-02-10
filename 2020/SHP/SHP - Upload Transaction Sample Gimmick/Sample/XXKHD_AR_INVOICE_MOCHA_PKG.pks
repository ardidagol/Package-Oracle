CREATE OR REPLACE PACKAGE APPS.XXKHD_AR_INVOICE_MOCHA_PKG
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2020 KN IT                                             |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXKHD_AR_INVOICE_MOCHA_PKG.pks                                                        |
   REM |     Parameters  :                                                                                       |
   REM |     Description :                                                                                       |
   REM |     History     : 29 April 2020      Rezky Pancanuary  Created Initial Coding                           |
   REM |     Proposed    : AR Invoice Interface Data Source from Mocha                                           |
   REM |     Revised     :                                                                                       |
   REM |                                                                                                         |
   REM +---------------------------------------------------------------------------------------------------------+
   */

   g_max_time       PLS_INTEGER DEFAULT 3600;
   g_interval       PLS_INTEGER DEFAULT 5;

   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;
   g_org_code       VARCHAR2 (50) := 'OTH';
   g_ar_appl_id     NUMBER := 222;                                       -- AR

   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   CURSOR c_dataheader (p_file_id NUMBER)
   IS
        SELECT stg.vendor_name,
               stg.interface_id,
               stg.invoice_num,
               stg.GROUP_ID,
               --               CASE
               --                  WHEN TO_CHAR (stg.process_date, 'MON-RR') = stg.periode
               --                  THEN
               --                     TRUNC (stg.process_date)
               --                  ELSE
               --                     TO_DATE (stg.periode, 'MON-RRRR')
               --               END
               stg.gl_date
          FROM XXKHD_AR_MOCHA_RCV_STG stg
         WHERE 1 = 1 AND stg.file_id = p_file_id
      GROUP BY stg.vendor_name,
               stg.interface_id,
               stg.invoice_num,
               stg.group_id,
                  stg.gl_date;


   CURSOR c_datadetail (p_file_id NUMBER, p_group_id VARCHAR2)
   IS
      SELECT file_id,
             GROUP_ID,
             no_invoice,
             transaction_type,
             customer,
             bill_to,
             currency,
             invoice_date,
             gl_date_invoice,
             coa,
             description_coa,
             amount,
             receipt_date,
             gl_date_receipt,
             bank,
             bank_account_number,
             amount_receipt
        FROM XXKHD_UPLD_MOCCA_REC_STG
       WHERE file_Id = p_file_id AND GROUP_ID = p_group_id;

   PROCEDURE process_data (errbuf          OUT VARCHAR2,
                           retcode         OUT VARCHAR2,
                           p_file_id    IN     NUMBER,
                           p_group_id   IN     VARCHAR2);

   PROCEDURE insert_data (errbuf         OUT VARCHAR2,
                          retcode        OUT NUMBER,
                          p_file_id   IN     NUMBER);

   PROCEDURE insert_header (errbuf         OUT VARCHAR2,
                            retcode        OUT NUMBER,
                            p_file_id   IN     NUMBER);
END XXKHD_AR_INVOICE_MOCHA_PKG;
/