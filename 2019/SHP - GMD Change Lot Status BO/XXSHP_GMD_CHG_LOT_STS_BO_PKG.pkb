CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_GMD_CHG_LOT_STS_BO_PKG
AS
   PROCEDURE logf (p_msg IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   END outf;

   -- Procedure update lot temporary tabel
   PROCEDURE update_temp_lotnumber (p_status_ref           NUMBER,
                                    p_status_id            NUMBER,
                                    p_lot_number           VARCHAR2,
                                    p_inventory_item_id    VARCHAR2)
   AS
   BEGIN
      UPDATE t_lot_number_temp
         SET status_id = p_status_ref
       WHERE     old_status_id = p_status_id
             AND lot_number = p_lot_number
             AND inventory_item_id = p_inventory_item_id;
   END update_temp_lotnumber;

   -- Procedure Change Lot Status BO
   PROCEDURE change_lot (errbuf          OUT VARCHAR2,
                         retcode         OUT NUMBER,
                         p_exp_date   IN     NUMBER,
                         p_email      IN     VARCHAR2)
   AS
      v_api_version         NUMBER := 1.0;
      v_init_msg_list       VARCHAR2 (100) := fnd_api.g_true;
      v_commit              VARCHAR2 (100) := fnd_api.g_false;
      v_return_status       VARCHAR2 (2);
      v_error_msg           VARCHAR2 (3000);
      p_count               NUMBER;
      v_object_type         VARCHAR2 (20);
      v_lines_rec           inv_material_status_pub.mtl_status_update_rec_type;
      v_count_proses        NUMBER := 0;
      v_retcode             VARCHAR2 (4000) := retcode;
      v_errbuf              VARCHAR2 (4000) := errbuf;
      v_exp_date            NUMBER := p_exp_date;
      v_result              VARCHAR2 (2000);

      -- Update Lot
      x_mtl_lot_numbers     mtl_lot_numbers%ROWTYPE;
      v_mtl_lot_numbers     mtl_lot_numbers%ROWTYPE;
      v_status              VARCHAR2 (1);
      v_msg_count           NUMBER;
      v_msg_data            VARCHAR2 (4000);
      v_message             VARCHAR2 (4000);

      -- Reference untuk perubahan
      v_status_id_ref       mtl_lot_numbers.status_id%TYPE := 207;
      v_inventory_item_id   mtl_lot_numbers.inventory_item_id%TYPE;
      v_lot_number          mtl_lot_numbers.lot_number%TYPE;

      v_exp                 EXCEPTION;

      CURSOR c_source (
         p_ref_io     NUMBER,
         p_exp_dat    NUMBER)
      IS
         SELECT ROWNUM no_baris, aa.*
           FROM (SELECT DISTINCT c.status_id,
                                 c.d_attribute1 mfg_date_ref,
                                 d.organization_code org_code,
                                 d.organization_id io,
                                 b.segment1 item_code,
                                 b.inventory_item_id,
                                 c.lot_number,
                                 b.description,
                                 c.expiration_date,
                                 c.origination_type,
                                 c.availability_type
                   FROM mtl_onhand_quantities_detail a
                        INNER JOIN mtl_system_items b
                           ON     a.organization_id = b.organization_id
                              AND a.inventory_item_id = b.inventory_item_id
                        INNER JOIN MTL_LOT_NUMBERS c
                           ON     b.organization_id = c.organization_id
                              AND b.inventory_item_id = c.inventory_item_id
                              AND a.LOT_NUMBER = c.LOT_NUMBER
                        INNER JOIN mtl_parameters d
                           ON d.organization_id = a.organization_id
                  WHERE     a.organization_id = g_organization_id
                        AND a.SUBINVENTORY_CODE IN ('RM',
                                                    'PM',
                                                    'IB',
                                                    'UB',
                                                    'UF',
                                                    'INTERMEDIATE',
                                                    'UNSTANDARD')
                        AND c.expiration_date - p_exp_date < SYSDATE
                        AND c.status_id <> v_status_id_ref
                        AND NOT EXISTS
                                   (SELECT *
                                      FROM mtl_reservations e
                                     WHERE     e.organization_id =
                                                  c.organization_id
                                           AND e.inventory_item_id =
                                                  c.inventory_item_id
                                           AND e.LOT_NUMBER = c.LOT_NUMBER)) aa;

      CURSOR c_target (
         p_io_cur                  IN NUMBER,
         p_target_io_cur           IN NUMBER,
         p_inventory_item_id_cur   IN NUMBER,
         p_lot_number_cur          IN VARCHAR2)
      IS
         SELECT organization_id,
                d_attribute1 manufacturing_date,
                status_id current_status_id
           FROM mtl_Lot_numbers
          WHERE     inventory_item_id = p_inventory_item_id_cur
                AND organization_id = p_io_cur
                AND lot_number = p_Lot_Number_cur;

      v_data_awal           NUMBER := 0;
      v_data_akhir          NUMBER := 0;
   BEGIN
      retcode := 0;

      -- Insert data ke tabel temporary
      BEGIN
         INSERT INTO t_lot_number_temp (inventory_item_id,
                                        segment1,
                                        description,
                                        gen_object_id,
                                        old_status_id,
                                        lot_number,
                                        organization_id,
                                        expiration_date,
                                        parent_lot_number,
                                        origination_type,
                                        availability_type)
            SELECT DISTINCT c.inventory_item_id,
                            b.segment1,
                            b.description,
                            c.gen_object_id,
                            c.status_id,
                            c.lot_number,
                            c.organization_id,
                            c.expiration_date,
                            c.parent_lot_number,
                            c.origination_type,
                            c.availability_type
              FROM mtl_onhand_quantities_detail a
                   INNER JOIN mtl_system_items b
                      ON     a.organization_id = b.organization_id
                         AND a.inventory_item_id = b.inventory_item_id
                   INNER JOIN MTL_LOT_NUMBERS c
                      ON     b.organization_id = c.organization_id
                         AND b.inventory_item_id = c.inventory_item_id
                         AND a.LOT_NUMBER = c.LOT_NUMBER
             WHERE     a.organization_id = g_organization_id
                   AND a.SUBINVENTORY_CODE IN ('RM',
                                               'PM',
                                               'IB',
                                               'UB',
                                               'UF',
                                               'INTERMEDIATE',
                                               'UNSTANDARD')
                   AND c.expiration_date - p_exp_date < SYSDATE
                   AND c.status_id <> v_status_id_ref
                   AND NOT EXISTS
                              (SELECT *
                                 FROM mtl_reservations e
                                WHERE     e.organization_id =
                                             c.organization_id
                                      AND e.inventory_item_id =
                                             c.inventory_item_id
                                      AND e.LOT_NUMBER = c.LOT_NUMBER);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error when get data, msg :' || SQLERRM);
            retcode := 2;
            RAISE v_exp;
      END;

      -- Kondisi awal dalam jumlah (summary)
      BEGIN
         SELECT COUNT (1)
           INTO v_data_awal
           FROM (SELECT DISTINCT c.*
                   FROM mtl_onhand_quantities_detail a
                        INNER JOIN mtl_system_items b
                           ON     a.organization_id = b.organization_id
                              AND a.inventory_item_id = b.inventory_item_id
                        INNER JOIN MTL_LOT_NUMBERS c
                           ON     b.organization_id = c.organization_id
                              AND b.inventory_item_id = c.inventory_item_id
                              AND a.LOT_NUMBER = c.LOT_NUMBER
                        INNER JOIN mtl_parameters d
                           ON d.organization_id = a.organization_id
                  WHERE     a.organization_id = g_organization_id
                        AND a.SUBINVENTORY_CODE IN ('RM',
                                                    'PM',
                                                    'IB',
                                                    'UB',
                                                    'UF',
                                                    'INTERMEDIATE',
                                                    'UNSTANDARD')
                        AND c.expiration_date - p_exp_date < SYSDATE
                        AND NOT EXISTS
                                   (SELECT *
                                      FROM mtl_reservations e
                                     WHERE     e.organization_id =
                                                  c.organization_id
                                           AND e.inventory_item_id =
                                                  c.inventory_item_id
                                           AND e.LOT_NUMBER = c.LOT_NUMBER)
                        AND c.status_id <> v_status_id_ref);
      END;

      IF v_data_awal = 0
      THEN
         logf ('Tidak ada data yang akan di update.');
         retcode := 1;
         RAISE v_exp;
      END IF;

      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      FOR i
         IN c_source (p_ref_io => g_organization_id, p_exp_dat => p_exp_date)
      LOOP
         FOR io IN c_target (p_io_cur                  => i.io,
                             p_target_io_cur           => i.io,
                             p_inventory_item_id_cur   => i.inventory_item_id,
                             p_lot_number_cur          => i.lot_number)
         LOOP
            --reset status
            v_return_status := NULL;

            -- Hitung proses
            v_count_proses := v_count_proses + 1;

            IF v_status_id_ref <> io.current_status_id
            THEN
               v_object_type := 'O'; -- 'O' = Lot , 'S' = Serial, 'Z' = Subinventory, 'L' = Locator, 'H' = Onhand

               v_lines_rec.organization_id := io.organization_id;
               v_lines_rec.inventory_item_id := i.inventory_item_id;
               v_lines_rec.lot_number := i.lot_number;
               v_lines_rec.status_id := v_status_id_ref;
               v_lines_rec.update_method := 2;

               inv_material_status_pub.update_status (
                  p_api_version_number   => v_api_version,
                  p_init_msg_lst         => v_init_msg_list,
                  p_commit               => v_commit,
                  x_return_status        => v_return_status,
                  x_msg_count            => v_msg_count,
                  x_msg_data             => v_msg_data,
                  p_object_type          => v_object_type,
                  p_status_rec           => v_lines_rec);

               update_temp_lotnumber (v_status_id_ref,
                                      i.status_id,
                                      i.lot_number,
                                      i.inventory_item_id);

               logf (
                     ' Status: '
                  || v_return_status
                  || '| Message Count: '
                  || v_msg_count
                  || '| v_msg_data: '
                  || v_msg_data);
            ELSE
               -- Jika status id sudah sama dengan statusnya, maka tidak perlu di-ubah status lot nya
               v_return_status := 'S';
            END IF;

            IF v_return_status = 'S'
            THEN
               IF i.mfg_date_ref IS NULL
               THEN
                  logf ('Manufacturing Date in IO Reference is NULL');
               END IF;

               -- jika update status berhasil maka akan menjalankan API
               IF     io.manufacturing_date IS NULL
                  AND i.mfg_date_ref IS NOT NULL
               THEN
                  SELECT inventory_item_id,
                         organization_id,
                         lot_number,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         last_update_login,
                         expiration_date,
                         disable_flag,
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
                         request_id,
                         program_application_id,
                         program_id,
                         program_update_date,
                         gen_object_id,
                         description,
                         vendor_name,
                         supplier_lot_number,
                         country_of_origin,
                         grade_code,
                         origination_date,
                         date_code,
                         status_id,
                         change_date,
                         age,
                         retest_date,
                         maturity_date,
                         lot_attribute_category,
                         item_size,
                         color,
                         volume,
                         volume_uom,
                         place_of_origin,
                         kill_date,
                         best_by_date,
                         LENGTH,
                         length_uom,
                         recycled_content,
                         thickness,
                         thickness_uom,
                         width,
                         width_uom,
                         curl_wrinkle_fold,
                         c_attribute1,
                         c_attribute2,
                         c_attribute3,
                         c_attribute4,
                         c_attribute5,
                         c_attribute6,
                         c_attribute7,
                         c_attribute8,
                         c_attribute9,
                         c_attribute10,
                         c_attribute11,
                         c_attribute12,
                         c_attribute13,
                         c_attribute14,
                         c_attribute15,
                         c_attribute16,
                         c_attribute17,
                         c_attribute18,
                         c_attribute19,
                         c_attribute20,
                         c_attribute21,
                         c_attribute22,
                         c_attribute23,
                         c_attribute24,
                         c_attribute25,
                         c_attribute26,
                         c_attribute27,
                         c_attribute28,
                         c_attribute29,
                         c_attribute30,
                         d_attribute1,
                         d_attribute2,
                         d_attribute3,
                         d_attribute4,
                         d_attribute5,
                         d_attribute6,
                         d_attribute7,
                         d_attribute8,
                         d_attribute9,
                         d_attribute10,
                         d_attribute11,
                         d_attribute12,
                         d_attribute13,
                         d_attribute14,
                         d_attribute15,
                         d_attribute16,
                         d_attribute17,
                         d_attribute18,
                         d_attribute19,
                         d_attribute20,
                         n_attribute1,
                         n_attribute2,
                         n_attribute3,
                         n_attribute4,
                         n_attribute5,
                         n_attribute6,
                         n_attribute7,
                         n_attribute8,
                         n_attribute9,
                         n_attribute10,
                         n_attribute11,
                         n_attribute12,
                         n_attribute13,
                         n_attribute14,
                         n_attribute15,
                         n_attribute16,
                         n_attribute17,
                         n_attribute18,
                         n_attribute19,
                         n_attribute20,
                         n_attribute21,
                         n_attribute22,
                         n_attribute23,
                         n_attribute24,
                         n_attribute25,
                         n_attribute26,
                         n_attribute27,
                         n_attribute28,
                         n_attribute29,
                         n_attribute30,
                         vendor_id,
                         territory_code,
                         parent_lot_number,
                         origination_type,
                         availability_type,
                         expiration_action_code,
                         expiration_action_date,
                         hold_date,
                         inventory_atp_code,
                         reservable_type,
                         sampling_event_id
                    INTO v_mtl_lot_numbers.inventory_item_id,
                         v_mtl_lot_numbers.organization_id,
                         v_mtl_lot_numbers.lot_number,
                         v_mtl_lot_numbers.last_update_date,
                         v_mtl_lot_numbers.last_updated_by,
                         v_mtl_lot_numbers.creation_date,
                         v_mtl_lot_numbers.created_by,
                         v_mtl_lot_numbers.last_update_login,
                         v_mtl_lot_numbers.expiration_date,
                         v_mtl_lot_numbers.disable_flag,
                         v_mtl_lot_numbers.attribute_category,
                         v_mtl_lot_numbers.attribute1,
                         v_mtl_lot_numbers.attribute2,
                         v_mtl_lot_numbers.attribute3,
                         v_mtl_lot_numbers.attribute4,
                         v_mtl_lot_numbers.attribute5,
                         v_mtl_lot_numbers.attribute6,
                         v_mtl_lot_numbers.attribute7,
                         v_mtl_lot_numbers.attribute8,
                         v_mtl_lot_numbers.attribute9,
                         v_mtl_lot_numbers.attribute10,
                         v_mtl_lot_numbers.attribute11,
                         v_mtl_lot_numbers.attribute12,
                         v_mtl_lot_numbers.attribute13,
                         v_mtl_lot_numbers.attribute14,
                         v_mtl_lot_numbers.attribute15,
                         v_mtl_lot_numbers.request_id,
                         v_mtl_lot_numbers.program_application_id,
                         v_mtl_lot_numbers.program_id,
                         v_mtl_lot_numbers.program_update_date,
                         v_mtl_lot_numbers.gen_object_id,
                         v_mtl_lot_numbers.description,
                         v_mtl_lot_numbers.vendor_name,
                         v_mtl_lot_numbers.supplier_lot_number,
                         v_mtl_lot_numbers.country_of_origin,
                         v_mtl_lot_numbers.grade_code,
                         v_mtl_lot_numbers.origination_date,
                         v_mtl_lot_numbers.date_code,
                         v_mtl_lot_numbers.status_id,
                         v_mtl_lot_numbers.change_date,
                         v_mtl_lot_numbers.age,
                         v_mtl_lot_numbers.retest_date,
                         v_mtl_lot_numbers.maturity_date,
                         v_mtl_lot_numbers.lot_attribute_category,
                         v_mtl_lot_numbers.item_size,
                         v_mtl_lot_numbers.color,
                         v_mtl_lot_numbers.volume,
                         v_mtl_lot_numbers.volume_uom,
                         v_mtl_lot_numbers.place_of_origin,
                         v_mtl_lot_numbers.kill_date,
                         v_mtl_lot_numbers.best_by_date,
                         v_mtl_lot_numbers.LENGTH,
                         v_mtl_lot_numbers.length_uom,
                         v_mtl_lot_numbers.recycled_content,
                         v_mtl_lot_numbers.thickness,
                         v_mtl_lot_numbers.thickness_uom,
                         v_mtl_lot_numbers.width,
                         v_mtl_lot_numbers.width_uom,
                         v_mtl_lot_numbers.curl_wrinkle_fold,
                         v_mtl_lot_numbers.c_attribute1,
                         v_mtl_lot_numbers.c_attribute2,
                         v_mtl_lot_numbers.c_attribute3,
                         v_mtl_lot_numbers.c_attribute4,
                         v_mtl_lot_numbers.c_attribute5,
                         v_mtl_lot_numbers.c_attribute6,
                         v_mtl_lot_numbers.c_attribute7,
                         v_mtl_lot_numbers.c_attribute8,
                         v_mtl_lot_numbers.c_attribute9,
                         v_mtl_lot_numbers.c_attribute10,
                         v_mtl_lot_numbers.c_attribute11,
                         v_mtl_lot_numbers.c_attribute12,
                         v_mtl_lot_numbers.c_attribute13,
                         v_mtl_lot_numbers.c_attribute14,
                         v_mtl_lot_numbers.c_attribute15,
                         v_mtl_lot_numbers.c_attribute16,
                         v_mtl_lot_numbers.c_attribute17,
                         v_mtl_lot_numbers.c_attribute18,
                         v_mtl_lot_numbers.c_attribute19,
                         v_mtl_lot_numbers.c_attribute20,
                         v_mtl_lot_numbers.c_attribute21,
                         v_mtl_lot_numbers.c_attribute22,
                         v_mtl_lot_numbers.c_attribute23,
                         v_mtl_lot_numbers.c_attribute24,
                         v_mtl_lot_numbers.c_attribute25,
                         v_mtl_lot_numbers.c_attribute26,
                         v_mtl_lot_numbers.c_attribute27,
                         v_mtl_lot_numbers.c_attribute28,
                         v_mtl_lot_numbers.c_attribute29,
                         v_mtl_lot_numbers.c_attribute30,
                         v_mtl_lot_numbers.d_attribute1,
                         v_mtl_lot_numbers.d_attribute2,
                         v_mtl_lot_numbers.d_attribute3,
                         v_mtl_lot_numbers.d_attribute4,
                         v_mtl_lot_numbers.d_attribute5,
                         v_mtl_lot_numbers.d_attribute6,
                         v_mtl_lot_numbers.d_attribute7,
                         v_mtl_lot_numbers.d_attribute8,
                         v_mtl_lot_numbers.d_attribute9,
                         v_mtl_lot_numbers.d_attribute10,
                         v_mtl_lot_numbers.d_attribute11,
                         v_mtl_lot_numbers.d_attribute12,
                         v_mtl_lot_numbers.d_attribute13,
                         v_mtl_lot_numbers.d_attribute14,
                         v_mtl_lot_numbers.d_attribute15,
                         v_mtl_lot_numbers.d_attribute16,
                         v_mtl_lot_numbers.d_attribute17,
                         v_mtl_lot_numbers.d_attribute18,
                         v_mtl_lot_numbers.d_attribute19,
                         v_mtl_lot_numbers.d_attribute20,
                         v_mtl_lot_numbers.n_attribute1,
                         v_mtl_lot_numbers.n_attribute2,
                         v_mtl_lot_numbers.n_attribute3,
                         v_mtl_lot_numbers.n_attribute4,
                         v_mtl_lot_numbers.n_attribute5,
                         v_mtl_lot_numbers.n_attribute6,
                         v_mtl_lot_numbers.n_attribute7,
                         v_mtl_lot_numbers.n_attribute8,
                         v_mtl_lot_numbers.n_attribute9,
                         v_mtl_lot_numbers.n_attribute10,
                         v_mtl_lot_numbers.n_attribute11,
                         v_mtl_lot_numbers.n_attribute12,
                         v_mtl_lot_numbers.n_attribute13,
                         v_mtl_lot_numbers.n_attribute14,
                         v_mtl_lot_numbers.n_attribute15,
                         v_mtl_lot_numbers.n_attribute16,
                         v_mtl_lot_numbers.n_attribute17,
                         v_mtl_lot_numbers.n_attribute18,
                         v_mtl_lot_numbers.n_attribute19,
                         v_mtl_lot_numbers.n_attribute20,
                         v_mtl_lot_numbers.n_attribute21,
                         v_mtl_lot_numbers.n_attribute22,
                         v_mtl_lot_numbers.n_attribute23,
                         v_mtl_lot_numbers.n_attribute24,
                         v_mtl_lot_numbers.n_attribute25,
                         v_mtl_lot_numbers.n_attribute26,
                         v_mtl_lot_numbers.n_attribute27,
                         v_mtl_lot_numbers.n_attribute28,
                         v_mtl_lot_numbers.n_attribute29,
                         v_mtl_lot_numbers.n_attribute30,
                         v_mtl_lot_numbers.vendor_id,
                         v_mtl_lot_numbers.territory_code,
                         v_mtl_lot_numbers.parent_lot_number,
                         v_mtl_lot_numbers.origination_type,
                         v_mtl_lot_numbers.availability_type,
                         v_mtl_lot_numbers.expiration_action_code,
                         v_mtl_lot_numbers.expiration_action_date,
                         v_mtl_lot_numbers.hold_date,
                         v_mtl_lot_numbers.inventory_atp_code,
                         v_mtl_lot_numbers.reservable_type,
                         v_mtl_lot_numbers.sampling_event_id
                    FROM mtl_lot_numbers
                   WHERE     inventory_item_id = i.inventory_item_id
                         AND organization_id = i.io
                         AND lot_number = i.lot_number;

                  v_mtl_lot_numbers.d_attribute1 := i.mfg_date_ref;

                  inv_lot_api_pub.update_inv_lot (
                     x_return_status   => v_status,
                     x_msg_count       => v_msg_count,
                     x_msg_data        => v_msg_data,
                     x_lot_rec         => x_mtl_lot_numbers,
                     p_lot_rec         => v_mtl_lot_numbers,
                     p_source          => 2,
                     p_api_version     => 1,
                     p_init_msg_list   => fnd_api.g_false,
                     p_commit          => fnd_api.g_false);


                  IF v_status <> 'S'
                  THEN
                     v_msg_data := 'API Update Lot - Error (';

                     FOR i IN 1 .. fnd_msg_pub.count_msg
                     LOOP
                        v_msg_data :=
                              v_msg_data
                           || '--'
                           || fnd_msg_pub.get (p_msg_index   => i,
                                               p_encoded     => 'F');
                     END LOOP;

                     v_message :=
                           'Error while Updating Lot Number for Misc. Receipt. Message: '
                        || v_msg_data;
                     logf ('v_message: ' || v_message);
                  ELSE
                     Logf ('Manufacturing Data ter-update');
                  END IF;
               END IF;
            ELSE
               IF v_msg_count = 1
               THEN
                  v_error_msg := v_msg_data;
               ELSE
                  v_error_msg := NULL;

                  LOOP
                     p_count := p_count + 1;
                     v_msg_data :=
                        fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false);

                     IF v_msg_data IS NULL
                     THEN
                        EXIT;
                     END IF;

                     IF v_error_msg IS NOT NULL
                     THEN
                        v_error_msg := v_error_msg || ' | ';
                     END IF;

                     v_error_msg := v_error_msg || v_msg_data;
                  END LOOP;
               END IF;
            END IF;

            COMMIT;
         END LOOP;
      END LOOP;

      IF v_return_status = 'S'
      THEN
         -- Jika status sukses maka akan mengirimkan email notifikasi update
         XXSHP_GMD_CHG_LOT_STS_BO_PKG.send_mail (v_errbuf,
                                                 v_retcode,
                                                 v_result,
                                                 p_email,
                                                 v_count_proses,
                                                 v_exp_date);

         logf ('Sukses.');
         logf (v_lot_number);
      END IF;

      -- Calculate Result setelah update
      BEGIN
         SELECT COUNT (1)
           INTO v_data_akhir
           FROM (SELECT DISTINCT c.*
                   FROM mtl_onhand_quantities_detail a
                        INNER JOIN mtl_system_items b
                           ON     a.organization_id = b.organization_id
                              AND a.inventory_item_id = b.inventory_item_id
                        INNER JOIN MTL_LOT_NUMBERS c
                           ON     b.organization_id = c.organization_id
                              AND b.inventory_item_id = c.inventory_item_id
                              AND a.LOT_NUMBER = c.LOT_NUMBER
                        INNER JOIN mtl_parameters d
                           ON d.organization_id = a.organization_id
                  WHERE     a.organization_id = g_organization_id
                        AND a.SUBINVENTORY_CODE IN ('RM',
                                                    'PM',
                                                    'IB',
                                                    'UB',
                                                    'UF',
                                                    'INTERMEDIATE',
                                                    'UNSTANDARD')
                        AND c.expiration_date - p_exp_date < SYSDATE
                        AND NOT EXISTS
                                   (SELECT *
                                      FROM mtl_reservations e
                                     WHERE     e.organization_id =
                                                  c.organization_id
                                           AND e.inventory_item_id =
                                                  c.inventory_item_id
                                           AND e.LOT_NUMBER = c.LOT_NUMBER)
                        AND c.status_id <> v_status_id_ref);
      END;

      CASE
         WHEN v_data_awal <> v_data_akhir
         THEN
            retcode := 0;
         ELSE
            retcode := 1;
      END CASE;

      -- Report
      v_data_akhir := 0;
      outf ('==================== Reference ======================');
      outf ('Status id ref : ' || v_status_id_ref);
      outf ('');
      outf ('====================== Result =======================');
      outf (
            RPAD ('IO', 10, ' ')
         || '|'
         || RPAD ('Status Code', 15, ' ')
         || '|'
         || RPAD ('Manufacturing Date', 20, ' '));
      outf (RPAD ('-', 45, '-'));

      FOR report
         IN (SELECT mp.organization_code,
                    mms.status_code,
                    TO_CHAR (mln.d_attribute1, 'DD-MON_RRRR')
                       manufacturing_date,
                    mln.lot_number
               FROM mtl_lot_numbers mln,
                    mtl_Parameters mp,
                    mtl_material_statuses mms
              WHERE     mln.organization_id <> g_organization_id
                    AND mln.inventory_Item_id = v_inventory_item_id
                    AND mln.lot_number = v_lot_number
                    AND mms.status_id = mln.status_id
                    AND mln.organization_id = mp.organization_id)
      LOOP
         v_data_akhir := v_data_akhir + 1;
         outf (
               RPAD (report.organization_code, 10, ' ')
            || '|'
            || RPAD (report.status_Code, 15, ' ')
            || '|'
            || RPAD (report.manufacturing_date, 20, ' '));
      END LOOP;

      IF v_data_akhir = 0
      THEN
         outf ('No Data');
      END IF;
   EXCEPTION
      WHEN v_exp
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Unexpected error while running concurrent. Msg: ' || SQLERRM);
         retcode := 2;
   END change_lot;

   -- Procedure process recipient
   PROCEDURE process_recipients (p_mail_conn   IN OUT UTL_SMTP.connection,
                                 p_list        IN     VARCHAR2)
   AS
      l_tab   string_api.t_split_array;
   BEGIN
      IF TRIM (p_list) IS NOT NULL
      THEN
         l_tab := string_api.split_text (p_list);

         FOR i IN 1 .. l_tab.COUNT
         LOOP
            UTL_SMTP.rcpt (p_mail_conn, TRIM (l_tab (i)));
         END LOOP;
      END IF;
   END process_recipients;

   -- Procedure Kirim E-mail
   PROCEDURE send_mail (errbuf              OUT VARCHAR2,
                        retcode             OUT VARCHAR2,
                        p_result            OUT VARCHAR2,
                        p_email          IN     VARCHAR2,
                        p_total_update   IN     VARCHAR2,
                        p_exp_date       IN     NUMBER)
   IS
      v_result                   VARCHAR2 (500);
      -- p_to                       VARCHAR2 (2000) := 'ardianto.ardi@kalbenutritionals.com';
      p_to                       VARCHAR2 (2000) := p_email; --'wilson.chandra@kalbenutritionals.com';
      --p_to                       VARCHAR2 (2000) := 'preparasi@kalbenutritionals.com, cuncun@kalbenutritionals.com';
      p_cc                       VARCHAR2 (2000);
      p_bcc                      VARCHAR2 (2000);
      lv_smtp_server             VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ln_counter                 NUMBER := 0;
      ln_cnt                     NUMBER;
      ld_date                    DATE;
      v_filename                 VARCHAR2 (100);
      v_filename_group           VARCHAR2 (100);


      CURSOR cur_data (p_io_cur IN NUMBER, p_expired_date_cur IN NUMBER)
      IS
         SELECT ROWNUM no_baris,
                inventory_item_id,
                segment1,
                description,
                status_id,
                old_status_id,
                organization_id,
                lot_number,
                primary_transaction_quantity,
                expiration_date,
                parent_lot_number,
                origination_type,
                availability_type,
                expiration_action_date,
                'update_status_id_lot_bo' filename,
                'update_status_id_lot_bo' filename_group
           FROM t_lot_number_temp;
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

      fnd_file.put_line (fnd_file.LOG, fnd_global.conc_request_id);

      ld_date := SYSDATE;
      lv_domain := lv_smtp_server;

      BEGIN
         v_connection := UTL_SMTP.open_connection (lv_smtp_server, 25); --To open the connection
         UTL_SMTP.helo (v_connection, lv_smtp_server);
         UTL_SMTP.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
         --UTL_SMTP.rcpt (v_connection, p_to); -- To send mail to valid receipent
         UTL_SMTP.open_data (v_connection);
         UTL_SMTP.write_data (
            v_connection,
               'Date: '
            || TO_CHAR (SYSDATE, 'Dy, DD Mon YYYY hh24:mi:ss')
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'From: ' || lv_from || UTL_TCP.crlf);

         IF TRIM (p_to) IS NOT NULL
         THEN
            --DBMS_OUTPUT.put_line ('POINT To: ');
            UTL_SMTP.write_data (v_connection,
                                 'To: ' || p_to || UTL_TCP.crlf);
         END IF;

         IF TRIM (p_cc) IS NOT NULL
         THEN
            --DBMS_OUTPUT.put_line ('POINT Cc: ');
            UTL_SMTP.write_data (v_connection,
                                 'Cc: ' || p_cc || UTL_TCP.crlf);
         END IF;

         --DBMS_OUTPUT.put_line ('POINT Sub: ');
         UTL_SMTP.write_data (
            v_connection,
               'Subject: Email Notification Change Lot Status BO'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'MIME-Version: 1.0' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               'Content-Type: multipart/mixed; boundary="'
            || c_mime_boundary
            || '"'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'This is a multi-part message in MIME format.' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'Content-Type: text/plain' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'Content-Transfer_Encoding: 7bit' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, '' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               'NOTE - Please do not reply since this is an automatically generated e-mail'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'Total Data ' || p_total_update || ' Was updated' || UTL_TCP.crlf);

         v_filename := 'kosong';
         v_filename_group := 'kosong';

         FOR i
            IN cur_data (p_io_cur             => g_organization_id,
                         p_expired_date_cur   => p_exp_date)
         LOOP
            IF (v_filename_group <> i.filename_group)
            THEN
               v_filename := i.filename;
               v_filename_group := i.filename_group;

               UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
               UTL_SMTP.write_data (v_connection,
                                    '--' || c_mime_boundary || UTL_TCP.crlf);
               ln_cnt := 1;

               /*Condition to check for the creation of csv attachment*/
               IF (ln_cnt <> 0)
               THEN
                  UTL_SMTP.write_data (
                     v_connection,
                        'Content-Disposition: attachment; filename="'
                     || v_filename
                     || '.csv'
                     || '"'
                     || UTL_TCP.crlf);
               END IF;

               UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);

               v_clob :=
                     'No,Item ID,Item Code,Item Description,Lot Number,Status ID,Old Status ID,Transaction Quantity,Expiration Date,Parent Lot Number,Origination Type,Availability Type,Expiration Action Date,File Name'
                  || UTL_TCP.crlf;

               UTL_SMTP.write_data (v_connection, v_clob);
            END IF;

            ln_counter := ln_counter + 1;

            --                IF ln_counter = 1 THEN
            --                    UTL_SMTP.write_data (v_connection, v_clob);--To avoid repeation of column heading in csv file
            --                END IF;
            BEGIN
               v_clob :=
                     i.no_baris
                  || ','
                  || i.inventory_item_id
                  || ','
                  || i.segment1
                  || ','
                  || i.description
                  || ','
                  || i.lot_number
                  || ','
                  || i.status_id
                  || ','
                  || i.old_status_id
                  || ','
                  || i.primary_transaction_quantity
                  || ','
                  || i.expiration_date
                  || ','
                  || i.parent_lot_number
                  || ','
                  || i.origination_type
                  || ','
                  || i.availability_type
                  || ','
                  || i.expiration_action_date
                  || ','
                  || v_filename
                  || UTL_TCP.crlf;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line (fnd_file.LOG, SQLERRM);
                  v_result := SQLERRM;
            END;

            UTL_SMTP.write_data (v_connection, v_clob); --Writing data in csv attachment.
         END LOOP;

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

         -- Delete all data from tabel temporary
         DELETE FROM t_lot_number_temp;

         COMMIT;
         DBMS_OUTPUT.put_line ('POINT Last: ');
         p_result := 'Success. Email Sent To ' || p_to;
         fnd_file.put_line (fnd_file.LOG, p_result);
      --return v_result;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_result := SQLERRM;
            fnd_file.put_line (fnd_file.LOG, v_result);
            DBMS_OUTPUT.put_line (SQLERRM);
      END;
   END send_mail;
END XXSHP_GMD_CHG_LOT_STS_BO_PKG;
/
