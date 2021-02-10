/* Formatted on 10/23/2020 10:58:21 AM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE APPS.xxshp_inv_upd_itemcat_pkg
IS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2017  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXSHP_INV_UPD_ITEMCAT_PKG.pks                                                         |
   REM |     Concurrent  : SHP - Upload Create Item Category Assign                                              |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Planning Parameter New all in this Package                                            |
   REM |     History     : 1 OCT 2020  --Ardianto--                                                              |
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

   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   CURSOR c_items_stg (p_file_id NUMBER)
   IS
      SELECT file_id,
             file_name,
             org_code,
             item_code,
             category_set_name,
             segment1,
             segment2,
             segment3,
             segment4,
             segment5,
             segment6
        FROM xxshp_inv_item_cats_stg ximp
       WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;


   CURSOR c_cat_create (
      p_file_id    NUMBER)
   IS
      SELECT xiit.category_set_name,
             xiit.segment1,
             xiit.segment2,
             xiit.segment3,
             xiit.segment4,
             xiit.segment5,
             xiit.segment6
        FROM (SELECT DISTINCT xii.category_set_name,
                              xii.segment1,
                              xii.segment2,
                              xii.segment3,
                              xii.segment4,
                              xii.segment5,
                              xii.segment6
                FROM xxshp_inv_item_cats_stg xii
               WHERE     1 = 1
                     AND xii.category_set_name = 'SHP_INVENTORY'
                     AND NVL (flag, 'Y') = 'Y'
                     AND file_id = p_file_id
                     AND NOT EXISTS
                                (SELECT 1
                                   FROM fnd_id_flex_structures fif,
                                        mtl_categories_b mcb
                                  WHERE     1 = 1
                                        AND xii.category_set_name =
                                               fif.id_flex_structure_code
                                        AND fif.id_flex_num =
                                               mcb.structure_id
                                        AND mcb.segment1 = xii.segment1
                                        AND mcb.segment2 = xii.segment2
                                        AND mcb.segment3 = xii.segment3
                                        AND mcb.segment4 = xii.segment4
                                        AND mcb.segment5 = xii.segment5
                                        AND mcb.segment6 = xii.segment6)
              UNION
              SELECT DISTINCT xii.category_set_name,
                              xii.segment1,
                              xii.segment2,
                              xii.segment3,
                              xii.segment4,
                              xii.segment5,
                              xii.segment6
                FROM xxshp_inv_item_cats_stg xii
               WHERE     1 = 1
                     AND xii.category_set_name = 'SHP_PURCHASING_TYPE'
                     AND NVL (flag, 'Y') = 'Y'
                     AND file_id = p_file_id
                     AND NOT EXISTS
                                (SELECT 1
                                   FROM fnd_id_flex_structures fif,
                                        mtl_categories_b mcb
                                  WHERE     1 = 1
                                        AND xii.category_set_name =
                                               fif.id_flex_structure_code
                                        AND fif.id_flex_num =
                                               mcb.structure_id
                                        AND mcb.segment1 = xii.segment1
                                        AND mcb.segment2 = xii.segment2
                                        AND mcb.segment3 = xii.segment3
                                        AND mcb.segment4 = xii.segment4)
              UNION
              SELECT DISTINCT xii.category_set_name,
                              xii.segment1,
                              xii.segment2,
                              xii.segment3,
                              xii.segment4,
                              xii.segment5,
                              xii.segment6
                FROM xxshp_inv_item_cats_stg xii
               WHERE     1 = 1
                     AND xii.category_set_name = 'SHP_PROCESS_GLCLASS'
                     AND NVL (flag, 'Y') = 'Y'
                     AND file_id = p_file_id
                     AND NOT EXISTS
                                (SELECT 1
                                   FROM fnd_id_flex_structures fif,
                                        mtl_categories_b mcb
                                  WHERE     1 = 1
                                        AND xii.category_set_name =
                                               fif.id_flex_structure_code
                                        AND fif.id_flex_num =
                                               mcb.structure_id
                                        AND mcb.segment1 = xii.segment1
                                        AND mcb.segment2 = xii.segment2
                                        AND mcb.segment3 = xii.segment3)
              UNION
              SELECT DISTINCT xii.category_set_name,
                              xii.segment1,
                              xii.segment2,
                              xii.segment3,
                              xii.segment4,
                              xii.segment5,
                              xii.segment6
                FROM xxshp_inv_item_cats_stg xii
               WHERE     1 = 1
                     AND xii.category_set_name = 'SHP_WMS_CATEGORY'
                     AND NVL (flag, 'Y') = 'Y'
                     AND file_id = p_file_id
                     AND NOT EXISTS
                                (SELECT 1
                                   FROM fnd_id_flex_structures fif,
                                        mtl_categories_b mcb
                                  WHERE     1 = 1
                                        AND xii.category_set_name =
                                               fif.id_flex_structure_code
                                        AND fif.id_flex_num =
                                               mcb.structure_id
                                        AND mcb.segment1 = xii.segment1))
             xiit;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER);
END xxshp_inv_upd_itemcat_pkg;
/