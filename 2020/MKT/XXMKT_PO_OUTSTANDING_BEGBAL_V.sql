DROP VIEW APPS.XXMKT_PO_OUTSTANDING_BEGBAL_V;

/* Formatted on 7/28/2020 2:07:51 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXMKT_PO_OUTSTANDING_BEGBAL_V
(
   PO_HEADER_ID,
   PO_DISTRIBUTION_ID,
   LINE_LOCATION_ID,
   SHIP_TO_LOCATION_ID,
   PO_NUMBER,
   LOCATION_CODE,
   STATUS,
   VENDOR_ID,
   VENDOR_NAME,
   VENDOR_SITE_ID,
   VENDOR_SITE_CODE,
   PO_LINE_ID,
   ITEM_ID,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   SHIP_TO_ORGANIZATION_ID,
   NEED_BY_DATE,
   UOM_CODE,
   UNIT_OF_MEASURE,
   QUANTITY,
   QUANTITY_RECEIVED,
   QTYSALDO,
   PRNO_ORACLE,
   PRNO_DOLPHIN,
   CODE_COMBINATION_ID,
   CODE_COMBINATION_NAME
)
   BEQUEATH DEFINER
AS
     SELECT DISTINCT
            ph.po_header_id,
            pda.po_distribution_id,
            plloc.line_location_id,
            ph.ship_to_location_id,
            ph.segment1 po_number,
            hrl.location_code,
            INITCAP (ph.authorization_status) status,
            ph.vendor_id,
            aps.vendor_name,
            ph.vendor_site_id,
            pvsa.vendor_site_code,
            pl.po_line_id,
            pl.item_id,
            (SELECT segment1
               FROM mtl_system_items
              WHERE     inventory_item_id = pl.item_id
                    AND organization_id = plloc.ship_to_organization_id)
               item_code,
            pl.item_description,
            plloc.ship_to_organization_id,
            plloc.need_by_date,
            muom.uom_code uom_code,
            muom.unit_of_measure unit_of_measure,
            plloc.quantity,
            plloc.quantity_received,
            (  plloc.quantity
             - (plloc.quantity_received + plloc.quantity_cancelled))
               qtysaldo,
            prha.segment1 prno_oracle,
            prha.attribute10 prno_dolphin,
            pda.code_combination_id,
            gcc.CONCATENATED_SEGMENTS code_combination_name
       FROM po_headers_all ph,
            po_lines_all pl,
            po_line_locations_all plloc,
            ap_suppliers aps,
            mtl_units_of_measure_tl muom,
            po_requisition_lines_all prla,
            po_requisition_headers_all prha,
            hr_locations_all_tl hrl,
            po_releases_all pra,
            po_vendor_sites_all pvsa,
            po_distributions_all pda,
            gl_code_combinations_kfv gcc
      WHERE     1 = 1
            AND ph.org_id = fnd_profile.VALUE ('ORG_ID')
            AND pvsa.vendor_id = ph.vendor_id
            AND pvsa.vendor_site_id = ph.vendor_site_id
            AND ph.po_header_id = pl.po_header_id
            AND ph.vendor_id = aps.vendor_id
            AND pl.po_line_id = plloc.po_line_id
            AND ph.po_header_id = pda.po_header_id
            AND pl.po_line_id = pda.po_line_id
            AND pda.code_combination_id = gcc.CODE_COMBINATION_ID
            AND hrl.location_id = plloc.ship_to_location_id
            AND muom.unit_of_measure = plloc.unit_meas_lookup_code
            AND pra.po_header_id(+) = ph.po_header_id
            AND prla.line_location_id(+) = plloc.line_location_id
            AND prha.requisition_header_id(+) = prla.requisition_header_id
            AND (  plloc.quantity
                 - (plloc.quantity_received + plloc.quantity_cancelled)) > 0
            AND plloc.quantity_cancelled = 0
            AND (   UPPER (ph.authorization_status) IN ('APPROVED')
                 OR ph.authorization_status IS NULL)
            AND NVL (ph.cancel_flag, 'N') <> 'Y'
            AND NVL (pl.closed_code, 'OPEN') = 'OPEN'
            AND plloc.closed_code NOT IN ('CLOSED FOR RECEIVING', 'CLOSED')
            AND ph.type_lookup_code <> 'BLANKET'
            AND (   pra.authorization_status IN ('APPROVED')
                 OR pra.authorization_status IS NULL)
            AND plloc.ship_to_organization_id IN (97, 95)
   --AND prha.attribute10 IS NOT NULL
   --AND ph.segment1 = '191373'
   ORDER BY ph.po_header_id, pl.po_line_id, pl.item_id;
