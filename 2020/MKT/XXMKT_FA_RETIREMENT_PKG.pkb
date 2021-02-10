CREATE OR REPLACE PACKAGE BODY APPS.xxmkt_fa_retirement_pkg
/* $Header: XXMKT_FA_RETIREMENT_PKG 122.5.1.0 2016/11/21 10:44:00 Hansen Darmawan $ */
AS
/**************************************************************************************************
       NAME: XXMKT_FA_RETIREMENT_PKG
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         21-Nov-2016          Hansen Darmawan     1. Created this package.
       1.0         04-Aug-2020          Ardi                2. Copy package from SHP
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

   /*PROCEDURE retirement_disp IS
   BEGIN
    NULL;
   END;

   PROCEDURE retirement_sale IS
   BEGIN
    NULL;
   END;*/
   PROCEDURE waitforrequest (v_requestid IN NUMBER, v_out_status OUT VARCHAR2, v_out_errormessage OUT VARCHAR2)
   IS
      v_result      BOOLEAN;
      v_phase       VARCHAR2 (20);
      v_devphase    VARCHAR2 (20);
      v_devstatus   VARCHAR2 (20);
   BEGIN
      v_result := fnd_concurrent.wait_for_request (v_requestid, 5, 0, v_phase, v_out_status, v_devphase, v_devstatus, v_out_errormessage);
   END;

   PROCEDURE print_output (p_type VARCHAR2)
   IS
      v_cnt         NUMBER;
      e_exception   EXCEPTION;
   BEGIN
      SELECT COUNT (*)
        INTO v_cnt
        FROM xxmkt_fa_retirement
       WHERE request_id = g_request_id AND status = 'E';

      IF v_cnt = 0
      THEN
         RAISE e_exception;
      END IF;

      outf (' ');
      outf ('----- PRINT ERROR DATA -----');
      outf (' ');

      IF p_type = 'DISPOSAL/CORRECTION'
      THEN
         outf (   RPAD ('Book Type Code', 20, ' ')
               || '|'
               || RPAD ('Serial Number', 20, ' ')
               || '|'
               || RPAD ('Cost Retired', 15, ' ')
               || '|'
               || RPAD ('Cost of Removal', 18, ' ')
               || '|'
               || RPAD ('Retirement Date', 18, ' ')
               || '|'
               || RPAD ('Retirement Type', 18, ' ')
               || '|'
               || RPAD ('Status', 8, ' ')
               || '|'
               || RPAD ('Error Message', 100, ' ')
              );
      ELSIF p_type = 'SALE'
      THEN
         outf (   RPAD ('Book Type Code', 20, ' ')
               || '|'
               || RPAD ('Serial Number', 20, ' ')
               || '|'
               || RPAD ('Cost Retired', 15, ' ')
               || '|'
               || RPAD ('Proceeds of Sale', 18, ' ')
               || '|'
               || RPAD ('Retirement Date', 18, ' ')
               || '|'
               || RPAD ('Retirement Type', 18, ' ')
               || '|'
               || RPAD ('Customer Id', 15, ' ')
               || '|'
               || RPAD ('Status', 8, ' ')
               || '|'
               || RPAD ('Error Message', 100, ' ')
              );
      END IF;

      FOR i IN (SELECT *
                  FROM xxmkt_fa_retirement
                 WHERE request_id = g_request_id AND status = 'E')
      LOOP
         IF p_type = 'DISPOSAL/CORRECTION'
         THEN
            outf (   RPAD (i.book_type_code, 20, ' ')
                  || '|'
                  || RPAD (i.serial_number, 20, ' ')
                  || '|'
                  || RPAD (i.cost_retired, 15, ' ')
                  || '|'
                  || RPAD (i.cost_of_removal, 18, ' ')
                  || '|'
                  || RPAD (i.retirement_date, 18, ' ')
                  || '|'
                  || RPAD (i.retirement_type, 18, ' ')
                  || '|'
                  || RPAD (i.status, 8, ' ')
                  || '|'
                  || RPAD (i.error_message, 200, ' ')
                 );
         ELSIF p_type = 'SALE'
         THEN
            outf (   RPAD (i.book_type_code, 20, ' ')
                  || '|'
                  || RPAD (i.serial_number, 20, ' ')
                  || '|'
                  || RPAD (i.cost_retired, 15, ' ')
                  || '|'
                  || RPAD (i.proceeds_of_sale, 18, ' ')
                  || '|'
                  || RPAD (i.retirement_date, 18, ' ')
                  || '|'
                  || RPAD (i.retirement_type, 18, ' ')
                  || '|'
                  || RPAD (i.customer_id, 15, ' ')
                  || '|'
                  || RPAD (i.status, 8, ' ')
                  || '|'
                  || RPAD (i.error_message, 200, ' ')
                 );
         END IF;
      END LOOP;
   EXCEPTION
      WHEN e_exception
      THEN
         outf ('ALL DATA PROCESSED SUCCESSFULLY');
   END;

   PROCEDURE retire_asset (
      p_serial_number      VARCHAR2,
      p_asset_id           NUMBER,
      p_book_type_code     VARCHAR2,
      p_cost_retired       NUMBER,
      p_cost_of_removal    NUMBER,
      p_retirement_type    VARCHAR2,
      p_retirement_date    DATE,
      p_proceeds_of_sale   NUMBER,
      p_comment            VARCHAR2
   )
   IS
      v_trans_rec          fa_api_types.trans_rec_type;
      v_dist_trans_rec     fa_api_types.trans_rec_type;
      v_asset_hdr_rec      fa_api_types.asset_hdr_rec_type;
      v_asset_retire_rec   fa_api_types.asset_retire_rec_type;
      v_asset_dist_tbl     fa_api_types.asset_dist_tbl_type;
      v_subcomp_tbl        fa_api_types.subcomp_tbl_type;
      v_inv_tbl            fa_api_types.inv_tbl_type;
      v_return_status      VARCHAR2 (1);
      v_msg_count          NUMBER;
      v_msg_data           VARCHAR2 (512);
      v_errmsg             VARCHAR2 (512);
      v_err_api            NUMBER                             := 0;
      v_gain_loss_req_id   NUMBER;
   BEGIN
      v_trans_rec.who_info.last_updated_by := g_user_id;
      v_trans_rec.who_info.last_update_date := SYSDATE;
      v_trans_rec.who_info.creation_date := SYSDATE;
      v_trans_rec.who_info.created_by := g_user_id;
      v_trans_rec.transaction_name := p_comment;
      v_asset_hdr_rec.asset_id := p_asset_id;
      v_asset_hdr_rec.book_type_code := p_book_type_code;
      v_asset_retire_rec.date_retired := p_retirement_date;
      v_asset_retire_rec.cost_retired := p_cost_retired;
      v_asset_retire_rec.cost_of_removal := p_cost_of_removal;
      v_asset_retire_rec.retirement_type_code := p_retirement_type;
      v_asset_retire_rec.calculate_gain_loss := fnd_api.g_false;
      v_asset_retire_rec.proceeds_of_sale := p_proceeds_of_sale;
      fa_retirement_pub.do_retirement (p_api_version            => 1,
                                       p_init_msg_list          => fnd_api.g_false,
                                       p_commit                 => fnd_api.g_true,
                                       p_validation_level       => fnd_api.g_valid_level_full,
                                       p_calling_fn             => 'Retirement Aset wrapper',
                                       x_return_status          => v_return_status,
                                       x_msg_count              => v_msg_count,
                                       x_msg_data               => v_msg_data,
                                       px_trans_rec             => v_trans_rec,
                                       px_dist_trans_rec        => v_dist_trans_rec,
                                       px_asset_hdr_rec         => v_asset_hdr_rec,
                                       px_asset_retire_rec      => v_asset_retire_rec,
                                       p_asset_dist_tbl         => v_asset_dist_tbl,
                                       p_subcomp_tbl            => v_subcomp_tbl,
                                       p_inv_tbl                => v_inv_tbl
                                      );

      IF (v_return_status = 'S') AND v_msg_count = 0
      THEN
         UPDATE xxmkt_fa_retirement
            SET status = 'C',
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;

