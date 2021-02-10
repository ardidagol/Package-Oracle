CREATE OR REPLACE PACKAGE BODY APPS.xxmkt_fa_mutation_pkg
/* $Header: XXSHP_FA_MUTATION_PKG 122.5.1.0 2016/11/23 15:14:00 Hansen Darmawan $ */
AS
   /**************************************************************************************************
       NAME: XXSHP_FA_MUTATION_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         23-Nov-2016          Hansen Darmawan     1. Created this package.
       1.0         04-Aug-2020          Ardi                2. Copy package from SHP
   **************************************************************************************************/
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END;

   PROCEDURE print_output
   IS
   BEGIN
      outf ('----- PRINT ERROR DATA -----');
      outf (' ');
      outf (   RPAD ('Book Type Code', 20, ' ')
            || '|'
            || RPAD ('Serial Number', 20, ' ')
            || '|'
            || RPAD ('Code Combination Id', 20, ' ')
            || '|'
            || RPAD ('Location Id', 15, ' ')
            || '|'
            || RPAD ('Status', 8, ' ')
            || '|'
            || RPAD ('Error Message', 400, ' ')
           );

      FOR i IN (SELECT *
                  FROM xxmkt_fa_mutation
                 WHERE status = 'E' AND request_id = g_request_id)
      LOOP
         outf (   RPAD (i.book_type_code, 20, ' ')
               || '|'
               || RPAD (i.serial_number, 20, ' ')
               || '|'
               || RPAD (i.depre_ccid, 20, ' ')
               || '|'
               || RPAD (i.location_id, 15, ' ')
               || '|'
               || RPAD (i.status, 8, ' ')
               || '|'
               || RPAD (i.error_message, 400, ' ')
              );
      END LOOP;
   END;

   PROCEDURE do_transfer (
      p_serial_number     VARCHAR2,
      p_asset_id          NUMBER,
      p_distribution_id   NUMBER,
      p_ori_ccid          NUMBER,
      p_ori_loc_id        NUMBER,
      p_ccid              NUMBER,
      p_loc_id            NUMBER
   )
   IS
      v_trans_rec        fa_api_types.trans_rec_type;
      v_asset_hdr_rec    fa_api_types.asset_hdr_rec_type;
      v_asset_dist_tbl   fa_api_types.asset_dist_tbl_type;
      v_return_status    VARCHAR2 (1);
      v_msg_count        NUMBER;
      v_msg_data         VARCHAR2 (512);
      v_errmsg           VARCHAR2 (4000);
   BEGIN
      v_asset_hdr_rec.asset_id := p_asset_id;
      --source
      v_asset_dist_tbl (1).transaction_units := -1;
      v_asset_dist_tbl (1).distribution_id := p_distribution_id;
      v_asset_dist_tbl (1).expense_ccid := p_ori_ccid;
      v_asset_dist_tbl (1).location_ccid := p_ori_loc_id;
      --destination
      v_asset_dist_tbl (2).transaction_units := 1;
      v_asset_dist_tbl (2).expense_ccid := p_ccid;
      v_asset_dist_tbl (2).location_ccid := p_loc_id;
      fa_transfer_pub.do_transfer (
                                   -- std parameters
                                   p_api_version           => 1.0,
                                   p_init_msg_list         => fnd_api.g_false,
                                   p_commit                => fnd_api.g_true,
                                   p_validation_level      => fnd_api.g_valid_level_full,
                                   p_calling_fn            => NULL,
                                   x_return_status         => v_return_status,
                                   x_msg_count             => v_msg_count,
                                   x_msg_data              => v_msg_data,
                                   -- api parameters
                                   px_trans_rec            => v_trans_rec,
                                   px_asset_hdr_rec        => v_asset_hdr_rec,
                                   px_asset_dist_tbl       => v_asset_dist_tbl
                                  );

      IF v_msg_count > 0
      THEN
         FOR l_index IN 1 .. v_msg_count
         LOOP
            v_errmsg := v_errmsg || ', ' || SUBSTR (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 255);
         END LOOP;

         UPDATE xxmkt_fa_mutation
            SET status = 'E',
                error_message = v_errmsg,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;

         logf ('Failed to Transfer Asset With Serial Number ' || p_serial_number);
      END IF;

      IF v_return_status = 'S'
      THEN
         UPDATE xxmkt_fa_mutation
            SET status = 'C',
                transaction_header_id = v_trans_rec.transaction_header_id,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;

         logf (   'Asset With Serial Number '
               || p_serial_number
               || ' Transfered Succesfully With Transaction Header Id '
               || v_trans_rec.transaction_header_id
              );
      END IF;
