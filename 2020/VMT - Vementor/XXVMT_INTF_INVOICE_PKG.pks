CREATE OR REPLACE PACKAGE APPS.XXVMT_INTF_INVOICE_PKG
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

   g_max_time       PLS_INTEGER DEFAULT 3600;
   g_intval_time    PLS_INTEGER DEFAULT 5;

   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;
   g_ar_appl_id     NUMBER := 222;
   g_org_id         NUMBER := 82;

   PROCEDURE validate_invoice_rfp (p_rfp_num     IN     VARCHAR2,
                                   p_req_id         OUT NUMBER,
                                   errbuf           OUT VARCHAR2,
                                   retcode          OUT NUMBER);

   FUNCTION chk_inv_cancellable (v_invoice_id IN NUMBER)
      RETURN BOOLEAN;
      
   FUNCTION gl_code_descr(p_gl_code NUMBER)
      RETURN VARCHAR2;

   PROCEDURE cancel_invoice_rfp (p_rfp_num             IN     VARCHAR2,
                                 p_last_updated_by     IN     NUMBER,
                                 p_last_update_login   IN     NUMBER,
                                 errbuf                   OUT VARCHAR2,
                                 retcode                  OUT NUMBER);
END XXVMT_INTF_INVOICE_PKG;
/