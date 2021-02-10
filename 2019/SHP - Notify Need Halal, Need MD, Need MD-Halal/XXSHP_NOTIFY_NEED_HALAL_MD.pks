/* Formatted on 7/2/2019 1:57:15 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE APPS.XXSHP_NOTIFY_NEED_HALAL_MD
AS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2019  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXSHP_NOTIFY_NEED_HALAL_MD.pks                                                        |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Untuk merubah menampilkan informasi Need Halal, Need MD, dan Need MD/Halal            |
   REM |     History     : 2 Jun 2019 --Ardianto--  create this package                                          |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */

   g_user_id           PLS_INTEGER := fnd_global.user_id;
   g_resp_id           PLS_INTEGER := fnd_global.resp_id;
   g_resp_appl_id      PLS_INTEGER := fnd_global.resp_appl_id;
   g_organization_id   PLS_INTEGER := fnd_global.org_id;

   PROCEDURE send_mail (retcode OUT NUMBER, errbuff OUT VARCHAR2);

   CURSOR mpn_info_cur
   IS
      SELECT DISTINCT
             mcb.segment3 kn_lob,
             msi.attribute2 item_template,
             msi.item_type,
             mis.inventory_item_status_code_tl,
             mm.manufacturer_id,
             manufacturer_name part,
             mm.description part_desc,
             mmp.inventory_item_id,
             msi.segment1 item_code,
             msi.description item_desc,
             mmp.organization_id,
             mp.organization_code,
             msi.primary_uom_code uom_code,
             mmp.attribute9 halal_number,
             TRUNC (TO_DATE (mmp.attribute10, 'yyyy/mm/dd hh24:mi:ss'))
                halal_valid_to,
             mmp.attribute4 MD_NUM,
             TRUNC (TO_DATE (mmp.attribute5, 'yyyy/mm/dd hh24:mi:ss'))
                MD_VALID_TO,
             aps.vendor_name supplier_name,
             mmp.attribute12 halal_body,
             mmp.mfg_part_num,
             mm.manufacturer_name
        FROM mtl_manufacturers mm,
             mtl_system_items msi,
             mtl_mfg_part_numbers mmp,
             po_approved_supplier_list pasl,
             ap_suppliers aps,
             ap_supplier_sites_all apss,
             mtl_parameters mp,
             mtl_item_categories mic,
             mtl_categories_b_kfv mcb,
             mtl_item_status mis
       WHERE     mmp.manufacturer_id = mm.manufacturer_id
             AND mmp.inventory_item_id = msi.inventory_item_id
             AND mmp.organization_id = msi.organization_id
             AND aps.vendor_id = apss.vendor_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_id = mm.attribute12
             AND apss.vendor_site_id = mm.attribute13
             --       AND mmp.attribute10 IS NOT NULL
             AND msi.attribute2 IS NOT NULL
             --       AND mmp.attribute5 IS NOT NULL
             AND mp.organization_id = mmp.organization_id
             AND mic.inventory_item_id = mmp.inventory_item_id
             AND mic.organization_id = mmp.organization_id
             AND mcb.category_id = mic.category_id
             AND mis.inventory_item_status_code =
                    msi.inventory_item_status_code
             AND category_set_id = '1100000042'
             AND msi.item_type IN ('PACKAGING MATERIAL', 'FINISHED GOODS')
             AND msi.inventory_item_status_code IN ('Need Halal',
                                                    'Need MD',
                                                    'Need MD/Ha');
END XXSHP_NOTIFY_NEED_HALAL_MD;
/