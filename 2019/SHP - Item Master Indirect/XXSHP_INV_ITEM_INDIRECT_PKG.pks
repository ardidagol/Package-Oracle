CREATE OR REPLACE PACKAGE APPS.xxshp_inv_item_indirect_pkg AUTHID CURRENT_USER
/* $Header: XXSHP_INV_ITEM_INDIRECT_PKG.pks 122.5.1.0 2016/12/06 10:41:10 Farry Ciptono $ */
AS
/******************************************************************************
    NAME: xxshp_inv_item_indirect_pkg
    PURPOSE:

    REVISIONS:
    Ver         Date            Author                Description
    ---------   ----------      ---------------       ------------------------------------
    1.0         6-Dec-2016      Farry Ciptono         1. Created this package.
    1.1         27-Jun-2019     Ardianto              2. Add Item_Type on insert to interface
   ******************************************************************************/
   g_org_id           NUMBER := fnd_profile.VALUE ('ORG_ID');
   g_user_id          NUMBER := fnd_profile.VALUE ('USER_ID');
   g_login_id         NUMBER := fnd_profile.VALUE ('LOGIN_ID');
   g_resp_id          NUMBER := fnd_profile.VALUE ('RESP_ID');
   g_application_id   NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');

   PROCEDURE logf (p_msg IN VARCHAR2);

   PROCEDURE outf (p_msg IN VARCHAR2);

   FUNCTION get_status_desc (p_status VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE waitforrequest (request_id IN NUMBER, status OUT VARCHAR2, err_message OUT VARCHAR2);

   PROCEDURE submit_report (p_requestor VARCHAR2, p_validator VARCHAR2, p_req_no NUMBER, p_return OUT NUMBER);

   PROCEDURE validate_item (p_req_no NUMBER, p_return OUT NUMBER);

   PROCEDURE submit_interface (p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_req_no NUMBER);

   PROCEDURE master_item (p_req_no NUMBER, p_return OUT NUMBER);

   PROCEDURE assign_category (p_req_no NUMBER, p_return OUT NUMBER);

   PROCEDURE assign_org_item (p_req_no NUMBER, p_return OUT NUMBER);

   PROCEDURE assign_item_subinv (p_req_no NUMBER, p_return OUT NUMBER);
END;
/
