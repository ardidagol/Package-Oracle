CREATE OR REPLACE PACKAGE BODY APPS.xxshp_inv_item_indirect_pkg
/* $Header: XXSHP_INV_ITEM_INDIRECT_PKG.pkb 122.5.1.0 2016/12/06 10:41:10 Farry Ciptono $ */
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
   PROCEDURE logf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
   --DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   --DBMS_OUTPUT.put_line (p_msg);
   END outf;

   FUNCTION get_status_desc (p_status VARCHAR2)
      RETURN VARCHAR2
   IS
      p_return   VARCHAR2 (50);
   BEGIN
      SELECT meaning
        INTO p_return
        FROM fnd_lookup_values flv, fnd_application fa
       WHERE     flv.view_application_id = fa.application_id
             AND fa.application_short_name = 'XXSHP'
             AND flv.lookup_type = 'XXSHP_INV_ITEM_INDIRECT_STATUS'
             AND flv.lookup_code = p_status;

      RETURN p_return;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'error retrieving lookup status ' || SQLERRM;
   END get_status_desc;

   PROCEDURE waitforrequest (request_id IN NUMBER, status OUT VARCHAR2, err_message OUT VARCHAR2)
   IS
      v_result      BOOLEAN;
      v_phase       VARCHAR2 (20);
      v_devphase    VARCHAR2 (20);
      v_devstatus   VARCHAR2 (20);
   BEGIN
      v_result :=
         fnd_concurrent.wait_for_request (request_id,
                                          5,
                                          0,
                                          v_phase,
                                          status,
                                          v_devphase,
                                          v_devstatus,
                                          err_message);
   END waitforrequest;

   PROCEDURE submit_report (p_requestor       VARCHAR2,
                            p_validator       VARCHAR2,
                            p_req_no          NUMBER,
                            p_return      OUT NUMBER)
   IS
      v_layout         BOOLEAN;
      v_notification   BOOLEAN;
      v_request_id     NUMBER;
      v_requestor      VARCHAR2 (100);
      v_validator      VARCHAR2 (100);
      v_status_hdr     VARCHAR2 (25);
      v_err            NUMBER := 0;
      v_message        VARCHAR2 (1000);
      v_status         VARCHAR2 (100);
      v_errmsg         VARCHAR2 (1000);
   BEGIN
      IF (p_requestor = 'Y' AND p_validator = 'Y')
      THEN
         BEGIN
            SELECT status, request_by_name, validate_by_name
              INTO v_status_hdr, v_requestor, v_validator
              FROM xxshp_inv_item_indirect_hdr_v
             WHERE hdr_id = p_req_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error when get requestor and validator name ' || SQLERRM);
               v_message := v_message || 'Error when get requestor and validator name ' || SQLERRM || ';';
               v_err := 1;
         END;
      ELSIF (p_requestor = 'N' AND p_validator = 'Y')
      THEN
         BEGIN
            SELECT status, validate_by_name
              INTO v_status_hdr, v_validator
              FROM xxshp_inv_item_indirect_hdr_v
             WHERE hdr_id = p_req_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error when get validator name ' || SQLERRM);
               v_message := v_message || 'Error when get validator name ' || SQLERRM || ';';
               v_err := 1;
         END;
      END IF;

      IF (   (v_requestor IS NOT NULL AND v_validator IS NOT NULL AND p_requestor = 'Y' AND p_validator = 'Y')
          OR (v_validator IS NOT NULL AND p_requestor = 'N' AND p_validator = 'Y'))
      THEN
         v_layout :=
            fnd_request.add_layout (template_appl_name   => 'XXSHP',
                                    template_code        => 'XXSHP_INV_REQ_ITEM_IDRCT',
                                    template_language    => 'en',
                                    template_territory   => 'US',
                                    output_format        => 'HTML');

         IF (p_requestor = 'Y' AND p_validator = 'Y')
         THEN
            v_notification := fnd_request.add_notification (v_requestor);
         END IF;

         v_notification := fnd_request.add_notification (v_validator);
         v_request_id :=
            fnd_request.submit_request (application   => 'XXSHP',
                                        program       => 'XXSHP_INV_REQ_ITEM_IDRCT',
                                        description   => NULL,
                                        start_time    => NULL,
                                        sub_request   => FALSE,
                                        argument1     => NULL,
                                        argument2     => p_req_no,
                                        argument3     => v_status_hdr,
                                        argument4     => NULL,
                                        argument5     => NULL);
         COMMIT;

         IF (v_request_id IS NULL)
         THEN
            logf ('Submit report failed ' || SQLERRM);
            v_message := v_message || 'Submit report failed ' || SQLERRM || ';';
         ELSE
            logf ('Report submitted with request ID: ' || v_request_id);
            waitforrequest (v_request_id, v_status, v_errmsg);
         END IF;

         IF (UPPER (v_status) <> 'NORMAL')
         THEN
            logf ('Report submission failed : ' || v_status);
            logf (v_errmsg || ' - ' || SQLERRM);
            v_err := 1;
            v_message := v_message || 'Report submission failed : ' || v_status || ' - ' || v_errmsg || ';';
         ELSE
            logf ('Report submission completed : ' || v_status);
         END IF;
      ELSE
         IF (v_requestor IS NULL AND v_err = 0 AND p_requestor = 'Y')
         THEN
            logf ('Error requestor is not found');
            v_message := v_message || 'Error requestor is not found;';
         END IF;

         IF (v_validator IS NULL AND v_err = 0)
         THEN
            logf ('Error validator is not found');
            v_message := v_message || 'Error validator is not found;';
         END IF;

         v_err := 1;
      END IF;

      IF (v_err = 0)
      THEN
         logf ('Report Notification Status Item Master Indirect completed successfully');
      ELSIF (v_err = 1)
      THEN
         UPDATE xxshp_inv_item_indirect_hdr
            SET MESSAGE = v_message,
                last_update_date = SYSDATE,
                last_updated_by = g_user_id,
                last_update_login = g_login_id
          WHERE hdr_id = p_req_no;

         p_return := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submit report notification ' || SQLERRM);
         p_return := 1;
   END submit_report;

   PROCEDURE validate_item (p_req_no NUMBER, p_return OUT NUMBER)
   IS
      v_message   VARCHAR2 (1000);
      v_err       NUMBER := 0;
   BEGIN
      NULL;
   END validate_item;

   PROCEDURE submit_interface (p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER, p_req_no NUMBER)
   IS
      v_return   NUMBER := 0;
      v_error    NUMBER := 0;
   BEGIN
      logf ('Start Interface Master Item');
      master_item (p_req_no, v_return);

      IF (v_return = 1)
      THEN
         v_error := 1;
      ELSE
         logf ('------------------------------------------------------------------------------');
         logf ('Start Interface Assign Category');
         assign_category (p_req_no, v_return);

         IF (v_return = 1)
         THEN
            v_error := 1;
         ELSE
            logf ('------------------------------------------------------------------------------');
            logf ('Start Interface Assign Organization Item');
            assign_org_item (p_req_no, v_return);

            IF (v_return = 1)
            THEN
               v_error := 1;
            ELSE
               logf ('------------------------------------------------------------------------------');
               logf ('Start Program Assign Item to Restrict Subinventory');
               assign_item_subinv (p_req_no, v_return);

               IF (v_return = 1)
               THEN
                  v_error := 1;
               END IF;
            END IF;
         END IF;
      END IF;

      logf ('------------------------------------------------------------------------------');
      logf ('Start Report Notification Status Item Master Indirect');

      IF (v_error = 1)
      THEN
         p_retcode := 2;

         UPDATE xxshp_inv_item_indirect_hdr
            SET status = 'ERROR',
                last_update_date = SYSDATE,
                last_updated_by = g_user_id,
                last_update_login = g_login_id
          WHERE hdr_id = p_req_no;

         submit_report ('N',
                        'Y',
                        p_req_no,
                        v_return);

         IF (v_return = 1)
         THEN
            v_error := 1;
         END IF;
      ELSE
         UPDATE xxshp_inv_item_indirect_hdr
            SET status = 'INTERFACED',
                last_update_date = SYSDATE,
                last_updated_by = g_user_id,
                last_update_login = g_login_id
          WHERE hdr_id = p_req_no;

         submit_report ('Y',
                        'Y',
                        p_req_no,
                        v_return);
      END IF;

      COMMIT;
      logf ('------------------------------------------------------------------------------');
      logf ('End of program');
   EXCEPTION
      WHEN OTHERS
      THEN
         p_retcode := 2;
         logf ('Error submitting interface ' || SQLERRM);
   END submit_interface;

   PROCEDURE master_item (p_req_no NUMBER, p_return OUT NUMBER)
   IS
      v_subinv_exist   NUMBER;
      v_attribute3     VARCHAR2 (240);
      v_request_id     NUMBER;
      v_val            NUMBER;
      v_status         VARCHAR2 (100);
      v_errmsg         VARCHAR2 (1000);
      v_message        VARCHAR2 (1000);
      v_err            NUMBER := 0;
      v_error          NUMBER := 0;
      v_item_id        NUMBER;
   BEGIN
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_application_id);

      FOR i IN (SELECT DISTINCT master_organization_id FROM mtl_parameters)
      LOOP
         ----delete previous error transaction
         DELETE mtl_system_items_interface
          WHERE set_process_id = p_req_no AND global_attribute20 = 'XXSHP_INV_ITEM_INDIRECT';

         SELECT COUNT (1)
           INTO v_val
           FROM mtl_system_items_interface
          WHERE set_process_id = p_req_no;

         IF (v_val = 0)
         THEN
            SELECT COUNT (1)
              INTO v_val
              FROM xxshp_inv_item_indirect_hdr_v
             WHERE hdr_id = p_req_no AND item_master_iface IS NULL;

            IF (v_val > 0)
            THEN
               v_err := 0;
               v_message := NULL;
               mo_global.set_policy_context ('S', i.master_organization_id);
               mo_global.init ('INV');
               logf ('Submit Interface Master Item for organization_id: ' || i.master_organization_id);

               FOR c IN (SELECT *
                           FROM xxshp_inv_item_indirect_hdr_v
                          WHERE hdr_id = p_req_no AND item_master_iface IS NULL)
               LOOP
                  v_subinv_exist := NULL;
                  v_attribute3 := NULL;

                  SELECT COUNT (1)
                    INTO v_subinv_exist
                    FROM xxshp_inv_item_indirect_sub
                   WHERE hdr_id = p_req_no AND ROWNUM = 1;

                  /*BEGIN
                     SELECT ffv.attribute3
                       INTO v_attribute3
                       FROM fnd_flex_values ffv, fnd_flex_values_tl ffvt
                      WHERE ffv.flex_value_id = ffvt.flex_value_id
                        AND ffv.enabled_flag = 'Y'
                        AND SYSDATE BETWEEN NVL (ffv.start_date_active, SYSDATE) AND NVL (ffv.end_date_active, SYSDATE) + 1
                        AND ffv.flex_value_id = c.criteria2_id
                        AND ffv.attribute3 IS NOT NULL;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf ('Error when get template_id ' || SQLERRM);
                        v_attribute3 := NULL;
                        v_message := v_message || 'Error when get template_id ' || SQLERRM || ';';
                        v_err := 1;
                  END;*/
                  --IF (v_attribute3 IS NOT NULL)
                  --THEN
                  INSERT INTO mtl_system_items_interface (set_process_id,
                                                          organization_id,
                                                          item_number,
                                                          description,
                                                          primary_uom_code,
                                                          unit_of_issue,
                                                          inventory_item_flag,
                                                          stock_enabled_flag,
                                                          mtl_transactions_enabled_flag,
                                                          taxable_flag,
                                                          purchasing_tax_code,
                                                          --lot_control_code,
                                                          --auto_lot_alpha_prefix,
                                                          --start_auto_lot_number,
                                                          item_type,
                                                          attribute7,
                                                          attribute13,
                                                          restrict_subinventories_code,                                                 --template_id,
                                                          transaction_type,
                                                          process_flag,
                                                          list_price_per_unit,
                                                          global_attribute20,
                                                          attribute_category,
                                                          template_id)
                       VALUES (c.hdr_id,
                               i.master_organization_id,
                               c.item_temp,
                               c.item_description,
                               c.primary_uom,
                               c.purchase_uom_meaning,
                               c.flag_inventory_item,
                               c.flag_inventory_item,
                               c.flag_inventory_item,
                               c.flag_taxable_item,
                               DECODE (c.flag_taxable_item, 'Y', fnd_profile.VALUE ('XXSHP_INV_DEFAULT_TAX_CODE'), NULL),
                               --DECODE (c.flag_lot_control, 'Y', 2, 1),
                               --DECODE (c.flag_lot_control, 'Y', c.criteria1_id, NULL),
                               --DECODE (c.flag_lot_control, 'Y', '00001', NULL),
                               c.CRITERIA1_DESC,
                               DECODE (c.flag_item_k3, 'Y', 'YES', 'NO'),
                               DECODE (c.flag_need_coa, 'Y', 'YES', 'NO'),
                               DECODE (v_subinv_exist, 1, '1', '2'),                                                                   --v_attribute3,
                               'CREATE',
                               1,
                               c.list_price,
                               'XXSHP_INV_ITEM_INDIRECT',
                               'Indirect',
                               c.template_id);

                  v_request_id :=
                     fnd_request.submit_request (application   => 'INV',
                                                 program       => 'INCOIN',
                                                 description   => NULL,
                                                 start_time    => NULL,
                                                 sub_request   => FALSE,
                                                 argument1     => i.master_organization_id,                                         -- Organization id
                                                 argument2     => 1,                                                              -- All organizations
                                                 argument3     => 1,                                                                 -- Validate Items
                                                 argument4     => 1,                                                                  -- Process Items
                                                 argument5     => 1,                                                          -- Delete Processed Rows
                                                 argument6     => c.hdr_id,                                              -- Process Set (Null for All)
                                                 argument7     => 1,                                                         -- Create or Update Items
                                                 argument8     => 1                                                               -- Gather Statistics
                                                                   );
                  COMMIT;

                  IF NVL (v_request_id, 0) = 0
                  THEN
                     logf ('Import Items submission failed ' || SQLERRM);
                     logf (SQLCODE || '-' || SQLERRM);
                     v_err := 1;
                     v_message := v_message || 'Import Items submission failed ' || SQLERRM || ';';
                  ELSE
                     logf ('Request ID ' || v_request_id || ' has been submitted');
                     waitforrequest (v_request_id, v_status, v_errmsg);
                  END IF;

                  IF (UPPER (v_status) <> 'NORMAL')
                  THEN
                     logf ('Import Items submission failed : ' || v_status);
                     logf (v_errmsg || ' - ' || SQLERRM);
                     v_err := 1;
                     v_message := v_message || 'Import Items submission failed : ' || v_status || ' - ' || v_errmsg || ';';

                     FOR a IN (SELECT error_message
                                 FROM mtl_interface_errors
                                WHERE table_name = 'MTL_SYSTEM_ITEMS_INTERFACE' AND request_id = v_request_id)
                     LOOP
                        v_message := v_message || a.error_message || ';';
                        logf ('err ' || a.error_message);
                     END LOOP;
                  ELSE
                     logf ('Import Items submission completed : ' || v_status);

                     BEGIN
                        SELECT inventory_item_id
                          INTO v_item_id
                          FROM mtl_system_items_b
                         WHERE segment1 = c.item_temp AND organization_id = i.master_organization_id;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           logf ('Error when get inventory_item_id ' || SQLERRM);
                           v_err := 1;
                           v_message := v_message || 'Error when get inventory_item_id ' || SQLERRM || ';';
                     END;
                  END IF;
               --END IF;
               END LOOP;
            ELSE
               logf ('No Data found');
            --v_err := 1;
            --v_message := v_message || 'No Data found;';
            END IF;
         ELSE
            logf ('Data found in MTL_SYSTEM_ITEMS_INTERFACE for set_process_id:' || p_req_no);
            v_err := 1;
            v_message := v_message || 'Data found in MTL_SYSTEM_ITEMS_INTERFACE for set_process_id:' || p_req_no || ';';
         END IF;

         IF (v_err = 0)
         THEN
            UPDATE xxshp_inv_item_indirect_hdr
               SET MESSAGE = NULL,
                   item_id = NVL (item_id, v_item_id),
                   item_code = item_temp,
                   item_master_iface = NVL (item_master_iface, v_request_id),
                   last_update_date = SYSDATE,
                   last_updated_by = g_user_id,
                   last_update_login = g_login_id
             WHERE hdr_id = p_req_no;

            logf ('Interface Master Item completed successfully');
         ELSIF (v_err = 1)
         THEN
            UPDATE xxshp_inv_item_indirect_hdr
               SET MESSAGE = v_message,
                   last_update_date = SYSDATE,
                   last_updated_by = g_user_id,
                   last_update_login = g_login_id
             WHERE hdr_id = p_req_no;

            v_error := 1;
         END IF;
      END LOOP;

      COMMIT;

      IF (v_error = 0)
      THEN
         p_return := 0;
      ELSE
         p_return := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submitting Interface Master Item ' || SQLERRM);
         p_return := 1;
   END master_item;

   PROCEDURE assign_category (p_req_no NUMBER, p_return OUT NUMBER)
   IS
      v_attribute_inv   VARCHAR2 (240);
      v_attribute_pur   VARCHAR2 (240);
      v_request_id      NUMBER;
      v_val             NUMBER;
      v_status          VARCHAR2 (100);
      v_errmsg          VARCHAR2 (1000);
      v_cat_set_id      NUMBER;
      v_oldcat_id       NUMBER;
      v_err             NUMBER := 0;
      v_message         VARCHAR2 (1000);
      v_error           NUMBER := 0;
   BEGIN
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_application_id);

      FOR i IN (SELECT DISTINCT master_organization_id FROM mtl_parameters)
      LOOP
         v_err := 0;
         v_message := NULL;
         logf ('Submit Interface Assign Category for organization_id: ' || i.master_organization_id);

         ----delete previous error transaction
         DELETE mtl_item_categories_interface
          WHERE set_process_id = p_req_no AND transaction_type = 'UPDATE';

         SELECT COUNT (1)
           INTO v_val
           FROM mtl_item_categories_interface
          WHERE set_process_id = p_req_no;

         IF (v_val = 0)
         THEN
            SELECT COUNT (1)
              INTO v_val
              FROM xxshp_inv_item_indirect_hdr_v
             WHERE hdr_id = p_req_no AND item_category_iface IS NULL AND inventory_category_id IS NULL AND purchasing_category_id IS NULL;

            IF (v_val > 0)
            THEN
               mo_global.set_policy_context ('S', i.master_organization_id);
               mo_global.init ('INV');

               FOR c
                  IN (SELECT *
                        FROM xxshp_inv_item_indirect_hdr_v
                       WHERE hdr_id = p_req_no AND item_category_iface IS NULL AND inventory_category_id IS NULL AND purchasing_category_id IS NULL)
               LOOP
                  IF (c.flag_inventory_item = 'Y')
                  THEN
                     BEGIN
                        SELECT category_set_id
                          INTO v_cat_set_id
                          FROM mtl_default_category_sets
                         WHERE functional_area_id = 1;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           logf ('Error when get inventory category_set_id ' || SQLERRM);
                           v_cat_set_id := NULL;
                           v_err := 1;
                           v_message := v_message || 'Error when get inventory category_set_id ' || SQLERRM || ';';
                     END;

                     BEGIN
                        SELECT ffv.attribute4
                          INTO v_attribute_inv
                          FROM fnd_flex_values ffv, fnd_flex_values_tl ffvt
                         WHERE     ffv.flex_value_id = ffvt.flex_value_id
                               AND ffv.enabled_flag = 'Y'
                               AND SYSDATE BETWEEN NVL (ffv.start_date_active, SYSDATE) AND NVL (ffv.end_date_active, SYSDATE) + 1
                               AND ffv.flex_value_id = c.criteria2_id
                               AND ffv.attribute4 IS NOT NULL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           logf ('Error when get inventory category_id ' || SQLERRM);
                           v_attribute_inv := NULL;
                           v_err := 1;
                           v_message := v_message || 'Error when get inventory category_id ' || SQLERRM || ';';
                     END;

                     BEGIN
                        SELECT cas.default_category_id
                          INTO v_oldcat_id
                          FROM mtl_category_sets_b cas, mtl_default_category_sets dcs
                         WHERE dcs.category_set_id = cas.category_set_id AND dcs.functional_area_id = 1;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           logf ('Error when get inventory old_category_id ' || SQLERRM);
                           v_oldcat_id := NULL;
                           v_err := 1;
                           v_message := v_message || 'Error when get inventory old_category_id ' || SQLERRM || ';';
                     END;

                     IF (v_cat_set_id IS NOT NULL AND v_attribute_inv IS NOT NULL AND v_oldcat_id IS NOT NULL)
                     THEN
                        INSERT INTO mtl_item_categories_interface (item_number,
                                                                   category_set_id,
                                                                   category_id,
                                                                   organization_id,
                                                                   transaction_type,
                                                                   process_flag,
                                                                   set_process_id,
                                                                   old_category_id)
                             VALUES (c.item_code,
                                     v_cat_set_id,
                                     v_attribute_inv,
                                     i.master_organization_id,
                                     'UPDATE',
                                     1,
                                     c.hdr_id,
                                     v_oldcat_id);
                     END IF;
                  END IF;

                  BEGIN
                     SELECT category_set_id
                       INTO v_cat_set_id
                       FROM mtl_default_category_sets
                      WHERE functional_area_id = 2;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf ('Error when get purchasing category_set_id ' || SQLERRM);
                        v_cat_set_id := NULL;
                        v_err := 1;
                        v_message := v_message || 'Error when get purchasing category_set_id ' || SQLERRM || ';';
                  END;

                  BEGIN
                     SELECT ffv.attribute5
                       INTO v_attribute_pur
                       FROM fnd_flex_values ffv, fnd_flex_values_tl ffvt
                      WHERE     ffv.flex_value_id = ffvt.flex_value_id
                            AND ffv.enabled_flag = 'Y'
                            AND SYSDATE BETWEEN NVL (ffv.start_date_active, SYSDATE) AND NVL (ffv.end_date_active, SYSDATE) + 1
                            AND ffv.flex_value_id = c.criteria2_id
                            AND ffv.attribute5 IS NOT NULL;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf ('Error when get purchasing category_id ' || SQLERRM);
                        v_attribute_pur := NULL;
                        v_err := 1;
                        v_message := v_message || 'Error when get purchasing category_id ' || SQLERRM || ';';
                  END;

                  BEGIN
                     SELECT cas.default_category_id
                       INTO v_oldcat_id
                       FROM mtl_category_sets_b cas, mtl_default_category_sets dcs
                      WHERE dcs.category_set_id = cas.category_set_id AND dcs.functional_area_id = 2;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf ('Error when get purchasing old_category_id ' || SQLERRM);
                        v_oldcat_id := NULL;
                        v_err := 1;
                        v_message := v_message || 'Error when get purchasing old_category_id ' || SQLERRM || ';';
                  END;

                  IF (v_cat_set_id IS NOT NULL AND v_attribute_pur IS NOT NULL AND v_oldcat_id IS NOT NULL)
                  THEN
                     INSERT INTO mtl_item_categories_interface (item_number,
                                                                category_set_id,
                                                                category_id,
                                                                organization_id,
                                                                transaction_type,
                                                                process_flag,
                                                                set_process_id,
                                                                old_category_id)
                          VALUES (c.item_code,
                                  v_cat_set_id,
                                  v_attribute_pur,
                                  i.master_organization_id,
                                  'UPDATE',
                                  1,
                                  c.hdr_id,
                                  v_oldcat_id);
                  END IF;

                  IF (v_err = 0)
                  THEN
                     v_request_id :=
                        fnd_request.submit_request (application   => 'INV',
                                                    program       => 'INV_ITEM_CAT_ASSIGN_OI',
                                                    description   => NULL,
                                                    start_time    => NULL,
                                                    sub_request   => FALSE,
                                                    argument1     => c.hdr_id,
                                                    argument2     => 1,
                                                    argument3     => 1);
                     COMMIT;
                  END IF;

                  IF NVL (v_request_id, 0) = 0
                  THEN
                     logf ('Interface Assign Category submission failed');
                     logf (SQLCODE || '-' || SQLERRM);
                     v_err := 1;
                     v_message := v_message || 'Interface Assign Category submission failed ' || SQLERRM || ';';
                  ELSE
                     logf ('Request ID ' || v_request_id || ' has been submitted');
                     waitforrequest (v_request_id, v_status, v_errmsg);
                  END IF;

                  IF (UPPER (v_status) <> 'NORMAL')
                  THEN
                     logf ('Interface Assign Category submission failed : ' || v_status);
                     logf (v_errmsg || ' - ' || SQLERRM);
                     v_err := 1;
                     v_message := v_message || 'Interface Assign Category submission failed : ' || v_status || ' - ' || v_errmsg || ';';
                  ELSE
                     logf ('Interface Assign Category completed : ' || v_status);
                  END IF;
               END LOOP;
            ELSE
               logf ('No Data found');
            --v_err := 1;
            --v_message := v_message || 'No Data found;';
            END IF;
         ELSE
            logf ('Data found in MTL_ITEM_CATEGORIES_INTERFACE for set_process_id:' || p_req_no);
            v_err := 1;
            v_message := v_message || 'Data found in MTL_ITEM_CATEGORIES_INTERFACE for set_process_id:' || p_req_no || ';';
         END IF;

         IF (v_err = 0)
         THEN
            UPDATE xxshp_inv_item_indirect_hdr
               SET MESSAGE = NULL,
                   item_category_iface = NVL (item_category_iface, v_request_id),
                   inventory_category_id = NVL (inventory_category_id, v_attribute_inv),
                   purchasing_category_id = NVL (purchasing_category_id, v_attribute_pur),
                   last_update_date = SYSDATE,
                   last_updated_by = g_user_id,
                   last_update_login = g_login_id
             WHERE hdr_id = p_req_no;

            logf ('Interface Assign Category completed successfully');
         ELSIF (v_err = 1)
         THEN
            UPDATE xxshp_inv_item_indirect_hdr
               SET MESSAGE = v_message,
                   last_update_date = SYSDATE,
                   last_updated_by = g_user_id,
                   last_update_login = g_login_id
             WHERE hdr_id = p_req_no;

            v_error := 1;
         END IF;
      END LOOP;

      COMMIT;

      IF (v_error = 0)
      THEN
         p_return := 0;
      ELSE
         p_return := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submitting Interface Assign Category ' || SQLERRM);
         p_return := 1;
   END assign_category;

   PROCEDURE assign_org_item (p_req_no NUMBER, p_return OUT NUMBER)
   IS
      v_subinv_exist                   NUMBER;
      v_attribute3                     VARCHAR2 (240);
      v_request_id                     NUMBER;
      v_val                            NUMBER;
      v_status                         VARCHAR2 (100);
      v_errmsg                         VARCHAR2 (1000);
      v_err                            NUMBER := 0;
      v_error                          NUMBER := 0;
      v_message                        VARCHAR2 (1000);
      v_item_id                        NUMBER;
      v_PROCESS_COSTING_ENABLED_FLAG   VARCHAR2 (1);
   BEGIN
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_application_id);

      ----delete previous error transaction
      DELETE mtl_system_items_interface
       WHERE set_process_id = p_req_no AND global_attribute20 = 'XXSHP_INV_ITEM_INDIRECT';

      SELECT COUNT (1)
        INTO v_val
        FROM mtl_system_items_interface
       WHERE set_process_id = p_req_no;

      IF (v_val = 0)
      THEN
         SELECT COUNT (1)
           INTO v_val
           FROM xxshp_inv_item_indirect_hdr_v h, xxshp_inv_item_indirect_dtl_v d
          WHERE h.hdr_id = d.hdr_id AND h.hdr_id = p_req_no AND d.item_organization_iface IS NULL;

         IF (v_val > 0)
         THEN
            FOR c
               IN (SELECT d.hdr_id,
                          d.dtl_id,
                          d.assign_to_io_code,
                          d.assign_to_io,
                          d.flag_minmax,
                          d.min_qty,
                          d.max_qty,
                          d.item_organization_iface,
                          d.planner_code,
                          d.status,
                          d.MESSAGE,
                          h.item_temp,
                          h.item_description,
                          h.criteria2_id,
                          h.primary_uom,
                          h.expense_account_id,
                          h.template_id,
                          UPPER (mit.attribute2) attribute2,
                          UPPER (hou.TYPE) TYPE
                     FROM xxshp_inv_item_indirect_hdr_v h,
                          xxshp_inv_item_indirect_dtl_v d,
                          mtl_item_templates mit,
                          mtl_parameters mp,
                          HR_ORGANIZATION_UNITS hou
                    WHERE     h.hdr_id = d.hdr_id
                          AND h.hdr_id = p_req_no
                          AND h.template_id = mit.template_id(+)
                          AND d.assign_to_io = mp.organization_id
                          AND d.assign_to_io = hou.organization_id
                          AND d.item_organization_iface IS NULL)
            LOOP
               mo_global.set_policy_context ('S', c.assign_to_io);
               mo_global.init ('INV');
               logf ('Submit Interface Assign Organization Item for organization_id: ' || c.assign_to_io);
               v_subinv_exist := NULL;
               v_attribute3 := NULL;
               v_err := 0;
               v_message := NULL;

               SELECT COUNT (1)
                 INTO v_subinv_exist
                 FROM xxshp_inv_item_indirect_sub
                WHERE hdr_id = p_req_no AND ROWNUM = 1;

               /*BEGIN
                  SELECT ffv.attribute3
                    INTO v_attribute3
                    FROM fnd_flex_values ffv, fnd_flex_values_tl ffvt
                   WHERE ffv.flex_value_id = ffvt.flex_value_id
                     AND ffv.enabled_flag = 'Y'
                     AND SYSDATE BETWEEN NVL (ffv.start_date_active, SYSDATE) AND NVL (ffv.end_date_active, SYSDATE) + 1
                     AND ffv.flex_value_id = c.criteria2_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf ('Error when get attribute3 ' || SQLERRM);
                     v_attribute3 := NULL;
                     v_err := 1;
                     v_message := v_message || 'Error when get attribute3 ' || SQLERRM || ';';
               END;*/

               --IF (v_attribute3 IS NOT NULL)
               --THEN

               IF (c.attribute2 = 'YES' AND c.TYPE <> 'IOI')
               THEN
                  v_PROCESS_COSTING_ENABLED_FLAG := 'N';
               ELSE
                  v_PROCESS_COSTING_ENABLED_FLAG := 'Y';
               END IF;

               INSERT INTO mtl_system_items_interface (set_process_id,
                                                       organization_id,
                                                       item_number,
                                                       description,
                                                       primary_uom_code,
                                                       expense_account,
                                                       inventory_planning_code,
                                                       min_minmax_quantity,
                                                       max_minmax_quantity,                                                             --template_id,
                                                       transaction_type,
                                                       process_flag,
                                                       global_attribute20,
                                                       global_attribute19,
                                                       attribute_category,
                                                       template_id,
                                                       planner_code,
                                                       PROCESS_COSTING_ENABLED_FLAG)
                    VALUES (c.hdr_id,
                            c.assign_to_io,
                            c.item_temp,
                            c.item_description,
                            c.primary_uom,
                            c.expense_account_id,
                            DECODE (c.flag_minmax, 'Y', 2, 6),
                            c.min_qty,
                            c.max_qty,                                                                                                 --v_attribute3,
                            'CREATE',
                            1,
                            'XXSHP_INV_ITEM_INDIRECT',
                            c.dtl_id,
                            'Indirect',
                            c.template_id,
                            c.planner_code,
                            v_PROCESS_COSTING_ENABLED_FLAG);

               v_request_id :=
                  fnd_request.submit_request (application   => 'INV',
                                              program       => 'INCOIN',
                                              description   => NULL,
                                              start_time    => NULL,
                                              sub_request   => FALSE,
                                              argument1     => c.assign_to_io,                                                      -- Organization id
                                              argument2     => 1,                                                                 -- All organizations
                                              argument3     => 1,                                                                    -- Validate Items
                                              argument4     => 1,                                                                     -- Process Items
                                              argument5     => 1,                                                             -- Delete Processed Rows
                                              argument6     => c.hdr_id,                                                 -- Process Set (Null for All)
                                              argument7     => 1,                                                            -- Create or Update Items
                                              argument8     => 1                                                                  -- Gather Statistics
                                                                );
               COMMIT;

               IF NVL (v_request_id, 0) = 0
               THEN
                  logf ('Import Items submission failed');
                  logf (SQLCODE || '-' || SQLERRM);
                  v_err := 1;
                  v_message := v_message || 'Import Items submission failed ' || SQLERRM || ';';
               ELSE
                  logf ('Request ID ' || v_request_id || ' has been submitted');
                  waitforrequest (v_request_id, v_status, v_errmsg);
               END IF;

               IF (UPPER (v_status) <> 'NORMAL')
               THEN
                  logf ('Import Items submission failed : ' || v_status);
                  logf (v_errmsg || ' - ' || SQLERRM);
                  v_err := 1;
                  v_message := v_message || 'Import Items submission failed : ' || v_status || ' - ' || v_errmsg || ';';
               ELSE
                  logf ('Import Items submission completed : ' || v_status);

                  BEGIN
                     SELECT inventory_item_id
                       INTO v_item_id
                       FROM mtl_system_items_b
                      WHERE segment1 = c.item_temp AND organization_id = c.assign_to_io;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf ('Error when get inventory_item_id ' || SQLERRM);
                        v_err := 1;
                        v_message := v_message || 'Error when get inventory_item_id ' || SQLERRM || ';';
                  END;
               END IF;

               --END IF;
               IF (v_err = 0)
               THEN
                  UPDATE xxshp_inv_item_indirect_dtl
                     SET status = 'S',
                         MESSAGE = NULL,
                         item_organization_iface = NVL (item_organization_iface, v_request_id),
                         last_update_date = SYSDATE,
                         last_updated_by = g_user_id,
                         last_update_login = g_login_id
                   WHERE dtl_id = c.dtl_id;
               ELSIF (v_err = 1)
               THEN
                  UPDATE xxshp_inv_item_indirect_dtl
                     SET status = 'E',
                         MESSAGE = v_message,
                         last_update_date = SYSDATE,
                         last_updated_by = g_user_id,
                         last_update_login = g_login_id
                   WHERE dtl_id = c.dtl_id;

                  v_error := 1;
               END IF;
            END LOOP;
         ELSE
            logf ('No Data found');
         END IF;
      ELSE
         logf ('Data found in MTL_SYSTEM_ITEMS_INTERFACE for set_process_id:' || p_req_no);
         v_err := 1;
         v_message := v_message || 'Data found in MTL_SYSTEM_ITEMS_INTERFACE for set_process_id:' || p_req_no || ';';

         UPDATE xxshp_inv_item_indirect_dtl
            SET status = 'E',
                MESSAGE = v_message,
                last_update_date = SYSDATE,
                last_updated_by = g_user_id,
                last_update_login = g_login_id
          WHERE hdr_id = p_req_no AND item_organization_iface IS NULL;

         v_error := 1;
      END IF;

      COMMIT;

      IF (v_error = 0)
      THEN
         p_return := 0;
      ELSE
         p_return := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submitting Interface Assign Organization Item ' || SQLERRM);
         p_return := 1;
   END assign_org_item;

   PROCEDURE assign_item_subinv (p_req_no NUMBER, p_return OUT NUMBER)
   IS
      v_val       NUMBER;
      v_val2      NUMBER;
      v_err       NUMBER := 0;
      v_error     NUMBER := 0;
      v_message   VARCHAR2 (1000);
   BEGIN
      SELECT COUNT (1)
        INTO v_val
        FROM xxshp_inv_item_indirect_hdr_v h, xxshp_inv_item_indirect_dtl_v d, xxshp_inv_item_indirect_sub_v s
       WHERE h.hdr_id = d.hdr_id AND d.dtl_id = s.dtl_id AND s.item_subinv_iface IS NULL AND h.hdr_id = p_req_no;

      IF (v_val > 0)
      THEN
         FOR i IN (SELECT s.*,
                          h.item_code,
                          h.item_id,
                          d.assign_to_io,
                          d.assign_to_io_code
                     FROM xxshp_inv_item_indirect_hdr_v h, xxshp_inv_item_indirect_dtl_v d, xxshp_inv_item_indirect_sub_v s
                    WHERE h.hdr_id = d.hdr_id AND d.dtl_id = s.dtl_id AND s.item_subinv_iface IS NULL AND h.hdr_id = p_req_no)
         LOOP
            v_err := 0;
            v_message := NULL;

            SELECT COUNT (1)
              INTO v_val
              FROM mtl_item_sub_inventories
             WHERE inventory_item_id = i.item_id AND secondary_inventory = i.subinventory AND organization_id = i.assign_to_io;

            SELECT COUNT (1)
              INTO v_val2
              FROM mtl_secondary_inventories sub
             WHERE secondary_inventory_name = i.subinventory AND organization_id = i.assign_to_io AND NVL (disable_date, SYSDATE + 1 / 24) > SYSDATE;

            IF (v_val = 0 AND v_val2 > 0)
            THEN
               BEGIN
                  INSERT INTO mtl_item_sub_inventories (inventory_item_id,
                                                        organization_id,
                                                        secondary_inventory,
                                                        last_update_date,
                                                        last_updated_by,
                                                        creation_date,
                                                        created_by,
                                                        last_update_login,
                                                        inventory_planning_code)
                       VALUES (i.item_id,
                               i.assign_to_io,
                               i.subinventory,
                               SYSDATE,
                               g_user_id,
                               SYSDATE,
                               g_user_id,
                               g_login_id,
                               6);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf ('Error when inserting to mtl_item_sub_inventories ' || SQLERRM);
                     v_message := v_message || 'Error when inserting to mtl_item_sub_inventories ' || SQLERRM || ';';
                     v_err := 1;
               END;
            ELSE
               IF (v_val > 0)
               THEN
                  logf (
                        'Item '
                     || i.item_code
                     || ' already assigned to restrict subinventory '
                     || i.subinventory
                     || ' organization '
                     || i.assign_to_io_code);
                  v_message :=
                        'Item '
                     || i.item_code
                     || ' already assigned to restrict subinventory '
                     || i.subinventory
                     || ' organization '
                     || i.assign_to_io_code;
               END IF;

               IF (v_val2 = 0)
               THEN
                  v_err := 1;
                  logf ('Subinventory ' || i.subinventory || ' is not assigned to organization ' || i.assign_to_io_code);
                  v_message := v_message || 'Subinventory ' || i.subinventory || ' is not assigned to organization ' || i.assign_to_io_code || ';';
               END IF;
            END IF;

            IF (v_err = 0)
            THEN
               UPDATE xxshp_inv_item_indirect_sub
                  SET status = 'S',
                      MESSAGE = NULL,
                      item_subinv_iface = 'Y',
                      last_update_date = SYSDATE,
                      last_updated_by = g_user_id,
                      last_update_login = g_login_id
                WHERE sub_id = i.sub_id;

               logf (
                  'Complete assign item ' || i.item_code || ' to restrict subinventory ' || i.subinventory || ' organization ' || i.assign_to_io_code);
            ELSIF (v_err = 1)
            THEN
               UPDATE xxshp_inv_item_indirect_sub
                  SET status = 'E',
                      MESSAGE = v_message,
                      last_update_date = SYSDATE,
                      last_updated_by = g_user_id,
                      last_update_login = g_login_id
                WHERE sub_id = i.sub_id;

               v_error := 1;
            END IF;

            COMMIT;
         END LOOP;
      ELSE
         logf ('No Data found');
      END IF;

      IF (v_error = 0)
      THEN
         p_return := 0;
      ELSE
         p_return := 1;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submitting Program Assign Item to Restrict Subinventory ' || SQLERRM);
         p_return := 1;
   END assign_item_subinv;
END xxshp_inv_item_indirect_pkg;
/
