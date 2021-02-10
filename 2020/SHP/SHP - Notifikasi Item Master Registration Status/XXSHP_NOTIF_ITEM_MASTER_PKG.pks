CREATE OR REPLACE PACKAGE APPS.XXSHP_NOTIF_ITEM_MASTER_PKG AUTHID CURRENT_USER
AS
   
   TYPE varchar2_table IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;
      
   TYPE ARRAY IS TABLE OF varchar2(255);

   g_user_id        NUMBER := fnd_global.user_id;
   g_resp_id        NUMBER := fnd_global.resp_id;
   g_resp_appl_id   NUMBER := fnd_global.resp_appl_id;
   g_request_id     NUMBER := fnd_global.conc_request_id;
   g_login_id       NUMBER := fnd_global.login_id;
   
   PROCEDURE send_mail_notification_pm(errbuf OUT VARCHAR2, retcode OUT NUMBER);
   PROCEDURE send_mail_notification_fgsab(errbuf OUT VARCHAR2, retcode OUT NUMBER);
   PROCEDURE send_mail_notification_fgsam(errbuf OUT VARCHAR2, retcode OUT NUMBER);
   PROCEDURE send_mail_notification_base(errbuf OUT VARCHAR2, retcode OUT NUMBER);
   PROCEDURE send_mail_notification_rm(errbuf OUT VARCHAR2, retcode OUT NUMBER);
   PROCEDURE validations(errbuf OUT VARCHAR2, retcode OUT NUMBER);
      
END;
/
