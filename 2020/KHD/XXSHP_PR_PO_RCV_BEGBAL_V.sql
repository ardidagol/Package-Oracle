--DROP VIEW APPS.XXSHP_PR_PO_RCV_BEGBAL_V;

/* Formatted on 7/28/2020 2:09:21 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXSHP_PR_PO_RCV_BEGBAL_V
(
   NO_PR_DOP,
   REQUISITION_LINE_ID,
   PR_DISTRIBUTION_ID,
   LINE_LOCATION_ID_PR,
   LINE_LOCATION_ID_PO,
   INVENTORY_ITEM_ID,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   UOM_CODE,
   UNIT_MEAS_LOOKUP_CODE,
   TOTAL_LEAD_TIME,
   DESTINATION_ORGANIZATION_ID,
   ORGANIZATION_CODE,
   PR_ID,
   PR_NUMBER,
   TYPE_PR,
   TYPE_LOOKUP_CODE,
   PR_LINES_ID,
   PR_LINES,
   PR_LINE_CANCEL_FLAG,
   PR_LINE_CLOSED_CODE,
   PR_CREATE_USER_ID,
   PR_CREATE_USER_NAME,
   PR_REQUESTOR,
   PR_QTY,
   PR_NEED_BY_DATE,
   PR_CREATION_DATE,
   PR_APPROVED_DATE,
   PR_STATUS,
   PR_CANCEL_DATE,
   MODIFIED_BY_AGENT_FLAG,
   PO_ID,
   SHIP_TO_LOCATION_ID,
   PO_NUMBER,
   TYPE_PO,
   RELEASE_NUM,
   RELEASE_CREATION_DATE,
   RELEASE_APPROVED_DATE,
   PO_LINES,
   PO_CREATE_USER_ID,
   PO_CREATE_USER_NAME,
   PO_STATUS,
   PO_CLOSED_CODE,
   PO_CREATION_DATE,
   PO_APPROVED_DATE,
   CATEGORY_CONCAT_SEGS,
   PO_QTY,
   PO_UNIT_PRICE_ORIGINAL,
   PO_UNIT_PRICE_OVERRIDE,
   PO_NEED_BY_DATE,
   PO_LINES_CANCEL_FLAG,
   PO_LINES_CLOSED_CODE,
   PO_LINE_LOCATIONS_CANCEL_FLAG,
   PO_LINE_LOCATIONS_CLOSED_CODE,
   DELIVER_TO_LOCATION_ID,
   VENDOR_CODE,
   VENDOR_NAME,
   VENDOR_SITE,
   MIN_ORDER_QTY,
   RECEIPT_ID,
   RECEIPT_NUM,
   RECEIPT_LINES,
   RECEIPT_CREATE_USER_ID,
   RECEIPT_CREATE_USER_NAME,
   RECEIPT_CREATION_DATE,
   TRANSACTION_ID,
   DESTINATION_TYPE_CODE,
   RECEIPT_QTY,
   TRANSACTION_TYPE,
   CURRENCY_CODE,
   CURRENCY_CONVERSION_RATE,
   CURRENCY_CONVERSION_TYPE,
   CURRENCY_CONVERSION_DATE,
   RECEIPT_DATE,
   SHIP_DATE,
   EXPENSE_ACCOUNT,
   REV_DEL_DATE,
   QTY_1,
   REV_DEL_DATE_2,
   QTY_2,
   REVISED_BY,
   COA_NUMBER,
   REQUEST_ID,
   SHIPMENT_HEADER_ID,
   SHIPMENT_LINE_ID,
   TRANSACTION_ID_RECEIPT,
   LINE_NUM
)
   BEQUEATH DEFINER
AS
   SELECT DISTINCT XX."NO_PR_DOP",
                   XX."REQUISITION_LINE_ID",
                   XX."PR_DISTRIBUTION_ID",
                   XX."LINE_LOCATION_ID_PR",
                   XX."LINE_LOCATION_ID_PO",
                   XX."INVENTORY_ITEM_ID",
                   XX."ITEM_CODE",
                   XX."ITEM_DESCRIPTION",
                   XX."UOM_CODE",
                   XX."UNIT_MEAS_LOOKUP_CODE",
                   XX."TOTAL_LEAD_TIME",
                   XX."DESTINATION_ORGANIZATION_ID",
                   XX."ORGANIZATION_CODE",
                   XX."PR_ID",
                   XX."PR_NUMBER",
                   XX."TYPE_PR",
                   XX."TYPE_LOOKUP_CODE",
                   XX."PR_LINES_ID",
                   XX."PR_LINES",
                   XX."PR_LINES_CANCEL_FLAG",
                   XX."PR_LINES_CLOSED_CODE",
                   XX."PR_CREATE_USER_ID",
                   XX."PR_CREATE_USER_NAME",
                   XX."PR_REQUESTOR",
                   XX."PR_QTY",
                   XX."PR_NEED_BY_DATE",
                   XX."PR_CREATION_DATE",
                   XX."PR_APPROVED_DATE",
                   XX."PR_STATUS",
                   XX."PR_CANCEL_DATE",
                   XX."MODIFIED_BY_AGENT_FLAG",
                   XX."PO_ID",
                   XX."SHIP_TO_LOCATION_ID",
                   XX."PO_NUMBER",
                   XX."TYPE_PO",
                   XX."RELEASE_NUM",
                   XX."RELEASE_CREATION_DATE",
                   XX."RELEASE_APPROVED_DATE",
                   XX."PO_LINES",
                   XX."PO_CREATE_USER_ID",
                   XX."PO_CREATE_USER_NAME",
                   XX."PO_STATUS",
                   XX."PO_CLOSED_CODE",
                   XX."PO_CREATION_DATE",
                   XX."PO_APPROVED_DATE",
                   XX."CATEGORY_CONCAT_SEGS",
                   XX."PO_QTY",
                   XX."PO_UNIT_PRICE_ORIGINAL",
                   XX."PO_UNIT_PRICE_OVERRIDE",
                   XX."PO_NEED_BY_DATE",
                   XX."PO_LINES_CANCEL_FLAG",
                   XX."PO_LINES_CLOSED_CODE",
                   XX."PO_LINE_LOCATIONS_CANCEL_FLAG",
                   XX."PO_LINE_LOCATIONS_CLOSED_CODE",
                   XX.DELIVER_TO_LOCATION_ID,
                   XX."VENDOR_CODE",
                   XX."VENDOR_NAME",
                   XX."VENDOR_SITE",
                   XX."MIN_ORDER_QTY",
                   XX."RECEIPT_ID",
                   XX."RECEIPT_NUM",
                   XX."RECEIPT_LINES",
                   XX."RECEIPT_CREATE_USER_ID",
                   XX."RECEIPT_CREATE_USER_NAME",
                   XX."RECEIPT_CREATION_DATE",
                   XX."TRANSACTION_ID",
                   XX."DESTINATION_TYPE_CODE",
                   XX."RECEIPT_QTY",
                   XX."TRANSACTION_TYPE",
                   XX."CURRENCY_CODE",
                   XX."CURRENCY_CONVERSION_RATE",
                   XX."CURRENCY_CONVERSION_TYPE",
                   XX."CURRENCY_CONVERSION_DATE",
                   XX."RECEIPT_DATE",
                   XX."SHIP_DATE",
                   XX."EXPENSE_ACCOUNT",
                   XX."REV_DEL_DATE",
                   XX."QTY_1",
                   XX."REV_DEL_DATE_2",
                   XX."QTY_2",
                   XX."REVISED_BY",
                   XX."COA_NUMBER",
                   XX.REQUEST_ID,
                   XX.SHIPMENT_HEADER_ID,
                   XX.SHIPMENT_LINE_ID,
                   XX.TRANSACTION_ID_RECEIPT,
                   XX.LINE_NUM
     FROM (SELECT DISTINCT
                  porh.Attribute10 AS NO_PR_DOP,
                  porl.REQUISITION_LINE_ID,
                  prd.distribution_id AS PR_DISTRIBUTION_ID,
                  porl.LINE_LOCATION_ID AS LINE_LOCATION_ID_PR,
                  poll.LINE_LOCATION_ID AS LINE_LOCATION_ID_PO,
                  msi.inventory_item_id,
                  msi.segment1 AS item_code,
                  NVL (msi.description, pol.item_description)
                     AS item_description,
                  muom.uom_code,
                  NVL (porl.unit_meas_lookup_code, pol.unit_meas_lookup_code)
                     AS unit_meas_lookup_code,
                  (  msi.full_lead_time
                   + msi.preprocessing_lead_time
                   + msi.postprocessing_lead_time)
                     AS total_lead_time,
                  NVL (porl.destination_organization_id,
                       pod.destination_organization_id)
                     AS destination_organization_id,
                  mp.organization_code,
                  porh.requisition_header_id AS pr_id,
                  porh.segment1 AS pr_number,
                  plt.LINE_TYPE AS TYPE_PR,
                  porh.type_lookup_code,
                  porl.requisition_line_id AS pr_lines_id,
                  porl.line_num AS pr_lines,
                  porl.cancel_flag AS pr_lines_cancel_flag,
                  porl.closed_code AS pr_lines_closed_code,
                  porh.created_by AS pr_create_user_id,
                  fu1.user_name AS pr_create_user_name,
                  ppv7.full_name AS pr_requestor,
                  porl.quantity AS pr_qty,
                  porl.need_by_date AS pr_need_by_date,
                  porh.creation_date AS pr_creation_date,
                  porh.approved_date AS pr_approved_date,
                  INITCAP (porh.authorization_status) AS pr_status,
                  porl.CANCEL_DATE AS PR_CANCEL_DATE,
                  porl.modified_by_agent_flag,
                  poh.po_header_id AS po_id,
                  poh.ship_to_location_id AS ship_to_location_id,
                  poh.segment1 AS po_number,
                  plt2.LINE_TYPE AS TYPE_PO,
                  por.release_num,
                  por.creation_date AS release_creation_date,
                  por.approved_date AS release_approved_date,
                  --pol.PO_LINE_ID AS po_lines_id,
                  pol.line_num AS po_lines,
                  poh.created_by AS po_create_user_id,
                  fu2.user_name AS po_create_user_name,
                  INITCAP (poh.authorization_status) AS po_status,
                  CASE UPPER (poh.type_lookup_code)
                     WHEN 'BLANKET' THEN INITCAP (por.closed_code)
                     ELSE INITCAP (poh.closed_code)
                  END
                     AS po_closed_code,
                  poh.creation_date AS po_creation_date,
                  poh.approved_date AS po_approved_date,
                  mc.category_concat_segs,
                  --pd.po_distribution_id,
                  --poll.line_location_id,
                  poll.quantity AS po_qty,
                  pol.unit_price AS po_unit_price_original,
                  poll.price_override AS po_unit_price_override,
                  poll.need_by_date AS po_need_by_date,
                  pol.cancel_flag AS PO_LINES_CANCEL_FLAG,
                  pol.closed_code AS PO_LINES_CLOSED_CODE,
                  poll.cancel_flag AS PO_LINE_LOCATIONS_CANCEL_FLAG,
                  poll.closed_code AS PO_LINE_LOCATIONS_CLOSED_CODE,
                  pod.DELIVER_TO_LOCATION_ID,
                  NVL (aps1.segment1, aps2.segment1) AS vendor_code,
                  NVL (aps1.vendor_name, aps2.vendor_name) AS vendor_name,
                  NVL (assa1.vendor_site_code, assa2.vendor_site_code)
                     AS vendor_site,
                  NVL (paa1.min_order_qty, paa2.min_order_qty)
                     AS min_order_qty,
                  --aps1.segment1                                                       AS pr_vendor_code,
                  --aps1.vendor_name                                                 AS pr_vendor_name,
                  --aps2.segment1                                                    AS po_vendor_code,
                  --aps2.vendor_name                                                 AS po_vendor_name,
                  rsh.shipment_header_id AS receipt_id,
                  rsh.receipt_num,
                  rsl.line_num AS receipt_lines,
                  rtr.created_by AS receipt_create_user_id,
                  fu3.user_name AS receipt_create_user_name,
                  rsh.creation_date AS receipt_creation_date,
                  --rsl.shipment_line_id,
                  rtr.transaction_id,
                  rtr.destination_type_code,
                  rtr.quantity AS receipt_qty,
                  rtr.transaction_type,
                  rtr.currency_code,
                  rtr.currency_conversion_rate,
                  rtr.currency_conversion_type,
                  TRUNC (rtr.currency_conversion_date)
                     AS currency_conversion_date,
                  TRUNC (rtr.transaction_date) AS receipt_date,
                  TRUNC (rsh.shipped_date) AS ship_date,
                  --gcc.segment1                                                     AS company_account,
                  --gcc.segment2                                                     AS natural_account,
                  gcc.segment3 AS expense_account,
                  --20120508YJL: Diremark karena kalo dia tipe blanket, ambil ke po_line_location
                  --SUBSTR (pol.attribute10, 1, 10) AS rev_del_date,
                  CASE
                     WHEN por.RELEASE_NUM IS NULL
                     THEN
                        TO_DATE (TO_CHAR (SUBSTR (pol.attribute10, 1, 10)),
                                 'YYYY-MM-DD')
                     ELSE
                        TO_DATE (TO_CHAR (SUBSTR (poll.attribute10, 1, 10)),
                                 'YYYY-MM-DD')
                  END
                     AS rev_del_date,
                  pol.attribute11 qty_1,
                  SUBSTR (pol.attribute12, 1, 10) AS rev_del_date_2,
                  pol.attribute13 qty_2,
                  pol.attribute14 revised_by,
                     gcc.segment1
                  || '-'
                  || gcc.segment2
                  || '-'
                  || gcc.segment3
                  || '-'
                  || gcc.segment4
                  || '-'
                  || gcc.segment5
                  || '-'
                  || gcc.segment6
                  || '-'
                  || gcc.segment7
                     coa_number,
                  rtr.Request_ID,
                  rtr.SHIPMENT_HEADER_ID,
                  rtr.SHIPMENT_LINE_ID,
                  rtr.TRANSACTION_ID AS TRANSACTION_ID_RECEIPT,
                  rsl.LINE_NUM
             --gcc.segment4                                                     AS trading_partner_account,
             --gcc.segment5                                                     AS lob_account,
             --gcc.segment6                                                     AS branch_account,
             --gcc.segment7                                                     AS reserve_account
             FROM po_headers_all poh
                  LEFT JOIN po_lines_all pol
                     ON poh.po_header_id = pol.po_header_id
                  LEFT JOIN po_distributions_all pod
                     ON     pod.po_header_id = pol.po_header_id
                        AND pod.po_line_id = pol.po_line_id
                  LEFT JOIN po_line_locations_all poll
                     ON     pol.po_line_id = poll.po_line_id
                        AND pod.line_location_id = poll.line_location_id
                  LEFT JOIN po_releases_all por
                     ON     poh.po_header_id = por.po_header_id
                        AND poll.po_release_id = por.po_release_id
                  INNER JOIN mtl_parameters mp
                     ON pod.destination_organization_id = mp.organization_id
                  LEFT JOIN mtl_units_of_measure_tl muom
                     ON pol.unit_meas_lookup_code = muom.unit_of_measure
                  LEFT JOIN mtl_system_items_b msi
                     ON pol.item_id = msi.inventory_item_id
                  LEFT JOIN ap_suppliers aps1
                     ON poh.vendor_id = aps1.vendor_id
                  LEFT JOIN ap_supplier_sites_all assa1
                     ON poh.vendor_site_id = assa1.vendor_site_id
                  LEFT JOIN po_asl_attributes paa1
                     ON     poh.vendor_id = paa1.vendor_id
                        AND pol.item_id = paa1.item_id
                  LEFT JOIN fnd_user fu2 ON poh.created_by = fu2.user_id
                  LEFT JOIN ap_suppliers aps2
                     ON poh.vendor_id = aps2.vendor_id
                  LEFT JOIN ap_supplier_sites_all assa2
                     ON poh.vendor_site_id = assa2.vendor_site_id
                  LEFT JOIN po_asl_attributes paa2
                     ON     poh.vendor_id = paa2.vendor_id
                        AND pol.item_id = paa2.item_id
                  LEFT JOIN mtl_categories_v mc
                     ON pol.category_id = mc.category_id
                  LEFT JOIN rcv_shipment_lines rsl
                     ON     poll.ship_to_organization_id =
                               rsl.to_organization_id
                        AND poll.line_location_id = rsl.po_line_location_id
                  LEFT JOIN rcv_transactions rtr
                     ON rsl.shipment_line_id = rtr.shipment_line_id
                  LEFT JOIN rcv_shipment_headers rsh
                     ON     rtr.shipment_header_id = rsh.shipment_header_id
                        AND rsl.shipment_header_id = rsh.shipment_header_id
                  LEFT JOIN fnd_user fu3 ON rtr.created_by = fu3.user_id
                  LEFT JOIN gl_code_combinations gcc
                     ON gcc.code_combination_id = pod.code_combination_id
                  LEFT JOIN po_req_distributions_all prd
                     ON prd.distribution_id = pod.req_distribution_id
                  LEFT JOIN po_requisition_lines_all porl
                     ON porl.requisition_line_id = prd.requisition_line_id
                  LEFT JOIN po_requisition_headers_all porh
                     ON porh.requisition_header_id =
                           porl.requisition_header_id
                  LEFT JOIN per_people_v7 ppv7
                     ON porl.to_person_id = ppv7.person_id
                  LEFT JOIN fnd_user fu1 ON porh.created_by = fu1.user_id
                  LEFT JOIN PO_LINE_TYPES_TL plt
                     ON porl.LINE_TYPE_ID = plt.LINE_TYPE_ID
                  LEFT JOIN PO_LINE_TYPES_TL plt2
                     ON pol.LINE_TYPE_ID = plt2.LINE_TYPE_ID
            WHERE 1 = 1
           --AND poh.segment1 = '191264'
           UNION ALL
           SELECT DISTINCT
                  porh.Attribute10 AS NO_PR_DOP,
                  porl.REQUISITION_LINE_ID,
                  prd.distribution_id AS PR_DISTRIBUTION_ID,
                  porl.LINE_LOCATION_ID AS LINE_LOCATION_ID_PR,
                  poll.LINE_LOCATION_ID AS LINE_LOCATION_ID_PO,
                  msi.inventory_item_id,
                  msi.segment1 AS item_code,
                  NVL (msi.description, porl.item_description)
                     AS item_description,
                  muom.uom_code,
                  porl.unit_meas_lookup_code,
                  (  msi.full_lead_time
                   + msi.preprocessing_lead_time
                   + msi.postprocessing_lead_time)
                     AS total_lead_time,
                  porl.destination_organization_id,
                  mp.organization_code,
                  porh.requisition_header_id AS pr_id,
                  porh.segment1 AS pr_number,
                  plt.LINE_TYPE AS TYPE_PR,
                  porh.type_lookup_code,
                  porl.requisition_line_id AS pr_lines_id,
                  porl.line_num AS pr_lines,
                  porl.cancel_flag AS pr_lines_cancel_flag,
                  porl.closed_code AS pr_lines_closed_code,
                  porh.created_by AS pr_create_user_id,
                  fu1.user_name AS pr_create_user_name,
                  ppv7.full_name AS pr_requestor,
                  porl.quantity AS pr_qty,
                  porl.need_by_date AS pr_need_by_date,
                  porh.creation_date AS pr_creation_date,
                  porh.approved_date AS pr_approved_date,
                  INITCAP (porh.authorization_status) AS pr_status,
                  porl.CANCEL_DATE AS PR_CANCEL_DATE,
                  porl.modified_by_agent_flag,
                  poh.po_header_id AS po_id,
                  poh.ship_to_location_id AS ship_to_location_id,
                  poh.segment1 AS po_number,
                  plt2.LINE_TYPE AS TYPE_PO,
                  por.release_num,
                  por.creation_date AS release_creation_date,
                  por.approved_date AS release_approved_date,
                  --pol.PO_LINE_ID AS po_lines_id,
                  pol.line_num AS po_lines,
                  poh.created_by AS po_create_user_id,
                  fu2.user_name AS po_create_user_name,
                  INITCAP (poh.authorization_status) AS po_status,
                  CASE UPPER (poh.type_lookup_code)
                     WHEN 'BLANKET' THEN INITCAP (por.closed_code)
                     ELSE INITCAP (poh.closed_code)
                  END
                     AS po_closed_code,
                  poh.creation_date AS po_creation_date,
                  poh.approved_date AS po_approved_date,
                  mc.category_concat_segs,
                  --pd.po_distribution_id,
                  --poll.line_location_id,
                  poll.quantity AS po_qty,
                  pol.unit_price AS po_unit_price_original,
                  poll.price_override AS po_unit_price_override,
                  poll.need_by_date AS po_need_by_date,
                  pol.cancel_flag AS PO_LINES_CANCEL_FLAG,
                  pol.closed_code AS PO_LINES_CLOSED_CODE,
                  poll.cancel_flag AS PO_LINE_LOCATIONS_CANCEL_FLAG,
                  poll.closed_code AS PO_LINE_LOCATIONS_CLOSED_CODE,
                  pod.DELIVER_TO_LOCATION_ID,
                  NVL (aps1.segment1, aps2.segment1) AS vendor_code,
                  NVL (aps1.vendor_name, aps2.vendor_name) AS vendor_name,
                  NVL (assa1.vendor_site_code, assa2.vendor_site_code)
                     AS vendor_site,
                  NVL (paa1.min_order_qty, paa2.min_order_qty)
                     AS min_order_qty,
                  --aps1.segment1                                                       AS pr_vendor_code,
                  --aps1.vendor_name                                                 AS pr_vendor_name,
                  --aps2.segment1                                                    AS po_vendor_code,
                  --aps2.vendor_name                                                 AS po_vendor_name,
                  rsh.shipment_header_id AS receipt_id,
                  rsh.receipt_num,
                  rsl.line_num AS receipt_lines,
                  rtr.created_by AS receipt_create_user_id,
                  fu3.user_name AS receipt_create_user_name,
                  rsh.creation_date AS receipt_creation_date,
                  --rsl.shipment_line_id,
                  rtr.transaction_id,
                  rtr.destination_type_code,
                  rtr.quantity AS receipt_qty,
                  rtr.transaction_type,
                  rtr.currency_code,
                  rtr.currency_conversion_rate,
                  rtr.currency_conversion_type,
                  TRUNC (rtr.currency_conversion_date)
                     AS currency_conversion_date,
                  TRUNC (rtr.transaction_date) AS receipt_date,
                  TRUNC (rsh.shipped_date) AS ship_date,
                  --gcc.segment1                                                     AS company_account,
                  --gcc.segment2                                                     AS natural_account,
                  gcc.segment3 AS expense_account,
                  --20120508YJL: Diremark karena kalo dia tipe blanket, ambil ke po_line_location
                  --SUBSTR (pol.attribute10, 1, 10) AS rev_del_date,
                  CASE
                     WHEN por.RELEASE_NUM IS NULL
                     THEN
                        TO_DATE (TO_CHAR (SUBSTR (pol.attribute10, 1, 10)),
                                 'YYYY-MM-DD')
                     ELSE
                        TO_DATE (TO_CHAR (SUBSTR (poll.attribute10, 1, 10)),
                                 'YYYY-MM-DD')
                  END
                     AS rev_del_date,
                  pol.attribute11 qty_1,
                  SUBSTR (pol.attribute12, 1, 10) AS rev_del_date_2,
                  pol.attribute13 qty_2,
                  pol.attribute14 revised_by,
                     gcc.segment1
                  || '-'
                  || gcc.segment2
                  || '-'
                  || gcc.segment3
                  || '-'
                  || gcc.segment4
                  || '-'
                  || gcc.segment5
                  || '-'
                  || gcc.segment6
                  || '-'
                  || gcc.segment7
                     coa_number,
                  rtr.Request_ID,
                  rtr.SHIPMENT_HEADER_ID,
                  rtr.SHIPMENT_LINE_ID,
                  rtr.TRANSACTION_ID,
                  rsl.LINE_NUM
             --gcc.segment4                                                     AS trading_partner_account,
             --gcc.segment5                                                     AS lob_account,
             --gcc.segment6                                                     AS branch_account,
             --gcc.segment7                                                     AS reserve_account
             FROM po_requisition_headers_all porh
                  INNER JOIN po_requisition_lines_all porl
                     ON porh.requisition_header_id =
                           porl.requisition_header_id
                  INNER JOIN po_req_distributions_all prd
                     ON porl.requisition_line_id = prd.requisition_line_id
                  INNER JOIN mtl_parameters mp
                     ON porl.destination_organization_id = mp.organization_id
                  INNER JOIN fnd_user fu1 ON porh.created_by = fu1.user_id
                  INNER JOIN per_people_v7 ppv7
                     ON porl.to_person_id = ppv7.person_id
                  LEFT JOIN mtl_units_of_measure_tl muom
                     ON porl.unit_meas_lookup_code = muom.unit_of_measure
                  LEFT JOIN mtl_system_items_b msi
                     ON     msi.organization_id =
                               porl.destination_organization_id
                        AND porl.item_id = msi.inventory_item_id
                  LEFT JOIN po_distributions_all pod
                     ON prd.distribution_id = pod.req_distribution_id
                  LEFT JOIN ap_suppliers aps1
                     ON porl.vendor_id = aps1.vendor_id
                  LEFT JOIN ap_supplier_sites_all assa1
                     ON porl.vendor_site_id = assa1.vendor_site_id
                  LEFT JOIN po_asl_attributes paa1
                     ON     porl.vendor_id = paa1.vendor_id
                        AND porl.item_id = paa1.item_id
                  LEFT JOIN po_headers_all poh
                     ON pod.po_header_id = poh.po_header_id
                  LEFT JOIN po_lines_all pol
                     ON     poh.po_header_id = pol.po_header_id
                        AND pod.po_line_id = pol.po_line_id
                  LEFT JOIN po_line_locations_all poll
                     ON     pol.po_line_id = poll.po_line_id
                        AND pod.line_location_id = poll.line_location_id
                  LEFT JOIN po_releases_all por
                     ON     poh.po_header_id = por.po_header_id
                        AND poll.po_release_id = por.po_release_id
                  LEFT JOIN fnd_user fu2 ON poh.created_by = fu2.user_id
                  LEFT JOIN ap_suppliers aps2
                     ON poh.vendor_id = aps2.vendor_id
                  LEFT JOIN ap_supplier_sites_all assa2
                     ON poh.vendor_site_id = assa2.vendor_site_id
                  LEFT JOIN po_asl_attributes paa2
                     ON     poh.vendor_id = paa2.vendor_id
                        AND pol.item_id = paa2.item_id
                  LEFT JOIN mtl_categories_v mc
                     ON pol.category_id = mc.category_id
                  LEFT JOIN rcv_shipment_lines rsl
                     ON     poll.ship_to_organization_id =
                               rsl.to_organization_id
                        AND poll.line_location_id = rsl.po_line_location_id
                  LEFT JOIN rcv_transactions rtr
                     ON rsl.shipment_line_id = rtr.shipment_line_id
                  LEFT JOIN rcv_shipment_headers rsh
                     ON     rtr.shipment_header_id = rsh.shipment_header_id
                        AND rsl.shipment_header_id = rsh.shipment_header_id
                  LEFT JOIN fnd_user fu3 ON rtr.created_by = fu3.user_id
                  LEFT JOIN gl_code_combinations gcc
                     ON gcc.code_combination_id = prd.code_combination_id
                  LEFT JOIN PO_LINE_TYPES_TL plt
                     ON porl.LINE_TYPE_ID = plt.LINE_TYPE_ID
                  LEFT JOIN PO_LINE_TYPES_TL plt2
                     ON pol.LINE_TYPE_ID = plt2.LINE_TYPE_ID
            WHERE 1 = 1) XX;
