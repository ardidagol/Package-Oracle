CREATE OR REPLACE PACKAGE APPS.xxmkt_fa_addition_pkg AUTHID CURRENT_USER
/* $Header: XXMKT_FA_ADDITION_PKG 122.5.1.0 2016/11/24 15:56:00 Hansen Darmawan $ */
AS
/**************************************************************************************************
       NAME: XXMKT_FA_ADDITION_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         24-Nov-2016          Hansen Darmawan     1. Created this package.
   **************************************************************************************************/
   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER);
END;
/