--         COMMIT;
         logf ('Asset for Serial Number ' || p_serial_number || ' Retired Succesfully ');
--         DBMS_OUTPUT.put_line (   'Asset for Serial Number '
--                               || p_serial_number
--                               || ' Retired Succesfully '
--                              );
      ELSIF v_msg_count > 0
      THEN
         v_err_api := 1;

         FOR l_index IN 1 .. v_msg_count
         LOOP
            v_errmsg := v_errmsg || ', ' || SUBSTR (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 255) || ' => ' || SQLERRM;
         END LOOP;
      ELSE
         v_err_api := 1;
         v_errmsg := v_errmsg || ', ' || 'ERROR execute API Retirement : ' || SQLERRM;
         logf ('ERROR execute API Retirement : ' || SQLERRM);
--         DBMS_OUTPUT.put_line ('ERROR execute API Retirement : ' || SQLERRM);
      END IF;

      IF v_err_api = 1
      THEN
         UPDATE xxmkt_fa_retirement
            SET status = 'E',
                error_message = v_errmsg,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;
--         COMMIT;
      END IF;
   END;

   PROCEDURE create_invoice (
      p_trx_source_id            NUMBER,
      p_retirement_date          DATE,
      p_serial_number            VARCHAR2,
      p_trx_type_id              NUMBER,
      p_customer_id              NUMBER,
      p_bill_site_use_id         NUMBER,
      p_term_id                  NUMBER,
      p_retirement_type          VARCHAR2,
      p_proceeds_of_sale         NUMBER,
      p_ccid                     NUMBER,
      p_desc                     VARCHAR2,
      v_msg_count          OUT   NUMBER
   )
   IS
      v_return_status          VARCHAR2 (1);
      --v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (512);
      v_customer_trx_id        NUMBER;
      v_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type;
      v_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type;
      v_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type;
      v_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type;
      v_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type;
      v_errmsg                 VARCHAR2 (3000)                              := NULL;
      v_trx_header_id          NUMBER;
      v_trx_line_id            NUMBER;
      v_trx_dist_id            NUMBER;
      v_cnt                    NUMBER;
      v_trx_number             VARCHAR2 (20);
   BEGIN
--        DBMS_OUTPUT.PUT_LINE('p_trx_source_id : '||p_trx_source_id);
--        DBMS_OUTPUT.PUT_LINE('p_retirement_date : '||p_retirement_date);
--        DBMS_OUTPUT.PUT_LINE('p_serial_number : '||p_serial_number);
--        DBMS_OUTPUT.PUT_LINE('p_trx_type_id : '||p_trx_type_id);
--        DBMS_OUTPUT.PUT_LINE('p_customer_id : '||p_customer_id);
--
--        DBMS_OUTPUT.PUT_LINE('p_bill_site_use_id : '||p_bill_site_use_id);
--        DBMS_OUTPUT.PUT_LINE('p_term_id : '||p_term_id);
--        DBMS_OUTPUT.PUT_LINE('p_retirement_type : '||p_retirement_type);
--        DBMS_OUTPUT.PUT_LINE('p_proceeds_of_sale : '||p_proceeds_of_sale);

      --        fnd_global.apps_initialize (g_user_id, 50757, 222);
