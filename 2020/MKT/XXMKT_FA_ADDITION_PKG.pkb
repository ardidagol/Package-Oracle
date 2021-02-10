CREATE OR REPLACE PACKAGE BODY APPS.xxmkt_fa_addition_pkg
/* $Header: XXMKT_FA_ADDITION_PKG 122.5.1.0 2016/11/24 15:56:00 Hansen Darmawan $ */
AS
   /**************************************************************************************************
       NAME: XXMKT_FA_ADDITION_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         24-Nov-2016          Hansen Darmawan     1. Created this package.
   **************************************************************************************************/
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
   --dbms_output.PUT_LINE(v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END;

   PROCEDURE print_output
   IS
      v_err_cnt   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO v_err_cnt
        FROM xxmkt_fa_addition
       WHERE request_id = g_request_id AND status = 'E';

      IF v_err_cnt = 0
      THEN
         outf ('All Data Processed Successfully');
      ELSE
         outf ('----- PRINT ERROR DATA -----');
         outf (' ');
         outf (   RPAD ('Book Type Code', 20, ' ')
               || '|'
               || RPAD ('Description', 40, ' ')
               || '|'
               || RPAD ('Asset Category Id', 20, ' ')
               || '|'
               || RPAD ('Unit', 5, ' ')
               || '|'
               || RPAD ('Location Id', 13, ' ')
               || '|'
               || RPAD ('Cost', 5, ' ')
               || '|'
               || RPAD ('Date Place In Service', 23, ' ')
               || '|'
               || RPAD ('Depreciation Expense CCID', 28, ' ')
               || '|'
               || RPAD ('Asset type', 15, ' ')
               || '|'
               || RPAD ('Serial Number', 20, ' ')
               || '|'
               || RPAD ('Status', 8, ' ')
               || '|'
               || 'Error Message'                                                                                   --RPAD ('Error Message', 400, ' ')
              );

         FOR i IN (SELECT *
                     FROM xxmkt_fa_addition
                    WHERE request_id = g_request_id AND status = 'E')
         LOOP
            outf (   RPAD (i.book_type_code, 20, ' ')
                  || '|'
                  || RPAD (i.description, 40, ' ')
                  || '|'
                  || RPAD (i.asset_category_id, 20, ' ')
                  || '|'
                  || RPAD (i.unit, 5, ' ')
                  || '|'
                  || RPAD (i.location_id, 13, ' ')
                  || '|'
                  || RPAD (i.COST, 5, ' ')
                  || '|'
                  || RPAD (i.date_place_in_service, 23, ' ')
                  || '|'
                  || RPAD (i.depre_ccid, 28, ' ')
                  || '|'
                  || RPAD (i.asset_type, 15, ' ')
                  || '|'
                  || RPAD (i.serial_number, 20, ' ')
                  || '|'
                  || RPAD (i.status, 8, ' ')
                  || '|'
                  || i.error_message                                                                                --RPAD ('Error Message', 400, ' ')
                 );
         END LOOP;

         outf (' ');
         outf ('----- END PRINT ERROR DATA -----');
      END IF;
   END;

   PROCEDURE insert_to_interface (
      p_book_type_code          VARCHAR2,
      p_description             VARCHAR2,
      p_asset_category_id       NUMBER,
      p_unit                    NUMBER,
      p_location_id             NUMBER,
      p_cost                    NUMBER,
      p_date_place_in_service   DATE,
      p_depre_ccid              NUMBER,
      p_asset_type              VARCHAR2,
      p_serial_number           VARCHAR2,
      p_asset_id                NUMBER,
      p_rowid                   ROWID,
      p_invoice_id              NUMBER,
      p_invoice_number          VARCHAR2,
      p_vendor_number           VARCHAR2,
      p_vendor_id               NUMBER,
      p_po_number               VARCHAR2
   )
   IS
      v_depre_flag    VARCHAR2 (5);
      v_mass_add_id   NUMBER;
--      v_mass_add_dist_id   NUMBER;
   BEGIN
      logf ('Insert to Interface for Serial Number : ' || p_serial_number);

      IF UPPER (p_asset_type) = 'CAPITALIZED'
      THEN
         v_depre_flag := 'YES';
      ELSIF UPPER (p_asset_type) = 'CIP'
      THEN
         v_depre_flag := 'NO';
      END IF;

      SELECT fa_mass_additions_s.NEXTVAL
        INTO v_mass_add_id
        FROM DUAL;

      /*SELECT fa_massadd_distributions_s.NEXTVAL
        INTO v_mass_add_dist_id
        FROM DUAL;*/
      INSERT INTO fa_mass_additions
                  (mass_addition_id, description, asset_category_id, serial_number, book_type_code, date_placed_in_service,
                   expense_code_combination_id, location_id, feeder_system_name, posting_status, depreciate_flag, add_to_asset_id, asset_type,
                   created_by, creation_date, last_update_login, salvage_value, salvage_type, fixed_assets_cost, fixed_assets_units, queue_name,
                   invoice_id, vendor_number, invoice_number, po_vendor_id, po_number
                  )
           VALUES (v_mass_add_id, p_description, p_asset_category_id, p_serial_number, p_book_type_code, p_date_place_in_service,
                   p_depre_ccid, p_location_id, 'AMEN', 'POST', v_depre_flag, p_asset_id, UPPER (p_asset_type),
                   g_user_id, SYSDATE, g_login_id, 1, 'AMT', p_cost, p_unit, 'POST',
                   p_invoice_id, p_vendor_number, p_invoice_number, p_vendor_id, p_po_number
                  );

      /*INSERT INTO fa_massadd_distributions
                  (massadd_dist_id, mass_addition_id, units,
                   deprn_expense_ccid, location_id, created_by,
                   creation_date, last_updated_by, last_update_login,
                   last_update_date
                  )
           VALUES (v_mass_add_dist_id, v_mass_add_id, p_unit,
                   p_depre_ccid, p_location_id, g_user_id,
                   SYSDATE, g_user_id, g_login_id,
                   SYSDATE
                  );*/
      logf ('Data Inserted Successfully');
      outf ('Serial Number ' || p_serial_number || ' Inserted Successfully');

      UPDATE xxmkt_fa_addition
         SET status = 'C',
             mass_addition_id = v_mass_add_id,
             invoice_id = p_invoice_id,
             vendor_id = p_vendor_id,
--             massadd_dist_id = v_mass_add_dist_id,
             last_updated_by = g_user_id,
             last_update_login = g_login_id,
             last_update_date = SYSDATE
       WHERE ROWID = p_rowid;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error When Inserting Data to Interface : ' || SQLERRM);
   END;

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER)
   IS
      v_err_cnt        NUMBER;
      v_errmsg         VARCHAR2 (4000);
      v_book_cnt       NUMBER;
      v_cat_cnt        NUMBER;
      v_loc_cnt        NUMBER;
      v_concat_seg     VARCHAR2 (240);
      v_ccid_flag      VARCHAR2 (1);
      v_serial_err     NUMBER;
      v_asset_id       NUMBER;
      v_invoice_id     NUMBER;
      v_invoice_date   DATE;
      v_vendor_cnt     NUMBER;
      v_vendor_id      NUMBER;

      CURSOR c_data
      IS
         SELECT ROWID, xfa.*
           FROM xxmkt_fa_addition xfa
          WHERE status IS NULL AND GROUP_ID = g_user_id;
   BEGIN
      logf ('----- Start Main Process -----');
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

      FOR i IN c_data
      LOOP
         v_err_cnt := 0;
         v_errmsg := NULL;
         v_concat_seg := NULL;
         v_ccid_flag := NULL;
         v_asset_id := NULL;
         v_serial_err := 0;
         v_invoice_id := NULL;
         v_invoice_date := NULL;
         v_vendor_id := NULL;

         UPDATE xxmkt_fa_addition
            SET request_id = g_request_id,
                last_updated_by = g_user_id,
                last_update_login = g_login_id,
                last_update_date = SYSDATE
          WHERE ROWID = i.ROWID;

         COMMIT;

         --validasi data
         SELECT COUNT (*)
           INTO v_book_cnt
           FROM fa_book_controls
          WHERE book_type_code = i.book_type_code;

         IF v_book_cnt <> 1
         THEN
            v_errmsg := v_errmsg || 'Invalid Book Type Code';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         SELECT COUNT (*)
           INTO v_cat_cnt
           FROM fa_categories
          WHERE category_id = i.asset_category_id AND enabled_flag = 'Y';

         IF v_cat_cnt <> 1
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Invalid Asset Category Id';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         IF i.unit <> 1
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Unit Must Be 1';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         SELECT COUNT (*)
           INTO v_loc_cnt
           FROM fa_locations
          WHERE location_id = i.location_id;

         IF v_loc_cnt <> 1
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Invalid Locations Id';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         /*IF i.COST <> 1
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Cost Must Be 1';
            v_err_cnt := v_err_cnt + 1;
         END IF;*/
         IF TO_NUMBER (TO_CHAR (i.date_place_in_service, 'YYYYMM')) > TO_NUMBER (TO_CHAR (SYSDATE, 'YYYYMM'))
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Invalid Date (Period Bigger Than Current Period)';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         BEGIN
            SELECT concatenated_segments
              INTO v_concat_seg
              FROM gl_code_combinations_kfv
             WHERE code_combination_id = i.depre_ccid AND enabled_flag = 'Y' AND gl_account_type = 'E';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_errmsg := v_errmsg || 'Invalid CCID';
               v_err_cnt := v_err_cnt + 1;
            WHEN OTHERS
            THEN
               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_errmsg := v_errmsg || 'CCID Error ' || SQLERRM;
               v_err_cnt := v_err_cnt + 1;
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

               v_errmsg := v_errmsg || 'Please Check CCID Security Rules';
               v_err_cnt := v_err_cnt + 1;
            END IF;
         END IF;

         IF UPPER (i.asset_type) <> 'CAPITALIZED' AND UPPER (i.asset_type) <> 'CIP'
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Invalid Asset Type';
            v_err_cnt := v_err_cnt + 1;
         END IF;

         /*if capitalized asset must not exist in oracle,if cip asset must exist in oracle*/
         BEGIN
            SELECT asset_id
              INTO v_asset_id
              FROM fa_additions
             WHERE serial_number = i.serial_number;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_asset_id := NULL;
            WHEN OTHERS
            THEN
               v_asset_id := NULL;
               v_serial_err := 1;

               IF v_err_cnt > 0
               THEN
                  v_errmsg := v_errmsg || ', ';
               END IF;

               v_errmsg := v_errmsg || 'Serial Number Error ' || SQLERRM;
               v_err_cnt := v_err_cnt + 1;
         END;

         IF UPPER (i.asset_type) = 'CAPITALIZED' AND v_asset_id IS NOT NULL
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Serial Number Already Exist';
            v_err_cnt := v_err_cnt + 1;
         ELSIF UPPER (i.asset_type) = 'CIP' AND v_asset_id IS NULL AND v_serial_err = 0
         THEN
            /*IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Serial Number Not Exist';
            v_err_cnt := v_err_cnt + 1;
            */
            /*Anggi 29-nov-2016 change request, IF serial number for CIP asset not exist, will still create asset*/
            v_asset_id := NULL;
         END IF;

         --additional new column and validation Hansen 03-Mar-2017
         IF i.invoice_number IS NOT NULL
         THEN
            BEGIN
               SELECT aia.invoice_id, aia.invoice_date
                 INTO v_invoice_id, v_invoice_date
                 FROM ap_invoices_all aia
                WHERE aia.invoice_num = i.invoice_number;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_errmsg := v_errmsg || ', ';
                  END IF;

                  v_errmsg := v_errmsg || 'Invalid Invoice Number';
                  v_err_cnt := v_err_cnt + 1;
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_errmsg := v_errmsg || ', ';
                  END IF;

                  v_errmsg := v_errmsg || 'Invoice Number Error ' || SQLERRM;
                  v_err_cnt := v_err_cnt + 1;
            END;

            IF v_invoice_date IS NOT NULL
            THEN
               IF TRUNC (v_invoice_date) <> TRUNC (i.invoice_date)
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_errmsg := v_errmsg || ', ';
                  END IF;

                  v_errmsg := v_errmsg || 'Invalid Invoice Date ' || SQLERRM;
                  v_err_cnt := v_err_cnt + 1;
               END IF;
            END IF;
         END IF;

         /*SELECT COUNT (*)
           INTO v_vendor_cnt
           FROM ap_suppliers aps
          WHERE aps.segment1 = i.vendor_number;

         IF v_vendor_cnt <> 1
         THEN
            IF v_err_cnt > 0
            THEN
               v_errmsg := v_errmsg || ', ';
            END IF;

            v_errmsg := v_errmsg || 'Invalid Vendor Number ' || SQLERRM;
            v_err_cnt := v_err_cnt + 1;
         END IF;*/
         IF i.vendor_number IS NOT NULL
         THEN
            BEGIN
               SELECT vendor_id
                 INTO v_vendor_id
                 FROM ap_suppliers aps
                WHERE aps.segment1 = i.vendor_number;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_errmsg := v_errmsg || ', ';
                  END IF;

                  v_errmsg := v_errmsg || 'Invalid Vendor Number';
                  v_err_cnt := v_err_cnt + 1;
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_errmsg := v_errmsg || ', ';
                  END IF;

                  v_errmsg := v_errmsg || 'Vendor Number Error ' || SQLERRM;
                  v_err_cnt := v_err_cnt + 1;
            END;
         END IF;

         --end additional 03-Mar-2017
         IF v_err_cnt > 0
         THEN
            UPDATE xxmkt_fa_addition
               SET status = 'E',
                   error_message = v_errmsg,
                   last_updated_by = g_user_id,
                   last_update_login = g_login_id,
                   last_update_date = SYSDATE
             WHERE ROWID = i.ROWID;

            retcode := 2;
         ELSE
            --insert to interface table
            insert_to_interface (i.book_type_code,
                                 i.description,
                                 i.asset_category_id,
                                 i.unit,
                                 i.location_id,
                                 i.COST,
                                 i.date_place_in_service,
                                 i.depre_ccid,
                                 i.asset_type,
                                 i.serial_number,
                                 v_asset_id,
                                 i.ROWID,
                                 v_invoice_id,
                                 i.invoice_number,
                                 i.vendor_number,
                                 v_vendor_id,
                                 i.po_number
                                );
         END IF;
      END LOOP;

      COMMIT;
      print_output;
      logf ('----- End Main Process -----');
   EXCEPTION
      WHEN OTHERS
      THEN
         retcode := 2;
         logf ('Program Error : ' || SQLERRM);
   END;
END;
/
