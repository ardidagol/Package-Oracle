/* Formatted on 11/3/2020 9:38:16 AM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE BODY APPS.xxshp_inv_upload_mpn_pkg
AS
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
      p_delim         IN     VARCHAR2 DEFAULT ';')
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER := 1;
      v_table      varchar2_table;
      v_delimpos   PLS_INTEGER := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0
      THEN
         logf ('Delimiter '';'' not Found');
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

   PROCEDURE print_result1 (p_file_id NUMBER)
   IS
      l_user_created_by   VARCHAR (50);
      l_creation_date     VARCHAR (50);
      l_file_name         VARCHAR (100);
      l_batch_no          VARCHAR (100);

      CURSOR c_data_mfg
      IS
           SELECT manufacturer_name,
                  description,
                  country,
                  factory_code,
                  comments,
                  mfg_status,
                  vendor_name,
                  vendor_site_code
             FROM xxshp_inv_mfg_parts_stg ximp
            WHERE 1 = 1 AND file_id = p_file_id
         GROUP BY manufacturer_name,
                  description,
                  country,
                  factory_code,
                  comments,
                  mfg_status,
                  vendor_name,
                  vendor_site_code;

      CURSOR c_data_mpn (
         p_manufacturer_name    VARCHAR2)
      IS
         SELECT mfg_part_num,
                item_code,
                org_code,
                allergen_num,
                allergen_valid_to,
                certificate_md_num,
                certificate_md_valid_to,
                akasia_num,
                prod_qm_version,
                prod_qm_valid_to,
                organic_certificate_num,
                organic_certificate_valid_to,
                organic_body,
                need_halal_certificate,
                halal_certificate_num,
                halal_certificate_valid_to,
                halal_logo,
                halal_body
           FROM xxshp_inv_mfg_parts_stg ximp
          WHERE     1 = 1
                AND file_id = p_file_id
                AND manufacturer_name = p_manufacturer_name;
   BEGIN
        SELECT file_name, user_created_by, creation_date
          INTO l_file_name, l_user_created_by, l_creation_date
          FROM (SELECT ximp.file_name,
                       (SELECT user_name
                          FROM fnd_user
                         WHERE 1 = 1 AND user_id = ximp.created_by)
                          user_created_by,
                       TO_CHAR (ximp.creation_date, 'DD-MON-RR HH24:MI:SS')
                          creation_date
                  FROM xxshp_inv_mfg_parts_stg ximp
                 WHERE 1 = 1 AND file_id = p_file_id)
         WHERE 1 = 1 AND ROWNUM <= 1
      GROUP BY file_name, user_created_by, creation_date;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Master Item status report');
      outf (' ');
      outf ('      ' || 'Batch No        : ' || l_batch_no);
      outf ('      ' || 'Proceed By      : ' || l_user_created_by);
      outf ('      ' || 'Proceed Date on : ' || l_creation_date);
      outF (
            '      '
         || '---------------- --------------------------------------------------- ----------------------- ----------------------- -----------------------------------');

      outF (
            '      '
         || 'manufacturer_name        description                                       mfg_status          vendor_name                 vendor_site_code              ');
      outF (
            '      '
         || '---------------- --------------------------------------------------- ----------------------- ----------------------- ------------------------------------');

      FOR i IN c_data_mfg
      LOOP
         -- Header
         outF (
               '      '
            || RPAD (i.manufacturer_name, 15, ' ')
            || '  '
            || RPAD (i.description, 50, ' ')
            || '  '
            || RPAD (i.mfg_status, 22, ' ')
            || '  '
            || RPAD (i.vendor_name, 22, ' ')
            || '  '
            || RPAD (i.vendor_site_code, 22, ' '));


         -- Line
         outF (
               '      '
            || '---------------- ---------------------------- ----------------------- ----------------------- ----------------- ----------------- ------------------------- ---------------------');

         outF (
               '      '
            || 'MFG_PART_NUM        ITEM_CODE                 ALLERGEN_NUM           CERTIFICATE_MD_NUM      AKASIA_NUM        PROD_QM_VERSION   ORGANIC_CERTIFICATE_NUM   HALAL_CERTIFICATE_NUM');
         outF (
               '      '
            || '---------------- ---------------------------- ----------------------- ----------------------- ----------------- ----------------- ------------------------- ---------------------');

         FOR c IN c_data_mpn (i.manufacturer_name)
         LOOP
            outF (
                  '      '
               || RPAD (c.mfg_part_num, 15, ' ')
               || '  '
               || RPAD (c.item_code, 50, ' ')
               || '  '
               || RPAD (c.allergen_num, 22, ' ')
               || '  '
               || RPAD (c.certificate_md_num, 22, ' ')
               || '  '
               || RPAD (c.akasia_num, 22, ' ')
               || '  '
               || RPAD (c.prod_qm_version, 22, ' ')
               || '  '
               || RPAD (c.organic_certificate_num, 22, ' ')
               || '  '
               || RPAD (c.halal_certificate_num, 22, ' '));
         END LOOP;

         outF (
               '      '
            || '---------------- ---------------------------- ----------------------- ----------------------- ----------------- ----------------- ------------------------- ---------------------');
      END LOOP;

      outF (
            '      '
         || '---------------- --------------------------------------------------- ----------------------- ----------------------- ------------------------------------');

      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result1;

   PROCEDURE print_result (p_file_id NUMBER)
   IS
      l_user_created_by   VARCHAR (50);
      l_creation_date     VARCHAR (50);
      l_file_name         VARCHAR (100);

      CURSOR c_data_mfg
      IS
           SELECT manufacturer_name,
                  description,
                  vendor_name,
                  vendor_site_code,
                  SUBSTR (message_manufacturer, 1, 200) error_message
             FROM xxshp_inv_mfg_parts_stg ximp
            WHERE     1 = 1
                  AND NVL (status_manufacturer, 'E') = 'E'
                  AND NVL (flag, 'N') = 'N'
                  AND file_id = p_file_id
         GROUP BY manufacturer_name,
                  description,
                  vendor_name,
                  vendor_site_code,
                  SUBSTR (message_manufacturer, 1, 200);

      CURSOR c_data_mpn (
         p_manufacturer_name    VARCHAR2)
      IS
         SELECT mfg_part_num,
                item_code,
                org_code,
                allergen_num,
                certificate_md_num,
                akasia_num,
                organic_certificate_num,
                halal_certificate_num,
                SUBSTR (message_mpn, 1, 200) error_message
           FROM xxshp_inv_mfg_parts_stg ximp
          WHERE     1 = 1
                AND NVL (status_mpn, 'E') = 'E'
                AND NVL (flag, 'N') = 'N'
                AND file_id = p_file_id
                AND manufacturer_name = p_manufacturer_name;
   BEGIN
        SELECT file_name, user_created_by, creation_date
          INTO l_file_name, l_user_created_by, l_creation_date
          FROM (SELECT ximp.file_name,
                       (SELECT user_name
                          FROM fnd_user
                         WHERE 1 = 1 AND user_id = ximp.created_by)
                          user_created_by,
                       TO_CHAR (ximp.creation_date, 'DD-MON-RR HH24:MI:SS')
                          creation_date
                  FROM xxshp_inv_mfg_parts_stg ximp
                 WHERE     1 = 1
                       AND NVL (status_manufacturer, 'E') = 'E'
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
         || '------------------ --------------------------------------------------- ------------------------------- ---------------------------- ----------------------------------------------------------------------------');

      outF (
            '      '
         || 'MANUFACTURER_NAME        DESCRIPTION                                   VENDOR_NAME                     VENDOR_SITE_CODE             ERROR MESSAGE                                                               ');
      outF (
            '      '
         || '------------------ --------------------------------------------------- ------------------------------- ---------------------------- ----------------------------------------------------------------------------');

      FOR i IN c_data_mfg
      LOOP
         outF (
               '      '
            || RPAD (i.manufacturer_name, 17, ' ')
            || '  '
            || RPAD (i.description, 50, ' ')
            || '  '
            || RPAD (i.vendor_name, 30, ' ')
            || '  '
            || RPAD (i.vendor_site_code, 27, ' ')
            || '  '
            || RPAD (i.error_message, 200, ' '));

         -- Line

         outF (' ');
         outF ('      /* Detail */');

         outF (
               '            '
            || '---------------- ------------------ ------------------------------------------------');

         outF (
               '            '
            || 'MFG_PART_NUM     ITEM_CODE          ERROR MESSAGE                                   ');
         outF (
               '            '
            || '---------------- ------------------ ------------------------------------------------');

         FOR c IN c_data_mpn (i.manufacturer_name)
         LOOP
            outF (
                  '            '
               || RPAD (c.mfg_part_num, 15, ' ')
               || '  '
               || RPAD (c.item_code, 17, ' ')
               || '  '
               || RPAD (c.error_message, 22, ' '));
         END LOOP;

         outF (
               '            '
            || '---------------- ------------------ ------------------------------------------------');
         outF ('      /* Detail */');
         outF (' ');
      END LOOP;

      outF (
            '      '
         || '------------------ --------------------------------------------------- ------------------------------- ---------------------------- ----------------------------------------------------------------------------');

      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result;

   PROCEDURE create_mfg_part_numbers (p_file_id IN NUMBER)
   /*
        Created by EY on 15-Mar-2017

        History Update:
   */
   IS
      v_count           NUMBER;
      v_mfg_id          NUMBER;
      v_master_io       NUMBER;
      v_item_id         NUMBER;
      v_split_kn_flag   VARCHAR2 (1);
      v_item_code       mtl_system_items_kfv.concatenated_segments%TYPE;
      v_supply_type     xxshp_inv_master_item_reg.supply_type%TYPE;
      v_validate        NUMBER;

      l_conc_status     BOOLEAN;

      CURSOR cur_mfg
      IS
           SELECT manufacturer_group,
                  manufacturer_name,
                  description,
                  country,
                  factory_code,
                  comments,
                  mfg_status,
                  vendor_name,
                  vendor_id,
                  vendor_site_code,
                  vendor_site_id
             FROM xxshp_inv_mfg_parts_stg xim
            WHERE xim.file_id = p_file_id
         GROUP BY manufacturer_group,
                  manufacturer_name,
                  description,
                  country,
                  factory_code,
                  comments,
                  mfg_status,
                  vendor_name,
                  vendor_id,
                  vendor_site_code,
                  vendor_site_id;

      CURSOR cur_mfg_part (
         p_mfg_group    VARCHAR2)
      IS
         SELECT ROWID mfg_part_rid,
                mfg_part_num,
                item_code,
                org_code,
                allergen_num,
                allergen_valid_to,
                certificate_md_num,
                certificate_md_valid_to,
                akasia_num,
                prod_qm_version,
                prod_qm_valid_to,
                organic_certificate_num,
                organic_certificate_valid_to,
                organic_body,
                need_halal_certificate,
                halal_certificate_num,
                halal_certificate_valid_to,
                halal_logo,
                halal_body,
                status_mpn,
                message_mpn
           FROM xxshp_inv_mfg_parts_stg ximpn
          WHERE     ximpn.file_id = p_file_id
                AND manufacturer_group = p_mfg_group;
   BEGIN
      SELECT COUNT (1)
        INTO v_validate
        FROM xxshp_inv_mfg_parts_stg
       WHERE file_id = p_file_id;

      IF (v_validate = 0)
      THEN
         logf ('No row to process');
      ELSE
         FOR c IN cur_mfg
         LOOP
            BEGIN
               SELECT COUNT (1)
                 INTO v_count
                 FROM mtl_manufacturers mm
                WHERE mm.manufacturer_name = c.manufacturer_name;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_count := 0;
            END;

            IF v_count > 0
            THEN
               logf (
                     'Manufacturer : '
                  || c.manufacturer_name
                  || ' already exists');

               UPDATE xxshp_inv_mfg_parts_stg
                  SET status_manufacturer = 'E',
                      message_manufacturer =
                            'Manufacturer : '
                         || c.manufacturer_name
                         || ' already exists',
                      last_update_date = SYSDATE,
                      last_updated_by = g_user_id,
                      last_update_login = g_login_id
                WHERE     file_id = p_file_id
                      AND manufacturer_name = c.manufacturer_name
                      AND manufacturer_group = c.manufacturer_group;

               BEGIN
                  SELECT manufacturer_id
                    INTO v_mfg_id
                    FROM mtl_manufacturers mm
                   WHERE mm.manufacturer_name = c.manufacturer_name;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     logf ('Failed when get manufacturer_id ' || SQLERRM);
               END;
            ELSE
               SELECT mtl_manufacturers_s.NEXTVAL INTO v_mfg_id FROM DUAL;

               logf ('Inserting manufacturer_id: ' || v_mfg_id);

               INSERT INTO mtl_manufacturers (manufacturer_id,
                                              manufacturer_name,
                                              last_update_date,
                                              last_updated_by,
                                              creation_date,
                                              created_by,
                                              description,
                                              attribute2,
                                              attribute3,
                                              attribute8,
                                              attribute1,
                                              attribute12,
                                              attribute13,
                                              attribute5)
                    VALUES (v_mfg_id,
                            c.manufacturer_name,
                            SYSDATE,
                            g_user_id,
                            SYSDATE,
                            g_user_id,
                            c.description,
                            c.country,
                            c.factory_code,
                            c.comments,
                            c.mfg_status,
                            TO_CHAR (c.vendor_id),
                            TO_CHAR (c.vendor_site_id),
                            2                                     -- default N
                             );



               UPDATE xxshp_inv_mfg_parts_stg
                  SET status = 'S',
                      last_update_date = SYSDATE,
                      last_updated_by = g_user_id,
                      last_update_login = g_login_id
                WHERE     file_id = p_file_id
                      AND manufacturer_name = c.manufacturer_name
                      AND manufacturer_group = c.manufacturer_group;
            END IF;


            IF (v_mfg_id IS NOT NULL)
            THEN
               FOR cp IN cur_mfg_part (c.manufacturer_group)
               LOOP
                  BEGIN
                       SELECT inventory_item_id, master_organization_id
                         INTO v_item_id, v_master_io
                         FROM mtl_parameters mp, mtl_system_items msi
                        WHERE     mp.organization_id = msi.organization_id
                              AND msi.segment1 = cp.item_code
                              AND mp.organization_code = cp.org_code
                     GROUP BY inventory_item_id, master_organization_id;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        --logf ('Error get item id ' || SQLERRM);
                        NULL;
                  END;

                  SELECT COUNT (1)
                    INTO v_count
                    FROM mtl_mfg_part_numbers
                   WHERE     organization_id = v_master_io
                         AND manufacturer_id = v_mfg_id
                         AND inventory_item_id = v_item_id
                         AND mfg_part_num = cp.mfg_part_num;


                  IF (v_count > 0)
                  THEN
                     logf (
                           'Manufacturer part number : '
                        || cp.mfg_part_num
                        || ' already exists');

                     UPDATE xxshp_inv_mfg_parts_stg
                        SET status_mpn = 'E',
                            message_mpn =
                               SUBSTR (
                                     message_mpn
                                  || 'Duplicate Manufacturer Part Number '
                                  || CHR (10),
                                  1,
                                  2000)
                      WHERE     ROWID = cp.mfg_part_rid
                            AND manufacturer_group = c.manufacturer_group;
                  ELSE
                     INSERT INTO mtl_mfg_part_numbers (manufacturer_id,
                                                       mfg_part_num,
                                                       inventory_item_id,
                                                       last_update_date,
                                                       last_updated_by,
                                                       creation_date,
                                                       created_by,
                                                       organization_id,
                                                       attribute3,
                                                       attribute2,
                                                       attribute4,
                                                       attribute5,
                                                       attribute6,
                                                       attribute7,
                                                       attribute8,
                                                       attribute13,
                                                       attribute14,
                                                       attribute15,
                                                       attribute_category,
                                                       attribute9,
                                                       attribute10,
                                                       attribute11,
                                                       attribute12)
                             VALUES (
                                       v_mfg_id,
                                       cp.mfg_part_num,
                                       v_item_id,
                                       SYSDATE,
                                       g_user_id,
                                       SYSDATE,
                                       g_user_id,
                                       v_master_io,
                                       cp.allergen_num,
                                       fnd_date.date_to_canonical (
                                          cp.allergen_valid_to),
                                       cp.certificate_md_num,
                                       fnd_date.date_to_canonical (
                                          cp.certificate_md_valid_to),
                                       cp.akasia_num,
                                       cp.prod_qm_version,
                                       fnd_date.date_to_canonical (
                                          cp.prod_qm_valid_to),
                                       cp.organic_certificate_num,
                                       fnd_date.date_to_canonical (
                                          cp.organic_certificate_valid_to),
                                       cp.organic_body,
                                       cp.need_halal_certificate,
                                       cp.halal_certificate_num,
                                       fnd_date.date_to_canonical (
                                          cp.halal_certificate_valid_to),
                                       cp.halal_logo,
                                       cp.halal_body);

                     UPDATE xxshp_inv_mfg_parts_stg
                        SET status = 'S',
                            last_update_date = SYSDATE,
                            last_updated_by = g_user_id,
                            last_update_login = g_login_id
                      WHERE     ROWID = cp.mfg_part_rid
                            AND manufacturer_group = c.manufacturer_group;
                  END IF;
               END LOOP;
            END IF;
         END LOOP;

         UPDATE xxshp_inv_mfg_parts_stg
            SET status = 'S'
          WHERE file_id = p_file_id;

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error on create_mfg_part_numbers: ' || SQLERRM);

         UPDATE xxshp_inv_mfg_parts_stg
            SET status = 'E'
          WHERE file_id = p_file_id;

         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);
   END create_mfg_part_numbers;

   PROCEDURE final_validation (p_file_id NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;

      CURSOR c_notvalid_items
      IS
           SELECT file_id, status
             FROM xxshp_inv_mfg_parts_stg ximp
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
         UPDATE xxshp_inv_mfg_parts_stg ximp
            SET status = 'E', flag = 'N'
          WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

         COMMIT;
      END IF;

      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_inv_mfg_parts_stg ximp
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('Error validation count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         print_result (p_file_id);

         logf ('Error, for data all ..!!!');
      ELSE
         logf ('Successfully, for data all ..!!!');
      --print_result1(p_file_id);
      END IF;
   END final_validation;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER)
   IS
      v_filename                       VARCHAR2 (50);
      v_blob_data                      BLOB;
      v_blob_len                       NUMBER;
      v_position                       NUMBER;
      v_loop                           NUMBER;
      v_raw_chunk                      RAW (10000);
      c_chunk_len                      NUMBER := 1;
      v_char                           CHAR;
      v_line                           VARCHAR2 (32767) := NULL;
      v_tab                            VARCHAR2_TABLE;
      v_tablen                         NUMBER;
      x                                NUMBER;
      l_err                            NUMBER := 0;

      v_vendor_id                      NUMBER;
      v_vendor_site_id                 NUMBER;

      L_manufacturer_group             VARCHAR2 (250);
      l_manufacturer_name              VARCHAR2 (250);
      l_description                    VARCHAR2 (250);
      l_country                        VARCHAR2 (250);
      l_factory_code                   VARCHAR2 (250);
      l_comments                       VARCHAR2 (250);
      l_mfg_status                     VARCHAR2 (250);
      l_vendor_name                    VARCHAR2 (250);
      l_vendor_site_code               VARCHAR2 (250);
      l_mfg_part_num                   VARCHAR2 (250);
      l_item_code                      VARCHAR2 (250);
      l_org_code                       VARCHAR2 (250);
      l_allergen_num                   VARCHAR2 (250);
      l_allergen_valid_to              VARCHAR2 (150);
      l_certificate_md_num             VARCHAR2 (250);
      l_certificate_md_valid_to        VARCHAR2 (150);
      l_akasia_num                     VARCHAR2 (250);
      l_prod_qm_version                VARCHAR2 (250);
      l_prod_qm_valid_to               VARCHAR2 (150);
      l_organic_certificate_num        VARCHAR2 (250);
      l_organic_certificate_valid_to   VARCHAR2 (150);
      l_organic_body                   VARCHAR2 (250);
      l_need_halal_certificate         VARCHAR2 (250);
      l_halal_certificate_num          VARCHAR2 (250);
      l_halal_certificate_valid_to     VARCHAR2 (150);
      l_halal_logo                     VARCHAR2 (250);
      l_halal_body                     VARCHAR2 (250);
      l_status_manufacturer            VARCHAR2 (1);
      l_message_manufacturer           VARCHAR2 (300);
      l_status_mpn                     VARCHAR2 (1);
      l_message_mpn                    VARCHAR2 (300);

      l_status                         VARCHAR2 (1);
      l_err_cnt                        NUMBER;
      l_stg_cnt                        NUMBER := 0;
      l_cnt_err_format                 NUMBER := 0;

      l_item_id                        NUMBER := 0;

      l_set_process_id                 NUMBER := 0;
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

      DELETE fnd_lobs
       WHERE file_name = v_filename AND file_id <> p_file_id;

      DELETE xxshp_inv_mfg_parts_stg
       WHERE file_name = v_filename;

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
            IF x = 27
            THEN
               IF v_loop >= 2
               THEN
                  FOR i IN 1 .. x
                  LOOP
                     IF i = 1
                     THEN
                        l_manufacturer_group := TRIM (v_tab (1));
                     ELSIF i = 2
                     THEN
                        l_manufacturer_name := TRIM (v_tab (2));
                     ELSIF i = 3
                     THEN
                        l_description := TRIM (v_tab (3));
                     ELSIF i = 4
                     THEN
                        l_country := TRIM (v_tab (4));
                     ELSIF i = 5
                     THEN
                        l_factory_code := TRIM (v_tab (5));
                     ELSIF i = 6
                     THEN
                        l_comments := TRIM (v_tab (6));
                     ELSIF i = 7
                     THEN
                        l_mfg_status := TRIM (v_tab (7));
                     ELSIF i = 8
                     THEN
                        l_vendor_name := TRIM (v_tab (8));
                     ELSIF i = 9
                     THEN
                        l_vendor_site_code := TRIM (v_tab (9));
                     ELSIF i = 10
                     THEN
                        l_mfg_part_num := TRIM (v_tab (10));
                     ELSIF i = 11
                     THEN
                        l_item_code := TRIM (v_tab (11));
                     ELSIF i = 12
                     THEN
                        l_org_code := TRIM (v_tab (12));
                     ELSIF i = 13
                     THEN
                        l_allergen_num := TRIM (v_tab (13));
                     ELSIF i = 14
                     THEN
                        l_allergen_valid_to := TRIM (v_tab (14));
                     ELSIF i = 15
                     THEN
                        l_certificate_md_num := TRIM (v_tab (15));
                     ELSIF i = 16
                     THEN
                        l_certificate_md_valid_to := TRIM (v_tab (16));
                     ELSIF i = 17
                     THEN
                        l_akasia_num := TRIM (v_tab (17));
                     ELSIF i = 18
                     THEN
                        l_prod_qm_version := TRIM (v_tab (18));
                     ELSIF i = 19
                     THEN
                        l_prod_qm_valid_to := TRIM (v_tab (19));
                     ELSIF i = 20
                     THEN
                        l_organic_certificate_num := TRIM (v_tab (20));
                     ELSIF i = 21
                     THEN
                        l_organic_certificate_valid_to := TRIM (v_tab (21));
                     ELSIF i = 22
                     THEN
                        l_organic_body := TRIM (v_tab (22));
                     ELSIF i = 23
                     THEN
                        l_need_halal_certificate := TRIM (v_tab (23));
                     ELSIF i = 24
                     THEN
                        l_halal_certificate_num := TRIM (v_tab (24));
                     ELSIF i = 25
                     THEN
                        l_halal_certificate_valid_to := TRIM (v_tab (25));
                     ELSIF i = 26
                     THEN
                        l_halal_logo := TRIM (v_tab (26));
                     ELSIF i = 27
                     THEN
                        l_halal_body := TRIM (v_tab (27));
                     END IF;
                  END LOOP;

                  l_err_cnt := 0;

                  --validasi
                  BEGIN
                     SELECT DISTINCT pv.vendor_id
                       INTO v_vendor_id
                       FROM po_vendors pv
                      WHERE 1 = 1 AND pv.vendor_name = l_vendor_name;
                  --GROUP BY pv.vendor_name;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_vendor_id := NULL;
                        l_err_cnt := 1;                          -- add by ish
                  END;

                  BEGIN
                     SELECT DISTINCT vendor_site_id
                       INTO v_vendor_site_id
                       FROM po_vendor_sites_all
                      WHERE     vendor_id = v_vendor_id
                            AND vendor_site_code = l_vendor_site_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_vendor_site_id := NULL;
                        l_err_cnt := 1;                          -- add by ish
                  END;


                  --*/
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                    INTO l_status
                    FROM DUAL;

                  BEGIN
                     EXECUTE IMMEDIATE
                        'insert into xxshp_inv_mfg_parts_stg(
                             file_id                        ,
                             file_name                      ,
                             manufacturer_group             ,
                             manufacturer_name              ,
                             description                    ,
                             country                        ,
                             factory_code                   ,
                             comments                       ,
                             mfg_status                     ,
                             vendor_name                    ,
                             vendor_id                      ,
                             vendor_site_code               ,
                             vendor_site_id                 ,
                             status_manufacturer            ,
                             message_manufacturer           ,
                             mfg_part_num                   ,
                             item_code                      ,
                             org_code                       ,
                             allergen_num                   ,
                             allergen_valid_to              ,
                             certificate_md_num             ,
                             certificate_md_valid_to        ,
                             akasia_num                     ,
                             prod_qm_version                ,
                             prod_qm_valid_to               ,
                             organic_certificate_num        ,
                             organic_certificate_valid_to   ,
                             organic_body                   ,
                             need_halal_certificate         ,
                             halal_certificate_num          ,
                             halal_certificate_valid_to     ,
                             halal_logo                     ,
                             halal_body                     ,
                             status_mpn                     ,
                             message_mpn                    ,
                             status                         ,
                             created_by                     ,
                             last_updated_by                ,
                             creation_date                  ,
                             last_update_date               ,
                             last_update_login               )
                         VALUES(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,:20,:21,:22,:23,:24,:25,:26,:27,:28,:29,:30,:31,:32,:33,:34,:35,:36,:37,:38,:39,:40,:41)'
                        USING p_file_id,
                              v_filename,
                              l_manufacturer_group,
                              l_manufacturer_name,
                              l_description,
                              l_country,
                              l_factory_code,
                              l_comments,
                              l_mfg_status,
                              l_vendor_name,
                              v_vendor_id,
                              l_vendor_site_code,
                              v_vendor_site_id,
                              l_status_manufacturer,
                              l_message_manufacturer,
                              l_mfg_part_num,
                              l_item_code,
                              l_org_code,
                              l_allergen_num,
                              TO_DATE (l_allergen_valid_to,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_certificate_md_num,
                              TO_DATE (l_certificate_md_valid_to,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_akasia_num,
                              l_prod_qm_version,
                              TO_DATE (l_prod_qm_valid_to,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_organic_certificate_num,
                              TO_DATE (l_organic_certificate_valid_to,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_organic_body,
                              l_need_halal_certificate,
                              l_halal_certificate_num,
                              TO_DATE (l_halal_certificate_valid_to,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_halal_logo,
                              l_halal_body,
                              l_status_mpn,
                              l_message_mpn,
                              l_status,
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
           FROM xxshp_inv_mfg_parts_stg
          WHERE 1 = 1 AND NVL (status, 'N') = 'N' AND file_id = p_file_id;

         IF NVL (l_stg_cnt, 0) > 0
         THEN
            --NULL;
            logf ('Call Procedure Create Manufacturing Part Numbers');
            create_mfg_part_numbers (p_file_id);
            print_result (p_file_id);
         END IF;

         UPDATE fnd_lobs
            SET expiration_date = SYSDATE, upload_date = SYSDATE
          WHERE 1 = 1 AND file_id = p_file_id;
      --*/

      END IF;

      COMMIT;
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
END;
/