--      mo_global.set_policy_context ('S', 83);
      SELECT ra_customer_trx_s.NEXTVAL
        INTO v_trx_header_id
        FROM DUAL;

      SELECT ra_customer_trx_lines_s.NEXTVAL
        INTO v_trx_line_id
        FROM DUAL;

      SELECT ra_cust_trx_line_gl_dist_s.NEXTVAL
        INTO v_trx_dist_id
        FROM DUAL;

--      logf ('v_trx_header_id : ' || v_trx_header_id);
--      logf ('v_trx_line_id : ' || v_trx_line_id);
--      logf ('v_trx_dist_id : ' || v_trx_dist_id);
      v_batch_source_rec.batch_source_id := p_trx_source_id;
      v_trx_header_tbl (1).trx_header_id := v_trx_header_id;
      --ra_customer_trx_s.NEXTVAL;
      v_trx_header_tbl (1).trx_date := p_retirement_date;
      v_trx_header_tbl (1).trx_currency := 'IDR';
      v_trx_header_tbl (1).reference_number := p_serial_number;
      v_trx_header_tbl (1).cust_trx_type_id := p_trx_type_id;
      v_trx_header_tbl (1).bill_to_customer_id := p_customer_id;
      v_trx_header_tbl (1).bill_to_site_use_id := p_bill_site_use_id;
      v_trx_header_tbl (1).term_id := p_term_id;
      v_trx_lines_tbl (1).trx_header_id := v_trx_header_id;
      --ra_customer_trx_s.CURRVAL;
      v_trx_lines_tbl (1).trx_line_id := v_trx_line_id;
      --ra_customer_trx_lines_s.NEXTVAL;
      v_trx_lines_tbl (1).line_number := 1;
      v_trx_lines_tbl (1).description := p_desc;
      v_trx_lines_tbl (1).quantity_invoiced := 1;
      v_trx_lines_tbl (1).unit_selling_price := p_proceeds_of_sale;
      v_trx_lines_tbl (1).line_type := 'LINE';
      v_trx_dist_tbl (1).trx_header_id := v_trx_header_id;
      --ra_customer_trx_s.CURRVAL;
      v_trx_dist_tbl (1).trx_line_id := v_trx_line_id;
      --ra_customer_trx_lines_s.CURRVAL;
      v_trx_dist_tbl (1).trx_dist_id := v_trx_dist_id;
      --ra_cust_trx_line_gl_dist_s.NEXTVAL;
      v_trx_dist_tbl (1).account_class := 'REV';
      v_trx_dist_tbl (1).PERCENT := 100;
      v_trx_dist_tbl (1).code_combination_id := p_ccid;
      ar_invoice_api_pub.create_single_invoice (p_api_version               => 1,
                                                p_batch_source_rec          => v_batch_source_rec,
                                                p_trx_header_tbl            => v_trx_header_tbl,
                                                p_trx_lines_tbl             => v_trx_lines_tbl,
                                                p_trx_dist_tbl              => v_trx_dist_tbl,
                                                p_trx_salescredits_tbl      => v_trx_salescredits_tbl,
                                                x_customer_trx_id           => v_customer_trx_id,
                                                x_return_status             => v_return_status,
                                                x_msg_count                 => v_msg_count,
                                                x_msg_data                  => v_msg_data
                                               );

--      DBMS_OUTPUT.put_line ('v_msg_cnt : ' || v_msg_count);
      BEGIN
         SELECT COUNT (*)
           INTO v_cnt
           FROM ar_trx_errors_gt;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_cnt := 0;
      END;

      IF v_cnt > 0
      THEN
         FOR l IN (SELECT *
                     FROM ar_trx_errors_gt)
         LOOP
--               DBMS_OUTPUT.PUT_LINE ('error_message : ' || l.error_message);
            v_errmsg := v_errmsg || ', ' || l.error_message;
         END LOOP;
      END IF;

      IF (v_return_status = 'S') AND NVL (v_msg_count, 0) = 0
      THEN
         UPDATE xxmkt_fa_retirement
            SET customer_trx_id = v_customer_trx_id,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;

--         COMMIT;
         SELECT rct.trx_number
           INTO v_trx_number
           FROM ra_customer_trx_all rct
          WHERE customer_trx_id = v_customer_trx_id;

         logf (   'Invoice for Serial Number '
               || p_serial_number
               || ' Created Successfully With ID : '
               || v_customer_trx_id
               || ' And Transaction Number '
               || v_trx_number
              );
         outf ('Invoice for Serial Number ' || p_serial_number || ' Created Successfully With Transaction Number ' || v_trx_number);
--         DBMS_OUTPUT.put_line (   'Invoice for Serial Number '
--                               || p_serial_number
--                               || ' Created Succesfully With ID : '
--                               || v_customer_trx_id
--                              );
      ELSIF v_msg_count > 0
      THEN
         FOR l_index IN 1 .. v_msg_count
         LOOP
            v_errmsg := v_errmsg || ', ' || SUBSTR (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 255) || ' => ' || SQLERRM;
         END LOOP;
      ELSE
         v_msg_count := 1;
         v_errmsg := v_errmsg || ', ' || 'ERROR execute API Create Invoice : ' || SQLERRM;
         logf ('ERROR execute API Create Invoice : ' || SQLERRM);
