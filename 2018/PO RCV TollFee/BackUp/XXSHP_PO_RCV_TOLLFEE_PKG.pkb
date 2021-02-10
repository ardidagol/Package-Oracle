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
     ***************************************************************************************************/
   PROCEDURE logf (p_msg IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   END outf;

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
   BEGIN
      v_group_id := 0;

      FOR i
         IN (SELECT rt.transaction_id,
                    prl.org_id,
                    rsh.receipt_num,
                    rsl.creation_date receipt_date,
                    rsh.shipment_header_id,
                    rsh.shipment_num,
                    rt.transaction_type,
                    rsh.receipt_source_code source_type,
                    prl.requisition_header_id req_header_id,
                    prh.segment1 req_number,
                    rt.source_document_code,
                    prl.attribute8 batch_id,
                    gbh.batch_no,
                    prh.authorization_status,
                    poh.vendor_id,
                    poh.vendor_site_id,
                    rsl.creation_date expected_receipt_date,
                    pll.shipment_type,
                    rt.organization_id,
                    rsl.item_id,
                    --rt.quantity
                    --updated by farry on 14sept 17
                    --rt.SOURCE_DOC_QUANTITY transact_qty,
                    --updated by farry on 19sept 17
                    rt.primary_quantity,
                    rt.primary_unit_of_measure,
                    rt.uom_code,
                    rt.secondary_quantity,
                    rt.secondary_unit_of_measure,
                    --rt.uom_code transact_uom,
                    poh.po_header_id,
                    pll.po_line_id,
                    pll.line_location_id,
                    pll.ship_to_organization_id,
                    rsh.ship_to_org_id,
                    poh.segment1 po_num,                                        /*rsl.employee_id,*/
                    rsh.ship_to_location_id,
                    rsl.creation_date shipped_date,
                    (SELECT hl.location_id
                       FROM hr_locations hl
                      WHERE     hl.inventory_organization_id IS NOT NULL
                            AND hl.inventory_organization_id = pll.ship_to_organization_id
                            AND hl.ship_to_site_flag = 'Y'
                            AND ROWNUM = 1)
                       location_id
               FROM rcv_transactions rt,
                    rcv_shipment_headers rsh,
                    rcv_shipment_lines rsl,
                    po_requisition_lines_all prl,
                    po_requisition_headers_all prh,
                    gme_batch_header gbh,
                    mtl_parameters_view mpv,
                    (SELECT DISTINCT po_header_id,
                                     attribute7 batch_link,
                                     shipment_type,
                                     po_line_id,
                                     line_location_id,
                                     ship_to_organization_id
                       FROM po_line_locations_all) pll,
                    po_headers_all poh
              WHERE     rsh.shipment_header_id = rt.shipment_header_id
                    AND rt.transaction_type = 'DELIVER'
                    AND rsh.receipt_source_code = 'INTERNAL ORDER'
                    AND rsl.shipment_line_id = rt.shipment_line_id
                    AND prl.requisition_line_id = rt.requisition_line_id
                    AND NVL (prl.clm_info_flag, 'N') = 'N'
                    AND NVL (prl.clm_option_indicator, 'B') <> 'O'
                    AND po_clm_intg_grp.hide_nonfunded ('REQUISITION',
                                                        prl.requisition_header_id,
                                                        prl.requisition_line_id,
                                                        NULL,
                                                        NULL) <> 'Y'
                    AND prh.requisition_header_id = prl.requisition_header_id
                    AND gbh.batch_id || '' = prl.attribute8 || ''
                    AND NVL (prh.federal_flag, 'N') = 'N'
                    --AND gbh.batch_status = 2     --remark 33Maret2017 ,BO boleh semua status                                                                                      --pending hardcode
                    AND gbh.organization_id = mpv.organization_id
                    AND mpv.attribute7 IS NOT NULL
                    AND UPPER (NVL (mpv.attribute14, 'No')) = 'YES'
                    AND gbh.batch_id || '' = pll.batch_link || ''
                    AND pll.po_header_id = poh.po_header_id
                    AND gbh.organization_id = rsl.from_organization_id                      --9mar17
                    AND rt.transaction_id = p_trx_id
                    AND poh.po_header_id = p_po_header_id)
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
              VALUES (v_header_iface_id,
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
                      i.receipt_num,                                              /*i.shipment_num*/
                      NULL,                               /*i.ship_to_location_id OR i.location_id*/
                      NULL,
                      i.shipped_date);

         logf ('After Insert to rcv_headers_interface');
         --transaction
         logf ('*******************************************');

         FOR j
            IN (SELECT pl.org_id,
                       pl.po_header_id,
                       pl.item_id,
                       pl.po_line_id,
                       pl.line_num,                                      /*pll.quantity PGH10mar17*/
                         --updated by farry on 19sept 17
                         --i.transact_qty quantity,
                         xxshp_general_pkg.get_uom_conv_value (i.item_id,
                                                               i.uom_code,
                                                               muom.uom_code,
                                                               NULL)
                       * i.primary_quantity
                          quantity,
                       pl.unit_meas_lookup_code,
                       mp.organization_code,
                       pll.line_location_id,
                       pll.closed_code,
                       pll.quantity_received,
                       pll.cancel_flag,
                       pll.shipment_num,
                       pda.destination_type_code,
                       pda.deliver_to_person_id,
                       pda.deliver_to_location_id,
                       pda.destination_subinventory,
                       pda.destination_organization_id
                  FROM po_lines_all pl,
                       po_line_locations_all pll,
                       mtl_parameters mp,
                       apps.po_distributions_all pda,
                       MTL_UNITS_OF_MEASURE muom
                 WHERE     pl.po_header_id = i.po_header_id
                       AND pl.po_line_id = pll.po_line_id
                       AND pll.line_location_id = pda.line_location_id
                       AND pll.line_location_id = i.line_location_id
                       AND pll.ship_to_organization_id = mp.organization_id
                       AND muom.unit_of_measure = pl.unit_meas_lookup_code)
         LOOP
            logf ('Before Insert to rcv_transactions_interface');
            logf ('UOM: ' || j.unit_meas_lookup_code);
            logf ('Quantity: ' || j.quantity);

            IF (NVL (j.quantity, 0) <= 0)
            THEN
               logf ('Please check UOM Conversion');
               retcode := 2;
            END IF;


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
                 VALUES (zrcv_transactions_interface_s.NEXTVAL,
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
                         j.item_id,
                         j.quantity,
                         j.unit_meas_lookup_code,
                         j.line_location_id,
                         'DELIVER',
                         'VENDOR',
                         i.ship_to_organization_id,                                /*i.location_id*/
                         NULL,
                         'PO',                                                          /*i.po_num*/
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
                         p_trx_id);

            logf ('After insert to rcv_transactions_interface');

            BEGIN
               logf ('count lot control code');

               SELECT COUNT (*)
                 INTO v_count
                 FROM mtl_system_items
                WHERE     inventory_item_id = j.item_id
                      AND lot_control_code = 2                   -- 2 - full_control, 1 - no control
                      AND organization_id = j.destination_organization_id;

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
                  mo_global.set_policy_context ('S', i.org_id);
                  mo_global.init ('INV');
                  -- Initialization for Organization_id
                  inv_globals.set_org_id (j.destination_organization_id);
                  -- initialize environment
                  fnd_global.apps_initialize (user_id        => g_user_id,
                                              resp_id        => g_resp_id,
                                              resp_appl_id   => g_resp_appl_id);
                  logf ('Calling inv_lot_api_pub.auto_gen_lot API to Create Lot Numbers');
                  logf ('*********************************************');
                  l_chr_lot_number :=
                     inv_lot_api_pub.auto_gen_lot (p_org_id              => j.destination_organization_id,
                                                   p_inventory_item_id   => j.item_id,
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

                  logf ('l_chr_return_status' || l_chr_return_status);
               --                  DBMS_OUTPUT.put_line ('Lot Number Created for the item is => ' l_chr_lot_number);
               END;

               logf ('Inserting the Record into mtl_transaction_lots_interface ');
               logf ('*********************************************');

               INSERT INTO mtl_transaction_lots_interface (transaction_interface_id,
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
                    VALUES (mtl_material_transactions_s.NEXTVAL,          --transaction_interface_id
                            SYSDATE,                                              --last_update_date
                            g_user_id,                                             --last_updated_by
                            SYSDATE,                                                 --creation_date
                            g_user_id,                                                  --created_by
                            g_login_id,                                          --last_update_login
                            l_chr_lot_number,                                           --lot_number
                            j.quantity,                                       --transaction_quantity
                            j.quantity,                                           --primary_quantity
                            NULL,                                       --serial_transaction_temp_id
                            'RCV',                                                    --product_code
                            rcv_transactions_interface_s.CURRVAL            --product_transaction_id
                                                                );
            ELSE
               logf ('The Ordered Item is Not Lot Controlled');
               logf ('********************************************');
            END IF;
         END LOOP;
      --         UPDATE xxshp_po_asn_receipt
      --            SET status = 'C',
      --                last_update_date = SYSDATE,
      --                last_updated_by = g_user_id,
      --                last_update_login = g_login_id
      --          WHERE request_id = g_request_id AND file_id = p_file_id AND asn_no = i.asn_no;
      END LOOP;

      COMMIT;

      IF (NVL (retcode, 0) <> 2)
      THEN
         IF v_group_id > 0
         THEN
            v_receipt_req_id :=
               apps.fnd_request.submit_request (
                  application   => 'PO',
                  program       => 'RVCTP',
                  description   => 'Autoreceive PO Toll Fee # ' || g_conc_request_id,
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
            logf ('Request ID ' || v_receipt_req_id || ' has been submitted !');
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