--      COMMIT;
   END;

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER)
   IS
      v_asset_id          NUMBER;
      v_book_type         VARCHAR2 (15);
      v_ccid_cnt          NUMBER;
      v_loc_cnt           NUMBER;
      v_err_cnt           NUMBER;
      v_errmsg            VARCHAR2 (4000);
      v_distribution_id   NUMBER;
      v_ori_loc_id        NUMBER;
      v_ori_ccid          NUMBER;
      v_total_err_cnt     NUMBER;
      v_concat_seg        VARCHAR2 (240);
      v_ccid_flag         VARCHAR2 (1);

      CURSOR c_data
      IS
         SELECT xfm.*, ROWID
           FROM xxmkt_fa_mutation xfm
          WHERE request_id IS NULL AND GROUP_ID = g_user_id;
   BEGIN
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
      v_err_cnt := 0;
      v_errmsg := NULL;
      v_asset_id := NULL;
      v_book_type := NULL;
      v_concat_seg := NULL;
      logf ('----- Start Main Process -----');

      FOR i IN c_data
      LOOP
         UPDATE xxmkt_fa_mutation
            SET request_id = g_request_id,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE ROWID = i.ROWID;

         COMMIT;

         BEGIN
            SELECT asset_id
              INTO v_asset_id
              FROM fa_additions
             WHERE serial_number = i.serial_number;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Invalid Serial Number';
            WHEN OTHERS
            THEN
               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Serial Number Error ' || SQLERRM;
         END;

         BEGIN
            SELECT book_type_code
              INTO v_book_type
              FROM fa_book_controls fbc
             WHERE fbc.book_type_code = i.book_type_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Invalid Book Type';
            WHEN OTHERS
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Book Type Error ' || SQLERRM;
         END;

         --Change ccid validation, using xxmkt_general_pkg.is_ccid_valid
         /*SELECT COUNT (*)
           INTO v_ccid_cnt
           FROM gl_code_combinations
          WHERE code_combination_id = i.depre_ccid
          and enabled_flag = 'Y'
          and account_type = 'E'; --expense

         IF v_ccid_cnt = 0
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_err_cnt := v_err_cnt + 1;
            v_errmsg := v_errmsg || 'Invalid CCID';
         END IF;*/
         BEGIN
            SELECT gcc.concatenated_segments
              INTO v_concat_seg
              FROM gl_code_combinations_kfv gcc
             WHERE code_combination_id = i.depre_ccid AND enabled_flag = 'Y' AND gl_account_type = 'E';                                     --expense;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Invalid CCID';
            WHEN OTHERS
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'CCID Error ' || SQLERRM;
         END;

         IF v_concat_seg IS NOT NULL
         THEN
            v_ccid_flag := xxmkt_general_pkg.is_ccid_valid (v_concat_seg);

            IF v_ccid_flag = 'N'
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_errmsg := v_errmsg || 'Please Check CCID Security Rules';
            END IF;
         END IF;

         SELECT COUNT (*)
           INTO v_loc_cnt
           FROM fa_locations
          WHERE location_id = i.location_id;

         IF v_loc_cnt = 0
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_err_cnt := v_err_cnt + 1;
            v_errmsg := v_errmsg || 'Invalid Location Id';
         END IF;

         IF v_asset_id IS NOT NULL AND v_book_type IS NOT NULL
         THEN
            SELECT distribution_id, location_id, code_combination_id
              INTO v_distribution_id, v_ori_loc_id, v_ori_ccid
              FROM fa_distribution_history
             WHERE asset_id = v_asset_id AND book_type_code = v_book_type AND transaction_header_id_out IS NULL;
         END IF;

         IF v_err_cnt > 0
         THEN
            UPDATE xxmkt_fa_mutation
               SET status = 'E',
                   error_message = v_errmsg,
                   last_updated_by = g_user_id,
                   last_update_date = SYSDATE,
                   last_update_login = g_login_id
             WHERE serial_number = i.serial_number AND request_id = g_request_id;

--            COMMIT;
            retcode := 2;
         ELSE
            UPDATE xxmkt_fa_mutation
               SET asset_id = v_asset_id,
                   last_updated_by = g_user_id,
                   last_update_date = SYSDATE,
                   last_update_login = g_login_id
             WHERE serial_number = i.serial_number AND request_id = g_request_id;

--            COMMIT;
            --call API transfer asset
            logf ('Calling do_transfer for serial number ' || i.serial_number);
            do_transfer (i.serial_number, v_asset_id, v_distribution_id, v_ori_ccid, v_ori_loc_id, i.depre_ccid, i.location_id);
         END IF;
      END LOOP;

      COMMIT;

      SELECT COUNT (*)
        INTO v_total_err_cnt
        FROM xxmkt_fa_mutation
       WHERE status = 'E' AND request_id = g_request_id;

      IF v_total_err_cnt > 0
      THEN
         --print output
         print_output;
         retcode := 2;
      END IF;

      logf ('----- End Main Process -----');
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Program Error : ' || SQLERRM);
         retcode := 2;
   END;
END;
/