--         DBMS_OUTPUT.put_line ('ERROR execute API Create Invoice : '
--                               || SQLERRM
--                              );
      END IF;

      IF v_errmsg IS NOT NULL
      THEN
         UPDATE xxmkt_fa_retirement
            SET status = 'E',
                error_message = v_errmsg,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE serial_number = p_serial_number AND request_id = g_request_id;
--         COMMIT;
      END IF;
   END;

   PROCEDURE create_invoice_group (
      p_trx_source_id      NUMBER,
      p_invoice_group      VARCHAR2,
      p_customer_id        NUMBER,
      p_trx_type_id        NUMBER,
      p_bill_site_use_id   NUMBER,
      p_payment_term_id    NUMBER,
      p_retirement_date    DATE
   )
   IS
      v_trx_header_id          NUMBER;
      v_trx_line_id            NUMBER;
      v_trx_dist_id            NUMBER;
      v_line_index             NUMBER                                       := 0;
      v_dist_index             NUMBER                                       := 0;
      v_customer_trx_id        NUMBER;
      v_batch_source_rec       ar_invoice_api_pub.batch_source_rec_type;
      v_trx_header_tbl         ar_invoice_api_pub.trx_header_tbl_type;
      v_trx_lines_tbl          ar_invoice_api_pub.trx_line_tbl_type;
      v_trx_dist_tbl           ar_invoice_api_pub.trx_dist_tbl_type;
      v_trx_salescredits_tbl   ar_invoice_api_pub.trx_salescredits_tbl_type;
      v_return_status          VARCHAR2 (1);
      v_msg_count              NUMBER;
      v_msg_data               VARCHAR2 (512);
      v_cnt                    NUMBER;
      v_errmsg                 VARCHAR2 (3000)                              := NULL;
      v_trx_number             VARCHAR2 (20);
      v_gain_loss_req_id       NUMBER;
      v_out_status             VARCHAR2 (240);
      v_out_errormessage       VARCHAR2 (240);
   BEGIN
      SELECT ra_customer_trx_s.NEXTVAL
        INTO v_trx_header_id
        FROM DUAL;

      v_batch_source_rec.batch_source_id := p_trx_source_id;
      v_trx_header_tbl (1).trx_header_id := v_trx_header_id;
      v_trx_header_tbl (1).trx_date := p_retirement_date;
      v_trx_header_tbl (1).trx_currency := 'IDR';
      v_trx_header_tbl (1).cust_trx_type_id := p_trx_type_id;
      v_trx_header_tbl (1).bill_to_customer_id := p_customer_id;
      v_trx_header_tbl (1).bill_to_site_use_id := p_bill_site_use_id;
      v_trx_header_tbl (1).term_id := p_payment_term_id;

      FOR i IN (SELECT *
                  FROM xxmkt_fa_retirement
                 WHERE request_id = g_request_id
                   AND GROUP_ID = g_user_id
                   AND status IS NULL
                   AND UPPER (retirement_type) IN ('SALE AFFI', 'SALE N-AFFI')
                   AND trx_source_id = p_trx_source_id
                   AND invoice_group = p_invoice_group
                   AND customer_id = p_customer_id
                   AND trx_type_id = p_trx_type_id
                   AND bill_site_use_id = p_bill_site_use_id
                   AND payment_term_id = p_payment_term_id
                   AND retirement_date = p_retirement_date)
      LOOP
         logf ('looping line ' || i.serial_number);
         v_line_index := v_line_index + 1;
         v_dist_index := v_dist_index + 1;

         SELECT ra_customer_trx_lines_s.NEXTVAL
           INTO v_trx_line_id
           FROM DUAL;

         SELECT ra_cust_trx_line_gl_dist_s.NEXTVAL
           INTO v_trx_dist_id
           FROM DUAL;

         v_trx_lines_tbl (v_line_index).trx_header_id := v_trx_header_id;
         v_trx_lines_tbl (v_line_index).trx_line_id := v_trx_line_id;
         v_trx_lines_tbl (v_line_index).line_number := v_line_index;
         v_trx_lines_tbl (v_line_index).description := i.description;
         v_trx_lines_tbl (v_line_index).quantity_invoiced := 1;
         v_trx_lines_tbl (v_line_index).unit_selling_price := i.proceeds_of_sale;
         v_trx_lines_tbl (v_line_index).line_type := 'LINE';
         --Added by EY on 9-Jun-2017
         v_trx_lines_tbl (v_line_index).tax_classification_code := g_ar_tax_code;
         --End EY
         v_trx_dist_tbl (v_dist_index).trx_header_id := v_trx_header_id;
         v_trx_dist_tbl (v_dist_index).trx_line_id := v_trx_line_id;
         v_trx_dist_tbl (v_dist_index).trx_dist_id := v_trx_dist_id;
         v_trx_dist_tbl (v_dist_index).account_class := 'REV';
         v_trx_dist_tbl (v_dist_index).PERCENT := 100;
         v_trx_dist_tbl (v_dist_index).code_combination_id := i.code_combination_id;
      END LOOP;

      ar_invoice_api_pub.create_single_invoice (p_api_version               => 1,
                                                p_batch_source_rec          => v_batch_source_rec,
                                                p_trx_header_tbl            => v_trx_header_tbl,
                                                p_trx_lines_tbl             => v_trx_lines_tbl,
                                                p_trx_dist_tbl              => v_trx_dist_tbl,
                                                p_trx_salescredits_tbl      => v_trx_salescredits_tbl,
                                                x_customer_trx_id           => v_customer_trx_id,
                                                x_return_status             => v_return_status,
                                                x_msg_count                 => v_msg_count,
                                                x_msg_data                  => v_msg_data
                                               );

      BEGIN
         SELECT COUNT (*)
           INTO v_cnt
           FROM ar_trx_errors_gt;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_cnt := 0;
      END;

      IF v_cnt > 0
      THEN
         FOR l IN (SELECT *
                     FROM ar_trx_errors_gt)
         LOOP
