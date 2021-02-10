CREATE OR REPLACE PACKAGE APPS.XXSHP_MAIL_AVAILABLE_FP_PKG
AS

    
      NAME XXSHP_WH_MTRG_PICK_PKG
      PURPOSE

      REVISIONS
      Ver         Date            Author                        Description
      ---------   ----------      ---------------               ------------------------------------
      1.0         4-MAY-2020     Ardie                         1. Created this package.
     
     
   g_user_id           PLS_INTEGER = fnd_global.user_id;
   g_resp_id           PLS_INTEGER = fnd_global.resp_id;
   g_resp_appl_id      PLS_INTEGER = fnd_global.resp_appl_id;
   g_organization_id   PLS_INTEGER = fnd_global.org_id;

   PROCEDURE check_available (errbuf OUT VARCHAR2, retcode OUT NUMBER);
      
   PROCEDURE send_mail (p_total_fp IN NUMBER, p_year IN VARCHAR2);

END XXSHP_MAIL_AVAILABLE_FP_PKG;

