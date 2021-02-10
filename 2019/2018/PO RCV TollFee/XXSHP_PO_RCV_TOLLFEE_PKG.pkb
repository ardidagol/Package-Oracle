CREATE OR REPLACE PACKAGE BODY APPS.xxshp_po_rcv_tollfee_pkg
/* $Header: XXSHP_PO_RCV_TOLLFEE_PKG.PKB 122.5.1.0 2017/02/03 10:34:23  Puguh MS $ */
AS
   /**************************************************************************************************
         NAME: XXSHP_PO_RCV_TOLLFEE_PKG
         PURPOSE:

         REVISIONS:
         VER         DATE                 AUTHOR              DESCRIPTION
         ---------   ----------          ---------------     ------------------------------------
         1.0         08-Feb-2017          Puguh MS          1. CREATED THIS PACKAGE
         1.1         14-Sep-2017          Farry             1. Fix quantity
         1.2         27-Nov-2018          Ardianto          1. Modified this package
                                                            2. Add Procedure insert_to_header_temp
                                                            3. Add Procedure insert_to_transaction_temp
                                                            4. Add Procedure insert_to_iface
                                                            5. Add Procedure process_recipients
                                                            6. Add Procedure send_mail
                                                            7. Enhancement in the package main_process
     ***************************************************************************************************/
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
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   PROCEDURE insert_to_header_temp (rec xxshp_rcv_headers_temp%ROWTYPE)
   IS
   BEGIN
      INSERT INTO xxshp_rcv_headers_temp (header_interface_id,
                                          GROUP_ID,
                                          processing_status_code,
                                          receipt_source_code,
                                          transaction_type,
                                          auto_transact_code,
                                          last_update_date,
                                          last_updated_by,
                                          last_update_login,
                                          creation_date,
                                          created_by,
                                          vendor_id,
                                          vendor_site_id,
                                          ship_to_organization_id,
                                          expected_receipt_date,
                                          org_id,
                                          validation_flag,
                                          attribute8,
                                          shipment_num,
                                          location_id,
                                          shipped_date)
           VALUES (rec.header_interface_id,
                   rec.GROUP_ID,
                   rec.processing_status_code,
                   rec.receipt_source_code,
                   rec.transaction_type,
                   rec.auto_transact_code,
                   rec.last_update_date,
                   rec.last_updated_by,
                   rec.last_update_login,
                   rec.creation_date,
                   rec.created_by,
                   rec.vendor_id,
                   rec.vendor_site_id,
                   rec.ship_to_organization_id,
                   rec.expected_receipt_date,
                   rec.org_id,
                   rec.validation_flag,
                   rec.attribute8,
                   rec.shipment_num,
                   rec.location_id,
                   rec.shipped_date);
   END;

   PROCEDURE insert_to_transaction_temp (
      rec    xxshp_rcv_transaction_temp%ROWTYPE)
   IS
   BEGIN
      INSERT INTO xxshp_rcv_transaction_temp (interface_transaction_id,
                                              GROUP_ID,
                                              last_update_date,
                                              last_updated_by,
                                              creation_date,
                                              created_by,
                                              last_update_login,
                                              transaction_type,
                                              transaction_date,
                                              processing_status_code,
                                              processing_mode_code,
                                              transaction_status_code,
                                              po_header_id,
                                              po_line_id,
                                              item_id,
                                              quantity,
                                              unit_of_measure,
                                              po_line_location_id,
                                              auto_transact_code,
                                              receipt_source_code,
                                              to_organization_id,
                                              ship_to_location_id,
                                              source_document_code,
                                              document_num,
                                              destination_type_code,
                                              deliver_to_person_id,
                                              deliver_to_location_id,
                                              subinventory,
                                              header_interface_id,
                                              validation_flag,
                                              interface_source_code,
                                              org_id,
                                              destination_organization_id,
                                              po_number,
                                              receipt_number,
                                              attribute9)
           VALUES (rec.interface_transaction_id,
                   rec.GROUP_ID,
                   rec.last_update_date,
                   rec.last_updated_by,
                   rec.creation_date,
                   rec.created_by,
                   rec.last_update_login,
                   rec.transaction_type,
                   rec.transaction_date,
                   rec.processing_status_code,
                   rec.processing_mode_code,
                   rec.transaction_status_code,
                   rec.po_header_id,
                   rec.po_line_id,
                   rec.item_id,
                   rec.quantity,
                   rec.unit_of_measure,
                   rec.po_line_location_id,
                   rec.auto_transact_code,
                   rec.receipt_source_code,
                   rec.to_organization_id,
                   rec.ship_to_location_id,
                   rec.source_document_code,
                   rec.document_num,
                   rec.destination_type_code,
                   rec.deliver_to_person_id,
                   rec.deliver_to_location_id,
                   rec.subinventory,
                   rec.header_interface_id,
                   rec.validation_flag,
                   rec.interface_source_code,
                   rec.org_id,
                   rec.destination_organization_id,
                   rec.po_number,
                   rec.receipt_number,
                   rec.attribute9);
   END;

   PROCEDURE insert_to_iface (errbuf                 OUT VARCHAR2,
                              retcode                OUT VARCHAR2,
                              p_group_id          IN     NUMBER,
                              p_header_cnt           OUT NUMBER,
                              p_transaction_cnt      OUT NUMBER,
                              p_status               OUT VARCHAR2)
   IS
      v_hdr_cnt             NUMBER := 0;
      v_transaction_cnt     NUMBER := 0;
      v_count               NUMBER;
      l_chr_lot_number      VARCHAR2 (50);
      l_chr_return_status   VARCHAR2 (2000);
      l_chr_msg_data        VARCHAR2 (50);
      l_num_msg_count       NUMBER;

      CURSOR header_iface_cur
      IS
         SELECT *
           FROM xxshp_rcv_headers_temp
          WHERE GROUP_ID = p_group_id;

      CURSOR transaction_iface_cur
      IS
         SELECT *
           FROM xxshp_rcv_transaction_temp
          WHERE GROUP_ID = p_group_id;
   BEGIN
      FOR hdr IN header_iface_cur
      LOOP
         INSERT INTO rcv_headers_interface (header_interface_id,
                                            GROUP_ID,
                                            processing_status_code,
                                            receipt_source_code,
                                            transaction_type,
                                            auto_transact_code,
                                            last_update_date,
                                            last_updated_by,
                                            last_update_login,
                                            creation_date,
                                            created_by,
                                            vendor_id,
                                            vendor_site_id,
                                            ship_to_organization_id,
                                            expected_receipt_date,
                                            org_id,
                                            validation_flag,
                                            attribute8,
                                            shipment_num,
                                            location_id,
                                            shipped_date)
              VALUES (hdr.header_interface_id,
                      hdr.GROUP_ID,
                      hdr.processing_status_code,
                      hdr.receipt_source_code,
                      hdr.transaction_type,
                      hdr.auto_transact_code,
                      hdr.last_update_date,
                      hdr.last_updated_by,
                      hdr.last_update_login,
                      hdr.creation_date,
                      hdr.created_by,
                      hdr.vendor_id,
                      hdr.vendor_site_id,
                      hdr.ship_to_organization_id,
                      hdr.expected_receipt_date,
                      hdr.org_id,
                      hdr.validation_flag,
                      hdr.attribute8,
                      hdr.shipment_num,
                      hdr.location_id,
                      hdr.shipped_date);

         v_hdr_cnt := v_hdr_cnt + 1;
      END LOOP;

      FOR rec IN transaction_iface_cur
      LOOP
         INSERT INTO rcv_transactions_interface (interface_transaction_id,
                                                 GROUP_ID,
                                                 last_update_date,
                                                 last_updated_by,
                                                 creation_date,
                                                 created_by,
                                                 last_update_login,
                                                 transaction_type,
                                                 transaction_date,
                                                 processing_status_code,
                                                 processing_mode_code,
                                                 transaction_status_code,
                                                 po_header_id,
                                                 po_line_id,
                                                 item_id,
                                                 quantity,
                                                 unit_of_measure,
                                                 po_line_location_id,
                                                 auto_transact_code,
                                                 receipt_source_code,
                                                 to_organization_id,
                                                 ship_to_location_id,
                                                 source_document_code,
                                                 document_num,
                                                 destination_type_code,
                                                 deliver_to_person_id,
                                                 deliver_to_location_id,
                                                 subinventory,
                                                 header_interface_id,
                                                 validation_flag,
                                                 interface_source_code,
                                                 org_id,
                                                 attribute9)
              VALUES (rec.interface_transaction_id,
                      rec.GROUP_ID,
                      rec.last_update_date,
                      rec.last_updated_by,
                      rec.creation_date,
                      rec.created_by,
                      rec.last_update_login,
                      rec.transaction_type,
                      rec.transaction_date,
                      rec.processing_status_code,
                      rec.processing_mode_code,
                      rec.transaction_status_code,
                      rec.po_header_id,
                      rec.po_line_id,
                      rec.item_id,
                      rec.quantity,
                      rec.unit_of_measure,
                      rec.po_line_location_id,
                      rec.auto_transact_code,
                      rec.receipt_source_code,
                      rec.to_organization_id,
                      rec.ship_to_location_id,
                      rec.source_document_code,
                      rec.document_num,
                      rec.destination_type_code,
                      rec.deliver_to_person_id,
                      rec.deliver_to_location_id,
                      rec.subinventory,
                      rec.header_interface_id,
                      rec.validation_flag,
                      rec.interface_source_code,
                      rec.org_id,
                      rec.attribute9);

         logf ('After insert to rcv_transactions_interface');

         BEGIN
            logf ('count lot control code');

            SELECT COUNT (*)
              INTO v_count
              FROM mtl_system_items
             WHERE     inventory_item_id = rec.item_id
                   AND lot_control_code = 2 -- 2 - full_control, 1 - no control
                   AND organization_id = rec.destination_organization_id;

            logf ('count = ' || v_count);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_count := 0;
               logf ('can not count lot control code');
         END;

         logf ('current count = ' || v_count);

         IF v_count > 0
         THEN
            logf ('The Ordered Item is Lot Controlled');
            logf ('Generate the Lot Number for the Lot Controlled Item');

            BEGIN
               logf ('initialization');
               -- initialization required for R12
               mo_global.set_policy_context ('S', g_org_id);
               mo_global.init ('INV');
               -- Initialization for Organization_id
               inv_globals.set_org_id (rec.destination_organization_id);
               -- initialize environment
               fnd_global.apps_initialize (user_id        => g_user_id,
                                           resp_id        => g_resp_id,
                                           resp_appl_id   => g_resp_appl_id);
               logf (
                  'Calling inv_lot_api_pub.auto_gen_lot API to Create Lot Numbers');
               logf ('*********************************************');
               l_chr_lot_number :=
                  inv_lot_api_pub.auto_gen_lot (
                     p_org_id              => rec.destination_organization_id,
                     p_inventory_item_id   => rec.item_id,
                     p_parent_lot_number   => NULL,
                     p_subinventory_code   => NULL,
                     p_locator_id          => NULL,
                     p_api_version         => 1.0,
                     p_init_msg_list       => 'F',
                     p_commit              => 'T',
                     p_validation_level    => 100,
                     x_return_status       => l_chr_return_status,
                     x_msg_count           => l_num_msg_count,
                     x_msg_data            => l_chr_msg_data);

               IF l_chr_return_status = 'S'
               THEN
                  COMMIT;
               ELSE
                  ROLLBACK;
               END IF;

               logf ('l_chr_return_status ' || l_chr_return_status);
               p_status := l_chr_return_status;
            --                  DBMS_OUTPUT.put_line ('Lot Number Created for the item is => ' l_chr_lot_number);
            END;

            logf ('l_chr_return_status ' || l_chr_return_status);

            logf (
               'Inserting the Record into mtl_transaction_lots_interface ');
            logf ('*********************************************');

            INSERT
              INTO mtl_transaction_lots_interface (transaction_interface_id,
                                                   last_update_date,
                                                   last_updated_by,
                                                   creation_date,
                                                   created_by,
                                                   last_update_login,
                                                   lot_number,
                                                   transaction_quantity,
                                                   primary_quantity,
                                                   serial_transaction_temp_id,
                                                   product_code,
                                                   product_transaction_id)
            VALUES (mtl_material_transactions_s.NEXTVAL, --transaction_interface_id
                    SYSDATE,                                --last_update_date
                    g_user_id,                               --last_updated_by
                    SYSDATE,                                   --creation_date
                    g_user_id,                                    --created_by
                    g_login_id,                            --last_update_login
                    l_chr_lot_number,                             --lot_number
                    rec.quantity,                       --transaction_quantity
                    rec.quantity,                           --primary_quantity
                    NULL,                         --serial_transaction_temp_id
                    'RCV',                                      --product_code
                    rec.interface_transaction_id      --product_transaction_id
                                                );
         ELSE
            logf ('The Ordered Item is Not Lot Controlled');
            logf ('********************************************');
         END IF;

         v_transaction_cnt := v_transaction_cnt + 1;
      END LOOP;

      p_header_cnt := v_hdr_cnt;
      p_transaction_cnt := v_transaction_cnt;
   END;

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
   PROCEDURE send_mail (errbuf       OUT VARCHAR2,
                        retcode      OUT VARCHAR2,
                        --p_result      OUT VARCHAR2,
                        --p_email    IN     VARCHAR2,
                        p_batch   IN     NUMBER)
   IS
      v_result                   VARCHAR2 (500);
      p_to                       VARCHAR2 (2000) := 'ardianto.ardi@kalbenutritionals.com';
      --p_to                       VARCHAR2 (2000) := p_email; --'wilson.chandra@kalbenutritionals.com';
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

      p_total_update             NUMBER := 0;


      CURSOR cur_data
      IS
         SELECT pie.interface_type,
                pie.column_name,
                rtt.po_number,
                rtt.receipt_number,
                rtt.item_id,
                pie.error_message,
                pie.processing_date,
                pie.request_id,
                pie.error_message_name,
                pie.table_name,
                pie.interface_header_id,
                pie.interface_line_id
           FROM po_interface_errors pie, xxshp_rcv_transaction_temp rtt
          WHERE     1 = 1
                AND pie.interface_header_id = rtt.header_interface_id
                AND pie.interface_line_id = rtt.interface_transaction_id
                AND batch_id = p_batch;
   BEGIN
      mo_global.set_policy_context ('S', 82);

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
         UTL_SMTP.write_data (v_connection,
                              'Subject: Email tES wOY tes' || UTL_TCP.crlf);
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

         FOR i IN cur_data
         LOOP
            IF (v_filename_group <> 'RCV Interface Error')
            THEN
               v_filename := 'RCV Interface Error';
               v_filename_group := 'RCV Interface Error';

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
                     'Interface Type,PO Number,GRN Number,Item ID,Column Name,Error Message,Processing Date,Requert_id,Error Message Name,Table Name,Interface Header Id,Interface Line Id'
                  || UTL_TCP.crlf;

               UTL_SMTP.write_data (v_connection, v_clob);
            END IF;

            ln_counter := ln_counter + 1;

            --                IF ln_counter = 1 THEN
            --                    UTL_SMTP.write_data (v_connection, v_clob);--To avoid repeation of column heading in csv file
            --                END IF;
            BEGIN
               v_clob :=
                     i.interface_type
                  || ','
                  || i.po_number
                  || ','
                  || i.receipt_number
                  || ','
                  || i.item_id
                  || ','
                  || i.column_name
                  || ','
                  || REPLACE (REPLACE (i.error_message, CHR (10), ' '), ',')
                  || ','
                  || i.processing_date
                  || ','
                  || i.request_id
                  || ','
                  || i.error_message_name
                  || ','
                  || i.table_name
                  || ','
                  || i.interface_header_id
                  || ','
                  || i.interface_line_id
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

         DBMS_OUTPUT.put_line ('POINT Last: ');
      --p_result := 'Success. Email Sent To ' || p_to;
      --fnd_file.put_line (fnd_file.LOG, p_result);
      --return v_result;
      EXCEPTION
         WHEN OTHERS
         THEN
            --p_result := SQLERRM;
            --fnd_file.put_line (fnd_file.LOG, v_result);
            DBMS_OUTPUT.put_line (SQLERRM);
      END;
   END send_mail;

   PROCEDURE waitforrequest (in_requestid       IN     NUMBER,
                             out_status            OUT VARCHAR2,
                             out_errormessage      OUT VARCHAR2)
   IS
      v_result      BOOLEAN;
      v_phase       VARCHAR2 (20);
      v_devphase    VARCHAR2 (20);
      v_devstatus   VARCHAR2 (20);
   BEGIN
      v_result :=
         fnd_concurrent.wait_for_request (in_requestid,
                                          5,
                                          0,
                                          v_phase,
                                          out_status,
                                          v_devphase,
                                          v_devstatus,
                                          out_errormessage);
   END waitforrequest;

   PROCEDURE main_process (errbuf           OUT VARCHAR2,
                           retcode          OUT NUMBER,
                           p_trx_id             NUMBER,
                           p_po_header_id       NUMBER)
   IS
      v_group_id            NUMBER;
      v_header_iface_id     NUMBER;
      v_org_id              NUMBER;
      v_request             NUMBER;
      v_receipt_req_id      NUMBER;
      v_count               NUMBER;
      l_num_msg_count       NUMBER;
      l_chr_lot_number      VARCHAR2 (50);
      l_chr_return_status   VARCHAR2 (2000);
      l_chr_msg_data        VARCHAR2 (50);
      v_err_req             VARCHAR2 (240);
      v_status_req          VARCHAR2 (240);
      v_phase               VARCHAR2 (50);
      v_out_status          VARCHAR2 (50);
      v_devphase            VARCHAR2 (50);
      v_devstatus           VARCHAR2 (50);
      v_errormessage        VARCHAR2 (250);
      v_result              BOOLEAN;
      v_receipt_num         VARCHAR2 (30);
      v_organization_id     NUMBER;
      v_report_id           NUMBER;
      v_val                 NUMBER := 0;
      v_layout              BOOLEAN;

      --aar
      v_iface_transaction   NUMBER;
      l_header_cnt          NUMBER;
      l_transaction_cnt     NUMBER;
      --end aar

      v_result              VARCHAR2 (4000);
      v_errbuf              VARCHAR2 (4000);
      v_retcode             VARCHAR2 (4000);
      l_status              VARCHAR2 (400);

      temp_transac          xxshp_rcv_transaction_temp%ROWTYPE;
      temp_hdr              xxshp_rcv_headers_temp%ROWTYPE;
   BEGIN
      v_group_id := 0;

      FOR i
         IN iface_hdr_cur (p_ntrx_id     => p_trx_id,
                           p_po_hdr_id   => p_po_header_id)
      LOOP
         v_org_id := i.org_id;

         IF v_group_id = 0
         THEN
            v_group_id := rcv_interface_groups_s.NEXTVAL;
            v_header_iface_id := rcv_headers_interface_s.NEXTVAL;

            v_receipt_num := i.receipt_num;
         ELSE
            logf ('More than 1 Header Found');
         END IF;

         logf ('Group ID :' || v_group_id);
         logf ('Header Interface ID :' || v_header_iface_id);
         --header
         logf ('*******************************************');
         logf ('Before Insert to rcv_headers_interface');

         -----aar
         temp_hdr.header_interface_id := v_header_iface_id;
         temp_hdr.GROUP_ID := v_group_id;
         temp_hdr.processing_status_code := 'PENDING';
         temp_hdr.receipt_source_code := 'VENDOR';
         temp_hdr.transaction_type := 'NEW';
         temp_hdr.auto_transact_code := 'DELIVER';
         temp_hdr.last_update_date := SYSDATE;
         temp_hdr.last_updated_by := g_user_id;
         temp_hdr.last_update_login := g_login_id;
         temp_hdr.creation_date := SYSDATE;
         temp_hdr.created_by := g_user_id;
         temp_hdr.vendor_id := i.vendor_id;
         temp_hdr.vendor_site_id := i.vendor_site_id;
         temp_hdr.ship_to_organization_id := i.ship_to_organization_id;
         temp_hdr.expected_receipt_date := i.expected_receipt_date;
         temp_hdr.org_id := g_org_id;
         temp_hdr.validation_flag := 'Y';
         temp_hdr.attribute8 := i.receipt_num;
         temp_hdr.shipment_num := NULL;
         temp_hdr.location_id := NULL;
         temp_hdr.shipped_date := i.shipped_date;

         insert_to_header_temp (temp_hdr);

         ----end aar

         /*INSERT INTO rcv_headers_interface (header_interface_id,
                                            GROUP_ID,
                                            processing_status_code,
                                            receipt_source_code,
                                            transaction_type,
                                            auto_transact_code,
                                            last_update_date,
                                            last_updated_by,
                                            last_update_login,
                                            creation_date,
                                            created_by,
                                            vendor_id,
                                            vendor_site_id,
                                            ship_to_organization_id,
                                            expected_receipt_date,
                                            org_id,
                                            validation_flag,
                                            attribute8,
                                            shipment_num,
                                            location_id,
                                            shipped_date)
              VALUES (NULL,                               --v_header_iface_id,
                      v_group_id,
                      'PENDING',
                      'VENDOR',
                      'NEW',
                      'DELIVER',
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      SYSDATE,
                      g_user_id,
                      i.vendor_id,
                      i.vendor_site_id,
                      i.ship_to_organization_id,
                      i.expected_receipt_date,
                      g_org_id,
                      'Y',
                      i.receipt_num,                        --/*i.shipment_num
                      NULL,         --/*i.ship_to_location_id OR i.location_id
                      NULL,
                      i.shipped_date);*/

         logf ('After Insert to rcv_headers_interface');
         --transaction
         logf ('*******************************************');

         FOR j
            IN transac_iface_cur (p_po_header_id       => i.po_header_id,
                                  p_line_loc_id        => i.line_location_id,
                                  p_item_id            => i.item_id,
                                  p_uom_code           => i.uom_code,
                                  p_primary_quantity   => i.primary_quantity)
         LOOP
            logf ('Before Insert to rcv_transactions_interface');
            logf ('UOM: ' || j.unit_meas_lookup_code);
            logf ('Quantity: ' || j.quantity);

            IF (NVL (j.quantity, 0) <= 0)
            THEN
               logf ('Please check UOM Conversion');
               retcode := 2;
            END IF;

            v_iface_transaction := rcv_transactions_interface_s.NEXTVAL;

            --aar
            temp_transac.interface_transaction_id := v_iface_transaction;
            temp_transac.GROUP_ID := v_group_id;
            temp_transac.last_update_date := SYSDATE;
            temp_transac.last_updated_by := g_user_id;
            temp_transac.creation_date := SYSDATE;
            temp_transac.created_by := g_user_id;
            temp_transac.last_update_login := g_login_id;
            temp_transac.transaction_type := 'RECEIVE';
            temp_transac.transaction_date := SYSDATE;
            temp_transac.processing_status_code := 'PENDING';
            temp_transac.processing_mode_code := 'BATCH';
            temp_transac.transaction_status_code := 'PENDING';
            temp_transac.po_header_id := j.po_header_id;
            temp_transac.po_line_id := j.po_line_id;
            temp_transac.item_id := j.item_id;
            temp_transac.quantity := j.quantity;
            temp_transac.unit_of_measure := j.unit_meas_lookup_code;
            temp_transac.po_line_location_id := j.line_location_id;
            temp_transac.auto_transact_code := 'DELIVER';
            temp_transac.receipt_source_code := 'VENDOR';
            temp_transac.to_organization_id := i.ship_to_organization_id;
            temp_transac.ship_to_location_id := NULL;
            temp_transac.source_document_code := 'PO';
            temp_transac.document_num := NULL;
            temp_transac.destination_type_code := j.destination_type_code;
            temp_transac.deliver_to_person_id := j.deliver_to_person_id;
            temp_transac.deliver_to_location_id := j.deliver_to_location_id;
            temp_transac.subinventory := j.destination_subinventory;
            temp_transac.header_interface_id := v_header_iface_id;
            temp_transac.validation_flag := 'Y';
            temp_transac.interface_source_code := 'RCV';
            temp_transac.org_id := i.org_id;
            temp_transac.destination_organization_id :=
               j.destination_organization_id;
            temp_transac.po_number := i.po_num;
            temp_transac.receipt_number := i.receipt_num;
            temp_transac.attribute9 := p_trx_id;

            insert_to_transaction_temp (temp_transac);
         --end aar

         /*INSERT INTO rcv_transactions_interface (interface_transaction_id,
                                                 GROUP_ID,
                                                 last_update_date,
                                                 last_updated_by,
                                                 creation_date,
                                                 created_by,
                                                 last_update_login,
                                                 transaction_type,
                                                 transaction_date,
                                                 processing_status_code,
                                                 processing_mode_code,
                                                 transaction_status_code,
                                                 po_header_id,
                                                 po_line_id,
                                                 item_id,
                                                 quantity,
                                                 unit_of_measure,
                                                 po_line_location_id,
                                                 auto_transact_code,
                                                 receipt_source_code,
                                                 to_organization_id,
                                                 ship_to_location_id,
                                                 source_document_code,
                                                 document_num,
                                                 destination_type_code,
                                                 deliver_to_person_id,
                                                 deliver_to_location_id,
                                                 subinventory,
                                                 header_interface_id,
                                                 validation_flag,
                                                 interface_source_code,
                                                 org_id,
                                                 attribute9)
              VALUES (v_iface_transaction,
                      v_group_id,
                      SYSDATE,
                      g_user_id,
                      SYSDATE,
                      g_user_id,
                      g_login_id,
                      'RECEIVE',
                      SYSDATE,
                      'PENDING',
                      'BATCH',
                      'PENDING',
                      j.po_header_id,
                      j.po_line_id,
                      NULL,                                    --j.item_id,
                      NULL,                                   --j.quantity,
                      j.unit_meas_lookup_code,
                      j.line_location_id,
                      'DELIVER',
                      'VENDOR',
                      i.ship_to_organization_id,          --/*i.location_id
                      NULL,
                      'PO',                                   -- /*i.po_num
                      NULL,
                      j.destination_type_code,
                      j.deliver_to_person_id,
                      j.deliver_to_location_id,
                      --NULL,
                      j.destination_subinventory,
                      v_header_iface_id,
                      'Y',
                      'RCV',
                      i.org_id,
                      p_trx_id);*/
         END LOOP;
      --         UPDATE xxshp_po_asn_receipt
      --            SET status = 'C',
      --                last_update_date = SYSDATE,
      --                last_updated_by = g_user_id,
      --                last_update_login = g_login_id
      --          WHERE request_id = g_request_id AND file_id = p_file_id AND asn_no = i.asn_no;
      END LOOP;

      COMMIT;

      insert_to_iface (v_errbuf,
                       v_retcode,
                       v_group_id,
                       l_header_cnt,
                       l_transaction_cnt,
                       l_status);
      logf ('Sukses insert into interface');
      logf ('Batch/Group Number ' || v_group_id);
      logf ('Total Header Counter ' || l_header_cnt);
      logf ('Total Transaction Counter ' || l_transaction_cnt);
      logf ('Status '|| l_status);


      IF (NVL (retcode, 0) <> 2)
      THEN
         IF v_group_id > 0
         THEN
            v_receipt_req_id :=
               apps.fnd_request.submit_request (
                  application   => 'PO',
                  program       => 'RVCTP',
                  description   =>    'Autoreceive PO Toll Fee # '
                                   || g_conc_request_id,
                  start_time    => NULL,
                  sub_request   => FALSE,
                  argument1     => 'BATCH',
                  argument2     => v_group_id,
                  argument3     => v_org_id);
            COMMIT;
         END IF;


         IF NVL (v_receipt_req_id, 0) = 0
         THEN
            --                v_errmsg :=
            --                      'Receiving Transaction Processor Concurrent submission failed : '
            --                   || SQLERRM;
            logf ('Receiving Transaction Processor Concurrent failed');
            logf (SQLCODE || '-' || SQLERRM);
         --RAISE e_exception;
         ELSE
            --wait for request
            logf (
               'Request ID ' || v_receipt_req_id || ' has been submitted !');
            waitforrequest (v_receipt_req_id, v_status_req, v_err_req);

            IF (UPPER (v_status_req) <> 'NORMAL')
            THEN
               retcode := 2;
               logf (
                     'Concurrent SHP - PO Autoreceive PO Toll Fee failed'
                  || SQLCODE
                  || ' - '
                  || SQLERRM
                  || ' - '
                  || v_err_req);

               FOR cek_rtp IN (SELECT error_message, interface_line_id
                                 FROM po_interface_errors
                                WHERE batch_id = v_group_id)
               LOOP
                  logf ('interface_line_id : ' || cek_rtp.interface_line_id);

                  IF TRIM (cek_rtp.error_message) IS NULL
                  THEN
                     logf ('no errors');
                     v_val := 1;
                  ELSE
                     logf ('error : ' || cek_rtp.error_message);
                     --aar
                     xxshp_po_rcv_tollfee_pkg.send_mail (v_errbuf,
                                                         v_retcode,
                                                         --v_result,
                                                         v_group_id);
                  --end aar
                  END IF;
               END LOOP;
            --RAISE e_exception;
            ELSE
               v_val := 1;

               FOR cek_rtp IN (SELECT error_message, interface_line_id
                                 FROM po_interface_errors
                                WHERE batch_id = v_group_id)
               LOOP
                  logf ('interface_line_id : ' || cek_rtp.interface_line_id);
                  logf ('error : ' || cek_rtp.error_message);
                  retcode := 2;
                  v_val := 0;
               END LOOP;
            --logf ('Concurrent SHP - PO Autoreceive PO Toll Fee Success');
            --DBMS_OUTPUT.put_line ('Concurrent SHP - PO Autoreceive PO Toll Fee Success');
            END IF;
         ----------- CANCELLED-----
         /*
         IF (v_val = 1)
         THEN
            logf ('Run SHP - Good Receipt Note Fee');

            BEGIN
               SELECT rsh.ship_to_org_id
                 INTO v_organization_id
                 FROM rcv_transactions rt, rcv_shipment_headers rsh
                WHERE     rt.shipment_header_id = rsh.shipment_header_id
                      AND rt.transaction_type = 'RECEIVE'
                      AND rsh.attribute8 IS NOT NULL
                      AND rt.request_id = v_receipt_req_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf ('Error when get ship_to_org_id ' || SQLERRM);
                  v_organization_id := NULL;
            END;


            IF (v_organization_id IS NOT NULL AND v_receipt_num IS NOT NULL)
            THEN
               v_layout :=
                  fnd_request.add_layout (template_appl_name   => 'XXSHP',
                                          template_code        => 'XXSHP_GRN_FEE',
                                          template_language    => 'en',
                                          template_territory   => 'US',
                                          output_format        => 'PDF');

               v_report_id :=
                  apps.fnd_request.submit_request (application   => 'XXSHP',
                                                   program       => 'XXSHP_GRN_FEE',
                                                   description   => g_conc_request_id,
                                                   start_time    => NULL,
                                                   sub_request   => FALSE,
                                                   argument1     => v_org_id,
                                                   argument2     => v_organization_id,
                                                   argument3     => g_user_id,
                                                   argument4     => v_receipt_num,
                                                   argument5     => v_receipt_num,
                                                   argument6     => NULL,
                                                   argument7     => NULL,
                                                   argument8     => NULL,
                                                   argument9     => NULL,
                                                   argument10    => NULL,
                                                   argument11    => NULL,
                                                   argument12    => NULL,
                                                   argument13    => NULL,
                                                   argument14    => NULL,
                                                   argument15    => NULL);

               IF NVL (v_report_id, 0) = 0
               THEN
                  logf ('Failed when submitting SHP - Good Receipt Note Fee');
                  logf (SQLCODE || '-' || SQLERRM);
               --RAISE e_exception;
               ELSE
                  logf (
                        'SHP - Good Receipt Note Fee has been submitted with Request ID '
                     || v_report_id);
               END IF;
            END IF;
         END IF;
         */
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         logf ('Error when submitting main process ' || SQLERRM);
         retcode := 2;
   END main_process;
END xxshp_po_rcv_tollfee_pkg;
/