--               DBMS_OUTPUT.PUT_LINE ('error_message : ' || l.error_message);
            v_errmsg := v_errmsg || ', ' || l.error_message;
            logf (v_errmsg);
         END LOOP;
      END IF;

      IF (v_return_status = 'S') AND NVL (v_msg_count, 0) = 0
      THEN
--      logf('update status');
         UPDATE xxmkt_fa_retirement
            SET customer_trx_id = v_customer_trx_id,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE UPPER (retirement_type) IN ('SALE AFFI', 'SALE N-AFFI')
            AND GROUP_ID = g_user_id
            AND trx_source_id = p_trx_source_id
            AND invoice_group = p_invoice_group
            AND customer_id = p_customer_id
            AND trx_type_id = p_trx_type_id
            AND bill_site_use_id = p_bill_site_use_id
            AND payment_term_id = p_payment_term_id
            AND retirement_date = p_retirement_date
            AND request_id = g_request_id;

--        logf('end update status');
--         COMMIT;
         SELECT rct.trx_number
           INTO v_trx_number
           FROM ra_customer_trx_all rct
          WHERE customer_trx_id = v_customer_trx_id;

         logf ('Invoice Created Successfully With ID : ' || v_customer_trx_id || ' And Transaction Number ' || v_trx_number);
         outf ('Invoice Created Successfully With Transaction Number ' || v_trx_number);
               /*FOR j IN (SELECT *
                           FROM xxmkt_fa_retirement
                          WHERE request_id = g_request_id
                            AND GROUP_ID = g_user_id
                            AND status IS NULL
                            AND UPPER (retirement_type) IN
                                                       ('SALE AFFI', 'SALE N-AFFI')
                            AND trx_source_id = p_trx_source_id
                            AND invoice_group = p_invoice_group
                            AND customer_id = p_customer_id
                            AND trx_type_id = p_trx_type_id
                            AND bill_site_use_id = p_bill_site_use_id
                            AND payment_term_id = p_payment_term_id
                            AND retirement_date = p_retirement_date)
               LOOP
                  --calling retire asset
                  logf ('calling retire asset for serial number ' || j.serial_number
                       );
                  retire_asset (j.serial_number,
                                j.asset_id,
                                j.book_type_code,
                                j.cost_retired,
                                j.cost_of_removal,
                                j.retirement_type,
                                j.retirement_date,
                                j.proceeds_of_sale,
                                --j.comments
                                v_trx_number  --KATA ANGGI SIH BEGINI
                               );
                  --call Calculate Gains and Losses concurrent
                  logf ('calling Calculate Gains and Losses');
                  fnd_global.apps_initialize (user_id           => g_user_id,
                                              --1090
                                              resp_id           => g_resp_id,
                                              --50760
                                              resp_appl_id      => g_resp_appl_id
                                             --140
                                             );
                  v_gain_loss_req_id :=
                     fnd_request.submit_request ('OFA',
                                                 'FARET',
                                                 NULL,
                                                 NULL,
                                                 FALSE,
                                                 j.book_type_code
                                                );
                  COMMIT;
      --               DBMS_OUTPUT.put_line (   'v_gain_loss_req_id : '
      --                                     || v_gain_loss_req_id
      --                                    );
                  logf ('Gain Loss Request Id : ' || v_gain_loss_req_id);
                  waitforrequest (v_gain_loss_req_id,
                                  v_out_status,
                                  v_out_errormessage
                                 );
               END LOOP;*/
      ELSIF v_msg_count > 0
      THEN
         FOR l_index IN 1 .. v_msg_count
         LOOP
            v_errmsg := v_errmsg || ', ' || SUBSTR (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 255) || ' => ' || SQLERRM;
         END LOOP;
      ELSE
         v_msg_count := 1;
         v_errmsg := v_errmsg || ', ' || 'ERROR execute API Create Invoice : ' || SQLERRM;
         logf ('ERROR execute API Create Invoice : ' || SQLERRM);
      END IF;

      IF v_errmsg IS NOT NULL
      THEN
         UPDATE xxmkt_fa_retirement
            SET status = 'E',
                error_message = v_errmsg,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE UPPER (retirement_type) IN ('SALE AFFI', 'SALE N-AFFI')
            AND GROUP_ID = g_user_id
            AND trx_source_id = p_trx_source_id
            AND invoice_group = p_invoice_group
            AND customer_id = p_customer_id
            AND trx_type_id = p_trx_type_id
            AND bill_site_use_id = p_bill_site_use_id
            AND payment_term_id = p_payment_term_id
            AND retirement_date = p_retirement_date
            AND request_id = g_request_id;
