CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_PHYSICAL_INV_TAGS_PKG
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

   PROCEDURE logf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   FUNCTION gen_instance_name
      RETURN VARCHAR2
   IS
      v_inst   v$instance.instance_name%TYPE;
   BEGIN
      SELECT instance_name INTO v_inst FROM v$instance;

      RETURN v_inst;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END gen_instance_name;



   PROCEDURE get_item_attributes (
      p_inv_item_id                    IN     NUMBER,
      p_organization_id                IN     NUMBER,
      x_tracking_quantity_ind             OUT VARCHAR2,
      x_secondary_default_ind             OUT VARCHAR2,
      x_secondary_uom_code                OUT VARCHAR2,
      x_process_costing_enabled_flag      OUT VARCHAR2,
      x_process_enabled_flag              OUT VARCHAR2)
   IS
   BEGIN
      -- tracking_quantity_ind (P-Primary, PS-Primary and Secondary)
      -- secondary_default_ind (F-Fixed, D-Default, N-No Default)
      SELECT msi.tracking_quantity_ind,
             msi.secondary_default_ind,
             msi.secondary_uom_code,
             msi.process_costing_enabled_flag,
             mtp.process_enabled_flag
        INTO x_tracking_quantity_ind,
             x_secondary_default_ind,
             x_secondary_uom_code,
             x_process_costing_enabled_flag,
             x_process_enabled_flag
        FROM mtl_system_items msi, mtl_parameters mtp
       WHERE     mtp.organization_id = p_organization_id
             AND msi.organization_id = mtp.organization_id
             AND msi.inventory_item_id = p_inv_item_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error while run procedure get_item_attributes ' || SQLERRM);
   END get_item_attributes;

   PROCEDURE check_for_duplicate_tag (errbuff         OUT VARCHAR2,
                                      retcode         OUT NUMBER,
                                      p_phys_inv_id       NUMBER,
                                      p_org_id            NUMBER,
                                      p_tag_number        VARCHAR2)
   IS
      v_count   NUMBER := 0;
   BEGIN
      SELECT COUNT (*)
        INTO v_count
        FROM MTL_PHYSICAL_INVENTORY_TAGS
       WHERE     PHYSICAL_INVENTORY_ID = p_phys_inv_id
             AND ORGANIZATION_ID = p_org_id
             AND TAG_NUMBER = p_tag_number;

      IF (v_count >= 1)
      THEN
         retcode := 2;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF (SQL%NOTFOUND)
         THEN
            NULL;
         END IF;
   END check_for_duplicate_tag;

   PROCEDURE find_existing_adjustment (errbuff                 OUT VARCHAR2,
                                       retcode                 OUT NUMBER,
                                       x_adjustment_id         OUT NUMBER,
                                       p_phys_inv_id               NUMBER,
                                       P_inv_item_id               NUMBER,
                                       p_org_id                    NUMBER,
                                       p_tag_id                    NUMBER,
                                       p_lot_expiration_date       DATE)
   IS
      v_adj_id                    NUMBER := -1;
      v_org_id                    NUMBER := p_org_id;
      v_phys_inv_id               NUMBER;
      v_tag_id                    NUMBER;
      v_inv_item_id               NUMBER := P_inv_item_id;
      v_subinv                    VARCHAR2 (10);
      v_revision                  VARCHAR2 (3);
      v_rev_qty_control_code      NUMBER;
      v_org_locator_type          NUMBER;
      v_sub_locator_type          NUMBER;
      v_location_control_code     NUMBER;
      v_locator_id                NUMBER;
      v_cost_group_id             NUMBER;
      v_parent_lpn_id             NUMBER;
      v_outermost_lpn_id          NUMBER;
      v_lot_control_code          NUMBER;
      v_lot_number                VARCHAR2 (80);
      v_serial_num                VARCHAR2 (30);
      v_serial_num_control_code   NUMBER;
      -- BEGIN INVCONV
      v_tracking_quantity_ind     VARCHAR2 (30);
      v_process_enabled_flag      VARCHAR2 (1);
      v_result_code               VARCHAR2 (30);
      v_return_status             VARCHAR2 (30);
      v_msg_count                 NUMBER;
      v_msg_data                  VARCHAR2 (2000);
      v_transaction_date          DATE;                          --freeze_date
      v_cost_mthd                 VARCHAR2 (15);
      v_cmpntcls                  NUMBER;
      v_analysis_code             VARCHAR2 (15);
      v_no_of_rows                NUMBER;
      -- END INVCONV

      v_actual_cost               NUMBER;
      v_last_updated_by           NUMBER := g_user_id;
      v_last_update_login         NUMBER := g_login_id;
      v_created_by                NUMBER := g_user_id;
      v_lot_expiration_date       DATE;              -- changes for bug2672616
      v_approval_status           NUMBER;
      l_mpa_cnt                   NUMBER := 0;      -- Added for bug # 5457537
   BEGIN
      BEGIN
           SELECT mpi.physical_inventory_id,
                  mpit.tag_id,
                  mpit.subinventory,
                  mpit.revision,
                  mpit.revision_qty_control_code,
                  mpit.locator_id,
                  mpit.cost_group_id,
                  mpit.parent_lpn_id,
                  mpit.outermost_lpn_id,
                  mpit.lot_control_code,
                  mpit.lot_number,
                  mpit.serial_num,
                  mpit.serial_number_control_code,
                  mpi.freeze_date
             INTO v_phys_inv_id,
                  v_tag_id,
                  v_subinv,
                  v_revision,
                  v_rev_qty_control_code,
                  v_locator_id,
                  v_cost_group_id,
                  v_parent_lpn_id,
                  v_outermost_lpn_id,
                  v_lot_control_code,
                  v_lot_number,
                  v_serial_num,
                  v_serial_num_control_code,
                  v_transaction_date
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
                  AND mpi.physical_inventory_id = p_phys_inv_id
                  AND INSTR (msi.segment1, '.') <> 0
                  AND msi.organization_id = p_org_id
                  AND mpit.tag_id = p_tag_id
         ORDER BY mpit.tag_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error get data procedure existing adjusment' || SQLERRM);
      END;

      logf ('Get sub locator type');

      BEGIN
           SELECT locator_type
             INTO v_sub_locator_type
             FROM mtl_physical_subinventories_v
            WHERE     organization_id = p_org_id
                  AND physical_inventory_id = p_phys_inv_id
                  AND INV_MATERIAL_STATUS_GRP.sub_valid_for_item (
                         p_org_id,
                         v_inv_item_id,
                         v_subinv) = 'Y'
                  AND (INV_MATERIAL_STATUS_GRP.is_status_applicable (NULL,
                                                                     NULL,
                                                                     8,
                                                                     NULL,
                                                                     NULL,
                                                                     p_org_id,
                                                                     NULL,
                                                                     v_subinv,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     'Z') = 'Y')
         ORDER BY subinventory, description;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error geting v_sub_locator_type ' || SQLERRM);
      END;

      logf ('Sub Locator Type : ' || v_sub_locator_type);
      logf ('Get org locator type');

      BEGIN
         SELECT STOCK_LOCATOR_CONTROL_CODE
           INTO v_org_locator_type
           FROM mtl_parameters
          WHERE organization_id = p_org_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error when get v_org_locator_type ' || SQLERRM);
      END;

      logf ('Sub Org Locator Type : ' || v_org_locator_type);
      logf ('Get lot Expiration Date');

      BEGIN
           SELECT expiration_date
             INTO v_lot_expiration_date
             FROM mtl_lot_numbers_all_v
            WHERE     inventory_item_id = v_inv_item_id
                  AND organization_id = p_org_id
         ORDER BY lot_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_lot_expiration_date := p_lot_expiration_date;
            logf ('v_lot_expiration_date : ' || v_lot_expiration_date);
      END;


      logf ('Get cost group id');

      IF (v_cost_group_id IS NULL AND v_subinv IS NOT NULL)
      THEN
         IF (v_parent_lpn_id IS NOT NULL)
         THEN                                       -- Added to get Cost Group
            inv_cyc_lovs.get_cost_group_id (
               p_organization_id     => v_org_id,
               p_subinventory        => v_subinv,
               p_locator_id          => v_locator_id,
               p_parent_lpn_id       => v_parent_lpn_id,
               p_inventory_item_id   => v_inv_item_id,
               p_revision            => v_revision,
               p_lot_number          => v_lot_number,
               p_serial_number       => v_serial_num,
               x_out                 => v_cost_group_id);
         END IF;

         logf ('Cost group id ' || v_cost_group_id);

         IF (v_cost_group_id IS NULL OR v_cost_group_id = -999)
         THEN
            SELECT default_cost_group_id
              INTO v_cost_group_id
              FROM mtl_secondary_inventories
             WHERE     organization_id = v_org_id
                   AND secondary_inventory_name = v_subinv;

            logf ('Cost group id ' || v_cost_group_id);
         END IF;
      END IF;

      --Added for Bug 2119423

      /*
      --*  DEBUG  *--
      logf (' ');
      logf ('---------------------------------------');
      logf ('v_rev_qty_control_code : ' || v_rev_qty_control_code);
      logf ('v_parent_lpn_id : ' || v_parent_lpn_id);
      logf ('v_cost_group_id : ' || v_cost_group_id);
      logf ('v_locator_id : ' || v_locator_id);
      logf ('v_org_locator_type : ' || v_org_locator_type);
      logf ('v_sub_locator_type : ' || v_sub_locator_type);
      logf ('v_location_control_code : ' || v_location_control_code);
      logf ('v_lot_control_code : ' || v_lot_control_code);
      logf ('v_serial_num : ' || v_serial_num);
      logf ('v_lot_number : ' || v_lot_number);
      logf ('v_serial_num_control_code : ' || v_serial_num_control_code);
      logf ('---------------------------------------');
      logf (' ');
      */

      logf ('Get adjusment id');

        SELECT MIN (ADJUSTMENT_ID)
          INTO v_adj_id
          FROM MTL_PHYSICAL_ADJUSTMENTS
         WHERE     ORGANIZATION_ID = v_org_id
               AND PHYSICAL_INVENTORY_ID = v_phys_inv_id
               AND INVENTORY_ITEM_ID = v_inv_item_id
               AND SUBINVENTORY_NAME = v_subinv
               AND (   NVL (REVISION, 'ZZZZ') = NVL (v_revision, 'ZZZZ')
                    OR v_rev_qty_control_code = 1)
               AND NVL (parent_lpn_id, -10) = NVL (v_parent_lpn_id, -10)
               AND NVL (cost_group_id, -10) = NVL (v_cost_group_id, -10)
               AND (   NVL (LOCATOR_ID, -10) = NVL (v_locator_id, -10)
                    OR v_org_locator_type = 1
                    OR (    v_org_locator_type = 4
                        AND (   v_sub_locator_type = 1
                             OR (    v_sub_locator_type = 5
                                 AND v_location_control_code = 1)))
                    OR (    v_location_control_code = 5
                        AND v_location_control_code = 1))
               AND (   NVL (LOT_NUMBER, 'ZZZZZZZZZZZ') =
                          NVL (v_lot_number, 'ZZZZZZZZZZZ')
                    OR v_lot_control_code = 1)
               AND (   NVL (SERIAL_NUMBER, 'ZZZZZZZZZZZ') =
                          NVL (v_serial_num, 'ZZZZZZZZZZZ')
                    OR v_serial_num_control_code = 1)
      GROUP BY ORGANIZATION_ID,
               PHYSICAL_INVENTORY_ID,
               INVENTORY_ITEM_ID,
               SUBINVENTORY_NAME,
               REVISION,
               LOCATOR_ID,
               PARENT_LPN_ID,
               COST_GROUP_ID,
               LOT_NUMBER,
               SERIAL_NUMBER;

      /* if the corresponding adjustment is posted, not allowing the user to enter a dynamic tag*/
      IF v_adj_id IS NOT NULL
      THEN
         SELECT approval_status
           INTO v_approval_status
           FROM mtl_physical_adjustments
          WHERE     adjustment_id = v_adj_id
                AND physical_inventory_id = v_phys_inv_id;

         IF (NVL (v_approval_status, 0) = 3)
         THEN
            logf ('INV' || 'INV_PHYSICAL_ADJ_POSTED');
            logf ('TOKEN1' || v_adj_id);
            retcode := 2;
         END IF;
      END IF;

      x_adjustment_id := v_adj_id;
      logf ('Adjusment_id ' || v_adj_id);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         -- insert new adjustment row
         -- For standard costed orgs, get the item cost with the common
         -- cost group ID = 1.  For average costed orgs, use the org's
         -- default cost group ID.
         -- All primary costing methods not equal to 1 should
         -- also be considered as an average costed org

         -- BEGIN INVCONV
         logf ('Insert to table Adjusment');
         v_process_enabled_flag := 'Y';
         v_adj_id := NULL;

         logf ('Get actual cost');

         IF v_process_enabled_flag = 'Y'
         THEN
            logf ('Get Process Item Cost');
            logf ('---------------------');

            v_result_code :=
               GMF_CMCOMMON.Get_Process_Item_Cost (
                  p_api_version               => 1,
                  p_init_msg_list             => 'F',
                  x_return_status             => v_return_status,
                  x_msg_count                 => v_msg_count,
                  x_msg_data                  => v_msg_data,
                  p_inventory_item_id         => v_inv_item_id,
                  p_organization_id           => v_org_id,
                  p_transaction_date          => v_transaction_date, /* Cost as on date */
                  p_detail_flag               => 1, /*  1 = total cost, 2 = details; 3 = cost for a specific component class/analysis code, etc. */
                  p_cost_method               => v_cost_mthd, /* OPM Cost Method */
                  p_cost_component_class_id   => v_cmpntcls,
                  p_cost_analysis_code        => v_analysis_code,
                  x_total_cost                => v_actual_cost, /* total cost */
                  x_no_of_rows                => v_no_of_rows /* number of detail rows retrieved */
                                                             );

            logf ('---------------------');
            logf ('');
         ELSE
            -- END INVCONV
            logf ('Get Process Item Cost1');
            logf ('---------------------');

            BEGIN
               SELECT NVL (ccicv.item_cost, 0)
                 INTO v_actual_cost
                 FROM cst_cg_item_costs_view ccicv, mtl_parameters mp
                WHERE     v_locator_id IS NULL
                      AND ccicv.organization_id = v_org_id
                      AND ccicv.inventory_item_id = v_inv_item_id
                      AND ccicv.organization_id = mp.organization_id
                      AND ccicv.cost_group_id =
                             DECODE (mp.primary_cost_method,
                                     1, 1,
                                     NVL (mp.default_cost_group_id, 1))
               UNION ALL
               SELECT NVL (ccicv.item_cost, 0)
                 FROM mtl_item_locations mil,
                      cst_cg_item_costs_view ccicv,
                      mtl_parameters mp
                WHERE     v_locator_id IS NOT NULL
                      AND mil.organization_id = v_org_id
                      AND mil.inventory_location_id = v_locator_id
                      AND mil.project_id IS NULL
                      AND ccicv.organization_id = mil.organization_id
                      AND ccicv.inventory_item_id = v_inv_item_id
                      AND ccicv.organization_id = mp.organization_id
                      AND ccicv.cost_group_id =
                             DECODE (mp.primary_cost_method,
                                     1, 1,
                                     NVL (mp.default_cost_group_id, 1))
               UNION ALL
               SELECT NVL (ccicv.item_cost, 0)
                 FROM mtl_item_locations mil,
                      mrp_project_parameters mrp,
                      cst_cg_item_costs_view ccicv,
                      mtl_parameters mp
                WHERE     v_locator_id IS NOT NULL
                      AND mil.organization_id = v_org_id
                      AND mil.inventory_location_id = v_locator_id
                      AND mil.project_id IS NOT NULL
                      AND mrp.organization_id = mil.organization_id
                      AND mrp.project_id = mil.project_id
                      AND ccicv.organization_id = mil.organization_id
                      AND ccicv.inventory_item_id = v_inv_item_id
                      AND ccicv.organization_id = mp.organization_id
                      AND ccicv.cost_group_id =
                             DECODE (mp.primary_cost_method,
                                     1, 1,
                                     NVL (mrp.costing_group_id, 1));

               logf ('---------------------');
               logf ('');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_actual_cost := 0;
            END;
         END IF;

         -- INVCONV

         -- Adding exception handling for the insert
         --logf ('Adjusmment Id : ' || v_adj_id);
         logf ('Physical Inventory Id : ' || v_phys_inv_id);

         --logf ('v_actual_cost : ' || v_actual_cost);

         BEGIN
            IF v_adj_id IS NULL
            THEN
               SELECT mtl_physical_adjustments_s.NEXTVAL
                 INTO v_adj_id
                 FROM DUAL;
            ELSE
               v_adj_id := v_adj_id;
            END IF;

            x_adjustment_id := v_adj_id;

            --logf ('Adjustment id : ' || x_adjustment_id);

            INSERT INTO mtl_physical_adjustments (adjustment_id,
                                                  organization_id,
                                                  physical_inventory_ID,
                                                  INVENTORY_ITEM_ID,
                                                  SUBINVENTORY_NAME,
                                                  SYSTEM_QUANTITY,
                                                  LAST_UPDATE_DATE,
                                                  LAST_UPDATED_BY,
                                                  CREATION_DATE,
                                                  CREATED_BY,
                                                  LAST_UPDATE_LOGIN,
                                                  COUNT_QUANTITY,
                                                  ADJUSTMENT_QUANTITY,
                                                  REVISION,
                                                  LOCATOR_ID,
                                                  PARENT_LPN_ID,
                                                  OUTERMOST_LPN_ID,
                                                  COST_GROUP_ID,
                                                  LOT_NUMBER,
                                                  LOT_EXPIRATION_DATE,
                                                  SERIAL_NUMBER,
                                                  ACTUAL_COST)
                 VALUES (v_adj_id,
                         v_org_id,
                         v_phys_inv_id,
                         v_inv_item_id,
                         v_subinv,
                         0,
                         SYSDATE,
                         NVL (v_created_by, -1),
                         SYSDATE,
                         NVL (v_last_updated_by, -1),
                         NVL (v_last_update_login, -1),
                         0,
                         0,
                         v_revision,
                         v_locator_id,
                         v_parent_lpn_id,
                         v_outermost_lpn_id,
                         v_cost_group_id,
                         v_lot_number,
                         v_lot_expiration_date,
                         v_serial_num,
                         v_actual_cost);
         EXCEPTION
            WHEN OTHERS
            THEN
               logf (SQLERRM);
               retcode := 2;
         END;

         --Re-checking whether record got inserted correctly or not
         SELECT COUNT (1)
           INTO l_mpa_cnt
           FROM mtl_physical_adjustments
          WHERE     adjustment_id = v_adj_id
                AND physical_inventory_id = v_phys_inv_id
                AND organization_id = v_org_id;

         IF (l_mpa_cnt < 1)
         THEN
            logf ('No MPA Record found for the adjustment_id ' || v_adj_id);
            logf (SQLERRM);
            retcode := 2;
         END IF;
   END find_existing_adjustment;

   PROCEDURE update_adjustment (errbuff          OUT VARCHAR2,
                                retcode          OUT NUMBER,
                                p_adj_id             NUMBER,
                                p_org_id             NUMBER,
                                p_phys_inv_id        NUMBER,
                                p_inv_item_id        NUMBER,
                                p_subinventory       VARCHAR2,
                                p_revision           VARCHAR2,
                                p_locator_id         NUMBER,
                                p_lot_number         VARCHAR2)
   IS
      v_adj_id                         NUMBER := p_adj_id;
      v_org_id                         NUMBER := p_org_id;
      v_phys_inv_id                    NUMBER := p_phys_inv_id;
      v_adj_count_quantity             NUMBER;
      v_last_updated_by                NUMBER := g_user_id;
      -- BEGIN INVCONV
      v_adj_secondary_count_quantity   NUMBER;
      l_tracking_quantity_ind          VARCHAR2 (30) := NULL;
      -- END INVCONV

      l_secondary_default_ind          VARCHAR2 (30) := NULL;
      l_secondary_uom_code             VARCHAR2 (30) := NULL;
      l_process_costing_enabled_flag   VARCHAR2 (30) := NULL;

      l_approval_required              NUMBER;
      l_approval_tolerance_pos         NUMBER;
      l_approval_tolerance_neg         NUMBER;
      l_cost_variance_pos              NUMBER;
      l_cost_variance_neg              NUMBER;
      l_count                          NUMBER;
      l_adjustment_quantity            NUMBER;
      l_old_adjustment_quantity        NUMBER;

      v_inv_id                         NUMBER := p_inv_item_id;
      v_locator_id                     NUMBER := p_locator_id;
      l_actual_cost                    NUMBER;
      l_process_enabled_flag           mtl_parameters.process_enabled_flag%TYPE;
   BEGIN
      SELECT NVL (SUM (tag_quantity_at_standard_uom), 0),
             NVL (SUM (tag_secondary_quantity), 0)
        INTO v_adj_count_quantity, v_adj_secondary_count_quantity   -- INVCONV
        FROM mtl_physical_inventory_tags
       WHERE     adjustment_id = v_adj_id
             AND organization_id = v_org_id
             AND physical_inventory_id = v_phys_inv_id
             AND void_flag = 2;

      /*    INVADPT1.update_adjustments(    v_org_id,
                          v_phys_inv_id,
                          v_adj_id,
                          v_last_updated_by,
                          v_adj_count_quantity);
      */


      SELECT NVL (process_enabled_flag, 'N')
        INTO l_process_enabled_flag
        FROM mtl_parameters
       WHERE organization_id = v_org_id;

      IF (l_process_enabled_flag = 'Y')
      THEN
         l_actual_cost :=
            gmf_cmcommon.process_item_unit_cost (v_inv_id, v_org_id, SYSDATE);
      ELSE
         INV_UTILITIES.GET_ITEM_COST (v_org_id       => v_org_id,
                                      v_item_id      => v_inv_id,
                                      v_locator_id   => v_locator_id,
                                      v_item_cost    => l_actual_cost);

         IF (l_actual_cost = -999)
         THEN
            l_actual_cost := 0;
         END IF;
      END IF;

      /* Get Item Attributes starts here */
      XXSHP_PHYSICAL_INV_TAGS_PKG.get_item_attributes (
         p_inv_item_id                    => p_inv_item_id,
         p_organization_id                => p_org_id,
         x_tracking_quantity_ind          => l_tracking_quantity_ind,
         x_secondary_default_ind          => l_secondary_default_ind,
         x_secondary_uom_code             => l_secondary_uom_code,
         x_process_costing_enabled_flag   => l_process_costing_enabled_flag,
         x_process_enabled_flag           => l_process_enabled_flag);

      /*
      --*  DEBUG  *--
      logf (' ');
      logf ('-------------------------------------------------------');
      logf ('l_tracking_quantity_ind : ' || l_tracking_quantity_ind);
      logf ('l_secondary_default_ind : ' || l_secondary_default_ind);
      logf ('l_secondary_uom_code : ' || l_secondary_uom_code);
      logf (
            'l_process_costing_enabled_flag : '
         || l_process_costing_enabled_flag);
      logf ('l_process_enabled_flag : ' || l_process_enabled_flag);
      logf ('-------------------------------------------------------');
      logf (' ');
      */

      UPDATE mtl_physical_adjustments
         SET last_update_date = SYSDATE,
             last_updated_by = NVL (last_updated_by, -1),
             count_quantity = v_adj_count_quantity,
             adjustment_quantity =
                  NVL (v_adj_count_quantity, NVL (system_quantity, 0))
                - NVL (system_quantity, 0),
             -- BEGIN INVCONV
             secondary_count_qty =
                DECODE (l_tracking_quantity_ind,
                        'PS', v_adj_secondary_count_quantity,
                        NULL),
             secondary_adjustment_qty =
                DECODE (
                   l_tracking_quantity_ind,
                   'PS',   NVL (v_adj_secondary_count_quantity,
                                NVL (secondary_system_qty, 0))
                         - NVL (secondary_system_qty, 0),
                   NULL),
             -- END INVCONV
             approval_status = NULL,
             approved_by_employee_id = NULL,
             actual_cost = l_actual_cost
       WHERE     adjustment_id = v_adj_id
             AND physical_inventory_id = v_phys_inv_id
             AND organization_id = v_org_id;

      SELECT approval_required,
             approval_tolerance_pos,
             approval_tolerance_neg,
             cost_variance_pos,
             cost_variance_neg
        INTO l_approval_required,
             l_approval_tolerance_pos,
             l_approval_tolerance_neg,
             l_cost_variance_pos,
             l_cost_variance_neg
        FROM mtl_physical_inventories
       WHERE physical_inventory_id = v_phys_inv_id;

      -- Query to check whether this adjustment requires approval or not
      SELECT COUNT (*)
        INTO l_count
        FROM mtl_physical_adjustments
       WHERE     adjustment_id = v_adj_id
             AND physical_inventory_id = v_phys_inv_id
             AND organization_id = v_org_id
             AND adjustment_quantity <> 0
             AND (   l_approval_required = 2
                  OR (    l_approval_required = 3
                      AND (    ABS (
                                  DECODE (
                                     system_quantity,
                                     0, NULL,
                                       adjustment_quantity
                                     * 100
                                     / system_quantity)) <=
                                  DECODE (SIGN (adjustment_quantity),
                                          -1, l_approval_tolerance_neg,
                                          l_approval_tolerance_pos)
                           AND ABS (actual_cost * adjustment_quantity) <=
                                  DECODE (SIGN (adjustment_quantity),
                                          -1, l_cost_variance_neg,
                                          l_cost_variance_pos))));

      -- Delete Cycle count reservations and check availability only if the adjustment
      -- does not require approval i.e. l_count > 0. Otherwise this will be done at the
      -- time of approving the adjustment.

      IF (l_count > 0)
      THEN
         logf ('CHECK for delete cc reservation.');
         delete_cc_reservation (errbuff,
                                retcode,
                                p_org_id,
                                p_inv_item_id,
                                p_subinventory,
                                p_revision,
                                p_locator_id,
                                p_lot_number);

         logf ('CHECK for availability.');
         check_availability (errbuff,
                             retcode,
                             p_adj_id,
                             p_org_id,
                             p_phys_inv_id,
                             p_inv_item_id,
                             p_subinventory,
                             p_locator_id,
                             p_lot_number,
                             p_revision);
      END IF;
   END update_adjustment;

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
                               p_lot_exp_date                  DATE)
   IS
      v_adj_id                         NUMBER := NULL;
      v_serial_num                     VARCHAR2 (30);
      v_adj_exists                     NUMBER := -1;
      v_serial_qty                     NUMBER := 0;

      v_locator_id                     NUMBER;
      v_tag_loc_id                     NUMBER := p_locator_id;
      v_tag_lpn_id                     NUMBER := p_parent_lpn_id;

      v_tag_quantity_at_standard_uom   VARCHAR2 (50);
   BEGIN
      logf ('Run check Adjusment Procedure');

      IF (p_serial_num_control_code NOT IN (1, 6))
      THEN
         /* Changed below query added serial_number_type not equal to 4 too */
         logf ('get serial_qty and locator_id');

         SELECT SUM (tag_quantity_at_standard_uom), MIN (locator_id)
           INTO v_serial_qty, v_locator_id
           FROM mtl_physical_inventory_tags mpit
          WHERE     organization_id = p_org_id
                AND physical_inventory_id = p_phys_inv_id
                AND serial_num = p_serial_num
                AND (   EXISTS
                           (SELECT 'X'
                              FROM mtl_parameters op
                             WHERE     op.organization_id = p_org_id
                                   AND op.serial_number_type NOT IN (1, 4))
                     OR mpit.inventory_item_id = p_inv_item_id);

         IF (    NVL (v_locator_id, 0) <> NVL (v_tag_loc_id, 0)
             AND v_tag_lpn_id IS NOT NULL)
         THEN
            NULL;                                    --do not count serial qty
         ELSE
            v_serial_qty :=
                 NVL (v_serial_qty, 0)
               + NVL (TO_NUMBER (v_tag_quantity_at_standard_uom), 0);
         END IF;

         IF (v_serial_qty > 1)
         THEN
            logf ('INV' || 'INV_SERIAL_QTY_MUST_BE_1');
            retcode := 2;
         END IF;
      END IF;

      /* Load adjustment data */
      logf ('Load adjustment data');

      IF (v_adj_id IS NULL)
      THEN
         find_existing_adjustment (errbuff,
                                   retcode,
                                   x_adjustment_id,
                                   p_phys_inv_id,
                                   p_inv_item_id,
                                   p_org_id,
                                   p_tag_id,
                                   p_lot_exp_date);
      ELSE
         BEGIN
            SELECT 1
              INTO v_adj_exists
              FROM mtl_physical_adjustments
             WHERE     adjustment_id = v_adj_id
                   AND organization_id = p_org_id
                   AND physical_inventory_id = p_phys_inv_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_adj_exists := 0;
         END;


         IF (v_adj_exists != 1)
         THEN
            find_existing_adjustment (errbuff,
                                      retcode,
                                      x_adjustment_id,
                                      p_phys_inv_id,
                                      p_inv_item_id,
                                      p_org_id,
                                      p_tag_id,
                                      p_lot_exp_date);
         END IF;
      END IF;
   END check_adjustment;

   PROCEDURE delete_cc_reservation (errbuff          OUT VARCHAR2,
                                    retcode          OUT NUMBER,
                                    p_org_id             NUMBER,
                                    p_inv_item_id        NUMBER,
                                    p_subinventory       VARCHAR2,
                                    p_revision           VARCHAR2,
                                    p_locator_id         NUMBER,
                                    p_lot_number         VARCHAR2)
   IS
      l_mtl_reservation_rec   INV_RESERVATION_GLOBAL.MTL_RESERVATION_REC_TYPE
         := INV_CC_RESERVATIONS_PVT.Define_Reserv_Rec_Type;
      l_init_msg_lst          VARCHAR2 (1);
      l_error_code            NUMBER;
      l_return_status         VARCHAR2 (1);
      l_msg_count             NUMBER;
      l_msg_data              VARCHAR2 (240);
      lmsg                    VARCHAR2 (2000);
   BEGIN
      /* passing input variable */
      /* delete only cycle count reservation */
      logf ('passing input variable');
      logf ('delete only cycle count reservation');

      l_mtl_reservation_rec.demand_source_type_id := 9;
      l_mtl_reservation_rec.organization_id := p_org_id;
      l_mtl_reservation_rec.inventory_item_id := p_inv_item_id;
      l_mtl_reservation_rec.subinventory_code := p_subinventory;
      l_mtl_reservation_rec.revision := p_revision;
      l_mtl_reservation_rec.locator_id := p_locator_id;
      l_mtl_reservation_rec.lot_number := p_lot_number;
      l_mtl_reservation_rec.lpn_id := NULL;
      --
      logf ('Run API delete Reservation');
      INV_CC_RESERVATIONS_PVT.Delete_All_Reservation (
         p_api_version_number    => 1.0,
         p_init_msg_lst          => l_init_msg_lst,
         p_mtl_reservation_rec   => l_mtl_reservation_rec,
         x_error_code            => l_error_code,
         x_return_status         => l_return_status,
         x_msg_count             => l_msg_count,
         x_msg_data              => l_msg_data);

      IF l_return_status <> 'S'
      THEN
         logf (SQLERRM);
         retcode := 2;
      END IF;
   END delete_cc_reservation;


   PROCEDURE check_availability (errbuff          OUT VARCHAR2,
                                 retcode          OUT NUMBER,
                                 p_adj_id             NUMBER,
                                 p_org_id             NUMBER,
                                 p_phys_inv_id        NUMBER,
                                 p_inv_item_id        NUMBER,
                                 p_subinventory       VARCHAR2,
                                 p_locator_id         NUMBER,
                                 p_lot_number         VARCHAR2,
                                 p_revision           VARCHAR2)
   IS
      v_adj_id                     NUMBER := p_adj_id;
      v_org_id                     NUMBER := p_org_id;
      v_phys_inv_id                NUMBER := p_phys_inv_id;
      v_item_id                    NUMBER := p_inv_item_id;
      v_sub                        VARCHAR2 (10) := p_subinventory;
      v_locator_id                 NUMBER := p_locator_id;
      v_lot_num                    VARCHAR2 (80) := p_lot_number;
      v_rev                        VARCHAR2 (3) := p_revision;
      v_lot_exp_date               DATE := NULL;

      v_available_quantity         NUMBER;
      x_return_status              VARCHAR2 (10);
      x_qoh                        NUMBER;
      x_att                        NUMBER;
      v_ser_code                   NUMBER;
      v_lot_code                   NUMBER;
      v_rev_code                   NUMBER;
      v_is_ser_controlled          BOOLEAN := FALSE;
      v_is_lot_controlled          BOOLEAN := FALSE;
      v_is_rev_controlled          BOOLEAN := FALSE;
      l_rqoh                       NUMBER;
      l_qr                         NUMBER;
      l_qs                         NUMBER;
      l_atr                        NUMBER;
      l_msg_count                  NUMBER;
      l_msg_data                   VARCHAR2 (2000);
      l_parent_lpn_id              NUMBER;
      l_adjustment_quantity        NUMBER;

      -- BEGIN INVCONV
      l_secondary_adjustment_qty   NUMBER;
      l_sec_available_quantity     NUMBER;
      x_sqoh                       NUMBER;
      x_srqoh                      NUMBER;
      x_sqr                        NUMBER;
      x_sqs                        NUMBER;
      x_satt                       NUMBER;
      x_satr                       NUMBER;
   -- END INVCONV

   BEGIN
      IF g_neg_inv_rcpt_code IS NULL
      THEN
         SELECT negative_inv_receipt_code
           INTO g_neg_inv_rcpt_code --Negative Balance  1:Allowed   2:Disallowed
           FROM mtl_parameters
          WHERE organization_id = v_org_id;
      END IF;

      SELECT adjustment_quantity, secondary_adjustment_qty          -- INVCONV
        INTO l_adjustment_quantity, l_secondary_adjustment_qty      -- INVCONV
        FROM mtl_physical_adjustments
       WHERE     adjustment_id = v_adj_id
             AND physical_inventory_id = v_phys_inv_id
             AND organization_id = v_org_id;

      ----logf('l_adjustment_qty = '||l_adjustment_quantity);

      IF (g_neg_inv_rcpt_code = 2 AND l_adjustment_quantity < 0)
      THEN
         SELECT serial_number_control_code,
                lot_control_code,
                revision_qty_control_code
           INTO v_ser_code, v_lot_code, v_rev_code
           FROM mtl_system_items
          WHERE inventory_item_id = v_item_id AND organization_id = v_org_id;

         IF (v_ser_code <> 1)
         THEN
            v_is_ser_controlled := TRUE;
         END IF;

         IF (v_lot_code <> 1)
         THEN
            v_is_lot_controlled := TRUE;
         END IF;

         IF (v_rev_code <> 1)
         THEN
            v_is_rev_controlled := TRUE;
         END IF;

         inv_quantity_tree_pub.query_quantities (
            p_api_version_number      => 1.0,
            p_init_msg_lst            => 'F',
            x_return_status           => x_return_status,
            x_msg_count               => l_msg_count,
            x_msg_data                => l_msg_data,
            p_organization_id         => v_org_id,
            p_inventory_item_id       => v_item_id,
            p_tree_mode               => 1,
            p_is_revision_control     => v_is_rev_controlled,
            p_is_lot_control          => v_is_lot_controlled,
            p_is_serial_control       => v_is_ser_controlled,
            p_grade_code              => NULL                       -- INVCONV
                                             ,
            p_demand_source_type_id   => NULL,
            p_revision                => v_rev,
            p_lot_number              => v_lot_num,
            p_lot_expiration_date     => v_lot_exp_date,
            p_subinventory_code       => v_sub,
            p_locator_id              => v_locator_id,
            p_onhand_source           => 3,
            x_qoh                     => x_qoh,
            x_rqoh                    => l_rqoh,
            x_qr                      => l_qr,
            x_qs                      => l_qs,
            x_att                     => x_att,
            x_atr                     => l_atr                -- BEGIN INVCONV
                                              ,
            x_sqoh                    => x_sqoh,
            x_srqoh                   => x_srqoh,
            x_sqr                     => x_sqr,
            x_sqs                     => x_sqs,
            x_satt                    => x_satt,
            x_satr                    => x_satr                 -- END INVCONV
                                               );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            logf ('INV ' || 'INV_QRY_QTY_FAILED' || SQLERRM);
            retcode := 2;
         END IF;

         v_available_quantity := x_att;

         ----logf(' ATR : ' || to_char(l_atr) || ' ATT ' ||x_att);
         ----logf('v_ON_hand_quantity : ' || to_char(X_QOH));

         IF (v_available_quantity + l_adjustment_quantity < 0)
         THEN
            -- The physical adjustment should not be processed since it
            -- will invalidate an existing reservation/allocation.
            logf ('INV ' || 'INV_CANNOT_APPROVE_PHY_ADJ' || SQLERRM);
            retcode := 2;
            -- clearing the quantity tree cache so that in case of error, all trees to be cleared
            -- and next time, availability check should be done with new trees.
            inv_quantity_tree_grp.clear_quantity_cache;
         END IF;

         inv_quantity_tree_pub.update_quantities (
            p_api_version_number      => 1.0,
            p_init_msg_lst            => 'F',
            x_return_status           => x_return_status,
            x_msg_count               => l_msg_count,
            x_msg_data                => l_msg_data,
            p_organization_id         => v_org_id,
            p_inventory_item_id       => v_item_id,
            p_tree_mode               => 1,
            p_is_revision_control     => v_is_rev_controlled,
            p_is_lot_control          => v_is_lot_controlled,
            p_is_serial_control       => v_is_ser_controlled,
            p_demand_source_type_id   => NULL,
            p_revision                => v_rev,
            p_lot_number              => v_lot_num,
            p_subinventory_code       => v_sub,
            p_locator_id              => v_locator_id,
            p_onhand_source           => 3,
            p_containerized           => 0,
            p_primary_quantity        => ABS (l_adjustment_quantity),
            p_quantity_type           => 5,
            p_secondary_quantity      => ABS (l_secondary_adjustment_qty) -- INVCONV
                                                                         ,
            x_qoh                     => x_qoh,
            x_rqoh                    => l_rqoh,
            x_qr                      => l_qr,
            x_qs                      => l_qs,
            x_att                     => x_att,
            x_atr                     => l_atr,
            p_lpn_id                  => NULL      --added for lpn reservation
                                             -- BEGIN INVCONV
            ,
            x_sqoh                    => x_sqoh,
            x_srqoh                   => x_srqoh,
            x_sqr                     => x_sqr,
            x_sqs                     => x_sqs,
            x_satt                    => x_satt,
            x_satr                    => x_satr                 -- END INVCONV
                                               );
      ----logf('After update-');
      ----logf('QOH ' || to_char(x_qoh) || ' ATR ' || to_char(l_atr) || ' ATT ' || to_char(x_att));

      END IF;
   END check_availability;

   PROCEDURE update_license_plate (p_parent_lpn_id NUMBER)
   IS
      v_outermost_lpn_id     NUMBER;
      v_container_item_id    NUMBER;
      v_container_revision   VARCHAR2 (3);
      v_container_cost_grp   NUMBER;
      v_container_lot_no     VARCHAR2 (80);
      v_container_serial     VARCHAR2 (30);
   BEGIN
      IF p_parent_lpn_id IS NOT NULL
      THEN
         UPDATE wms_license_plate_numbers
            SET inventory_item_id = v_container_item_id,
                revision = v_container_revision,
                cost_group_id = v_container_cost_grp,
                lot_number = v_container_lot_no,
                serial_number = v_container_serial
          WHERE lpn_id = p_parent_lpn_id;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Unespected Error ' || SQLERRM);
   END update_license_plate;

   PROCEDURE create_new_tags (errbuff      OUT VARCHAR2,
                              retcode      OUT NUMBER,
                              p_inv_tags       VARCHAR2)
   IS
      v_Rowid                          VARCHAR2 (18);
      v_Tag_Id                         NUMBER;
      v_Physical_Inventory_Id          NUMBER;
      v_Organization_Id                NUMBER;
      v_Last_Update_Date               DATE;
      v_Last_Updated_By                NUMBER;
      v_Creation_Date                  DATE;
      v_Created_By                     NUMBER;
      v_Last_Update_Login              NUMBER;
      v_Void_Flag                      NUMBER;
      v_Tag_Number                     VARCHAR2 (40);
      v_Adjustment_Id                  NUMBER;
      v_Inventory_Item_Id              NUMBER;
      v_Tag_Quantity                   NUMBER := 0;
      v_System_Quantity                NUMBER := 0;
      v_Tag_Uom                        VARCHAR2 (3);
      v_Tag_Quantity_At_Standard_Uom   NUMBER;
      v_Subinventory                   VARCHAR2 (10);
      v_Locator_Id                     NUMBER;
      v_Lot_Number                     VARCHAR2 (80);
      v_Revision                       VARCHAR2 (3);
      v_Serial_Num                     VARCHAR2 (30);
      v_Counted_By_Employee_Id         NUMBER;
      v_Attribute_Category             VARCHAR2 (30);
      v_Attribute1                     VARCHAR2 (150);
      v_Attribute2                     VARCHAR2 (150);
      v_Attribute3                     VARCHAR2 (150);
      v_Attribute4                     VARCHAR2 (150);
      v_Attribute5                     VARCHAR2 (150);
      v_Attribute6                     VARCHAR2 (150);
      v_Attribute7                     VARCHAR2 (150);
      v_Attribute8                     VARCHAR2 (150);
      v_Attribute9                     VARCHAR2 (150);
      v_Attribute10                    VARCHAR2 (150);
      v_Attribute11                    VARCHAR2 (150);
      v_Attribute12                    VARCHAR2 (150);
      v_Attribute13                    VARCHAR2 (150);
      v_Attribute14                    VARCHAR2 (150);
      v_Attribute15                    VARCHAR2 (150);
      v_lot_expiration_date            DATE;
      --WMS
      v_parent_lpn_id                  NUMBER;
      v_outermost_lpn_id               NUMBER;
      v_cost_group_id                  NUMBER;
      v_cost_group_name                VARCHAR2 (50);
      v_return_status                  VARCHAR2 (1);
      v_msg_count                      NUMBER;
      v_msg_data                       VARCHAR2 (2000);

      v_Count_Quanity                  NUMBER := 0;

      -- BEGIN INVCONV
      v_tag_secondary_quantity         NUMBER;
      v_tag_secondary_uom              VARCHAR2 (3);
   -- END INVCONV
   BEGIN
      -- sctipt insert
      logf ('Run Program Create New Tags');
      logf ('_____________________________________');

      FOR i IN inv_tags_cur (p_inventory_name => p_inv_tags)
      LOOP
         logf ('Get new inventory item id.');

         BEGIN
            SELECT inventory_item_id
              INTO v_Inventory_Item_Id
              FROM mtl_system_items
             WHERE     segment1 = REGEXP_SUBSTR (i.item_code,
                                                 '[^.]+',
                                                 1,
                                                 1)
                   AND organization_id = 84;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               logf ('Error When Get Item ' || SQLERRM);
               retcode := 2;
         END;

         logf ('Chack for duplicate tags.');
         check_for_duplicate_tag (errbuff         => errbuff,
                                  retcode         => retcode,
                                  p_phys_inv_id   => i.physical_inventory_id,
                                  p_org_id        => i.organization_id,
                                  p_tag_number    => i.tag_number);

         logf ('Check Adjusment.');

         check_adjustment (
            errbuff                     => errbuff,
            retcode                     => retcode,
            x_adjustment_id             => v_Adjustment_Id,
            p_phys_inv_id               => i.physical_inventory_id,
            p_org_id                    => i.organization_id,
            p_serial_num_control_code   => i.serial_number_control_code,
            p_tag_number                => i.tag_number,
            p_inv_item_id               => v_Inventory_Item_Id,
            p_serial_num                => i.serial_num,
            p_locator_id                => i.locator_id,
            p_parent_lpn_id             => i.parent_lpn_id,
            p_tag_id                    => i.tag_id,
            p_lot_exp_date              => i.lot_expiration_date);

         /*Jika Cost Group Kosong maka ambil dari sini*/
         logf ('Adjusment Id : ' || v_Adjustment_Id);

         IF (v_Adjustment_Id = -1)
         THEN
            retcode := 2;
         END IF;

         logf ('Validasi Cost Group 1');

         IF (i.cost_group_id IS NULL)
         THEN
            INV_COST_GROUP_PVT.get_cost_group (
               x_cost_group_id       => v_cost_group_id,
               x_cost_group          => v_cost_group_name,
               x_return_status       => v_return_status,
               x_msg_count           => v_msg_count,
               x_msg_data            => v_msg_data,
               p_organization_id     => i.organization_id,
               p_lpn_id              => i.parent_lpn_id,
               p_inventory_item_id   => v_Inventory_Item_Id,
               p_revision            => i.revision,
               p_subinventory_code   => i.subinventory,
               p_locator_id          => i.locator_id,
               p_lot_number          => i.lot_number,
               p_serial_number       => i.serial_num);

            IF (v_return_status <> fnd_api.g_ret_sts_success)
            THEN
               fnd_msg_pub.count_and_get (p_count     => v_msg_count,
                                          p_data      => v_msg_data,
                                          p_encoded   => 'F');
            END IF;

            /*Jika Cost Group Masih Kosong maka ambil dari sini*/
            logf ('Validasi Cost group 2');

            IF (v_cost_group_id IS NULL AND i.Subinventory IS NOT NULL)
            THEN
               IF (i.parent_lpn_id IS NOT NULL)
               THEN
                  inv_cyc_lovs.get_cost_group_id (
                     p_organization_id     => i.organization_id,
                     p_subinventory        => i.subinventory,
                     p_locator_id          => i.locator_id,
                     p_parent_lpn_id       => i.parent_lpn_id,
                     p_inventory_item_id   => v_Inventory_Item_Id,
                     p_revision            => i.revision,
                     p_lot_number          => i.lot_number,
                     p_serial_number       => i.serial_num,
                     x_out                 => v_cost_group_id);

                  logf ('v_cost_group_id ' || v_cost_group_id);
               END IF;

               /*Jika Cost Group Masih Kosong Juga maka ambil dari sini*/
               logf ('Valisadi Cost Group 3');

               IF (v_cost_group_id IS NULL OR i.cost_group_id = -999)
               THEN
                  SELECT default_cost_group_id
                    INTO v_cost_group_id
                    FROM mtl_secondary_inventories
                   WHERE     organization_id = i.organization_id
                         AND secondary_inventory_name = i.Subinventory;

                  logf ('v_cost_group_id ' || v_cost_group_id);
               END IF;
            END IF;
         ELSE
            v_cost_group_id := i.cost_group_id;
         END IF;

         /*Insert biasa ke Physical Inventory*/
         logf ('Insert to Physical Inventory');

         SELECT mtl_physical_inventory_tags_s.NEXTVAL INTO v_tag_id FROM DUAL;

         INSERT
           INTO mtl_physical_inventory_tags (tag_id,
                                             physical_inventory_id,
                                             organization_id,
                                             last_update_date,
                                             last_updated_by,
                                             creation_date,
                                             created_by,
                                             last_update_login,
                                             void_flag,
                                             tag_number,
                                             adjustment_id,
                                             inventory_item_id,
                                             tag_quantity,
                                             tag_uom,
                                             tag_quantity_at_standard_uom,
                                             subinventory,
                                             locator_id,
                                             lot_number,
                                             lot_expiration_date,
                                             revision,
                                             serial_num,
                                             counted_by_employee_id,
                                             attribute_category,
                                             attribute1,
                                             attribute2,
                                             attribute3,
                                             attribute4,
                                             attribute5,
                                             attribute6,
                                             attribute7,
                                             attribute8,
                                             attribute9,
                                             attribute10,
                                             attribute11,
                                             attribute12,
                                             attribute13,
                                             attribute14,
                                             attribute15,
                                             parent_lpn_id,
                                             outermost_lpn_id,
                                             cost_group_id,
                                             -- BEGIN INVCONV
                                             tag_secondary_quantity,
                                             tag_secondary_uom --tag_qty_at_std_secondary_uom,
                                                              --standard_secondary_uom
                                                              -- END INVCONV
                                             )
         VALUES (v_tag_id,
                 i.Physical_Inventory_Id,
                 i.Organization_Id,
                 --to_date('01-JAN-1996', 'DD-MON-YYYY'),
                 SYSDATE,                                --i.Last_Update_Date,
                 --g_user_id,
                 i.Last_Updated_By,
                 --to_date( '01-JAN-1996', 'DD-MON-YYYY'),
                 SYSDATE,                                   --i.Creation_Date,
                 --g_user_id,
                 i.Created_By,
                 --g_login_id,
                 i.Last_Update_Login,
                 i.Void_Flag,
                 'NEW_' || i.Tag_Number,
                 v_Adjustment_Id,
                 v_Inventory_Item_Id,
                 i.Tag_Quantity,
                 i.Tag_Uom,
                 i.Tag_Quantity_At_Standard_Uom,
                 i.Subinventory,
                 i.Locator_Id,
                 i.Lot_Number,
                 i.lot_expiration_date,
                 i.Revision,
                 i.Serial_Num,
                 i.Counted_By_Employee_Id,
                 i.Attribute_Category,
                 i.Attribute1,
                 i.Attribute2,
                 i.Attribute3,
                 i.Attribute4,
                 i.Attribute5,
                 i.Attribute6,
                 i.Attribute7,
                 i.Attribute8,
                 i.Attribute9,
                 i.Attribute10,
                 i.Attribute11,
                 i.Attribute12,
                 i.Attribute13,
                 i.Attribute14,
                 i.Attribute15,
                 i.parent_lpn_id,
                 i.outermost_lpn_id,
                 v_cost_group_id,
                 -- BEGIN INVCONV
                 i.tag_secondary_quantity,
                 i.tag_secondary_uom               --i.tag_secondary_quantity,
                                    --i.tag_secondary_uom
                                    -- END INVCONV
                 );

         /*Kemudian Update LPN*/
         logf ('Update LPN');
         update_license_plate (i.parent_lpn_id);


         IF i.parent_lpn_id IS NOT NULL
         THEN
            logf ('Delete duplicat entries');
            inv_phy_inv_lovs.delete_duplicate_entries (
               i.Physical_Inventory_Id,
               i.Organization_Id,
               i.parent_lpn_id,
               v_Inventory_Item_Id,
               i.revision,
               i.lot_number,
               i.serial_num,
               i.Adjustment_Id);
         END IF;

         /*UPDATE existing tag quantity*/
         logf ('UPDATE existing tag quantity');

         BEGIN
            UPDATE mtl_physical_inventory_tags
               SET tag_quantity = v_Tag_Quantity
             WHERE     tag_id = i.tag_id
                   AND Physical_Inventory_Id = i.Physical_Inventory_Id;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error when update tags quantity ' || SQLERRM);
               retcode := 2;
         END;

         /*UPDATE existing tag quantity*/
         logf ('UPDATE existing count quantity');

         BEGIN
            UPDATE mtl_physical_adjustments
               SET count_quantity = v_Count_Quanity,
                   adjustment_quantity = (-1 * i.count_quantity)
             WHERE     adjustment_id = i.adjustment_id
                   AND Physical_Inventory_Id = i.Physical_Inventory_Id
                   AND inventory_item_id = i.inventory_item_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error when update count quantity ' || SQLERRM);
               retcode := 2;
         END;

         logf ('Update Adjusment');
         update_adjustment (errbuff          => errbuff,
                            retcode          => retcode,
                            p_adj_id         => v_Adjustment_Id,
                            p_org_id         => i.organization_id,
                            p_phys_inv_id    => i.physical_inventory_id,
                            p_inv_item_id    => v_Inventory_Item_Id,
                            p_subinventory   => i.subinventory,
                            p_revision       => i.revision,
                            p_locator_id     => i.locator_id,
                            p_lot_number     => i.lot_number);
      END LOOP;

      --------------------------------------------------------------------------------------------------------------


      IF (retcode = 0 OR retcode IS NULL)
      THEN
         COMMIT;
         logf ('COMMIT Successfully');
      ELSIF (retcode = 2 OR retcode = 1)
      THEN
         ROLLBACK;
         logf ('Rollback');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Unexpected Error' || SQLERRM);
         ROLLBACK;
         logf ('Rollback');
         retcode := 2;
   END;

   PROCEDURE update_inv_tags (errbuff      OUT VARCHAR2,
                              retcode      OUT NUMBER,
                              p_inv_tags       VARCHAR2)
   IS
      v_Rowid                          VARCHAR2 (18);
      v_Tag_Id                         NUMBER;
      -- v_Physical_Inventory_Id number;
      v_Physical_Inventory_Id          NUMBER;
      v_Organization_Id                NUMBER;
      v_Last_Update_Date               DATE;
      v_Last_Updated_By                NUMBER;
      v_Creation_Date                  DATE;
      v_Created_By                     NUMBER;
      v_Last_Update_Login              NUMBER;
      v_Void_Flag                      NUMBER;
      v_Tag_Number                     VARCHAR2 (40);
      v_Adjustment_Id                  NUMBER;
      v_Inventory_Item_Id              NUMBER;
      v_Tag_Quantity                   NUMBER;
      v_Tag_Uom                        VARCHAR2 (3);
      v_Tag_Quantity_At_Standard_Uom   NUMBER;
      v_Subinventory                   VARCHAR2 (10);
      v_Locator_Id                     NUMBER;
      v_Lot_Number                     VARCHAR2 (80);
      v_Revision                       VARCHAR2 (3);
      v_Serial_Num                     VARCHAR2 (30);
      v_Counted_By_Employee_Id         NUMBER;
      v_Attribute_Category             VARCHAR2 (30);
      v_Attribute1                     VARCHAR2 (150);
      v_Attribute2                     VARCHAR2 (150);
      v_Attribute3                     VARCHAR2 (150);
      v_Attribute4                     VARCHAR2 (150);
      v_Attribute5                     VARCHAR2 (150);
      v_Attribute6                     VARCHAR2 (150);
      v_Attribute7                     VARCHAR2 (150);
      v_Attribute8                     VARCHAR2 (150);
      v_Attribute9                     VARCHAR2 (150);
      v_Attribute10                    VARCHAR2 (150);
      v_Attribute11                    VARCHAR2 (150);
      v_Attribute12                    VARCHAR2 (150);
      v_Attribute13                    VARCHAR2 (150);
      v_Attribute14                    VARCHAR2 (150);
      v_Attribute15                    VARCHAR2 (150);
      v_lot_expiration_date            DATE;
      --WMS
      v_parent_lpn_id                  NUMBER;
      v_outermost_lpn_id               NUMBER;
      v_cost_group_id                  NUMBER;
      v_cost_group_name                VARCHAR2 (50);
      v_return_status                  VARCHAR2 (1);
      v_msg_count                      NUMBER;
      v_msg_data                       VARCHAR2 (2000);


      -- BEGIN INVCONV
      v_tag_secondary_quantity         NUMBER;
      v_tag_secondary_uom              VARCHAR2 (3);
   -- END INVCONV
   BEGIN
      v_Last_Update_Date := SYSDATE;
      v_lot_expiration_date := SYSDATE;

      IF (v_cost_group_id IS NULL AND v_Subinventory IS NOT NULL)
      THEN
         SELECT default_cost_group_id
           INTO v_cost_group_id
           FROM mtl_secondary_inventories
          WHERE     organization_id = g_organization_id
                AND secondary_inventory_name = v_Subinventory;
      END IF;

      -- script update
      UPDATE mtl_physical_inventory_tags
         SET last_update_date = v_Last_Update_Date,
             last_updated_by = v_Last_Updated_By,
             last_update_login = v_Last_Update_Login,
             void_flag = v_Void_Flag,
             adjustment_id = v_Adjustment_Id,
             inventory_item_id = v_Inventory_Item_Id,
             tag_quantity = v_Tag_Quantity,
             tag_uom = v_Tag_Uom,
             tag_quantity_at_standard_uom = v_Tag_Quantity_At_Standard_Uom,
             subinventory = v_Subinventory,
             locator_id = v_Locator_Id,
             lot_number = v_Lot_Number,
             lot_expiration_date = v_lot_expiration_date,
             /* changes for bug2672616 */
             revision = v_Revision,
             serial_num = v_Serial_Num,
             counted_by_employee_id = v_Counted_By_Employee_Id,
             attribute_category = v_Attribute_Category,
             attribute1 = v_Attribute1,
             attribute2 = v_Attribute2,
             attribute3 = v_Attribute3,
             attribute4 = v_Attribute4,
             attribute5 = v_Attribute5,
             attribute6 = v_Attribute6,
             attribute7 = v_Attribute7,
             attribute8 = v_Attribute8,
             attribute9 = v_Attribute9,
             attribute10 = v_Attribute10,
             attribute11 = v_Attribute11,
             attribute12 = v_Attribute12,
             attribute13 = v_Attribute13,
             attribute14 = v_Attribute14,
             attribute15 = v_Attribute15,
             parent_lpn_id = v_parent_lpn_id,
             outermost_lpn_id = v_outermost_lpn_id,
             cost_group_id = v_cost_group_id,
             -- BEGIN INVCONV
             tag_secondary_quantity = v_tag_secondary_quantity,
             tag_secondary_uom = v_tag_secondary_uom
       --tag_qty_at_std_secondary_uom      =     v_tag_secondary_quantity,
       --standard_secondary_uom            =     v_tag_secondary_uom
       -- END INVCONV
       WHERE ROWID = v_rowid;


      update_license_plate (v_parent_lpn_id);
   END;

   PROCEDURE main_process (errbuff         OUT VARCHAR2,
                           retcode         OUT NUMBER,
                           p_inv_tags   IN     VARCHAR2)
   IS
      l_conc_status   BOOLEAN;
   BEGIN
      create_new_tags (errbuff, retcode, p_inv_tags);

      IF retcode = 2
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);
      ELSIF retcode = 1
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('WARNING', 1);
      ELSE
         NULL;
      END IF;
   END main_process;
END XXSHP_PHYSICAL_INV_TAGS_PKG;
/