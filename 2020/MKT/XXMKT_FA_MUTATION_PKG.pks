CREATE OR REPLACE PACKAGE APPS.xxmkt_fa_mutation_pkg AUTHID CURRENT_USER
/* $Header: XXSHP_FA_MUTATION_PKG 122.5.1.0 2016/11/23 15:14:00 Hansen Darmawan $ */
AS
/**************************************************************************************************
       NAME: XXSHP_FA_MUTATION_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         23-Nov-2016          Hansen Darmawan     1. Created this package.
       1.0         04-Aug-2020          Ardi                2. Copy package from SHP
   **************************************************************************************************/
   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER);
END xxmkt_fa_mutation_pkg;
/