--         COMMIT;
      END IF;
   END create_invoice_group;

   PROCEDURE main_process (errbuf VARCHAR2, retcode OUT NUMBER, p_retirement_type VARCHAR2)
   IS
      TYPE currtyp IS REF CURSOR;

      v_ret_curr           currtyp;
      v_book_type_code     VARCHAR2 (15);
      v_serial_number      VARCHAR2 (35);
      v_cost_retired       NUMBER;
      v_retirement_date    DATE;
      v_cost_of_removal    NUMBER;
      v_retirement_type    VARCHAR2 (15);
      v_customer_id        NUMBER;
      v_curr_sql           VARCHAR2 (3000);
      v_asset_id           NUMBER;
      v_party_id           NUMBER;
      v_bill_site_use_id   NUMBER;
      v_payment_term_id    NUMBER;
      v_trx_source_id      NUMBER;
      v_trx_type_id        NUMBER;
      v_asset_cost         NUMBER;
      v_book_type          VARCHAR2 (15);
      v_period_counter     NUMBER;
      v_err_cnt            NUMBER          := 0;
      v_err_msg            VARCHAR2 (4000);
      v_gain_loss_req_id   NUMBER;
      v_inv_cnt            NUMBER;
      v_inv_err            NUMBER          := 0;
      v_proceeds_of_sale   NUMBER;
      v_ccid               NUMBER;
      v_out_status         VARCHAR2 (240);
      v_out_errormessage   VARCHAR2 (240);
      v_rowid              ROWID;
      v_desc               VARCHAR2 (240);
      v_comment            VARCHAR2 (30);
      v_sale_err_cnt       NUMBER;
      v_trx_number         VARCHAR2 (100);
   BEGIN
      logf ('----- Start Main Process -----');
--      DBMS_OUTPUT.put_line ('----- Start Main Process -----');
      v_curr_sql :=
            'SELECT book_type_code,serial_number,cost_retired,retirement_date,
         cost_of_removal,retirement_type,customer_id, proceeds_of_sale,rowid,description, comments
         FROM xxmkt_fa_retirement 
         WHERE request_id IS NULL AND GROUP_ID = '
         || g_user_id
         || ' AND upper(retirement_type) in ';

      IF p_retirement_type = 'DISPOSAL/CORRECTION'
      THEN
         v_curr_sql := v_curr_sql || '(''DISPOSAL'', ''CORRECTION'')';
      ELSIF p_retirement_type = 'SALE'
      THEN
         v_curr_sql := v_curr_sql || '(''SALE AFFI'', ''SALE N-AFFI'')';
      END IF;

      logf ('SQL Query : ' || v_curr_sql);

--      DBMS_OUTPUT.put_line ('v_curr_sql : ' || v_curr_sql);
      OPEN v_ret_curr FOR v_curr_sql;

      LOOP
         FETCH v_ret_curr
          INTO v_book_type_code, v_serial_number, v_cost_retired, v_retirement_date, v_cost_of_removal, v_retirement_type, v_customer_id,
               v_proceeds_of_sale, v_rowid, v_desc, v_comment;

         EXIT WHEN v_ret_curr%NOTFOUND;
--         DBMS_OUTPUT.put_line ('loop');
         v_asset_id := NULL;
         v_asset_cost := 0;
         v_err_cnt := 0;
         v_err_msg := NULL;
         v_book_type := NULL;
         v_party_id := NULL;
         v_bill_site_use_id := NULL;
         v_inv_err := 0;
         v_payment_term_id := NULL;
         v_trx_source_id := NULL;
         v_trx_type_id := NULL;
         v_ccid := NULL;
         logf ('running validation for serial number ' || v_serial_number);

         UPDATE xxmkt_fa_retirement
            SET request_id = g_request_id,
                last_updated_by = g_user_id,
                last_update_date = SYSDATE,
                last_update_login = g_login_id
          WHERE ROWID = v_rowid;

         COMMIT;

         --validasi
         BEGIN
            SELECT asset_id
              INTO v_asset_id
              FROM fa_additions fa
             WHERE fa.serial_number = v_serial_number;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_asset_id := NULL;
               v_err_cnt := v_err_cnt + 1;
               v_err_msg := 'Invalid Serial Number';
            WHEN OTHERS
            THEN
               v_asset_id := NULL;
               v_err_cnt := v_err_cnt + 1;
               v_err_msg := 'Serial Number Error ' || SQLERRM;
         END;

--         logf('validasi 1 ok');
         BEGIN
            SELECT book_type_code
              INTO v_book_type
              FROM fa_book_controls fbc
             WHERE fbc.book_type_code = v_book_type_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Invalid Book Type';
            WHEN OTHERS
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Book Type Error ' || SQLERRM;
         END;

--         logf('validasi 2 ok');
         IF v_asset_id IS NOT NULL AND v_book_type IS NOT NULL
         THEN
            SELECT fb.COST
              INTO v_asset_cost
              FROM fa_books fb
             WHERE asset_id = v_asset_id AND book_type_code = v_book_type AND transaction_header_id_out IS NULL;

            IF v_asset_cost <> v_cost_retired
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Cost retired must equal with Asset Cost';
            END IF;
         END IF;

--         logf('validasi 3 ok');

         --         DBMS_OUTPUT.put_line ('v_retirement_date : ' || v_retirement_date);
--         DBMS_OUTPUT.put_line (   'v_retirement_date : '
--                               || TO_CHAR (v_retirement_date, 'MON-YY')
--                              );
         IF v_book_type IS NOT NULL
         THEN
            BEGIN
               SELECT period_counter
                 INTO v_period_counter
                 FROM fa_deprn_periods fdp
                WHERE book_type_code = v_book_type AND period_close_date IS NULL AND period_name = TO_CHAR (v_retirement_date, 'MON-YY');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Retirement Date not In Open Period';
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Retirement Date Error ' || SQLERRM;
            END;
         END IF;

