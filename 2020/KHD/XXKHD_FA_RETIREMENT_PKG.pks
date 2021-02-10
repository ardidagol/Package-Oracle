CREATE OR REPLACE PACKAGE APPS.xxkhd_fa_retirement_pkg AUTHID CURRENT_USER
/* $Header: XXKHD_FA_RETIREMENT_PKG 122.5.1.0 2016/11/21 10:44:00 Hansen Darmawan $ */
AS
/**************************************************************************************************
       NAME: XXKHD_FA_RETIREMENT_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         21-Nov-2016          Hansen Darmawan     1. Created this package.
       1.0         04-Aug-2020          Ardi                2. Copy package from SHP
   **************************************************************************************************/
   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;
   --Added by EY on 9-Jun-2017
   g_ar_tax_code    zx_mco_lv_rates_v.tax_rate_code%type := fnd_profile.value('XXKHD_AR_TAX_RATE_CODE');
   --End EY

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER, p_retirement_type VARCHAR2);
END;
/
