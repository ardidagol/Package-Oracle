CREATE OR REPLACE PACKAGE BODY APPS.XXGVN_INV_ITEMS_PLAN_PARAM_PKG
IS
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
      DBMS_OUTPUT.put_line (v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
      DBMS_OUTPUT.put_line (p_message);
   END;

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
      p_delim         IN     VARCHAR2 DEFAULT ',')
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER := 1;
      v_table      varchar2_table;
      v_delimpos   PLS_INTEGER := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0
      THEN
         logf ('Delimiter '','' not Found');
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

      CURSOR c_data
      IS
           SELECT xou.organization_code,
                  xou.segment1,
                  SUBSTR (xou.description, 1, 50) item_description,
                  xou.status,
                  SUBSTR (xou.error_message, 1, 200) error_message
             FROM xxgvn_inv_items_stg xou
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'N') = 'N'
                  AND file_id = p_file_id
         GROUP BY xou.organization_code,
                  xou.segment1,
                  SUBSTR (xou.description, 1, 50),
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
                  FROM xxgvn_inv_items_stg xou
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
      outf ('      ' || 'Upload Master Item status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || l_user_created_by);
      outf ('      ' || 'Proceed Date on : ' || l_creation_date);
      outF (
            '      '
         || '---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');
      outF (
            '      '
         || 'ORG  ITEM CODE        ITEM DESCRIPTION                                    STATUS ERROR MESSAGE                                                                                                           ');
      outF (
            '      '
         || '---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');

      FOR i IN c_data
      LOOP
         outF (
               '      '
            || RPAD (i.organization_code, 3, ' ')
            || '  '
            || RPAD (i.segment1, 15, ' ')
            || '  '
            || RPAD (i.item_description, 50, ' ')
            || '  '
            || RPAD (i.status, 5, ' ')
            || '  '
            || RPAD (i.error_message, 200, ' '));
      END LOOP;

      outF (
            '      '
         || '---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result;

   PROCEDURE process_data (p_file_id NUMBER)
   IS
      x_return_status          VARCHAR2 (2);
      x_msg_count              NUMBER := 0;
      x_msg_data               VARCHAR2 (2000);
      x_msg_data2              VARCHAR2 (2000);
      x_loop_cnt               NUMBER (10) := 0;
      x_dummy_cnt              NUMBER (10) := 0;
      x_msg_index_out          NUMBER;

      l_counter                NUMBER := 0;

      x_ledger_id              NUMBER := 0;
      x_chart_of_accounts_id   NUMBER := 0;
      v_description            mtl_system_items.description%TYPE;

      l_item_table             EGO_Item_PUB.Item_Tbl_Type;
      x_item_table             EGO_Item_PUB.Item_Tbl_Type;
      x_message_list           Error_Handler.Error_Tbl_Type;

      --i                        NUMBER := 1;

      l_error                  PLS_INTEGER := 0;
      l_conc_status            BOOLEAN;
   BEGIN
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      SELECT ledger_id, chart_of_accounts_id
        INTO x_ledger_id, x_chart_of_accounts_id
        FROM gl_ledgers
       WHERE 1 = 1 AND UPPER (ledger_category_code) = 'PRIMARY';

      FOR i IN c_items_stg (p_file_id)
      LOOP
         l_counter := l_counter + 1;

         SELECT description
           INTO v_description
           FROM mtl_system_items
          WHERE segment1 = i.segment1
                AND ROWNUM = 1;

         --FIRST Item definition
         l_item_table (1).transaction_type := 'UPDATE'; -- replace this with 'update' for update transaction or 'create' for create transaction.
         l_item_table (1).segment1 := i.segment1;
         l_item_table (1).description := v_description;
         l_item_table (1).organization_code := i.organization_code;
         l_item_table (1).primary_uom_code := i.primary_uom_code;
         l_item_table (1).minimum_order_quantity := i.minimum_order_quantity;
         l_item_table (1).attribute21 := i.attribute21;
         l_item_table (1).attribute22 := i.attribute22;
         l_item_table (1).attribute3 := i.attribute3;


         x_return_status := NULL;
         x_msg_count := NULL;
         x_msg_data := NULL;
         x_msg_data2 := NULL;
         x_loop_cnt := NULL;
         x_dummy_cnt := NULL;
         x_msg_index_out := NULL;

         logf ('=====================================');
         logf ('Calling EGO_ITEM_PUB.Process_Items API');
         ego_item_pub.process_items (p_api_version     => 1.0,
                                     p_init_msg_list   => FND_API.g_TRUE,
                                     p_commit          => FND_API.g_TRUE,
                                     p_Item_Tbl        => l_item_table,
                                     x_Item_Tbl        => x_item_table,
                                     x_return_status   => x_return_status,
                                     x_msg_count       => x_msg_count);
         logf ('==================================');
         logf ('Return Status ==>' || x_return_status);


         IF x_return_status = 'S'
         THEN
            UPDATE xxgvn_inv_items_stg
               SET status = 'S', flag = 'N'
             WHERE     1 = 1
                   AND segment1 = i.segment1
                   AND organization_code = i.organization_code
                   AND file_id = p_file_id;
         ELSE
            IF x_msg_count = 1
            THEN
               UPDATE xxgvn_inv_items_stg
                  SET error_message = SUBSTR (x_msg_data, 1, 2000),
                      status = 'E',
                      flag = 'N'
                WHERE     1 = 1
                      AND segment1 = i.segment1
                      AND organization_code = i.organization_code
                      AND file_id = p_file_id;
            ELSE
               FOR i IN 1 .. x_msg_count
               LOOP
                  fnd_msg_pub.get (p_msg_index       => i,
                                   p_data            => x_msg_data,
                                   p_encoded         => fnd_api.g_false,
                                   p_msg_index_out   => x_msg_index_out);

                  x_msg_data2 := x_msg_data2 || SUBSTR (x_msg_data, 1, 255);
               END LOOP;

               UPDATE xxgvn_inv_items_stg
                  SET error_message = SUBSTR (x_msg_data2, 1, 2000),
                      status = 'E',
                      flag = 'N'
                WHERE     1 = 1
                      AND segment1 = i.segment1
                      AND organization_code = i.organization_code
                      AND file_id = p_file_id;
            END IF;
         END IF;
      END LOOP;

      COMMIT;

      SELECT COUNT (*)
        INTO l_error
        FROM xxgvn_inv_items_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('API error count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('WARNING', 2);

         print_result (p_file_id);
      ELSE
         logf ('API Master Item successfully for all data..!!!');
      END IF;
   END;

   PROCEDURE final_validation (p_file_id NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;

      CURSOR c_notvalid_items
      IS
           SELECT file_id, status
             FROM xxgvn_inv_items_stg xou
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
         UPDATE xxgvn_inv_items_stg
            SET status = 'E', flag = 'N'
          WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

         COMMIT;
      END IF;

      SELECT COUNT (*)
        INTO l_error
        FROM xxgvn_inv_items_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('Error validation count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         print_result (p_file_id);

         logf ('Error, Master Item for data all ..!!!');
      ELSE
         logf ('Successfully, Master Item for data all ..!!!');
      END IF;
   END final_validation;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER)
   IS
      v_filename                 VARCHAR2 (50);
      v_blob_data                BLOB;
      v_blob_len                 NUMBER;
      v_position                 NUMBER;
      v_loop                     NUMBER;
      v_raw_chunk                RAW (10000);
      c_chunk_len                NUMBER := 1;
      v_char                     CHAR (1);
      v_line                     VARCHAR2 (32767) := NULL;
      v_tab                      VARCHAR2_TABLE;
      v_tablen                   NUMBER;
      x                          NUMBER;
      l_err                      NUMBER := 0;

      l_segment1                 VARCHAR2 (40);
      l_organization_code        VARCHAR2 (10);
      l_description              VARCHAR2 (240);
      l_primary_uom_code         VARCHAR2 (10);
      l_minimum_order_quantity   NUMBER;
      l_attribute3               VARCHAR2 (240);
      l_attribute21              VARCHAR2 (240);
      l_attribute22              VARCHAR2 (240);

      l_status                   VARCHAR2 (20);
      l_error_message            VARCHAR2 (200);

      l_err_cnt                  NUMBER;
      l_stg_cnt                  NUMBER := 0;
      l_cnt_err_format           NUMBER := 0;

      l_ledger_id                NUMBER := 0;
      l_org_id                   NUMBER := 0;
      l_chart_of_accounts_id     NUMBER := 0;

      l_set_process_id           NUMBER := 0;

      l_uom_code                 VARCHAR2 (10);
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

      BEGIN
         SELECT ledger_id, chart_of_accounts_id
           INTO l_ledger_id, l_chart_of_accounts_id
           FROM GL_LEDGERS
          WHERE 1 = 1 AND UPPER (ledger_category_code) = 'PRIMARY';
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

            --logf ('v_line: ' || v_line);

            delimstring_to_table (v_line,
                                  v_tab,
                                  x,
                                  v_tablen);

            --logf ('x : ' || x);
            IF x = 8
            THEN
               IF v_loop >= 2
               THEN
                  FOR i IN 1 .. x
                  LOOP
                     IF i = 1
                     THEN
                        l_segment1 := TRIM (v_tab (1));
                     ELSIF i = 2
                     THEN
                        l_organization_code := TRIM (v_tab (2));
                     ELSIF i = 3
                     THEN
                        l_description := TRIM (v_tab (3));
                     ELSIF i = 4
                     THEN
                        l_primary_uom_code := TRIM (v_tab (4));
                     ELSIF i = 5
                     THEN
                        l_minimum_order_quantity := TRIM (v_tab (5));
                     ELSIF i = 6
                     THEN
                        l_attribute3 := TRIM (v_tab (6));
                     ELSIF i = 7
                     THEN
                        l_attribute21 := TRIM (v_tab (7));
                     ELSIF i = 8
                     THEN
                        l_attribute22 := TRIM (v_tab (8));
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
                        WHERE     1 = 1
                              AND mp.organization_code = l_organization_code
                     GROUP BY mp.organization_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  --validasi primary_uom_code
                  BEGIN
                     l_uom_code := NULL;

                     SELECT uom_code
                       INTO l_uom_code
                       FROM mtl_units_of_measure
                      WHERE     1 = 1
                            AND uom_code = l_primary_uom_code
                            AND uom_class IN ('Weight',
                                              'Volume',
                                              'Count',
                                              'Length',
                                              'Area');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid primary_uom_code, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  --*/
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                    INTO l_status
                    FROM DUAL;

                  BEGIN
                     EXECUTE IMMEDIATE
                        'insert into xxgvn_inv_items_stg(
                            file_id                         ,
                            file_name                       ,
                            set_process_id                  ,
                            segment1                        ,
                            organization_code               ,
                            description                     ,
                            primary_uom_code                ,
                            minimum_order_quantity          ,
                            attribute21                     ,
                            attribute22                     ,
                            attribute3                      ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  )
                         VALUES(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18)'
                        USING p_file_id,
                              v_filename,
                              l_set_process_id,
                              l_segment1,
                              l_organization_code,
                              l_description,
                              l_primary_uom_code,
                              l_minimum_order_quantity,
                              l_attribute21,
                              l_attribute22,
                              l_attribute3,
                              l_status,
                              l_error_message,
                              g_user_id,
                              g_user_id,
                              SYSDATE,
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
                        'Wrong file,please check the comma delimiter has '
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

         final_validation (p_file_id);

         --/*
         SELECT COUNT (*)
           INTO l_stg_cnt
           FROM xxgvn_inv_items_stg
          WHERE 1 = 1 AND NVL (status, 'N') = 'N' AND file_id = p_file_id;

         IF NVL (l_stg_cnt, 0) > 0
         THEN
            process_data (p_file_id);
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
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Error others : ' || SQLERRM);
         logf (DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data;
END XXGVN_INV_ITEMS_PLAN_PARAM_PKG;
/