--         logf('validasi 4 ok');

         --validate for retirement_type = 'SALE', for create invoice purpose
         IF p_retirement_type = 'SALE'
         THEN
            BEGIN
               /*SELECT party_id, payment_term_id
                 INTO v_party_id, v_payment_term_id
                 FROM hz_cust_accounts hca
                WHERE cust_account_id = v_customer_id;*/ -- REMARK BY ISH20190528, req by Devo
                
                SELECT DISTINCT HCA.PARTY_ID, RTT.TERM_ID 
                  INTO v_party_id, v_payment_term_id
                  FROM RA_TERMS_TL RTT, HZ_CUST_SITE_USES_ALL HCSU, HZ_CUST_ACCT_SITES_ALL HCAS, HZ_CUST_ACCOUNTS_ALL HCA
                 WHERE 1=1
                   AND RTT.TERM_ID(+) = HCSU.PAYMENT_TERM_ID
                   AND HCAS.CUST_ACCT_SITE_ID = HCSU.CUST_ACCT_SITE_ID  
                   AND HCA.CUST_ACCOUNT_ID    = HCAS.cust_account_id(+)
                   AND HCSU.SITE_USE_CODE = 'BILL_TO'
                   AND HCSU.PRIMARY_FLAG = 'Y'
                   AND HCSU.STATUS = 'A' 
                   AND HCA.CUST_ACCOUNT_ID = v_customer_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Customer Id not Found';
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Customer Id Error ' || SQLERRM;
            END;
            

--            logf('validasi 5 ok');
            IF v_party_id IS NULL
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Party Not Found';
            END IF;

--            logf('validasi 6 ok');

            IF v_payment_term_id IS NULL and v_party_id is not null THEN -- ADD BY ISH 20190628, double searching payment term 
            
               BEGIN
               SELECT payment_term_id
                 INTO v_payment_term_id
                 FROM hz_cust_accounts hca
                WHERE cust_account_id = v_customer_id;
               EXCEPTION WHEN OTHERS THEN
                    v_payment_term_id := NULL;
               END;
                
            END IF;
            
            IF v_payment_term_id IS NULL
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Payment Term Not Found';
            END IF;

