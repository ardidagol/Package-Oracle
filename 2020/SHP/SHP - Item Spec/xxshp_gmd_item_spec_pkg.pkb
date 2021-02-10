CREATE OR REPLACE PACKAGE BODY APPS.xxshp_gmd_item_spec_pkg
/* $Header: xxshp_gmd_item_spec_pkg.pkb 122.5.1.0 2016/11/10 11:38:00 Farry Ciptono $ */
AS
   /******************************************************************************
       NAME: xxshp_gmd_item_spec_pkg
       PURPOSE:

       REVISIONS:
       Ver         Date            Author              Description
       ---------   ----------      ---------------       ------------------------------------
       1.0         28-Nov-2016     Farry Ciptono         1. Created this package.
       1.1         28-Nov-2016     Ardianto             1. Add Spec Detail
      ******************************************************************************/
   v_tlog   tlog_type;
   log_no   NUMBER := 0;

   PROCEDURE logf (p_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_char);
   END logf;

   PROCEDURE outf (p_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_char);
   END outf;

   PROCEDURE get_error_msg (p_msg_count IN NUMBER, p_msg_index IN OUT NUMBER, x_msg_data OUT VARCHAR2)
   IS
      v_msg             VARCHAR2 (2000);
      v_data            VARCHAR2 (2000);
      v_msg_index_out   NUMBER;
   BEGIN
      FOR i IN 1 .. p_msg_count - p_msg_index
      LOOP
         fnd_msg_pub.get (p_msg_index       => (p_msg_index + 1),
                          p_encoded         => 'F',
                          p_data            => v_data,
                          p_msg_index_out   => v_msg_index_out);
         v_msg := SUBSTR (v_msg || ',' || v_data, 1, 2000);
         EXIT WHEN i = 1;
      END LOOP;

      p_msg_index := v_msg_index_out;
      x_msg_data := v_msg;
   END get_error_msg;

   PROCEDURE validate_spec (p_process_id NUMBER, p_status OUT VARCHAR2, p_message OUT VARCHAR2)
   IS
      v_val              NUMBER;
      v_val2             NUMBER;
      v_message          VARCHAR2 (1000);
      v_err              NUMBER := 0;
      e_exception        EXCEPTION;
      v_min_value_num    NUMBER;
      v_max_value_num    NUMBER;
      v_test_type        VARCHAR2 (1);
      v_spec_type        VARCHAR2 (1);
      v_test_method_id   NUMBER;

      CURSOR c_data
      IS
         SELECT *
           FROM xxshp_gmd_item_spec_stg
          WHERE (status IN ('E', 'P') OR status IS NULL) AND process_id = p_process_id;
   BEGIN
      SELECT COUNT (1)
        INTO v_val
        FROM xxshp_gmd_item_spec_stg
       WHERE (status IN ('E', 'P') OR status IS NULL) AND process_id = p_process_id;

      IF (v_val > 0)
      THEN
         ----reset error message
         UPDATE xxshp_gmd_item_spec_stg
            SET MESSAGE = NULL,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE process_id = p_process_id;

         FOR i IN c_data
         LOOP
            v_message := NULL;

            -----validate if spec already exists
            SELECT COUNT (1)
              INTO v_val
              FROM gmd_specifications
             WHERE spec_name = i.spec_name AND spec_vers = i.spec_vers;

            IF (v_val > 0)
            THEN
               v_message := v_message || 'Error spec name and vers already exists;';
               v_err := 1;
            END IF;

            ---validate spec type
            IF (i.spec_type NOT IN ('I', 'M'))
            THEN
               v_message := v_message || 'Error invalid spec type;';
               v_err := 1;
            END IF;

            ----validate test
            BEGIN
               SELECT 1
                 INTO v_val
                 FROM gmd_qc_tests
                WHERE test_id = i.test_id;

               SELECT test_type
                 INTO v_test_type
                 FROM gmd_qc_tests
                WHERE test_id = i.test_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := v_message || 'Error when validate Test ID ' || SQLERRM || ';';
                  v_err := 1;
            END;

            ----validate test method
            BEGIN
               SELECT 1
                 INTO v_val
                 FROM gmd_test_methods_b
                WHERE test_method_id = i.test_method_id;

               SELECT test_method_id
                 INTO v_test_method_id
                 FROM gmd_qc_tests
                WHERE test_id = i.test_id;

               IF (v_test_method_id <> i.test_method_id)
               THEN
                  v_message := v_message || 'Error Test Method ID in Staging is not equal to OPM Tests ' || SQLERRM || ';';
                  v_err := 1;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_message := v_message || 'Error when validate Test Method ID ' || SQLERRM || ';';
                  v_err := 1;
            END;

            ----validate master item
            ---if found then item common
            IF (i.spec_type = 'I')
            THEN
               SELECT COUNT (1)
                 INTO v_val
                 FROM mtl_system_items_b
                WHERE segment1 = i.item_code AND organization_id = i.owner_organization_id;

               IF (v_val = 0)
               THEN
                  ---if found then item pecah KN
                  SELECT COUNT (1)
                    INTO v_val
                    FROM mtl_system_items_b
                   WHERE attribute11 = i.item_code AND organization_id = i.owner_organization_id AND segment1 LIKE i.item_code || '%';

                  IF (v_val = 0)
                  THEN
                     v_message := v_message || 'Error when validate Item Master ' || SQLERRM || ';';
                     v_err := 1;
                  END IF;
               END IF;
            END IF;

            ---validate item test range
            IF (v_test_type = 'N')
            THEN
               BEGIN
                  SELECT min_value_num, max_value_num
                    INTO v_min_value_num, v_max_value_num
                    FROM gmd_qc_tests
                   WHERE test_id = i.test_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_message := v_message || 'Error when retrieve min and max value num ' || SQLERRM || ';';
                     v_err := 1;
               END;

               /*IF (i.target_value_num IS NULL)
               THEN
                  v_message := v_message || 'Error Target value num can not be null;';
                  v_err := 1;
               END IF;*/
               IF (i.target_value_num IS NOT NULL AND (i.target_value_num NOT BETWEEN i.min_value_num AND i.max_value_num))
               THEN
                  v_message := v_message || 'Error Target value num should be between min and max value num range;';
                  v_err := 1;
               END IF;

               IF (i.min_value_num < v_min_value_num)
               THEN
                  v_message := v_message || 'Error Spec Min value num must be greater than Test Min value;';
                  v_err := 1;
               END IF;

               IF (i.max_value_num > v_max_value_num)
               THEN
                  v_message := v_message || 'Error Spec Max value num must be less than Test Max value;';
                  v_err := 1;
               END IF;
            ELSE
               IF (i.target_value_char IS NULL)                                             --OR i.min_value_char IS NULL OR i.max_value_char IS NULL)
               THEN
                  --v_message := v_message || 'Error Target value char/ Min value/ Max value char can not be null;';
                  v_message := v_message || 'Error Target value char can not be null;';
                  v_err := 1;
               /*ELSIF (i.min_value_char IS NULL AND i.max_value_char IS NOT NULL)
               THEN
                  v_message := v_message || 'Error Min value char can not be null;';
                  v_err := 1;
               ELSIF (i.min_value_char IS NOT NULL AND i.max_value_char IS NULL)
               THEN
                  v_message := v_message || 'Error Max value char can not be null;';
                  v_err := 1;*/
               END IF;
            END IF;

            ---validate qty and UOM
            /*IF (i.test_qty IS NULL)
            THEN
               v_message := v_message || 'Error Test Quantity can not be null;';
               v_err := 1;
            END IF;

            IF (i.test_qty_uom IS NULL)
            THEN
               v_message := v_message || 'Error Test Quantity UOM can not be null;';
               v_err := 1;
            END IF;*/

            -----update status
            BEGIN
               IF (v_message IS NULL)
               THEN
                  UPDATE xxshp_gmd_item_spec_stg
                     SET status = 'P',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE row_id = i.row_id;
               ELSE
                  UPDATE xxshp_gmd_item_spec_stg
                     SET status = 'E',
                         MESSAGE = MESSAGE || v_message,
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE row_id = i.row_id;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf ('Error when update status for row_id: ' || i.row_id || ' ' || SQLERRM || ';');
                  v_message := v_message || 'Error when update status for row_id: ' || i.row_id || ' ' || SQLERRM || ';';
                  v_err := 1;
            END;
         END LOOP;

         IF (v_err = 1)
         THEN
            p_status := 'E';
         ELSE
            p_status := 'S';
         END IF;

         COMMIT;
      ELSE
         logf ('No data found for process_id: ' || p_process_id);
         p_message := 'No data found for process_id: ' || p_process_id;
         p_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := 'E';
         p_message := 'Error when run validate_spec ' || SQLERRM;
   END validate_spec;

   PROCEDURE item_spec_iface (errbuf OUT VARCHAR2, retcode OUT NUMBER, p_process_id NUMBER)
   IS
      v_process_id               NUMBER;
      v_tlog                     tlog_type;
      log_no                     NUMBER := 0;
      x_status                   VARCHAR2 (1);
      x_message                  VARCHAR2 (2000);
      v_spec_rec                 gmd_specifications%ROWTYPE;
      v_spec_tests_tbl           gmd_spec_pub.spec_tests_tbl;
      x_spec_rec                 gmd_specifications%ROWTYPE;
      x_spec_tests_tbl           gmd_spec_pub.spec_tests_tbl;
      x_return_status            VARCHAR2 (1);
      x_msg_count                NUMBER;
      x_msg_data                 VARCHAR2 (2000);
      v_msg_index_out            NUMBER;
      v_valid                    BOOLEAN;
      v_invalid_cnt              NUMBER;
      v_index                    NUMBER;
      v_processed_specs          NUMBER;
      v_processed_spec_tests     NUMBER;
      v_success_specs_cnt        NUMBER;
      v_success_spec_tests_cnt   NUMBER;
      v_failed_specs_cnt         NUMBER;
      v_failed_spec_tests_cnt    NUMBER;
      v_test_id_tmp              NUMBER;
      v_test_type                VARCHAR2 (1);
      v_test_method_id           NUMBER;
      v_test_display_precision   NUMBER;
      v_test_report_precision    NUMBER;
      v_test_min_num             NUMBER;
      v_test_max_num             NUMBER;
      v_number_tmp               NUMBER;
      v_err_m                    VARCHAR2 (4000);
      v_lerr_m                   VARCHAR2 (4000);
      v_exists                   VARCHAR2 (100);
      v_debug_step               VARCHAR2 (100);
      v_test                     BOOLEAN := TRUE;
      v_inventory_item_id        NUMBER;
      v_err                      NUMBER := 0;
      v_val                      NUMBER;
      e_exception                EXCEPTION;
      v_pecah_kn                 VARCHAR2 (1);

      CURSOR c_spec
      IS
           SELECT process_id,
                  interface_id,
                  spec_name,
                  spec_vers,
                  spec_desc,
                  spec_type,
                  item_code,
                  spec_status,
                  owner_organization_id,
                  owner_id
             FROM xxshp_gmd_item_spec_stg
            WHERE (status IN ('E', 'P') OR status IS NULL) AND process_id = p_process_id
         GROUP BY process_id,
                  interface_id,
                  spec_name,
                  spec_vers,
                  spec_desc,
                  spec_type,
                  item_code,
                  spec_status,
                  owner_organization_id,
                  owner_id;

      CURSOR c_spec_test (v_process_id NUMBER, v_interface_id NUMBER)
      IS
         SELECT *
           FROM xxshp_gmd_item_spec_stg
          WHERE (status IN ('E', 'P') OR status IS NULL) AND process_id = p_process_id AND interface_id = v_interface_id;
   BEGIN
      logf ('Start');

      SELECT COUNT (1)
        INTO v_val
        FROM xxshp_gmd_item_spec_stg
       WHERE (status IN ('E', 'P') OR status IS NULL) AND process_id = p_process_id;

      IF (v_val > 0)
      THEN
         validate_spec (p_process_id, x_status, x_message);
         logf ('Spec validation completed with status: ' || x_status || ' ' || x_message);

         IF (x_status = 'S')
         THEN
            FOR i IN c_spec
            LOOP
               IF (i.spec_type = 'I')
               THEN
                  BEGIN
                     ---if found then item common
                     SELECT inventory_item_id
                       INTO v_inventory_item_id
                       FROM mtl_system_items_b
                      WHERE segment1 = i.item_code AND organization_id = i.owner_organization_id;

                     v_pecah_kn := 'N';
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        ---if found then item pecah KN
                        BEGIN
                           SELECT DISTINCT 1
                             INTO v_val
                             FROM mtl_system_items_b
                            WHERE attribute11 = i.item_code AND organization_id = i.owner_organization_id;

                           v_pecah_kn := 'Y';
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              logf ('Error when retrieve Inventory_Item_ID ' || SQLERRM);
                              v_err := 1;
                              RAISE e_exception;
                        END;
                  END;
               ELSE
                  v_inventory_item_id := NULL;
               END IF;

               IF (v_pecah_kn = 'N' OR i.spec_type = 'M')
               THEN
                  logf ('Creating spec ' || TRIM (i.spec_name));
                  v_spec_rec := NULL;
                  v_spec_tests_tbl.DELETE;
                  x_spec_rec := NULL;
                  x_spec_tests_tbl.DELETE;
                  v_spec_rec.inventory_item_id := v_inventory_item_id;
                  v_spec_rec.spec_name := TRIM (i.spec_name);
                  v_spec_rec.spec_vers := i.spec_vers;
                  v_spec_rec.spec_desc := TRIM (i.spec_desc);
                  v_spec_rec.spec_type := i.spec_type;
                  v_spec_rec.spec_status := i.spec_status;
                  v_spec_rec.delete_mark := 0;
                  v_spec_rec.owner_organization_id := i.owner_organization_id;
                  v_spec_rec.owner_id := i.owner_id;
                  --v_spec_rec.attribute10 := c_specs.attribute10;
                  --v_spec_rec.attribute11 := c_specs.attribute11;
                  v_index := 0;
                  log_no := log_no + 1;

                  FOR j IN c_spec_test (i.process_id, i.interface_id)
                  LOOP
                     v_index := v_index + 1;
                     v_spec_tests_tbl (v_index).seq := j.seq;
                     v_spec_tests_tbl (v_index).test_id := j.test_id;
                     v_spec_tests_tbl (v_index).test_method_id := j.test_method_id;
                     v_spec_tests_tbl (v_index).test_qty := j.test_qty;
                     v_spec_tests_tbl (v_index).test_qty_uom := j.test_qty_uom;
                     v_spec_tests_tbl (v_index).test_replicate := j.test_replicate;
                     v_spec_tests_tbl (v_index).test_priority := j.test_priority;
                     v_spec_tests_tbl (v_index).display_precision := j.stored_precision;
                     v_spec_tests_tbl (v_index).report_precision := j.report_precision;
                     v_spec_tests_tbl (v_index).target_value_num := j.target_value_num;
                     v_spec_tests_tbl (v_index).min_value_num := j.min_value_num;
                     v_spec_tests_tbl (v_index).max_value_num := j.max_value_num;
                     v_spec_tests_tbl (v_index).target_value_char := j.target_value_char;
                     v_spec_tests_tbl (v_index).min_value_char := j.min_value_char;
                     v_spec_tests_tbl (v_index).max_value_char := j.max_value_char;
                     --v_spec_tests_tbl (v_index).attribute1 := j.parameter_type;
                     --v_spec_tests_tbl (v_index).attribute2 := j.analyzed_by;
                     v_spec_tests_tbl (v_index).attribute3 := j.parameter_type;
                     v_spec_tests_tbl (v_index).attribute4 := j.analyzed_by;
                     --v_spec_tests_tbl (v_index).attribute3 := j.MONITORING;
                     --v_spec_tests_tbl (v_index).attribute4 := j.info_idc;
                     v_spec_tests_tbl (v_index).attribute5 := j.repeat;
                     v_spec_tests_tbl (v_index).attribute6 := j.spec_detail;  -- Add AAR 26 AUG 2020
                  END LOOP;

                  ----------Create spec
                  gmd_spec_pub.create_spec (p_api_version      => 2,
                                            p_spec             => v_spec_rec,
                                            p_spec_tests_tbl   => v_spec_tests_tbl,
                                            p_user_name        => g_user_name,
                                            x_spec             => x_spec_rec,
                                            x_spec_tests_tbl   => x_spec_tests_tbl,
                                            x_return_status    => x_return_status,
                                            x_msg_count        => x_msg_count,
                                            x_msg_data         => x_msg_data);
                  logf ('Record processed with status : ' || x_return_status);

                  IF x_return_status = 'S'
                  THEN
                     v_tlog (log_no).process_id := p_process_id;
                     v_tlog (log_no).interface_id := i.interface_id;
                     v_tlog (log_no).status := 'S';
                  ELSE
                     v_failed_specs_cnt := v_failed_specs_cnt + 1;

                     FOR i IN 1 .. x_msg_count
                     LOOP
                        fnd_msg_pub.get (p_msg_index       => i,
                                         p_encoded         => 'F',
                                         p_data            => x_msg_data,
                                         p_msg_index_out   => v_msg_index_out);
                        DBMS_OUTPUT.put_line ('Error Text ' || x_msg_data);
                     END LOOP;

                     logf ('API Message : ' || x_msg_data);

                     IF x_msg_count - v_msg_index_out > 0
                     THEN
                        get_error_msg (x_msg_count, v_msg_index_out, x_msg_data);
                     END IF;

                     v_tlog (log_no).process_id := p_process_id;
                     v_tlog (log_no).interface_id := i.interface_id;
                     v_tlog (log_no).status := 'E';
                     v_tlog (log_no).MESSAGE := x_msg_data;
                     v_err := 1;
                  END IF;
               ELSIF (v_pecah_kn = 'Y' AND i.spec_type = 'I')
               THEN
                  FOR n
                     IN (  SELECT ffv.flex_value
                             FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
                            WHERE     ffvs.flex_value_set_id = ffv.flex_value_set_id
                                  AND ffvs.flex_value_set_name = 'XXSHP_TYPE_KN'
                                  AND ffv.enabled_flag = 'Y'
                         ORDER BY ffv.flex_value)
                  LOOP
                     BEGIN
                        SELECT inventory_item_id
                          INTO v_inventory_item_id
                          FROM mtl_system_items_b
                         WHERE     attribute11 = i.item_code
                               AND organization_id = i.owner_organization_id
                               AND segment1 LIKE i.item_code || '.' || n.flex_value;

                        v_pecah_kn := 'Y';
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           logf ('Error when retrieve Inventory_Item_ID pecah KN ' || SQLERRM);
                           v_err := 1;
                           RAISE e_exception;
                     END;

                     logf ('Creating Spec ' || TRIM (i.spec_name) || '.' || n.flex_value);
                     v_spec_rec := NULL;
                     v_spec_tests_tbl.DELETE;
                     x_spec_rec := NULL;
                     x_spec_tests_tbl.DELETE;
                     v_spec_rec.inventory_item_id := v_inventory_item_id;
                     v_spec_rec.spec_name := TRIM (i.spec_name) || '.' || n.flex_value;
                     v_spec_rec.spec_vers := i.spec_vers;
                     v_spec_rec.spec_desc := TRIM (i.spec_desc);
                     v_spec_rec.spec_type := i.spec_type;
                     v_spec_rec.spec_status := i.spec_status;
                     v_spec_rec.delete_mark := 0;
                     v_spec_rec.owner_organization_id := i.owner_organization_id;
                     v_spec_rec.owner_id := i.owner_id;
                     --v_spec_rec.attribute10 := c_specs.attribute10;
                     --v_spec_rec.attribute11 := c_specs.attribute11;
                     v_index := 0;
                     log_no := log_no + 1;

                     FOR j IN c_spec_test (i.process_id, i.interface_id)
                     LOOP
                        v_index := v_index + 1;
                        v_spec_tests_tbl (v_index).seq := j.seq;
                        v_spec_tests_tbl (v_index).test_id := j.test_id;
                        v_spec_tests_tbl (v_index).test_method_id := j.test_method_id;
                        v_spec_tests_tbl (v_index).test_qty := j.test_qty;
                        v_spec_tests_tbl (v_index).test_qty_uom := j.test_qty_uom;
                        v_spec_tests_tbl (v_index).test_replicate := j.test_replicate;
                        v_spec_tests_tbl (v_index).test_priority := j.test_priority;
                        v_spec_tests_tbl (v_index).display_precision := j.stored_precision;
                        v_spec_tests_tbl (v_index).report_precision := j.report_precision;
                        v_spec_tests_tbl (v_index).target_value_num := j.target_value_num;
                        v_spec_tests_tbl (v_index).min_value_num := j.min_value_num;
                        v_spec_tests_tbl (v_index).max_value_num := j.max_value_num;
                        v_spec_tests_tbl (v_index).target_value_char := j.target_value_char;
                        v_spec_tests_tbl (v_index).min_value_char := j.min_value_char;
                        v_spec_tests_tbl (v_index).max_value_char := j.max_value_char;
                        v_spec_tests_tbl (v_index).attribute3 := j.parameter_type;
                        v_spec_tests_tbl (v_index).attribute4 := j.analyzed_by;
                        --v_spec_tests_tbl (v_index).attribute3 := j.MONITORING;
                        --v_spec_tests_tbl (v_index).attribute4 := j.info_idc;
                        v_spec_tests_tbl (v_index).attribute5 := j.repeat;
                        v_spec_tests_tbl (v_index).attribute6 := j.spec_detail;  -- Add AAR 26 AUG 2020
                     END LOOP;

                     ----------Create spec
                     gmd_spec_pub.create_spec (p_api_version      => 2,
                                               p_spec             => v_spec_rec,
                                               p_spec_tests_tbl   => v_spec_tests_tbl,
                                               p_user_name        => g_user_name,
                                               x_spec             => x_spec_rec,
                                               x_spec_tests_tbl   => x_spec_tests_tbl,
                                               x_return_status    => x_return_status,
                                               x_msg_count        => x_msg_count,
                                               x_msg_data         => x_msg_data);
                     logf ('Record processed with status : ' || x_return_status);

                     IF x_return_status = 'S'
                     THEN
                        v_tlog (log_no).process_id := p_process_id;
                        v_tlog (log_no).interface_id := i.interface_id;
                        v_tlog (log_no).status := 'S';
                     ELSE
                        v_failed_specs_cnt := v_failed_specs_cnt + 1;

                        FOR i IN 1 .. x_msg_count
                        LOOP
                           fnd_msg_pub.get (p_msg_index       => i,
                                            p_encoded         => 'F',
                                            p_data            => x_msg_data,
                                            p_msg_index_out   => v_msg_index_out);
                           DBMS_OUTPUT.put_line ('Error Text ' || x_msg_data);
                        END LOOP;

                        logf ('API Message : ' || x_msg_data);

                        IF x_msg_count - v_msg_index_out > 0
                        THEN
                           get_error_msg (x_msg_count, v_msg_index_out, x_msg_data);
                        END IF;

                        v_tlog (log_no).process_id := p_process_id;
                        v_tlog (log_no).interface_id := i.interface_id;
                        v_tlog (log_no).status := 'E';
                        v_tlog (log_no).MESSAGE := x_msg_data;
                        v_err := 1;
                     END IF;
                  END LOOP;
               END IF;
            END LOOP;

            IF (v_err = 0)
            THEN
               retcode := 0;
               logf ('All records processed successfully');

               UPDATE xxshp_gmd_item_spec_stg
                  SET status = 'S',
                      last_updated_by = g_user_id,
                      last_update_date = SYSDATE,
                      last_update_login = g_login_id
                WHERE process_id = p_process_id;

               COMMIT;
            ELSIF (v_err = 1)
            THEN
               retcode := 2;
               logf ('Error found when processing process_id: ' || p_process_id);
               ROLLBACK;

               FOR i IN 1 .. v_tlog.COUNT
               LOOP
                  IF (v_tlog (i).status = 'E')
                  THEN
                     UPDATE xxshp_gmd_item_spec_stg
                        SET status = v_tlog (i).status,
                            MESSAGE = MESSAGE || v_tlog (i).MESSAGE,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE process_id = p_process_id AND interface_id = v_tlog (i).interface_id;
                  ELSE
                     UPDATE xxshp_gmd_item_spec_stg
                        SET status = 'P',
                            MESSAGE = MESSAGE || v_tlog (i).MESSAGE,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE process_id = p_process_id AND interface_id = v_tlog (i).interface_id;
                  END IF;
               END LOOP;

               COMMIT;
            END IF;
         ELSE
            retcode := 2;
            logf ('Please check error message in staging table XXSHP_GMD_ITEM_SPEC_STG');
         END IF;
      ELSE
         retcode := 1;
         logf ('Data not found');
      END IF;

      logf ('End');
   EXCEPTION
      WHEN e_exception
      THEN
         retcode := 2;
      WHEN OTHERS
      THEN
         logf ('Error when run item_spec_iface ' || SQLERRM);
         retcode := 2;
   END item_spec_iface;
END xxshp_gmd_item_spec_pkg;
/
