CREATE OR REPLACE PACKAGE APPS.xxshp_gmd_item_spec_pkg AUTHID CURRENT_USER
/* $Header: xxshp_gmd_item_spec_pkg.pks 122.5.1.0 2016/11/10 11:38:00 Farry Ciptono $ */
AS
/******************************************************************************
    NAME: xxshp_gmd_item_spec_pkg
    PURPOSE:

    REVISIONS:
    Ver         Date            Author              Description
    ---------   ----------      ---------------       ------------------------------------
    1.0         28-Nov-2016     Farry Ciptono         1. Created this package.
   ******************************************************************************/
   g_user_id           NUMBER         := fnd_profile.VALUE ('USER_ID');
   g_login_id          NUMBER         := fnd_profile.VALUE ('LOGIN_ID');
   g_resp_id           NUMBER         := fnd_profile.VALUE ('RESP_ID');
   g_resp_appl_id      NUMBER         := fnd_profile.VALUE ('RESP_APPL_ID');
   g_formula_status    VARCHAR2 (30)  := '700';                                                                          --"Approved for General Use"
   g_organization_id   NUMBER         := fnd_profile.VALUE ('MFG_ORGANIZATION_ID');
   g_user_name         VARCHAR2 (100) := fnd_global.user_name;

   PROCEDURE logf (p_char VARCHAR2);

   PROCEDURE outf (p_char VARCHAR2);

   PROCEDURE get_error_msg (p_msg_count IN NUMBER, p_msg_index IN OUT NUMBER, x_msg_data OUT VARCHAR2);

   PROCEDURE validate_spec (p_process_id NUMBER, p_status OUT VARCHAR2, p_message OUT VARCHAR2);

   PROCEDURE item_spec_iface (errbuf OUT VARCHAR2, retcode OUT NUMBER, p_process_id NUMBER);

   TYPE tlog IS RECORD (
      process_id     NUMBER,
      interface_id   NUMBER,
      status         VARCHAR2 (15),
      MESSAGE        VARCHAR2 (1000)
   );

   TYPE tlog_type IS TABLE OF tlog
      INDEX BY BINARY_INTEGER;
END xxshp_gmd_item_spec_pkg;
/
