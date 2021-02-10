CREATE OR REPLACE PACKAGE APPS.xxshp_inv_master_item_reg_pkg
   AUTHID CURRENT_USER
/* $Header: xxshp_inv_master_item_reg_pkg.pks 122.5.1.0 2017/03/14 10:36:10 Edi Yanto $ */
AS
   /******************************************************************************
       NAME: xxshp_inv_master_item_reg_pkg
       PURPOSE:

       REVISIONS:
       Ver         Date            Author                Description
       ---------   ----------      ---------------       ------------------------------------
       1.0         14-Mar-2017      Edi Yanto            1. Created this package.
      ******************************************************************************/
   g_org_id                NUMBER := fnd_profile.VALUE ('ORG_ID');
   g_user_id               NUMBER := fnd_profile.VALUE ('USER_ID');
   g_login_id              NUMBER := fnd_profile.VALUE ('LOGIN_ID');
   g_resp_id               NUMBER := fnd_profile.VALUE ('RESP_ID');
   g_resp_appl_id          NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   g_request_id            NUMBER := fnd_global.conc_request_id;
   g_item_type_parent      VARCHAR2 (20) := 'PARENT';
   g_item_type_kn          VARCHAR2 (20) := 'K';
   g_item_type_unstd       VARCHAR2 (20) := 'U';
   g_item_type_tollfee     VARCHAR2 (20) := 'T';
   g_cat_inv               mtl_category_sets.category_set_name%TYPE := 'SHP_INVENTORY';
   g_cat_glclass           mtl_category_sets.category_set_name%TYPE := 'SHP_PROCESS_GLCLASS';
   g_cat_glclass           mtl_category_sets.category_set_name%TYPE := 'SHP_PURCHASING_TYPE';
   g_cat_glclass           mtl_category_sets.category_set_name%TYPE := 'SHP_WMS_CATEGORY';
   g_cat_glclass           mtl_category_sets.category_set_name%TYPE := 'SHP_MAR&FA_PRODUCT_LINE';
   g_inprocess             VARCHAR2 (20) := 'INPROCESS';
   g_error_interface       VARCHAR2 (20) := 'ERROR_INTERFACE';
   g_inprocess_interface   VARCHAR2 (20) := 'INPROCESS_INTERFACE';
   g_complete              VARCHAR2 (20) := 'COMPLETE';
   g_success               VARCHAR2 (20) := 'SUCCESS';

   --Added by EY on 29-Sep-2017
   g_prod_sid              VARCHAR2 (50) := fnd_profile.VALUE ('XXSHP_SID_INSTANCE_REAL_EMAIL');

   --End EY

   PROCEDURE logf (p_msg IN VARCHAR2);

   PROCEDURE outf (p_msg IN VARCHAR2);

   FUNCTION get_post_processing (p_post_Processing VARCHAR2, p_template_id NUMBER)
      RETURN NUMBER;

   FUNCTION get_status_desc (p_status VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE waitforrequest (request_id IN NUMBER, status OUT VARCHAR2, err_message OUT VARCHAR2);

   PROCEDURE create_uom_conversion (p_reg_hdr_id IN NUMBER);

   PROCEDURE create_asl_attributes (p_reg_hdr_id IN NUMBER);

   PROCEDURE create_mfg_part_numbers (p_reg_hdr_id IN NUMBER);

   PROCEDURE create_bill_of_dist (p_reg_hdr_id IN NUMBER);

   PROCEDURE assign_item_category (p_reg_hdr_id IN NUMBER, x_return OUT NUMBER);

   PROCEDURE assign_item_subinv (p_reg_hdr_id IN NUMBER, x_return OUT NUMBER);

   PROCEDURE create_master_item (p_reg_hdr_id IN NUMBER, x_return OUT NUMBER);

   PROCEDURE assign_org_item (p_reg_hdr_id NUMBER, x_return OUT NUMBER);

   PROCEDURE submit_items_interface (p_errbuf          OUT VARCHAR2,
                                     p_retcode         OUT NUMBER,
                                     p_reg_hdr_id   IN     NUMBER);

   PROCEDURE main_process (p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_reg_hdr_id IN NUMBER);
   
   -- Added Fajrin 2018-07-14
   procedure change_status(p_item_id NUMBER, p_org_id NUMBER, p_status VARCHAR);
   -- end Added Fajrin 2018-07-14
END xxshp_inv_master_item_reg_pkg;
/