--            logf('validasi 7 ok');
            BEGIN
               SELECT hcs.site_use_id
                 INTO v_bill_site_use_id
                 FROM hz_cust_site_uses_all hcs
                WHERE hcs.site_use_code = 'BILL_TO' AND hcs.primary_flag = 'Y' AND cust_acct_site_id IN (SELECT cust_acct_site_id
                                                                                                           FROM hz_cust_acct_sites_all hca
                                                                                                          WHERE cust_account_id = v_customer_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Bill To not Found';
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Bill To Error ' || SQLERRM;
            END;

--            logf('validasi 8 ok');
            SELECT fnd_profile.VALUE ('XXMKT_AR_TX_SOURCE_SALE_ASSET')
              INTO v_trx_source_id
              FROM DUAL;

--              logf('validasi 9 ok');
            IF v_trx_source_id IS NULL
            THEN
               IF v_err_cnt > 0
               THEN
                  v_err_msg := v_err_msg || ', ';
               END IF;

               v_err_cnt := v_err_cnt + 1;
               v_err_msg := v_err_msg || 'Value of Profile ''XXMKT_AR_TX_SOURCE_SALE_ASSET'' not Found';
            END IF;

            BEGIN
               SELECT cust_trx_type_id, gl_id_rev
                 INTO v_trx_type_id, v_ccid
                 FROM ra_cust_trx_types_all
                WHERE attribute1 = v_retirement_type;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Transaction Type not Found';
               WHEN OTHERS
               THEN
                  IF v_err_cnt > 0
                  THEN
                     v_err_msg := v_err_msg || ', ';
                  END IF;

                  v_err_cnt := v_err_cnt + 1;
                  v_err_msg := v_err_msg || 'Transaction Type Error ' || SQLERRM;
            END;
--            logf('validasi 10 ok');
         END IF;

--         logf('v_err_cnt = '||v_err_cnt);
         IF v_err_cnt > 0
         THEN
            UPDATE xxmkt_fa_retirement
               SET status = 'E',
                   error_message = v_err_msg,
--                   request_id = g_request_id,
                   last_updated_by = g_user_id,
                   last_update_date = SYSDATE,
                   last_update_login = g_login_id
             WHERE serial_number = v_serial_number AND request_id = g_request_id;

--            COMMIT;
            retcode := 2;
         ELSE
            UPDATE xxmkt_fa_retirement
               SET asset_id = v_asset_id,
                   party_id = v_party_id,
                   bill_site_use_id = v_bill_site_use_id,
                   payment_term_id = v_payment_term_id,
                   trx_source_id = v_trx_source_id,
                   trx_type_id = v_trx_type_id,
                   code_combination_id = v_ccid,
--                   request_id = g_request_id,
                   last_updated_by = g_user_id,
                   last_update_date = SYSDATE,
                   last_update_login = g_login_id
             WHERE serial_number = v_serial_number AND request_id = g_request_id;

            COMMIT;

            /*IF p_retirement_type = 'SALE'            --affiliate/non-affiliate
                        THEN
                           --check is invoice already exist
                           SELECT COUNT (*)
                             INTO v_inv_cnt
                             FROM ra_customer_trx_all
                            WHERE ct_reference = v_serial_number;

                           IF v_inv_cnt = 0
                           THEN
                              --call AR API
            --                  DBMS_OUTPUT.put_line
            --                              (   'calling create invoice for serial number '
            --                               || v_serial_number
            --                              );
                              logf (   'calling create invoice for serial number '
                                    || v_serial_number
                                   );
                              create_invoice (v_trx_source_id,
                                              v_retirement_date,
                                              v_serial_number,
                                              v_trx_type_id,
                                              v_customer_id,
                                              v_bill_site_use_id,
                                              v_payment_term_id,
                                              v_retirement_type,
                                              v_proceeds_of_sale,
                                              v_ccid,
                                              v_desc,
                                              v_inv_err
                                             );
                           END IF;
            --               v_proceeds_of_sale := v_cost_retired;
                        END IF;*/
            IF p_retirement_type = 'DISPOSAL/CORRECTION'
            --NVL (v_inv_err, 0) = 0
            THEN
               --call FA API
--               DBMS_OUTPUT.put_line
--                                (   'calling retire asset for serial number '
--                                 || v_serial_number
--                                );
               logf ('calling retire asset for serial number ' || v_serial_number);
               retire_asset (v_serial_number,
                             v_asset_id,
                             v_book_type_code,
                             v_cost_retired,
                             v_cost_of_removal,
                             v_retirement_type,
                             v_retirement_date,
                             v_proceeds_of_sale,
                             v_comment
                            );
               --call Calculate Gains and Losses concurrent
               logf ('calling Calculate Gains and Losses');
               fnd_global.apps_initialize (user_id => g_user_id,
                                                                --1090
                                           resp_id => g_resp_id,
                                                                --50760
                                           resp_appl_id => g_resp_appl_id
                                                                         --140
               );
               v_gain_loss_req_id := fnd_request.submit_request ('OFA', 'FARET', NULL, NULL, FALSE, v_book_type_code);
               COMMIT;
--               DBMS_OUTPUT.put_line (   'v_gain_loss_req_id : '
--                                     || v_gain_loss_req_id
--                                    );
               logf ('Gain Loss Request Id : ' || v_gain_loss_req_id);
               waitforrequest (v_gain_loss_req_id, v_out_status, v_out_errormessage);
--            ELSE
--               retcode := 2;
            END IF;
         END IF;
      END LOOP;

      CLOSE v_ret_curr;

      IF p_retirement_type = 'SALE'
      THEN
         SELECT COUNT (1)
           INTO v_sale_err_cnt
           FROM xxmkt_fa_retirement
          WHERE request_id = g_request_id AND status = 'E';

         IF v_sale_err_cnt = 0
         THEN
            FOR i IN (SELECT   xfr.trx_source_id, xfr.invoice_group, xfr.customer_id, xfr.trx_type_id, xfr.bill_site_use_id, xfr.payment_term_id,
                               xfr.retirement_date
                          FROM xxmkt_fa_retirement xfr
                         WHERE request_id = g_request_id
                           AND GROUP_ID = g_user_id
                           AND status IS NULL
                           AND UPPER (retirement_type) IN ('SALE AFFI', 'SALE N-AFFI')
                           --add hansen 24 mar 2017 check if invoice already exist
                           AND NOT EXISTS (SELECT 1
                                             FROM ra_customer_trx_all rcta
                                            WHERE rcta.attribute1 = xfr.serial_number)
                      --end add hansen 24 mar 2017
                      GROUP BY trx_source_id, invoice_group, customer_id, trx_type_id, bill_site_use_id, payment_term_id, retirement_date)
            LOOP
               logf ('calling create invoice for serial number ' || v_serial_number);
               create_invoice_group (i.trx_source_id,
                                     i.invoice_group,
                                     i.customer_id,
                                     i.trx_type_id,
                                     i.bill_site_use_id,
                                     i.payment_term_id,
                                     i.retirement_date
                                    );
            END LOOP;

            FOR j IN (SELECT *
                        FROM xxmkt_fa_retirement xfr
                       WHERE request_id = g_request_id
                         AND GROUP_ID = g_user_id
                         AND status IS NULL
                         AND UPPER (retirement_type) IN ('SALE AFFI', 'SALE N-AFFI')
                         AND customer_trx_id IS NOT NULL)
            LOOP
               SELECT rct.trx_number
                 INTO v_trx_number
                 FROM ra_customer_trx_all rct
                WHERE customer_trx_id = j.customer_trx_id;

               --calling retire asset
               logf ('calling retire asset for serial number ' || j.serial_number);
               retire_asset (j.serial_number,
                             j.asset_id,
                             j.book_type_code,
                             j.cost_retired,
                             j.cost_of_removal,
                             j.retirement_type,
                             j.retirement_date,
                             j.proceeds_of_sale,
                             --j.comments
                             v_trx_number                                                                                      --KATA ANGGI SIH BEGINI
                            );
               --call Calculate Gains and Losses concurrent
               logf ('calling Calculate Gains and Losses');
               fnd_global.apps_initialize (user_id => g_user_id,
                                                                --1090
                                           resp_id => g_resp_id,
                                                                --50760
                                           resp_appl_id => g_resp_appl_id
                                                                         --140
               );
               v_gain_loss_req_id := fnd_request.submit_request ('OFA', 'FARET', NULL, NULL, FALSE, j.book_type_code);
               COMMIT;
               --               DBMS_OUTPUT.put_line (   'v_gain_loss_req_id : '
               --                                     || v_gain_loss_req_id
               --                                    );
               logf ('Gain Loss Request Id : ' || v_gain_loss_req_id);
               waitforrequest (v_gain_loss_req_id, v_out_status, v_out_errormessage);
            END LOOP;
         END IF;
      END IF;

      print_output (p_retirement_type);
      COMMIT;
      logf ('----- End Main Process -----');
--      DBMS_OUTPUT.put_line ('----- End Main Process -----');
   EXCEPTION
      WHEN OTHERS
      THEN
--         DBMS_OUTPUT.put_line ('Program Error : ' || SQLERRM);
         logf ('Program Error : ' || SQLERRM);
         retcode := 2;
   END;
END;
/
