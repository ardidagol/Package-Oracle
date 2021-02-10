CREATE OR REPLACE PACKAGE APPS.XXGVN_MISSASSIGN_ITEM_MAIL_PKG
AS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2019  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXGVN_MISSASSIGN_ITEM_MAIL_PKG.pks                                                    |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Untuk merubah status item menjadi phase out                                           |
   REM |     History     : 20 Des 2019 --Ardianto--  create this package                                         |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */

   g_user_id           PLS_INTEGER := fnd_global.user_id;
   g_resp_id           PLS_INTEGER := fnd_global.resp_id;
   g_resp_appl_id      PLS_INTEGER := fnd_global.resp_appl_id;
   g_organization_id   PLS_INTEGER := fnd_global.org_id;

   PROCEDURE send_mail (p_total IN NUMBER, p_result OUT VARCHAR2);

   PROCEDURE send_mail1(p_result OUT VARCHAR2);

   PROCEDURE proses_email (errbuf    OUT VARCHAR2,
                           retcode    OUT NUMBER);

   CURSOR source_data_cur
   IS
        SELECT *
          FROM (SELECT msi.segment1 item_code,
                       msi.description,
                       'Not Assigned as GVN Organization Item' Remarks
                  FROM mtl_system_items msi
                 WHERE     1 = 1
                       AND msi.organization_id = 83
                       AND msi.inventory_item_status_code = 'Active'
                       AND msi.item_type IN ('PREMIX COMPILE',
                                             'PACKAGING MATERIAL',
                                             'RAW MATERIAL',
                                             'MATERIAL GRAMATION',
                                             'PREMIX MIX')
                       AND msi.inventory_item_id NOT IN (SELECT inventory_item_id
                                                           FROM mtl_system_items
                                                          WHERE organization_id =
                                                                   84)
                UNION ALL
                SELECT msi.segment1 item_code,
                       msi.description,
                       'Not Assigned to GVN SubInventories' Remarks
                  FROM mtl_system_items msi
                 WHERE     1 = 1
                       AND msi.organization_id = 84
                       AND msi.inventory_item_status_code = 'Active'
                       AND msi.item_type IN ('PREMIX COMPILE',
                                             'PACKAGING MATERIAL',
                                             'RAW MATERIAL',
                                             'MATERIAL GRAMATION',
                                             'PREMIX MIX')
                       AND msi.inventory_item_id NOT IN (SELECT inventory_item_id
                                                           FROM MTL_ITEM_SUB_INVENTORIES_ALL_V))
      ORDER BY 3;
END XXGVN_MISSASSIGN_ITEM_MAIL_PKG;
/
