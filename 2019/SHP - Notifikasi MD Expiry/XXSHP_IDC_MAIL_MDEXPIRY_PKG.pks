CREATE OR REPLACE PACKAGE APPS.XXSHP_IDC_MAIL_MDEXPIRY_PKG AS

   type array is table of varchar2(255);

   g_max_time                  PLS_INTEGER      DEFAULT 259200; --3 hari.
   g_intval_time               PLS_INTEGER      DEFAULT 4;
   
    CURSOR data_stag4m
        IS
        SELECT distinct mcb.segment3 kn_lob, msi.attribute2 item_template,
        mm.manufacturer_id, manufacturer_name part, mm.description part_desc, 
        mmp.inventory_item_id, msi.segment1 item_code, msi.description item_desc,
        mmp.organization_id, mp.organization_code, msi.primary_uom_code uom_code,
        mmp.attribute4 MD_NUM, trunc(to_date(mmp.attribute5,'yyyy/mm/dd hh24:mi:ss')) MD_VALID_TO, aps.vendor_name supplier_name
    FROM mtl_manufacturers mm,
          mtl_system_items msi,
          mtl_mfg_part_numbers mmp,
          po_approved_supplier_list pasl,
          ap_suppliers aps,
          ap_supplier_sites_all apss,
          mtl_parameters mp,
          mtl_item_categories mic, 
          mtl_categories_b_kfv mcb 
    WHERE   mmp.manufacturer_id = mm.manufacturer_id
          AND mmp.inventory_item_id = msi.inventory_item_id
          AND mmp.organization_id = msi.organization_id
          AND aps.vendor_id = apss.vendor_id
          AND apss.vendor_site_id = pasl.vendor_site_id
          and apss.vendor_site_id = pasl.vendor_site_id
          and apss.vendor_id = mm.attribute12
          and apss.vendor_site_id = mm.attribute13
          and mmp.attribute5 is not null 
          and msi.attribute2 is not null
          and mp.organization_id = mmp.organization_id
          and mic.inventory_item_id = mmp.inventory_item_id
          and mic.organization_id = mmp.organization_id
          and mcb.category_id = mic.category_id
          and category_set_id = '1100000042' 
          AND SUBSTR (mmp.attribute5, 1, 10) BETWEEN TO_CHAR (
                                                           TRUNC (
                                                              ADD_MONTHS (
                                                                 SYSDATE,
                                                                 3)),
                                                           'YYYY/MM/DD')
                                                    AND TO_CHAR (
                                                           TRUNC (
                                                              ADD_MONTHS (
                                                                 SYSDATE,
                                                                 4)),
                                                           'YYYY/MM/DD');
          
        CURSOR data_stag3m
        IS
        SELECT distinct mcb.segment3 kn_lob, msi.attribute2 item_template,
        mm.manufacturer_id, manufacturer_name part, mm.description part_desc, 
        mmp.inventory_item_id, msi.segment1 item_code, msi.description item_desc,
        mmp.organization_id, mp.organization_code, msi.primary_uom_code uom_code,
        mmp.attribute4 MD_NUM, trunc(to_date(mmp.attribute5,'yyyy/mm/dd hh24:mi:ss')) MD_VALID_TO, aps.vendor_name supplier_name,
        (SELECT max(first_notification_date) FROM xxshp_md_expiry_stag where item_code = mmp.mfg_part_num and md_number = mmp.attribute4) first_notification_date
    FROM mtl_manufacturers mm,
          mtl_system_items msi,
          mtl_mfg_part_numbers mmp,
          po_approved_supplier_list pasl,
          ap_suppliers aps,
          ap_supplier_sites_all apss,
          mtl_parameters mp,
          mtl_item_categories mic, 
          mtl_categories_b_kfv mcb 
    WHERE   mmp.manufacturer_id = mm.manufacturer_id
          AND mmp.inventory_item_id = msi.inventory_item_id
          AND mmp.organization_id = msi.organization_id
          AND aps.vendor_id = apss.vendor_id
          AND apss.vendor_site_id = pasl.vendor_site_id
          and apss.vendor_site_id = pasl.vendor_site_id
          and apss.vendor_id = mm.attribute12
          and apss.vendor_site_id = mm.attribute13
          and mmp.attribute5 is not null 
          and msi.attribute2 is not null
          and mp.organization_id = mmp.organization_id
          and mic.inventory_item_id = mmp.inventory_item_id
          and mic.organization_id = mmp.organization_id
          and mcb.category_id = mic.category_id
          and category_set_id = '1100000042' 
          --Ardi 23042019
          and msi.inventory_item_status_code <> 'Phase Out'
          --AND mmp.attribute4 NOT IN (SELECT md_number
          --                                FROM xxshp_md_expiry_stag
          --                               WHERE phase_out IS NOT NULL)
          --Ardi 23042019
             AND SUBSTR (mmp.attribute5, 1, 10) <=
                    TO_CHAR (TRUNC (ADD_MONTHS (SYSDATE, 3)), 'YYYY/MM/DD');

           
          CURSOR data_change_status
        IS
select distinct msi.inventory_item_id, mp.organization_id
          from xxshp_md_expiry_stag xmes, mtl_parameters mp, mtl_system_items msi
          where 1=1
          and xmes.io = mp.organization_code
          and xmes.item_code = msi.segment1
          and msi.organization_id = 85
          and trunc(xmes.creation_date) = trunc(sysdate)
          and trunc(xmes.phase_out) = trunc(sysdate);
          
   PROCEDURE INITIALIZE(
                            p_user_id      in number,
                            p_resp_id      in number,
                            p_resp_app_id  in number
                        );
   
   
   PROCEDURE checking_md_expiry_stag(
                                        errbuf OUT VARCHAR2, retcode OUT NUMBER
                                    );

procedure process_recipients(p_mail_conn IN OUT UTL_SMTP.connection,p_list IN VARCHAR2);

procedure send_mail_fg_4m;

procedure send_mail_fg_3m;

procedure change_status(v_inventory_item_id NUMBER, v_organization_id NUMBER);
END;
/
