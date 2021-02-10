CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_MPN_HALAL_EXP_NOTIFY
AS
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

   PROCEDURE change_status_exp (v_inventory_item_id       NUMBER,
                                v_organization_id         NUMBER,
                                p_message             OUT VARCHAR2,
                                p_return_status       OUT VARCHAR2)
   IS
      l_item_table      ego_item_pub.item_tbl_type;
      x_item_table      ego_item_pub.item_tbl_type;
      x_return_status   VARCHAR2 (1);
      x_msg_count       NUMBER (10);
      x_message_list    error_handler.error_tbl_type;
      error_bro         EXCEPTION;

      v_item_code       VARCHAR2 (50);
      v_org             VARCHAR2 (50);
      v_message_err     VARCHAR2 (5000) := '';
   BEGIN
      --Apps Initialize
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      -- Item definition
      l_item_table (1).transaction_type := 'UPDATE';
      l_item_table (1).inventory_item_id := v_inventory_item_id;
      l_item_table (1).organization_id := v_organization_id;
      l_item_table (1).inventory_item_status_code := 'Phase Out';

      -- Calling procedure EGO_ITEM_PUB.Process_Items
      ego_item_pub.process_items (                          --Input Parameters
                                  p_api_version     => 1.0,
                                  p_init_msg_list   => fnd_api.g_true,
                                  p_commit          => fnd_api.g_true,
                                  p_item_tbl        => l_item_table,
                                  --Output Parameters
                                  x_item_tbl        => x_item_table,
                                  x_return_status   => x_return_status,
                                  x_msg_count       => x_msg_count);

      logf ('Items updated Status ==>' || x_return_status);

      IF (x_return_status = fnd_api.g_ret_sts_success)
      THEN
         FOR i IN 1 .. x_item_table.COUNT
         LOOP
            logf (
                  'Inventory Item Id :'
               || TO_CHAR (x_item_table (i).inventory_item_id));
            logf (
                  'Organization Id   :'
               || TO_CHAR (x_item_table (i).organization_id));
         END LOOP;
      ELSE
         logf ('Error Messages :');
         error_handler.get_message_list (x_message_list => x_message_list);

         FOR i IN 1 .. x_message_list.COUNT
         LOOP
            logf (x_message_list (i).MESSAGE_TEXT);
            v_message_err :=
               v_message_err || ', ' || x_message_list (i).MESSAGE_TEXT;
         END LOOP;
      --         IF x_return_status = 'E'
      --         THEN
      --            --null;
      --            RAISE error_bro;
      --         END IF;
      END IF;

      p_message := v_message_err;
      p_return_status := x_return_status;
   END;

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

   PROCEDURE check_mpn_halal_exp (errbuf OUT VARCHAR2, retcode OUT NUMBER)
   IS
      v_cnt_ed          NUMBER := 0;
      v_cnt_3m          NUMBER := 0;
      v_result_ed       VARCHAR2 (250);
      v_result_3m       VARCHAR2 (250);
      v_message         VARCHAR2 (2000);
      v_return_status   VARCHAR2 (50);
      v_item_code       VARCHAR2 (50);
      v_org             VARCHAR2 (50);

      error_bro         EXCEPTION;
      l_err_cnt         NUMBER := 0;
   BEGIN
      logf ('Status data M-3 - insert ke dalam temp');

      FOR rec3m IN mpn_3m_cur
      LOOP
         INSERT INTO xxshp_mpn_halal_exp_stag (data_id,
                                               kn,
                                               item_code,
                                               item_desc,
                                               uom,
                                               organization_code,
                                               supplier_name,
                                               part,
                                               sertf_halal_number,
                                               halal_expiry_date,
                                               first_notification_date,
                                               phase_out,
                                               creation_date,
                                               last_update_date,
                                               type_email,
                                               item_template,
                                               item_type,
                                               halal_body,
                                               manufacturer_name,
                                               mfg_part_num)
              VALUES (xxshp_mpn_halal_exp_stag_s.NEXTVAL,
                      rec3m.kn_lob,
                      rec3m.item_code,
                      rec3m.item_desc,
                      rec3m.uom_code,
                      rec3m.organization_code,
                      rec3m.supplier_name,
                      rec3m.part,
                      rec3m.halal_number,
                      rec3m.halal_valid_to,
                      SYSDATE,
                      rec3m.halal_valid_to, --add_months(add_months(sysdate,4),-3),
                      SYSDATE,
                      SYSDATE,
                      'M-3',
                      rec3m.item_template,
                      rec3m.item_type,
                      rec3m.halal_body,
                      rec3m.manufacturer_name,
                      rec3m.mfg_part_num);

         v_cnt_3m := v_cnt_3m + 1;
      END LOOP;

      logf ('Status data Phase Out - insert ke dalam temp');

      FOR recEd IN mpn_ed_cur
      LOOP
         INSERT INTO xxshp_mpn_halal_exp_stag (data_id,
                                               kn,
                                               item_code,
                                               item_desc,
                                               uom,
                                               organization_code,
                                               supplier_name,
                                               part,
                                               sertf_halal_number,
                                               halal_expiry_date,
                                               first_notification_date,
                                               phase_out,
                                               creation_date,
                                               last_update_date,
                                               type_email,
                                               item_template,
                                               item_type,
                                               halal_body,
                                               manufacturer_name,
                                               mfg_part_num)
                 VALUES (
                           xxshp_mpn_halal_exp_stag_s.NEXTVAL,
                           recEd.kn_lob,
                           recEd.item_code,
                           recEd.item_desc,
                           recEd.uom_code,
                           recEd.organization_code,
                           recEd.supplier_name,
                           recEd.part,
                           recEd.halal_number,
                           recEd.halal_valid_to,
                           (CASE
                               WHEN recEd.first_notification_date IS NOT NULL
                               THEN
                                  recEd.first_notification_date
                            END),
                           SYSDATE,
                           SYSDATE,
                           SYSDATE,
                           'Phase Out',
                           recEd.item_template,
                           recEd.item_type,
                           recEd.halal_body,
                           recEd.manufacturer_name,
                           recEd.mfg_part_num);

         v_cnt_ed := v_cnt_ed + 1;
      END LOOP;

      logf ('Total 3M : ' || v_cnt_3m);
      logf ('Total Phase Out : ' || v_cnt_ed);

      IF v_cnt_ed > 0
      THEN
         logf ('Update status menjadi Phase Out');

         FOR i IN chg_stts_cur
         LOOP
            change_status_exp (v_inventory_item_id   => i.inventory_item_id,
                               v_organization_id     => i.organization_id,
                               p_message             => v_message,
                               p_return_status       => v_return_status);

            SELECT DISTINCT segment1
              INTO v_item_code
              FROM mtl_system_items
             WHERE     inventory_item_id = i.inventory_item_id
                   AND organization_id = i.organization_id;

            SELECT organization_code
              INTO v_org
              FROM mtl_parameters
             WHERE organization_id = i.organization_id;

            UPDATE xxshp_mpn_halal_exp_stag
               SET status = v_return_status, error_message = v_message
             WHERE     item_code = v_item_code
                   AND organization_code = v_org
                   AND data_id = i.data_id
                   AND TRUNC (creation_date) = TRUNC (SYSDATE);

            IF v_return_status = 'E'
            THEN
               l_err_cnt := l_err_cnt + 1;
            END IF;
         END LOOP;

         logf ('Update Phase Out sukses');

         logf ('Kirim email status Phase Out');
         send_mail_ed (v_cnt_ed, v_result_ed);
      END IF;

      IF v_cnt_3m > 0
      THEN
         logf ('Kirim email status M-3');
         send_mail_m3 (v_cnt_3m, v_result_3m);
      END IF;

      COMMIT;

      IF l_err_cnt > 0
      THEN
         RAISE error_bro;
      END IF;
   END check_mpn_halal_exp;

   PROCEDURE send_mail_ed (p_total IN NUMBER, p_result OUT VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000) := 'Evi.Rachmaniatun@kalbenutritionals.com,Debby.Ardi@kalbenutritionals.com';--'ardianto.ardi@kalbenutritionals.com'; --
      p_cc                       VARCHAR2 (2000);-- := 'reza.fajrin@kalbenutritionals.com';
      p_bcc                      VARCHAR2 (2000) := 'adhi.rizaldi@kalbenutritionals.com,ardianto.ardi@kalbenutritionals.com';
      lv_smtp_server             VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ln_cnt                     NUMBER;
      ld_date                    DATE;
      v_filename                 VARCHAR2 (100);
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);
      
