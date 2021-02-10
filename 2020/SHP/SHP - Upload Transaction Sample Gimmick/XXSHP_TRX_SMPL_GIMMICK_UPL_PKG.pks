CREATE OR REPLACE PACKAGE APPS.XXSHP_TRX_SMPL_GIMMICK_UPL_PKG
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

   g_max_time       PLS_INTEGER DEFAULT 3600;
   g_intval_time    PLS_INTEGER DEFAULT 5;

   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;
   g_ar_appl_id     NUMBER := 222;

   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   CURSOR c_items_stg (p_file_id NUMBER)
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
        FROM xxshp_trx_smpl_gimmick_stg xtsg
       WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER);
                          
   PROCEDURE process_data (errbuf         OUT VARCHAR2,
                           retcode        OUT VARCHAR2,
                           p_file_id   IN     NUMBER);
END XXSHP_TRX_SMPL_GIMMICK_UPL_PKG;
/
