CREATE OR REPLACE PACKAGE APPS.XXSHP_PHYSICAL_INV_TAGS_PKG
AS
   /*
      REM +=========================================================================================================+
      REM |                                    Copyright (C) 2019  KNITERS                                          |
      REM |                                        All rights Reserved                                              |
      REM +=========================================================================================================+
      REM |                                                                                                         |
      REM |     Program Name: XXSHP_PHYSICAL_INV_TAGS_PKG.pks                                                       |
      REM |     Parameters  :                                                                                       |
      REM |     Description : Untuk merubah status item menjadi phase out                                           |
      REM |     History     : 21 Des 2019 --Ardianto--  create this package                                         |
      REM |     Proposed    :                                                                                       |
      REM |     Updated     :                                                                                       |
      REM +---------------------------------------------------------------------------------------------------------+
      */

   g_user_id             PLS_INTEGER := fnd_global.user_id;
   g_resp_id             PLS_INTEGER := fnd_global.resp_id;
   g_resp_appl_id        PLS_INTEGER := fnd_global.resp_appl_id;
   g_organization_id     PLS_INTEGER := fnd_global.org_id;
   g_login_id            PLS_INTEGER := fnd_global.login_id;

   g_neg_inv_rcpt_code   NUMBER;

   CURSOR inv_tags_cur (p_inventory_name VARCHAR2)
   IS
        SELECT mpi.physical_inventory_id,
               mpit.tag_number,
               mpit.void_flag,
               mpit.adjustment_id,
               mpit.inventory_item_id,
               msi.segment1 item_code,
               mpit.item_description,
               mpit.tag_id,
               msi.description,
               mpa.system_quantity,
               mpa.ADJUSTMENT_QUANTITY,
               mpa.count_quantity,
               mpa.actual_cost,
               mpit.revision_qty_control_code,
               mpit.lot_control_code,
               mpit.serial_number_control_code,
               mpit.location_control_code,
               mpit.tag_quantity,
               mpit.tag_uom,
               mpit.tag_quantity_at_standard_uom,
               mpit.standard_uom,
               mpit.subinventory,
               mpit.locator_id,
               mpit.lot_number,
               mpit.revision,
               mpit.serial_num,
               mpit.counted_by_employee_id,
               mpit.LAST_UPDATE_DATE,
               mpit.LAST_UPDATED_BY,
               mpit.CREATION_DATE,
               mpit.CREATED_BY,
               mpit.LAST_UPDATE_LOGIN,
               mpit.ATTRIBUTE_CATEGORY,
               mpit.ATTRIBUTE1,
               mpit.ATTRIBUTE2,
               mpit.ATTRIBUTE3,
               mpit.ATTRIBUTE4,
               mpit.ATTRIBUTE5,
               mpit.ATTRIBUTE6,
               mpit.ATTRIBUTE7,
               mpit.ATTRIBUTE8,
               mpit.ATTRIBUTE9,
               mpit.ATTRIBUTE10,
               mpit.ATTRIBUTE11,
               mpit.ATTRIBUTE12,
               mpit.ATTRIBUTE13,
               mpit.ATTRIBUTE14,
               mpit.ATTRIBUTE15,
               mpit.parent_lpn_id,
               mpit.outermost_lpn_id,
               mpit.parent_lpn,
               mpit.outermost_lpn,
               mpit.container_item_id,
               mpit.container_revision,
               mpit.container_lot_number,
               mpit.container_serial_number,
               mpit.cost_group_id,
               mpit.cost_group_name,
               mpit.container_cost_group_id,
               mpit.container_cost_group_name,
               mpit.lot_expiration_date,
               mpit.tag_secondary_quantity,
               mpit.tag_secondary_uom                               -- INVCONV
                                     --, tag_qty_at_std_secondary_uom, standard_secondary_uom -- INVCONV
               ,
               mpit.organization_id
          FROM MTL_PHYSICAL_INVENTORY_TAGS_V mpit,
               MTL_PHYSICAL_INVENTORIES_V mpi,
               mtl_system_items msi,
               mtl_physical_adjustments mpa
         WHERE     1 = 1
               AND mpi.physical_inventory_id = mpit.physical_inventory_id
               AND mpi.organization_id = mpit.organization_id
               AND mpit.inventory_item_id = msi.inventory_item_id
               AND mpit.organization_id = msi.organization_id
               AND mpit.adjustment_id = mpa.adjustment_id
               AND mpa.physical_inventory_id = mpit.physical_inventory_id
               AND mpi.physical_inventory_name = p_inventory_name
               AND INSTR (msi.segment1, '.') <> 0
               AND ( (INV_MATERIAL_STATUS_GRP.is_status_applicable (
                         NULL,
                         NULL,
                         8,
                         NULL,
                         NULL,
                         mpit.organization_id,
                         mpit.inventory_item_id,
                         mpit.subinventory,
                         mpit.locator_id,
                         mpit.lot_number,
                         mpit.serial_num,
                         'A') = 'Y'))
      ORDER BY mpit.tag_number;

   PROCEDURE check_for_duplicate_tag (errbuff         OUT VARCHAR2,
                                      retcode         OUT NUMBER,
                                      p_phys_inv_id       NUMBER,
                                      p_org_id            NUMBER,
                                      p_tag_number        VARCHAR2);

   PROCEDURE update_adjustment (errbuff          OUT VARCHAR2,
                                retcode          OUT NUMBER,
                                p_adj_id             NUMBER,
                                p_org_id             NUMBER,
                                p_phys_inv_id        NUMBER,
                                p_inv_item_id        NUMBER,
                                p_subinventory       VARCHAR2,
                                p_revision           VARCHAR2,
                                p_locator_id         NUMBER,
                                p_lot_number         VARCHAR2);

   PROCEDURE check_adjustment (errbuff                     OUT VARCHAR2,
                               retcode                     OUT NUMBER,
                               x_adjustment_id             OUT NUMBER,
                               p_phys_inv_id                   NUMBER,
                               p_org_id                        NUMBER,
                               p_serial_num_control_code       NUMBER,
                               p_tag_number                    VARCHAR2,
                               p_inv_item_id                   NUMBER,
                               p_serial_num                    VARCHAR2,
                               p_locator_id                    NUMBER,
                               p_parent_lpn_id                 NUMBER,
                               p_tag_id                        NUMBER,
                               p_lot_exp_date                  DATE);

   PROCEDURE find_existing_adjustment (errbuff                 OUT VARCHAR2,
                                       retcode                 OUT NUMBER,
                                       x_adjustment_id         OUT NUMBER,
                                       p_phys_inv_id               NUMBER,
                                       P_inv_item_id               NUMBER,
                                       p_org_id                    NUMBER,
                                       p_tag_id                    NUMBER,
                                       p_lot_expiration_date       DATE);

   PROCEDURE delete_cc_reservation (errbuff          OUT VARCHAR2,
                                    retcode          OUT NUMBER,
                                    p_org_id             NUMBER,
                                    p_inv_item_id        NUMBER,
                                    p_subinventory       VARCHAR2,
                                    p_revision           VARCHAR2,
                                    p_locator_id         NUMBER,
                                    p_lot_number         VARCHAR2); 

   PROCEDURE check_availability (errbuff          OUT VARCHAR2,
                                 retcode          OUT NUMBER,
                                 p_adj_id             NUMBER,
                                 p_org_id             NUMBER,
                                 p_phys_inv_id        NUMBER,
                                 p_inv_item_id        NUMBER,
                                 p_subinventory       VARCHAR2,
                                 p_locator_id         NUMBER,
                                 p_lot_number         VARCHAR2,
                                 p_revision           VARCHAR2); 

   PROCEDURE create_new_tags (errbuff      OUT VARCHAR2,
                              retcode      OUT NUMBER,
                              p_inv_tags       VARCHAR2);

   PROCEDURE update_inv_tags (errbuff      OUT VARCHAR2,
                              retcode      OUT NUMBER,
                              p_inv_tags       VARCHAR2);

   PROCEDURE main_process (errbuff         OUT VARCHAR2,
                           retcode         OUT NUMBER,
                           p_inv_tags   IN     VARCHAR2);
END XXSHP_PHYSICAL_INV_TAGS_PKG;
/