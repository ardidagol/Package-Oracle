CREATE OR REPLACE PACKAGE APPS.XXGVN_INV_ITEMS_PLAN_PARAM_PKG
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXGVN_INV_ITEMS_PLAN_PARAM_PKG.pks                                                    |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Planning Parameter Modifying all in this Package                                      |
   REM |     History     : 1 Maret 2019 --Ardianto--  Copy From Package XXGVN_INV_ITEMS_API_PKG.pks              |
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


   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   CURSOR c_items_stg (p_file_id NUMBER)
   IS
      SELECT msi.segment1,
             msi.description,
             msi.long_description,
             msi.organization_code,
             msi.primary_uom_code,
             msi.minimum_order_quantity,
             msi.attribute21,                                   --Packing Size
             msi.attribute3,                                      --LT Release
             msi.attribute22                                   --safety Stock
        FROM xxgvn_inv_items_stg msi
       WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER);
END XXGVN_INV_ITEMS_PLAN_PARAM_PKG;
/
