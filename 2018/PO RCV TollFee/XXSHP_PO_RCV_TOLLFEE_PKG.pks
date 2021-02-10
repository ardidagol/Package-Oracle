CREATE OR REPLACE PACKAGE APPS.xxshp_po_rcv_tollfee_pkg
   AUTHID CURRENT_USER
/* $Header: xxshp_po_rcv_tollfee_pkg.pks 122.5.1.0 2017/02/08 10:34:00 Puguh MS $ */
AS
   /**************************************************************************************************
      NAME: xxshp_po_rcv_tollfee_pkg
      PURPOSE:

      REVISIONS:
      Ver         Date                 Author              Description
      ---------   ----------          ---------------     ------------------------------------
      1.0         08-Feb-2017          Puguh MS            1. Created this package
      1.2         27-Nov-2018          Ardianto            1. Modified this package
                                                           2. Add Procedure send_mail
                                                           3. Add Cursor iface_hdr_cur
                                                           4. Add Cursor transac_iface_cur
  **************************************************************************************************/

   g_resp_appl_id      NUMBER DEFAULT fnd_global.resp_appl_id;
   g_resp_id           NUMBER DEFAULT fnd_global.resp_id;
   g_conc_program_id   NUMBER DEFAULT fnd_global.conc_program_id;
   g_conc_request_id   NUMBER DEFAULT fnd_global.conc_request_id;
   g_org_id            NUMBER DEFAULT fnd_global.org_id;
   g_user_id           NUMBER DEFAULT fnd_global.user_id;
   g_username          VARCHAR2 (100) DEFAULT fnd_global.user_name;
   g_login_id          NUMBER := fnd_global.login_id;


   PROCEDURE main_process (errbuf           OUT VARCHAR2,
                           retcode          OUT NUMBER,
                           p_trx_id             NUMBER,
                           p_po_header_id       NUMBER);

   PROCEDURE send_mail (errbuf       OUT VARCHAR2,
                        retcode      OUT VARCHAR2,
                        --p_result      OUT VARCHAR2,
                        --p_email    IN     VARCHAR2,
                        p_batch   IN     NUMBER);

   --awt27-11-18
   CURSOR iface_hdr_cur (
      p_ntrx_id      NUMBER,
      p_po_hdr_id    NUMBER)
   IS
      SELECT rt.transaction_id,
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
             poh.segment1 po_num,                         /*rsl.employee_id,*/
             rsh.ship_to_location_id,
             rsl.creation_date shipped_date,
             (SELECT hl.location_id
                FROM hr_locations hl
               WHERE     hl.inventory_organization_id IS NOT NULL
                     AND hl.inventory_organization_id =
                            pll.ship_to_organization_id
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
             AND gbh.organization_id = rsl.from_organization_id       --9mar17
             AND rt.transaction_id = p_ntrx_id
             AND poh.po_header_id = p_po_hdr_id;

   CURSOR transac_iface_cur (
      p_po_header_id        NUMBER,
      p_line_loc_id         NUMBER,
      p_item_id             NUMBER,
      p_uom_code            VARCHAR,
      p_primary_quantity    NUMBER)
   IS
      SELECT pl.org_id,
             pl.po_header_id,
             pl.item_id,
             pl.po_line_id,
             pl.line_num,                          /*pll.quantity PGH10mar17*/
               --updated by farry on 19sept 17
               --i.transact_qty quantity,
               xxshp_general_pkg.get_uom_conv_value (p_item_id,
                                                     p_uom_code,
                                                     muom.uom_code,
                                                     NULL)
             * p_primary_quantity
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
       WHERE     pl.po_header_id = p_po_header_id
             AND pl.po_line_id = pll.po_line_id
             AND pll.line_location_id = pda.line_location_id
             AND pll.line_location_id = p_line_loc_id
             AND pll.ship_to_organization_id = mp.organization_id
             AND muom.unit_of_measure = pl.unit_meas_lookup_code;
--end awt27-11-18
END xxshp_po_rcv_tollfee_pkg;
/
