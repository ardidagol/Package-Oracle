CREATE OR REPLACE PACKAGE APPS.XXSHP_MPN_HALAL_EXP_NOTIFY
AS

   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2019  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXSHP_MPN_HALAL_EXP_NOTIFY.pks                                                        |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Untuk merubah status item menjadi phase out                                           |
   REM |     History     : 21 Des 2019 --Ardianto--  create this package                                         |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */
   
   g_user_id           PLS_INTEGER := fnd_global.user_id;
   g_resp_id           PLS_INTEGER := fnd_global.resp_id;
   g_resp_appl_id      PLS_INTEGER := fnd_global.resp_appl_id;
   g_organization_id   PLS_INTEGER := fnd_global.org_id;

   PROCEDURE check_mpn_halal_exp (errbuf OUT VARCHAR2, retcode OUT NUMBER);

   PROCEDURE send_mail_ed (p_total IN NUMBER, p_result OUT VARCHAR2);

   PROCEDURE send_mail_m3 (p_total IN NUMBER, p_result OUT VARCHAR2);

   CURSOR mpn_3m_cur
   IS
      SELECT DISTINCT
             mcb.segment3 kn_lob,
             msi.attribute2 item_template,
             msi.item_type,
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
             mtl_categories_b_kfv mcb
       WHERE     mmp.manufacturer_id = mm.manufacturer_id
             AND mmp.inventory_item_id = msi.inventory_item_id
             AND mmp.organization_id = msi.organization_id
             AND aps.vendor_id = apss.vendor_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_id = mm.attribute12
             AND apss.vendor_site_id = mm.attribute13
             AND mmp.attribute10 IS NOT NULL
             AND msi.attribute2 IS NOT NULL
             AND mp.organization_id = mmp.organization_id
             AND mic.inventory_item_id = mmp.inventory_item_id
             AND mic.organization_id = mmp.organization_id
             AND mcb.category_id = mic.category_id
             AND category_set_id = '1100000042'
             AND msi.item_type in ('FINISHED GOODS') --'PACKAGING MATERIAL',
             AND TRUNC (TO_DATE (mmp.attribute10, 'yyyy/mm/dd hh24:mi:ss')) BETWEEN TRUNC (SYSDATE+8)
                                                                                AND TRUNC (ADD_MONTHS (SYSDATE+8, 3));

   CURSOR mpn_ed_cur
   IS
      SELECT DISTINCT
             mcb.segment3 kn_lob,
             msi.attribute2 item_template,
             msi.item_type,
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
             (SELECT MAX (first_notification_date)
                FROM xxshp_mpn_halal_exp_stag
               WHERE     item_code = mmp.mfg_part_num
                     AND sertf_halal_number = mmp.attribute9)
                first_notification_date,
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
             mtl_categories_b_kfv mcb
       WHERE     mmp.manufacturer_id = mm.manufacturer_id
             AND mmp.inventory_item_id = msi.inventory_item_id
             AND mmp.organization_id = msi.organization_id
             AND aps.vendor_id = apss.vendor_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_site_id = pasl.vendor_site_id
             AND apss.vendor_id = mm.attribute12
             AND apss.vendor_site_id = mm.attribute13
             AND mmp.attribute10 IS NOT NULL
             AND msi.attribute2 IS NOT NULL
             AND mp.organization_id = mmp.organization_id
             AND mic.inventory_item_id = mmp.inventory_item_id
             AND mic.organization_id = mmp.organization_id
             AND mcb.category_id = mic.category_id
             AND category_set_id = '1100000042'
             AND msi.inventory_item_status_code <> 'Phase Out'
             AND msi.item_type in ('FINISHED GOODS') --'PACKAGING MATERIAL',
             AND (TRUNC (TO_DATE (mmp.attribute10, 'yyyy/mm/dd hh24:mi:ss')) BETWEEN TRUNC (SYSDATE)
                                                                                AND TRUNC (SYSDATE + 7)
             OR TRUNC (TO_DATE (mmp.attribute10, 'yyyy/mm/dd hh24:mi:ss')) <= TRUNC(SYSDATE));

   CURSOR mail_ed_cur
   IS
        SELECT DISTINCT kn,
                        item_code,
                        item_desc,
                        uom,
                        organization_code,
                        supplier_name,
                        part,
                        sertf_halal_number,
                        halal_expiry_date,
                        TRUNC(first_notification_date) first_notification_date,
                        TRUNC (phase_out) phase_out,
                        type_email,
                        halal_body,
                        manufacturer_name,
                        mfg_part_num,
                        item_template,
                        error_message,
                        item_type
          FROM xxshp_mpn_halal_exp_stag
         WHERE TRUNC (creation_date) = TRUNC (SYSDATE) AND type_email = 'Phase Out'
      ORDER BY item_code;

   CURSOR mail_3m_cur
   IS
        SELECT DISTINCT kn,
                        item_code,
                        item_desc,
                        uom,
                        organization_code,
                        supplier_name,
                        part,
                        sertf_halal_number,
                        halal_expiry_date,
                        TRUNC(first_notification_date) first_notification_date,
                        TRUNC (phase_out) phase_out,
                        type_email,
                        halal_body,
                        manufacturer_name,
                        mfg_part_num,
                        item_template,
                        item_type
          FROM xxshp_mpn_halal_exp_stag
         WHERE TRUNC (creation_date) = TRUNC (SYSDATE) AND type_email = 'M-3'
      ORDER BY item_code;


   CURSOR chg_stts_cur
   IS
      SELECT DISTINCT msi.inventory_item_id, mp.organization_id, data_id
        FROM xxshp_mpn_halal_exp_stag het,
             mtl_parameters mp,
             mtl_system_items msi
       WHERE     1 = 1
             AND het.organization_code = mp.organization_code
             AND het.item_code = msi.segment1
             AND msi.organization_id = 84
             AND TRUNC (het.creation_date) = TRUNC (SYSDATE)
             AND TRUNC (het.phase_out) = TRUNC (SYSDATE);
END XXSHP_MPN_HALAL_EXP_NOTIFY;
/