--       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
--          into v_to
--          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
--                      FROM (SELECT DESCRIPTION,
--                                   ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
--                                   COUNT (*) OVER () cnt
--                              FROM FND_LOOKUP_VALUES
--                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_MD_EXPIRY')
--                     WHERE rn = cnt
--        START WITH rn = 1
--        CONNECT BY rn = PRIOR rn + 1);

      logf ('Request ID : ' || fnd_global.conc_request_id);

      ld_date := SYSDATE;
      lv_domain := lv_smtp_server;

      BEGIN
         v_connection := UTL_SMTP.open_connection (lv_smtp_server, 25); --To open the connection
         UTL_SMTP.helo (v_connection, lv_smtp_server);
         UTL_SMTP.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
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
            UTL_SMTP.write_data (v_connection,
                                 'To: ' || p_to || UTL_TCP.crlf);
         END IF;

         IF TRIM (p_cc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Cc: ' || p_cc || UTL_TCP.crlf);
         END IF;
         
         IF TRIM (p_bcc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Bcc: ' || p_bcc || UTL_TCP.crlf);
         END IF;

         UTL_SMTP.write_data (
            v_connection,
            'Subject: Notifikasi Halal Phase Out' || UTL_TCP.crlf);
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
         UTL_SMTP.write_data (v_connection, 'Dear All,' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Please be aware that attached Material Halal Certificate is expired. '
            || CHR (13)
            || CHR (10)
            || 'These item status has been changed to PHASE OUT.'
            || CHR (13)
            || CHR (10)
            || 'All PR (Purchase Requisition), PO (Purchase Order), BO (Batch Order) using these items can not be created when the item status is in phase out.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Please renew the Halal Expiry Date to change the status back to ACTIVE.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'NOTE - Please do not reply since this is an automatically generated e-mail.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'Total Data ' || p_total || UTL_TCP.crlf);

         v_filename := 'SHP__Halal_Phase-Out-' || TO_CHAR (SYSDATE, 'MON-RR');

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         ln_cnt := 1;

         --/*Condition to check for the creation of csv attachment
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
               'Category,Item Code,Item Desc,Organization,Supplier Name,Part,Sertificate Halal Number,Expiry Date,Phase Out,Type Email,Item Template,Item Type,Halal Body,Manufacturer Name,Error Message'
            || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, v_clob);

         FOR i IN mail_ed_cur
         LOOP
            BEGIN
               v_clob :=
                     i.kn
                  || ','
                  || i.item_code
                  || ','
                  || REPLACE (REPLACE(REPLACE(i.item_desc,CHR(13)),CHR(10)), ',')
                  || ','
                  || i.organization_code
                  || ','
                  || REPLACE (i.supplier_name, ',')
                  || ','
                  || i.part
                  || ','
                  || '='
                  || '"'
                  || i.sertf_halal_number
                  || '"'
                  || ','
                  || i.halal_expiry_date
                  || ','
                  || i.phase_out
                  || ','
                  || i.type_email
                  || ','
                  || i.item_template
                  || ','
                  || i.item_type
                  || ','
                  || i.halal_body
                  || ','
                  || i.manufacturer_name
                  || ','
                  || REPLACE (
                        REPLACE (REPLACE (i.error_message, ','),
                                 CHR (13),
                                 ' '),
                        CHR (10),
                        ' ')
                  || UTL_TCP.crlf;
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf (SQLERRM);
                  logf (DBMS_UTILITY.format_error_backtrace);
            END;

            --Writing data in csv attachment.
            UTL_SMTP.write_data (v_connection, v_clob);
         END LOOP;

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail_ed;

   PROCEDURE send_mail_m3 (p_total IN NUMBER, p_result OUT VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000) := 'Evi.Rachmaniatun@kalbenutritionals.com,Debby.Ardi@kalbenutritionals.com';--'ardianto.ardi@kalbenutritionals.com'; --
      p_cc                       VARCHAR2 (2000);-- := 'reza.fajrin@kalbenutritionals.com';
      p_bcc                      VARCHAR2 (2000) := 'adhi.rizaldi@kalbenutritionals.com,ardianto.ardi@kalbenutritionals.com';
      lv_smtp_server             VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ln_cnt                     NUMBER;
      ld_date                    DATE;
      v_filename                 VARCHAR2 (100);

      p_total_update             NUMBER := 0;
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

--       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
--          into v_to
--          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
--                      FROM (SELECT DESCRIPTION,
--                                   ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
--                                   COUNT (*) OVER () cnt
--                              FROM FND_LOOKUP_VALUES
--                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_MD_EXPIRY')
--                     WHERE rn = cnt
--        START WITH rn = 1
--        CONNECT BY rn = PRIOR rn + 1);

      logf ('request ID : ' || fnd_global.conc_request_id);

      ld_date := SYSDATE;
      lv_domain := lv_smtp_server;

      BEGIN
         v_connection := UTL_SMTP.open_connection (lv_smtp_server, 25); --To open the connection
         UTL_SMTP.helo (v_connection, lv_smtp_server);
         UTL_SMTP.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
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
            UTL_SMTP.write_data (v_connection,
                                 'To: ' || p_to || UTL_TCP.crlf);
         END IF;

         IF TRIM (p_cc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Cc: ' || p_cc || UTL_TCP.crlf);
         END IF;
         
         IF TRIM (p_bcc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Bcc: ' || p_bcc || UTL_TCP.crlf);
         END IF;

         UTL_SMTP.write_data (
            v_connection,
            'Subject: Notifikasi Halal Expiry M-3' || UTL_TCP.crlf);
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
         UTL_SMTP.write_data (v_connection, 'Dear All,' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Please be aware that attached Material Halal Expiry Date would shortly expired within 3 months.'
            || CHR (13)
            || CHR (10)
            || 'Please renew the Halal Expiry Date to avoid item status changes to phase out.'
            || CHR (13)
            || CHR (10)
            || 'All PR (Purchase Requisition), PO (Purchase Order), BO (Batch Order) using these items can not be created when the item status is in phase out.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'NOTE - Please do not reply since this is an automatically generated e-mail.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'Total Data ' || p_total || UTL_TCP.crlf);

         v_filename := 'SHP__Halal_expiry_3M-' || TO_CHAR (SYSDATE, 'MON-RR');

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         ln_cnt := 1;

         --/*Condition to check for the creation of csv attachment
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
               'Category,Item Code,Item Desc,Organization,Supplier Name,Part,Sertificate Halal Number,Expiry Date,Phase Out,Type Email,Item Template,Item Type,Halal Body,Manufacturer Name'
            || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, v_clob);

         FOR i IN mail_3m_cur
         LOOP
            BEGIN
               v_clob :=
                     i.kn
                  || ','
                  || i.item_code
                  || ','
                  || REPLACE (REPLACE(REPLACE(i.item_desc,CHR(13)),CHR(10)), ',')
                  || ','
                  || i.organization_code
                  || ','
                  || REPLACE (i.supplier_name, ',')
                  || ','
                  || i.part
                  || ','
                  || '='
                  || '"'
                  || i.sertf_halal_number
                  || '"'
                  || ','
                  || i.halal_expiry_date
                  || ','
                  || i.phase_out
                  || ','
                  || i.type_email
                  || ','
                  || i.item_template
                  || ','
                  || i.item_type
                  || ','
                  || i.halal_body
                  || ','
                  || i.manufacturer_name
                  || UTL_TCP.crlf;
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf (SQLERRM);
                  logf (DBMS_UTILITY.format_error_backtrace);
            END;

            --Writing data in csv attachment.
            UTL_SMTP.write_data (v_connection, v_clob);
         END LOOP;

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error : ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail_m3;
END XXSHP_MPN_HALAL_EXP_NOTIFY;
/
