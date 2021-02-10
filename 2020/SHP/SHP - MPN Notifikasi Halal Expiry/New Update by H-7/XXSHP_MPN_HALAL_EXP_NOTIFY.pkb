CREATE OR REPLACE package body APPS.xxshp_mpn_halal_exp_notify
as
   procedure logf (p_msg varchar2)
   is
   begin
      fnd_file.put_line (fnd_file.log, p_msg);
      dbms_output.put_line (p_msg);
   end logf;

   procedure outf (p_msg varchar2)
   is
   begin
      fnd_file.put_line (fnd_file.output, p_msg);
      dbms_output.put_line (p_msg);
   end outf;

   procedure change_status_exp (v_inventory_item_id    number,
                                v_organization_id      number)
   is
      l_item_table      ego_item_pub.item_tbl_type;
      x_item_table      ego_item_pub.item_tbl_type;
      x_return_status   varchar2 (1);
      x_msg_count       number (10);
      x_message_list    error_handler.error_tbl_type;
      error_bro         exception;
   begin
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

      if (x_return_status = fnd_api.g_ret_sts_success)
      then
         for i in 1 .. x_item_table.count
         loop
            logf (
                  'Inventory Item Id :'
               || to_char (x_item_table (i).inventory_item_id));
            logf (
                  'Organization Id   :'
               || to_char (x_item_table (i).organization_id));
         end loop;
      else
         logf ('Error Messages :');
         error_handler.get_message_list (x_message_list => x_message_list);

         for i in 1 .. x_message_list.count
         loop
            logf (x_message_list (i).message_text);
         end loop;
                  
          if x_return_status = 'E' then
            raise error_bro;
          end if;
      end if;
   end;

   procedure process_recipients (p_mail_conn   in out utl_smtp.connection,
                                 p_list        in     varchar2)
   as
      l_tab   string_api.t_split_array;
   begin
      if trim (p_list) is not null
      then
         l_tab := string_api.split_text (p_list);

         for i in 1 .. l_tab.count
         loop
            utl_smtp.rcpt (p_mail_conn, trim (l_tab (i)));
         end loop;
      end if;
   end process_recipients;

   procedure check_mpn_halal_exp (errbuf out varchar2, retcode out number)
   is
      v_cnt_ed      number := 0;
      v_cnt_3m      number := 0;
      v_result_ed   varchar2 (250);
      v_result_3m   varchar2 (250);
   begin
      logf ('Status data M-3 - insert ke dalam temp');

      for rec3m in mpn_3m_cur
      loop
         insert into xxshp_mpn_halal_exp_stag (data_id,
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
                                               halal_body,
                                               manufacturer_name,
                                               mfg_part_num)
              values (xxshp_mpn_halal_exp_stag_s.nextval,
                      rec3m.kn_lob,
                      rec3m.item_code,
                      rec3m.item_desc,
                      rec3m.uom_code,
                      rec3m.organization_code,
                      rec3m.supplier_name,
                      rec3m.part,
                      rec3m.halal_number,
                      rec3m.halal_valid_to,
                      sysdate,
                      rec3m.halal_valid_to, --add_months(add_months(sysdate,4),-3),
                      sysdate,
                      sysdate,
                      'M-3',
                      rec3m.item_template,
                      rec3m.halal_body,
                      rec3m.manufacturer_name,
                      rec3m.mfg_part_num);

         v_cnt_3m := v_cnt_3m + 1;
      end loop;

      logf ('Status data ED - insert ke dalam temp');

      for recEd in mpn_ed_cur
      loop
         insert into xxshp_mpn_halal_exp_stag (data_id,
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
                                               halal_body,
                                               manufacturer_name,
                                               mfg_part_num)
                 values (
                           xxshp_mpn_halal_exp_stag_s.nextval,
                           recEd.kn_lob,
                           recEd.item_code,
                           recEd.item_desc,
                           recEd.uom_code,
                           recEd.organization_code,
                           recEd.supplier_name,
                           recEd.part,
                           recEd.halal_number,
                           recEd.halal_valid_to,
                           (case
                               when recEd.first_notification_date is not null
                               then
                                  recEd.first_notification_date
                            end),
                           sysdate,
                           sysdate,
                           sysdate,
                           'ED',
                           recEd.item_template,
                           recEd.halal_body,
                           recEd.manufacturer_name,
                           recEd.mfg_part_num);

         v_cnt_ed := v_cnt_ed + 1;
      end loop;

      logf ('Total 3M : ' || v_cnt_3m);
      logf ('Total ED : ' || v_cnt_ed);

      if v_cnt_ed > 0
      then

         logf ('Update status menjadi Phase Out');
         for i in chg_stts_cur
         loop
            change_status_exp (v_inventory_item_id   => i.inventory_item_id,
                               v_organization_id     => i.organization_id);
         end loop;
         logf ('Update Phase Out sukses');
         
         logf ('Kirim email status ED');
         send_mail_ed (v_cnt_ed, v_result_ed);

      end if;

      if v_cnt_3m > 0
      then
         logf ('Kirim email status M-3');
         send_mail_m3 (v_cnt_3m, v_result_3m);
      end if;
      
      commit;
   end check_mpn_halal_exp;

   procedure send_mail_ed (p_total in number, p_result out varchar2)
   is
      p_to                       varchar2 (2000) := 'ardianto.ardi@kalbenutritionals.com';--'reza.fajrin@kalbenutritionals.com';-- 
      p_cc                       varchar2 (2000) ;--:= 'ardianto.ardi@kalbenutritionals.com,Evi.Rachmaniatun@kalbenutritionals.com,Debby.Ardi@kalbenutritionals.com';
      p_bcc                      varchar2 (2000);
      lv_smtp_server             varchar2 (100)
                                    := fnd_profile.value ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  varchar2 (100);
      lv_from                    varchar2 (100)
                                    := fnd_profile.value ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               utl_smtp.connection;
      c_mime_boundary   constant varchar2 (256) := '--AAAAA000956--';
      v_clob                     clob;
      ln_cnt                     number;
      ld_date                    date;
      v_filename                 varchar2 (100);

   begin
      mo_global.set_policy_context ('S', g_organization_id);

      logf ('Request ID : ' || fnd_global.conc_request_id);

      ld_date := sysdate;
      lv_domain := lv_smtp_server;

      begin
         v_connection := utl_smtp.open_connection (lv_smtp_server, 25); --To open the connection
         utl_smtp.helo (v_connection, lv_smtp_server);
         utl_smtp.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
         utl_smtp.open_data (v_connection);
         utl_smtp.write_data (
            v_connection,
               'Date: '
            || to_char (sysdate, 'Dy, DD Mon YYYY hh24:mi:ss')
            || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'From: ' || lv_from || utl_tcp.crlf);

         if trim (p_to) is not null
         then
            utl_smtp.write_data (v_connection,
                                 'To: ' || p_to || utl_tcp.crlf);
         end if;

         if trim (p_cc) is not null
         then
            utl_smtp.write_data (v_connection,
                                 'Cc: ' || p_cc || utl_tcp.crlf);
         end if;

         utl_smtp.write_data (
            v_connection,
            'Subject: Notifikasi Halal Expiry Date' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'MIME-Version: 1.0' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               'Content-Type: multipart/mixed; boundary="'
            || c_mime_boundary
            || '"'
            || utl_tcp.crlf);
         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'This is a multi-part message in MIME format.' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              '--' || c_mime_boundary || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'Content-Type: text/plain' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (v_connection, '' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               'Dear All,'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               utl_tcp.crlf||'Please be aware that attached Material Halal Certificate is expired. '||chr(13)||chr(10)||
               'These item status has been changed to PHASE OUT.'||chr(13)||chr(10)||
               'All PR (Purchase Requisition), PO (Purchase Order), BO (Batch Order) using these items can not be created when the item status is in phase out.'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               utl_tcp.crlf||'Please renew the Halal Expiry Date to change the status back to ACTIVE.'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               utl_tcp.crlf||'NOTE - Please do not reply since this is an automatically generated e-mail.'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'Total Data ' || p_total || utl_tcp.crlf);

         v_filename := 'Attc_halal_expiry_ED-' || to_char (sysdate, 'MON-RR');

         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              '--' || c_mime_boundary || utl_tcp.crlf);
         ln_cnt := 1;

         --/*Condition to check for the creation of csv attachment
         if (ln_cnt <> 0)
         then
            utl_smtp.write_data (
               v_connection,
                  'Content-Disposition: attachment; filename="'
               || v_filename
               || '.csv'
               || '"'
               || utl_tcp.crlf);
         end if;

         utl_smtp.write_data (v_connection, utl_tcp.crlf);

         v_clob :=
               'Category,Item Code,Item Desc,Organization,Supplier Name,Part,Sertificate Halal Number,Expiry Date,Phase Out,Type Email,Item Template, Halal Body, Manufacturer Name'
            || utl_tcp.crlf;

         utl_smtp.write_data (v_connection, v_clob);

         for i in mail_ed_cur
         loop
            begin
               v_clob :=
                     i.kn
                  || ','
                  || i.item_code
                  || ','
                  || replace(i.item_desc,',')
                  || ','
                  || i.organization_code
                  || ','
                  || replace(i.supplier_name,',')
                  || ','
                  || i.part
                  || ','
                  || '='||'"'||i.sertf_halal_number||'"'
                  || ','
                  || i.halal_expiry_date
                  || ','
                  || i.phase_out
                  || ','
                  || i.type_email
                  || ','
                  || i.item_template
                  || ','
                  || i.halal_body
                  || ','
                  || i.manufacturer_name
                  || utl_tcp.crlf;
            exception
               when others
               then
                  logf (sqlerrm);
                  logf (dbms_utility.format_error_backtrace);
            end;

            --Writing data in csv attachment.
            utl_smtp.write_data (v_connection, v_clob);
         end loop;

         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.close_data (v_connection);
         utl_smtp.quit (v_connection);

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      exception
         when others
         then
            logf ('Error ' || sqlerrm);
            logf (dbms_utility.format_error_backtrace);
      end;
   end send_mail_ed;

   procedure send_mail_m3 (p_total in number, p_result out varchar2)
   is
      p_to                       varchar2 (2000) := 'ardianto.ardi@kalbenutritionals.com';--'reza.fajrin@kalbenutritionals.com';-- 
      p_cc                       varchar2 (2000) ;--:= 'ardianto.ardi@kalbenutritionals.com,Evi.Rachmaniatun@kalbenutritionals.com,Debby.Ardi@kalbenutritionals.com';
      p_bcc                      varchar2 (2000);
      lv_smtp_server             varchar2 (100)
                                    := fnd_profile.value ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  varchar2 (100);
      lv_from                    varchar2 (100)
                                    := fnd_profile.value ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               utl_smtp.connection;
      c_mime_boundary   constant varchar2 (256) := '--AAAAA000956--';
      v_clob                     clob;
      ln_cnt                     number;
      ld_date                    date;
      v_filename                 varchar2 (100);

      p_total_update             number := 0;
   begin
      mo_global.set_policy_context ('S', g_organization_id);

      logf ('request ID : ' || fnd_global.conc_request_id);

      ld_date := sysdate;
      lv_domain := lv_smtp_server;

      begin
         v_connection := utl_smtp.open_connection (lv_smtp_server, 25); --To open the connection
         utl_smtp.helo (v_connection, lv_smtp_server);
         utl_smtp.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
         utl_smtp.open_data (v_connection);
         utl_smtp.write_data (
            v_connection,
               'Date: '
            || to_char (sysdate, 'Dy, DD Mon YYYY hh24:mi:ss')
            || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'From: ' || lv_from || utl_tcp.crlf);

         if trim (p_to) is not null
         then
            utl_smtp.write_data (v_connection,
                                 'To: ' || p_to || utl_tcp.crlf);
         end if;

         if trim (p_cc) is not null
         then
            utl_smtp.write_data (v_connection,
                                 'Cc: ' || p_cc || utl_tcp.crlf);
         end if;

         utl_smtp.write_data (
            v_connection,
            'Subject: Notifikasi Halal Expiry M-3' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'MIME-Version: 1.0' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               'Content-Type: multipart/mixed; boundary="'
            || c_mime_boundary
            || '"'
            || utl_tcp.crlf);
         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'This is a multi-part message in MIME format.' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              '--' || c_mime_boundary || utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              'Content-Type: text/plain' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf);
         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (v_connection, '' || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               'Dear All,'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               utl_tcp.crlf||'Please be aware that attached Material Halal Expiry Date would shortly expired within 3 months.'||chr(13)||chr(10)||
               'Please renew the Halal Expiry Date to avoid item status changes to phase out.'||chr(13)||chr(10)||
               'All PR (Purchase Requisition), PO (Purchase Order), BO (Batch Order) using these items can not be created when the item status is in phase out.'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
               utl_tcp.crlf||'NOTE - Please do not reply since this is an automatically generated e-mail.'
            || utl_tcp.crlf);
         utl_smtp.write_data (
            v_connection,
            'Total Data ' || p_total || utl_tcp.crlf);

         v_filename := 'Attc_halal_expiry_3M-' || to_char (sysdate, 'MON-RR');

         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.write_data (v_connection,
                              '--' || c_mime_boundary || utl_tcp.crlf);
         ln_cnt := 1;

         --/*Condition to check for the creation of csv attachment
         if (ln_cnt <> 0)
         then
            utl_smtp.write_data (
               v_connection,
                  'Content-Disposition: attachment; filename="'
               || v_filename
               || '.csv'
               || '"'
               || utl_tcp.crlf);
         end if;

         utl_smtp.write_data (v_connection, utl_tcp.crlf);

         v_clob :=
               'Category,Item Code,Item Desc,Organization,Supplier Name,Part,Sertificate Halal Number,Expiry Date,Phase Out,Type Email,Item Template, Halal Body, Manufacturer Name'
            || utl_tcp.crlf;

         utl_smtp.write_data (v_connection, v_clob);

         for i in mail_3m_cur
         loop
            begin
               v_clob :=
                     i.kn
                  || ','
                  || i.item_code
                  || ','
                  || replace(i.item_desc,',')
                  || ','
                  || i.organization_code
                  || ','
                  || replace(i.supplier_name,',')
                  || ','
                  || i.part
                  || ','
                  || '='||'"'||i.sertf_halal_number||'"'
                  || ','
                  || i.halal_expiry_date
                  || ','
                  || i.phase_out
                  || ','
                  || i.type_email
                  || ','
                  || i.item_template
                  || ','
                  || i.halal_body
                  || ','
                  || i.manufacturer_name
                  || utl_tcp.crlf;
            exception
               when others
               then
                  logf (sqlerrm);
                  logf (dbms_utility.format_error_backtrace);
            end;

            --Writing data in csv attachment.
            utl_smtp.write_data (v_connection, v_clob);
         end loop;

         utl_smtp.write_data (v_connection, utl_tcp.crlf);
         utl_smtp.close_data (v_connection);
         utl_smtp.quit (v_connection);

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      exception
         when others
         then
            logf ('Error : '||sqlerrm);
            logf (dbms_utility.format_error_backtrace);
      end;
   end send_mail_m3;

end xxshp_mpn_halal_exp_notify;
/
