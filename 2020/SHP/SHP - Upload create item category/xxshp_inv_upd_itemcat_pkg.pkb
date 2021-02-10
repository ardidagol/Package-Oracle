/* Formatted on 10/23/2020 5:54:11 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE BODY APPS.xxshp_inv_upd_itemcat_pkg
AS
   PROCEDURE logf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
      --this function is based on one by Connor McDonald
      --http://www.jlcomp.demon.co.uk/faq/base_convert.html

      RETURN NUMBER
   IS
      v_dec   NUMBER;
      v_hex   VARCHAR2 (16) := '0123456789ABCDEF';
   BEGIN
      v_dec := 0;

      FOR indx IN 1 .. LENGTH (p_hex_str)
      LOOP
         v_dec :=
              v_dec * 16
            + INSTR (v_hex, UPPER (SUBSTR (p_hex_str, indx, 1)))
            - 1;
      END LOOP;

      RETURN v_dec;
   END hex_to_decimal;

   PROCEDURE delimstring_to_table (
      p_delimstring   IN     VARCHAR2,
      p_table            OUT varchar2_table,
      p_nfields          OUT INTEGER,
      p_a                OUT NUMBER,
      p_delim         IN     VARCHAR2 DEFAULT '|')
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER := 1;
      v_table      varchar2_table;
      v_delimpos   PLS_INTEGER := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0
      THEN
         logf ('Delimiter ''|'' not Found');
      END IF;

      WHILE v_delimpos > 0
      LOOP
         v_table (v_nfields) := SUBSTR (v_string, 1, v_delimpos - 1);
         v_string := SUBSTR (v_string, v_delimpos + v_delimlen);
         v_nfields := v_nfields + 1;
         v_delimpos := INSTR (v_string, p_delim);
      END LOOP;

      v_table (v_nfields) := v_string;
      p_table := v_table;
      p_nfields := v_nfields;
   END delimstring_to_table;

   PROCEDURE print_result (p_file_id NUMBER)
   IS
      l_user_created_by   VARCHAR (50);
      l_creation_date     VARCHAR (50);
      l_file_name         VARCHAR (100);

      l_error             PLS_INTEGER := 0;
      l_count             PLS_INTEGER := 0;
      l_conc_status       BOOLEAN;

      CURSOR c_data
      IS
           SELECT xou.org_code,
                  xou.item_code,
                  xou.category_set_name,
                  xou.status,
                  SUBSTR (xou.error_message, 1, 200) error_message
             FROM xxshp_inv_item_cats_stg xou
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'N') = 'N'
                  AND file_id = p_file_id
                  AND xou.error_message IS NOT NULL
         GROUP BY xou.org_code,
                  xou.item_code,
                  xou.category_set_name,
                  xou.status,
                  SUBSTR (xou.error_message, 1, 200);
   BEGIN
        SELECT file_name, user_created_by, creation_date
          INTO l_file_name, l_user_created_by, l_creation_date
          FROM (SELECT xou.file_name,
                       (SELECT user_name
                          FROM fnd_user
                         WHERE 1 = 1 AND user_id = xou.created_by)
                          user_created_by,
                       TO_CHAR (xou.creation_date, 'DD-MON-RR HH24:MI:SS')
                          creation_date
                  FROM xxshp_inv_item_cats_stg xou
                 WHERE     1 = 1
                       AND NVL (status, 'E') = 'E'
                       AND NVL (flag, 'N') = 'N'
                       AND file_id = p_file_id)
         WHERE 1 = 1 AND ROWNUM <= 1
      GROUP BY file_name, user_created_by, creation_date;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload item category status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || l_user_created_by);
      outf ('      ' || 'Proceed Date on : ' || l_creation_date);
      outF (
            '      '
         || '---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');
      outF (
            '      '
         || 'ORG  ITEM_CODE        CATEGORY NAME                             STATUS ERROR_MESSAGE                                                              ');
      outF (
            '      '
         || '---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');

      FOR i IN c_data
      LOOP
         outF (
               '      '
            || RPAD (i.org_code, 3, ' ')
            || '  '
            || RPAD (i.item_code, 15, ' ')
            || '  '
            || RPAD (i.category_set_name, 40, ' ')
            || '  '
            || RPAD (i.status, 5, ' ')
            || '  '
            || RPAD (i.error_message, 160, ' '));
      END LOOP;

      outF (
            '      '
         || '---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result;

   PROCEDURE assign_item_cat (errbuf         OUT VARCHAR2,
                              retcode        OUT NUMBER,
                              p_file_id   IN     NUMBER)
   IS
      l_itemcat             NUMBER := 0;

      l_msg_index_out       NUMBER;
      l_error_message       VARCHAR2 (2000);

      x_return_status       VARCHAR2 (80);
      x_errorcode           NUMBER;
      x_msg_count           NUMBER;
      x_msg_data            VARCHAR2 (250);

      i                     NUMBER := 1;

      l_category_id         NUMBER;
      l_category_set_id     NUMBER;
      l_inventory_item_id   NUMBER;
      l_organization_id     NUMBER;

      l_counter             NUMBER := 0;

      l_error               PLS_INTEGER := 0;
      l_conc_status         BOOLEAN;
   BEGIN
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      l_counter := 0;

      FOR dt IN c_items_stg (p_file_id)
      LOOP
         l_itemcat := l_itemcat + 1;

         l_organization_id := NULL;
         l_inventory_item_id := NULL;
         l_category_set_id := NULL;
         l_category_id := NULL;

         l_msg_index_out := 0;
         l_error_message := '';

         BEGIN
            SELECT mcs_tl.category_set_id
              INTO l_category_set_id
              FROM mtl_category_sets_tl mcs_tl
             WHERE mcs_tl.category_set_name = dt.category_set_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error get category set id ' || SQLERRM);
         END;

         IF l_category_set_id IS NOT NULL
         THEN
            IF dt.category_set_name = 'SHP_INVENTORY'            -- 6 segments
            THEN
               BEGIN
                  SELECT mcb.category_id
                    INTO l_category_id
                    FROM mtl_categories_b mcb
                   WHERE     1 = 1
                         AND NVL (mcb.segment1, dt.segment1) = dt.segment1
                         AND NVL (mcb.segment2, dt.segment2) = dt.segment2
                         AND NVL (mcb.segment3, dt.segment3) = dt.segment3
                         AND NVL (mcb.segment4, dt.segment4) = dt.segment4
                         AND NVL (mcb.segment5, dt.segment5) = dt.segment5
                         AND NVL (mcb.segment6, dt.segment6) = dt.segment6
                         AND mcb.structure_id =
                                (SELECT mcs.structure_id
                                   FROM mtl_category_sets_b mcs
                                  WHERE mcs.category_set_id =
                                           l_category_set_id)
                         AND mcb.segment1 IS NOT NULL
                         AND mcb.segment2 IS NOT NULL
                         AND mcb.segment3 IS NOT NULL
                         AND mcb.segment4 IS NOT NULL
                         AND mcb.segment5 IS NOT NULL
                         AND mcb.segment6 IS NOT NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf ('Error get category id SHP_INVENTORY ' || SQLERRM);
               END;
            ELSIF dt.category_set_name = 'SHP_PURCHASING_TYPE'   -- 4 segments
            THEN
               BEGIN
                  SELECT mcb.category_id
                    INTO l_category_id
                    FROM mtl_categories_b mcb
                   WHERE     1 = 1
                         AND NVL (mcb.segment1, dt.segment1) = dt.segment1
                         AND NVL (mcb.segment2, dt.segment2) = dt.segment2
                         AND NVL (mcb.segment3, dt.segment3) = dt.segment3
                         AND NVL (mcb.segment4, dt.segment4) = dt.segment4
                         AND mcb.structure_id =
                                (SELECT mcs.structure_id
                                   FROM mtl_category_sets_b mcs
                                  WHERE mcs.category_set_id =
                                           l_category_set_id)
                         AND mcb.segment1 IS NOT NULL
                         AND mcb.segment2 IS NOT NULL
                         AND mcb.segment3 IS NOT NULL
                         AND mcb.segment4 IS NOT NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf (
                           'Error get category id SHP_PURCHASING_TYPE '
                        || SQLERRM);
               END;
            ELSIF dt.category_set_name = 'SHP_PROCESS_GLCLASS'   -- 3 segments
            THEN
               BEGIN
                  SELECT mcb.category_id
                    INTO l_category_id
                    FROM mtl_categories_b mcb
                   WHERE     1 = 1
                         AND NVL (mcb.segment1, dt.segment1) = dt.segment1
                         AND NVL (mcb.segment2, dt.segment2) = dt.segment2
                         AND NVL (mcb.segment3, dt.segment3) = dt.segment3
                         AND mcb.structure_id =
                                (SELECT mcs.structure_id
                                   FROM mtl_category_sets_b mcs
                                  WHERE mcs.category_set_id =
                                           l_category_set_id)
                         AND mcb.segment1 IS NOT NULL
                         AND mcb.segment2 IS NOT NULL
                         AND mcb.segment3 IS NOT NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf (
                           'Error get category id SHP_PROCESS_GLCLASS '
                        || SQLERRM);
               END;
            ELSIF dt.category_set_name = 'SHP_WMS_CATEGORY'       -- 1 segment
            THEN
               BEGIN
                  SELECT mcb.category_id
                    INTO l_category_id
                    FROM mtl_categories_b mcb
                   WHERE     1 = 1
                         AND NVL (mcb.segment1, dt.segment1) = dt.segment1
                         AND mcb.structure_id =
                                (SELECT mcs.structure_id
                                   FROM mtl_category_sets_b mcs
                                  WHERE mcs.category_set_id =
                                           l_category_set_id)
                         AND mcb.segment1 IS NOT NULL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf (
                        'Error get category id SHP_WMS_CATEGORY ' || SQLERRM);
               END;
            END IF;
         END IF;

         BEGIN
            SELECT organization_id
              INTO l_organization_id
              FROM mtl_parameters
             WHERE organization_code = dt.org_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error get Organization id ' || SQLERRM);
         END;

         BEGIN
            SELECT inventory_item_id
              INTO l_inventory_item_id
              FROM mtl_system_items_b
             WHERE     1 = 1
                   AND segment1 = dt.item_code
                   AND organization_id = l_organization_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error get item id ' || SQLERRM);
         END;


         INV_ITEM_CATEGORY_PUB.create_category_assignment (
            p_api_version         => 1.0,
            p_init_msg_list       => fnd_api.g_false,
            p_commit              => fnd_api.g_false,
            x_return_status       => x_return_status,
            x_errorcode           => x_errorcode,
            x_msg_count           => x_msg_count,
            x_msg_data            => x_msg_data,
            p_category_id         => l_category_id,
            p_category_set_id     => l_category_set_id,
            p_inventory_item_id   => l_inventory_item_id,
            p_organization_id     => l_organization_id);

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            UPDATE xxshp_inv_item_cats_stg
               SET status = 'S', flag = 'N'
             WHERE     1 = 1
                   AND org_code = dt.org_code
                   AND item_code = dt.item_code
                   AND category_set_name = dt.category_set_name
                   AND file_id = p_file_id;
         ELSE
            FOR i IN 1 .. x_msg_count
            LOOP
               apps.fnd_msg_pub.get (p_msg_index       => i,
                                     p_encoded         => fnd_api.g_false,
                                     p_data            => x_msg_data,
                                     p_msg_index_out   => l_msg_index_out);

               IF l_error_message IS NULL
               THEN
                  l_error_message := SUBSTR (x_msg_data, 1, 250);
               ELSE
                  l_error_message :=
                     l_error_message || ' /' || SUBSTR (x_msg_data, 1, 250);
               END IF;
            END LOOP;


            UPDATE xxshp_inv_item_cats_stg
               SET status = 'E', flag = 'N', error_message = l_error_message
             WHERE     1 = 1
                   AND org_code = dt.org_code
                   AND item_code = dt.item_code
                   AND category_set_name = dt.category_set_name
                   AND file_id = p_file_id;
         END IF;
      END LOOP;



      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_inv_item_cats_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('API error count1 : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status :=
            fnd_concurrent.set_completion_status ('WARNING',
                                                  'Error assign category');

         print_result (p_file_id);
         retcode := 1;
         logf ('Error , API Assign item category for data all ...!!!');
      ELSE
         logf ('Successfully , API Assign item category for data all ...!!!');
      END IF;


      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error others assign category : ' || SQLERRM);
   END assign_item_cat;

   PROCEDURE create_item_cat (errbuf         OUT VARCHAR2,
                              retcode        OUT NUMBER,
                              p_file_id   IN     NUMBER)
   IS
      l_category_rec      INV_ITEM_CATEGORY_PUB.CATEGORY_REC_TYPE;
      l_structure_id      NUMBER;

      l_msg_index_out     NUMBER;
      l_error_message     VARCHAR2 (2000);

      x_return_status     VARCHAR2 (80);
      x_errorcode         NUMBER;
      x_msg_count         NUMBER;
      x_msg_data          VARCHAR2 (250);
      x_out_category_id   NUMBER;

      i                   NUMBER := 1;

      l_counter           NUMBER := 0;

      l_error             PLS_INTEGER := 0;
      l_conc_status       BOOLEAN;
   BEGIN
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      FOR dt IN c_cat_create (p_file_id)
      LOOP
         l_counter := l_counter + 1;

         l_msg_index_out := 0;
         l_error_message := '';

         SELECT f.ID_FLEX_NUM
           INTO l_structure_id
           FROM FND_ID_FLEX_STRUCTURES f
          WHERE f.ID_FLEX_STRUCTURE_CODE = dt.category_set_name;


         l_category_rec := NULL;
         l_category_rec.structure_id := l_structure_id;
         l_category_rec.summary_flag := 'N';
         l_category_rec.enabled_flag := 'Y';
         l_category_rec.segment1 := dt.segment1;
         l_category_rec.segment2 := dt.segment2;
         l_category_rec.segment3 := dt.segment3;
         l_category_rec.segment4 := dt.segment4;
         l_category_rec.segment5 := dt.segment5;
         l_category_rec.segment6 := dt.segment6;

         logf ('Call API Create_Category');
         INV_ITEM_CATEGORY_PUB.Create_Category (
            p_api_version     => 1.0,
            p_init_msg_list   => FND_API.G_FALSE,
            p_commit          => FND_API.G_TRUE,
            x_return_status   => x_return_status,
            x_errorcode       => x_errorcode,
            x_msg_count       => x_msg_count,
            x_msg_data        => x_msg_data,
            p_category_rec    => l_category_rec,
            x_category_id     => x_out_category_id);

         IF (x_return_status = fnd_api.g_ret_sts_success)
         THEN
            UPDATE xxshp_inv_item_cats_stg
               SET status = 'S', flag = 'N'
             WHERE     1 = 1
                   AND category_set_name = dt.category_set_name
                   AND NVL (segment1, dt.segment1) = dt.segment1
                   AND NVL (segment2, dt.segment2) = dt.segment2
                   AND NVL (segment3, dt.segment3) = dt.segment3
                   AND NVL (segment4, dt.segment4) = dt.segment4
                   AND NVL (segment5, dt.segment5) = dt.segment5
                   AND NVL (segment6, dt.segment6) = dt.segment6
                   AND file_id = p_file_id;
         ELSE
            FOR i IN 1 .. x_msg_count
            LOOP
               apps.fnd_msg_pub.get (p_msg_index       => i,
                                     p_encoded         => fnd_api.g_false,
                                     p_data            => x_msg_data,
                                     p_msg_index_out   => l_msg_index_out);

               IF l_error_message IS NULL
               THEN
                  l_error_message := SUBSTR (x_msg_data, 1, 250);
               ELSE
                  l_error_message :=
                     l_error_message || ' /' || SUBSTR (x_msg_data, 1, 250);
               END IF;
            END LOOP;

            UPDATE xxshp_inv_item_cats_stg
               SET status = 'E', flag = 'N', error_message = l_error_message
             WHERE     1 = 1
                   AND category_set_name = dt.category_set_name
                   AND NVL (segment1, dt.segment1) = dt.segment1
                   AND NVL (segment2, dt.segment2) = dt.segment2
                   AND NVL (segment3, dt.segment3) = dt.segment3
                   AND NVL (segment4, dt.segment4) = dt.segment4
                   AND NVL (segment5, dt.segment5) = dt.segment5
                   AND NVL (segment6, dt.segment6) = dt.segment6
                   AND file_id = p_file_id;
         END IF;
      END LOOP;

      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_inv_item_cats_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('API error count1 : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status :=
            fnd_concurrent.set_completion_status ('WARNING',
                                                  'Error Create Category');

         print_result (p_file_id);
         retcode := 1;
         logf ('Error , API Create item category for data all ...!!!');
      ELSE
         logf ('Successfully , API Create item category for data all ...!!!');
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error others create category : ' || SQLERRM);
   END create_item_cat;

   PROCEDURE final_validation (errbuf         OUT VARCHAR2,
                               retcode        OUT NUMBER,
                               p_file_id   IN     NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;


      CURSOR c_notvalid_items
      IS
           SELECT file_id, status
             FROM xxshp_inv_item_cats_stg xou
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'Y') = 'Y'
                  AND file_id = p_file_id
         GROUP BY file_id, status;
   BEGIN
      l_jml_data := 0;

      FOR i IN c_notvalid_items
      LOOP
         EXIT WHEN c_notvalid_items%NOTFOUND;

         l_jml_data := l_jml_data + 1;

         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      END IF;

      IF l_nextproceed
      THEN
         UPDATE xxshp_inv_item_cats_stg
            SET status = 'E', flag = 'N'
          WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

         COMMIT;
      END IF;

      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_inv_item_cats_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('Error validation count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         print_result (p_file_id);
         retcode := 2;

         logf ('Error, Update Item Categories for data all ..!!!');
      ELSE
         logf ('Successfully, Update Item Categories for data all ..!!!');
      END IF;
   END final_validation;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER)
   IS
      v_filename            VARCHAR2 (50);
      v_plan_name           VARCHAR2 (50);
      v_blob_data           BLOB;
      v_blob_len            NUMBER;
      v_position            NUMBER;
      v_loop                NUMBER;
      v_raw_chunk           RAW (10000);
      c_chunk_len           NUMBER := 1;
      v_char                CHAR (1);
      v_line                VARCHAR2 (32767) := NULL;
      v_tab                 VARCHAR2_TABLE;
      v_tablen              NUMBER;
      x                     NUMBER;
      l_err                 NUMBER := 0;

      l_org_code            VARCHAR2 (10);
      l_item_code           VARCHAR2 (20);
      l_category_set_name   VARCHAR2 (30);

      l_segment1            VARCHAR2 (50);
      l_segment2            VARCHAR2 (50);
      l_segment3            VARCHAR2 (50);
      l_segment4            VARCHAR2 (50);
      l_segment5            VARCHAR2 (50);
      l_segment6            VARCHAR2 (50);

      l_comments            VARCHAR2 (200);
      l_status              VARCHAR2 (20);
      l_error_message       VARCHAR2 (200);

      l_err_cnt             NUMBER;
      l_stg_cnt             NUMBER := 0;
      l_item_cnt            NUMBER := 0;
      l_cnt_err_format      NUMBER := 0;
      l_sql                 VARCHAR2 (32767);

      l_org_id              NUMBER := 0;
      l_inventory_item_id   NUMBER := 0;
      l_sub_inv_code        VARCHAR2 (10);
      l_status_code         VARCHAR2 (20);

      l_category_set_id     NUMBER;
      l_category_id         NUMBER;
   BEGIN
      BEGIN
         SELECT file_data, file_name
           INTO v_blob_data, v_filename
           FROM fnd_lobs
          WHERE 1 = 1 AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;

      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len)
      LOOP
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10)
         THEN
            IF v_position <> v_blob_len
            THEN
               v_line :=
                  REPLACE (
                     REPLACE (
                        SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1),
                        CHR (13),
                        ''),
                     CHR (10),
                     '');
            END IF;

            delimstring_to_table (v_line,
                                  v_tab,
                                  x,
                                  v_tablen,
                                  '|');

            --logf ('x : ' || x);
            IF x = 9
            THEN
               IF v_loop >= 2
               THEN
                  FOR i IN 1 .. x
                  LOOP
                     IF i = 1
                     THEN
                        l_org_code := TRIM (v_tab (1));
                     ELSIF i = 2
                     THEN
                        l_item_code := TRIM (v_tab (2));
                     ELSIF i = 3
                     THEN
                        l_category_set_name := TRIM (v_tab (3));
                     ELSIF i = 4
                     THEN
                        l_segment1 := TRIM (v_tab (4));
                     ELSIF i = 5
                     THEN
                        l_segment2 := TRIM (v_tab (5));
                     ELSIF i = 6
                     THEN
                        l_segment3 := TRIM (v_tab (6));
                     ELSIF i = 7
                     THEN
                        l_segment4 := TRIM (v_tab (7));
                     ELSIF i = 8
                     THEN
                        l_segment5 := TRIM (v_tab (8));
                     ELSIF i = 9
                     THEN
                        l_segment6 := TRIM (v_tab (9));
                     END IF;
                  END LOOP;


                  l_err_cnt := 0;
                  l_error_message := NULL;


                  --validasi org_code
                  BEGIN
                     l_org_id := NULL;

                       SELECT mp.organization_id
                         INTO l_org_id
                         FROM mtl_parameters mp
                        WHERE 1 = 1 AND mp.organization_code = l_org_code
                     GROUP BY mp.organization_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;


                  --/*
                  --validasi item

                  BEGIN
                     l_inventory_item_id := NULL;

                     SELECT msi.inventory_item_id
                       INTO l_inventory_item_id
                       FROM mtl_system_items msi
                      WHERE     1 = 1
                            AND msi.organization_id = l_org_id
                            AND msi.segment1 = l_item_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                              l_error_message
                           || ', Item code : '
                           || l_item_code
                           || ' no exist in Organization : '
                           || l_org_code;
                        l_err_cnt := l_err_cnt + 1;
                  END;


                  BEGIN
                     l_category_set_id := NULL;

                     SELECT mcs_tl.category_set_id
                       INTO l_category_set_id
                       FROM mtl_category_sets_tl mcs_tl
                      WHERE mcs_tl.category_set_name = l_category_set_name;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                              l_error_message
                           || ', Invalid category_set_name : '
                           || l_category_set_name;
                        l_err_cnt := l_err_cnt + 1;
                  END;


                  IF l_category_set_id IS NOT NULL
                  THEN
                     IF l_category_set_name = 'SHP_INVENTORY'    -- 6 segments
                     THEN
                        IF l_segment1 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment1';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment2 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment2';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment3 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment3';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment4 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment4';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment5 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment5';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment6 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment6';
                           l_err_cnt := l_err_cnt + 1;
                        END IF;
                     ELSIF l_category_set_name = 'SHP_PURCHASING_TYPE' -- 4 segments
                     THEN
                        IF l_segment1 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment1';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment2 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment2';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment3 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment3';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment4 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment4';
                           l_err_cnt := l_err_cnt + 1;
                        END IF;
                     ELSIF l_category_set_name = 'SHP_PROCESS_GLCLASS' -- 3 segments
                     THEN
                        IF l_segment1 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment1';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment2 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment2';
                           l_err_cnt := l_err_cnt + 1;
                        ELSIF l_segment3 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment3';
                           l_err_cnt := l_err_cnt + 1;
                        END IF;
                     ELSIF l_category_set_name = 'SHP_WMS_CATEGORY' -- 1 segment
                     THEN
                        IF l_segment1 IS NULL
                        THEN
                           l_error_message :=
                              l_error_message || ', Invalid Segment1';
                           l_err_cnt := l_err_cnt + 1;
                        END IF;
                     END IF;
                  END IF;

                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                    INTO l_status
                    FROM DUAL;

                  --insert to staging
                  BEGIN
                     EXECUTE IMMEDIATE
                        'insert into xxshp_inv_item_cats_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            item_code                       ,
                            category_set_name               ,
                            segment1                        ,
                            segment2                        ,
                            segment3                        ,
                            segment4                        ,
                            segment5                        ,
                            segment6                        ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            creation_date                   ,
                            last_updated_by                 ,
                            last_update_date                ,
                            last_update_login               )
                         VALUES(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18)'
                        USING p_file_id,
                              v_filename,
                              l_org_code,
                              l_item_code,
                              l_category_set_name,
                              l_segment1,
                              l_segment2,
                              l_segment3,
                              l_segment4,
                              l_segment5,
                              l_segment6,
                              l_status,
                              l_error_message,
                              g_user_id,
                              SYSDATE,
                              g_user_id,
                              SYSDATE,
                              g_login_id;
                  --COMMIT;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len
               THEN
                  logf ('Upload File Finished');
               ELSE
                  logf (
                        'Wrong file,please check the pipeline delimiter has '
                     || x
                     || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);

      IF l_err > 0
      THEN
         ROLLBACK;
         logf (
               'File: '
            || v_filename
            || ' has 0 rows inserting to staging table, ROLLBACK');

         retcode := 2;
      ELSE
         COMMIT;
         logf (
               'File: '
            || v_filename
            || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan

         final_validation (errbuf, retcode, p_file_id);

         --/*
         BEGIN
            SELECT COUNT (*)
              INTO l_stg_cnt
              FROM xxshp_inv_item_cats_stg
             WHERE 1 = 1 AND NVL (status, 'N') = 'N' AND file_id = p_file_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Staging error');
         END;

         IF NVL (l_stg_cnt, 0) > 0
         THEN
            logf ('Call Procedure create_item_cat.');
            create_item_cat (errbuf, retcode, p_file_id);

            logf ('Call procedure assign_item_cat.');
            assign_item_cat (errbuf, retcode, p_file_id);
         END IF;

         UPDATE fnd_lobs
            SET expiration_date = SYSDATE, upload_date = SYSDATE
          WHERE 1 = 1 AND file_id = p_file_id;
      --*/

      END IF;
   --print_result(p_file_id);

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         logf ('error no data found6');
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Error others : ' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data;
END xxshp_inv_upd_itemcat_pkg;
/