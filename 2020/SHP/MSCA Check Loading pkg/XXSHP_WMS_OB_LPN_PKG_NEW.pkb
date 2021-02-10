CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_WMS_OB_LPN_PKG_NEW
/* $HEADER: XXSHP_WMS_OB_LPN_PKG.PK 122.5.1.8 2016/12/27 17:27:00 Iqbal Dwi Prawira $ */

/******************************************************************************
    NAME: XXSHP_WMS_OB_LPN_PKG_NEW
    PURPOSE:

    REVISIONS:
    Ver         Date            Author                        Description
    ---------   ----------      ---------------               ------------------------------------
    1.0         17-Jan-2017    Iqbal DwiPrawira,             1. Created this package.
    1.1         21 Juni 2017   Farid Bachtiar               2. Mengubah LOV Untuk LPN Outbound
    3.0         13 May 2019   Michael Leonard              1. tambah procesuder get_spm_load_lov
                                                           2. tambah procedure get_lpn_ob_load_lov
                                                           3. tambah procedure get_lot_ob_load_lov
                                                           4. tambah procedure get_remarks_load_lov
                                                           5. tambah procedure get_checking_lpn
                                                           6. tambah procedure get_load_notes
                                                           7. tambah procedure GET_LOAD_ITEM_ID
                                                           8. tambah procedure get_prim_qty_load
                                                           9. tambah procedure get_load_remaining_lot
                                                           10. tambah procedure get_load_remaining_lpn
                                                           11. tambah procedure INSERT_NEW_LOAD_TAB
                                                           12. tambah procedure INSERT_LOAD_TEMP
   *************************    *****************************************************/


AS
   PROCEDURE COMMIT_TRANSACTION (p_source IN VARCHAR2)
   IS
   BEGIN
      DELETE FROM XXSHP_WMS_OB_LPN_STG_TEMP
            WHERE source_doc_num = p_source;

      DELETE FROM XXSHP_WMS_OB_LPN_LOAD_TEMP
            WHERE source_doc_num = p_source;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOV ' || SQLERRM);
   END COMMIT_TRANSACTION;

   PROCEDURE GET_SPM_LOV (x_spm         OUT NOCOPY t_ref_csr,
                          p_spm      IN            VARCHAR2,
                          p_org_id   IN            NUMBER)
   IS
   BEGIN
      OPEN x_spm FOR
         SELECT DISTINCT ORGANIZATION_ID, source_doc_num
           FROM XXSHP_WMS_OB_LPN_STG
          WHERE     organization_id = p_org_id
                AND trx_type = 'SPM'
                AND SOURCE_DOC_NUM LIKE p_spm || '%';
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOV ' || SQLERRM);
   END GET_SPM_LOV;

   PROCEDURE GET_SPM_LOAD_LOV (x_spm         OUT NOCOPY t_ref_csr,
                               p_spm      IN            VARCHAR2,
                               p_org_id   IN            NUMBER)
   IS
    v_spm_hdr_id NUMBER;
    v_cnt_sts    NUMBER;

   BEGIN
       BEGIN
          SELECT DISTINCT spm_header_id
            INTO v_spm_hdr_id
            FROM XXSHP_OE_EXD_SPM_SHIP_hdr_v
           WHERE     1 = 1
                 AND organization_id = 85
                 AND status NOT IN ('Cancelled', 'Shipped')
                 AND dock_door IS NOT NULL
                 AND ship_from = 'KNS - Kalbe Nutritionals'
                 AND spm_no = p_spm;
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOAD LOV ');
       END;


       BEGIN
          SELECT COUNT (status)
            INTO v_cnt_sts
            FROM (SELECT DISTINCT (status)
                    FROM XXSHP_OE_EXD_SPM_SHIP_ORDER_V
                   WHERE     delivery_id IS NOT NULL
                         AND status = 'Staged/Pick Confirmed'
                         AND spm_header_id = v_spm_hdr_id);
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOAD LOV ');
       END;

       IF v_cnt_sts > 0
       THEN
          OPEN x_spm FOR
             SELECT DISTINCT organization_id,
                             spm_no source_doc_num,
                             dock_id,
                             dock_door
               FROM XXSHP_OE_EXD_SPM_SHIP_HDR_V
              WHERE     1 = 1
                    AND organization_id = p_org_id
                    AND status NOT IN ('Cancelled', 'Shipped')
                    AND dock_door IS NOT NULL
                    AND ship_from = 'KNS - Kalbe Nutritionals'
                    AND spm_no LIKE p_spm || '%';
       ELSE
          DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOAD LOV ');
       END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN SPM LOAD LOV ' || SQLERRM);
   END GET_SPM_LOAD_LOV;

   PROCEDURE GET_LPN_OB_LOV (x_lpn       OUT NOCOPY t_ref_csr,
                             p_spm    IN            VARCHAR2,
                             p_lpn    IN            VARCHAR2,
                             p_item   IN            VARCHAR2)
   IS
   BEGIN
      OPEN x_lpn FOR
           SELECT a.CONTAINER_NAME license_plate_number,
                  msi.segment1,
                  msi.description,
                  msi.primary_uom_code,
                  msi.secondary_uom_code,
                  xoso.inventory_item_id,
                  SUM (ABS (mmt.primary_quantity)) primary_quantity,
                  xwolsn.PRIMARY_STG_QTY,
                  xwolsn.SECONDARY_STG_QTY,
                  xwolsn.REMARKS_STG,
                  xwolsn.NOTES_STG,
                  xwols.organization_id,
                  0 DELIVERY_DETAIL_ID
             FROM oe_order_lines_all ool,
                  OE_ORDER_HEADERS_ALL ooh,
                  xxshp_oe_exd_spm_hdr xoes,
                  XXSHP_OE_EXD_SPM_ORDER xoso,
                  WSH_DELIVERY_DETAILS wdd,
                  mtl_system_items msi,
                  (SELECT wdv1.parent_container_instance_id,
                          wdv1.SOURCE_HEADER_ID,
                          wdv1.delivery_detail_id,
                          wdv2.CONTAINER_NAME,
                          wdv1.LOT_NUMBER,
                          wdv1.RELEASED_STATUS_NAME,
                          wdv2.RELEASED_STATUS_NAME kl
                     FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
                    WHERE wdv1.parent_container_instance_id =
                             wdv2.CONTAINER_INSTANCE_ID) a,
                  wms_license_plate_numbers wlpn,
                  mtl_material_transactions mmt,
                  XXSHP_WMS_OB_LPN_STG xwols,
                  XXSHP_WMS_OB_LPN_STG_new xwolsn
            WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
                  AND xoso.OE_HEADER_ID = ooh.HEADER_ID
                  AND xoso.OE_LINE_ID = ool.LINE_ID
                  AND ooh.HEADER_ID = ool.HEADER_ID
                  AND a.delivery_detail_id = wdd.delivery_detail_id
                  AND xoso.delivery_detail_id = wdd.delivery_detail_id --update 1/5/2017
                  --update 1/5/2017
                  --       AND ooh.header_ID = wdd.SOURCE_HEADER_ID
                  --       AND ool.line_id = wdd.source_line_id
                  AND msi.inventory_item_id = xoso.inventory_item_id
                  AND msi.organization_id = wdd.organization_id
                  AND a.CONTAINER_NAME = wlpn.license_plate_number
                  AND mmt.transaction_id = wdd.transaction_id
                  AND wlpn.license_plate_number = xwols.license_plate_number
                  AND xwolsn.license_plate_number(+) =
                         xwols.license_plate_number
                  AND xwolsn.lot_number(+) = a.lot_number
                  AND xoso.delivery_detail_id = wdd.delivery_detail_id
                  AND xwolsn.source_doc_num(+) = xwols.source_doc_num
                  AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
                  --   AND xoes.spm_no = 'KNS17060242'
                  AND NOT EXISTS
                             (SELECT 1
                                FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                               WHERE     xwols.LICENSE_PLATE_NUMBER =
                                            LICENSE_PLATE_NUMBER
                                     AND a.lot_number = xwolst.lot_number
                                     AND xwolst.inventory_item_id =
                                            xoso.inventory_item_id)
                  -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
                  AND NOT EXISTS
                             (SELECT 1
                                FROM XXSHP_WMS_OB_LPN_STG_new aa
                               WHERE     xwols.LICENSE_PLATE_NUMBER =
                                            aa.LICENSE_PLATE_NUMBER
                                     AND a.lot_number = aa.lot_number
                                     AND aa.inventory_item_id =
                                            xoso.inventory_item_id
                                     AND aa.primary_qty = aa.primary_stg_qty)
                  AND xoes.spm_no = p_spm
                  AND wlpn.LICENSE_PLATE_NUMBER LIKE p_lpn || '%'
         GROUP BY a.CONTAINER_NAME,
                  msi.segment1,
                  msi.description,
                  msi.primary_uom_code,
                  msi.secondary_uom_code,
                  xoso.inventory_item_id,
                  xwolsn.PRIMARY_STG_QTY,
                  xwolsn.SECONDARY_STG_QTY,
                  xwolsn.REMARKS_STG,
                  xwolsn.NOTES_STG,
                  xwols.organization_id;
         /*
         SELECT a.CONTAINER_NAME license_plate_number,
                msi.segment1,
                msi.description,
                msi.primary_uom_code,
                msi.secondary_uom_code,
                xoso.inventory_item_id,
                ABS (mmt.primary_quantity) primary_quantity,
                xwolsn.PRIMARY_STG_QTY,
                xwolsn.SECONDARY_STG_QTY,
                xwolsn.REMARKS_STG,
                xwolsn.NOTES_STG,
                xwols.organization_id,
                wdd.DELIVERY_DETAIL_ID
           FROM oe_order_lines_all ool,
                OE_ORDER_HEADERS_ALL ooh,
                xxshp_oe_exd_spm_hdr xoes,
                XXSHP_OE_EXD_SPM_ORDER xoso,
                WSH_DELIVERY_DETAILS wdd,
                mtl_system_items msi,
                (SELECT wdv1.parent_container_instance_id,
                        wdv1.SOURCE_HEADER_ID,
                        wdv1.delivery_detail_id,
                        wdv2.CONTAINER_NAME,
                        wdv1.LOT_NUMBER,
                        wdv1.RELEASED_STATUS_NAME,
                        wdv2.RELEASED_STATUS_NAME kl
                   FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
                  WHERE wdv1.parent_container_instance_id =
                           wdv2.CONTAINER_INSTANCE_ID) a,
                wms_license_plate_numbers wlpn,
                mtl_material_transactions mmt,
                XXSHP_WMS_OB_LPN_STG xwols,
                XXSHP_WMS_OB_LPN_STG_new xwolsn
          WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
                AND xoso.OE_HEADER_ID = ooh.HEADER_ID
                AND xoso.OE_LINE_ID = ool.LINE_ID
                AND ooh.HEADER_ID = ool.HEADER_ID
                AND a.delivery_detail_id = wdd.delivery_detail_id
                AND ooh.header_ID = wdd.SOURCE_HEADER_ID
                AND ool.line_id = wdd.source_line_id
                AND msi.inventory_item_id = xoso.inventory_item_id
                AND msi.organization_id = wdd.organization_id
                AND a.CONTAINER_NAME = wlpn.license_plate_number
                AND mmt.transaction_id = wdd.transaction_id
                AND wlpn.license_plate_number = xwols.license_plate_number
                AND xwolsn.license_plate_number(+) =
                       xwols.license_plate_number
                AND xwolsn.lot_number(+) = a.lot_number
                AND xoso.delivery_detail_id = wdd.delivery_detail_id
                AND xwolsn.source_doc_num(+) = xwols.source_doc_num
                AND NOT EXISTS
                           (SELECT 1
                              FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                             WHERE     xwols.LICENSE_PLATE_NUMBER =
                                          LICENSE_PLATE_NUMBER
                                   AND a.lot_number = xwolst.lot_number
                                   AND xwolst.inventory_item_id =
                                          xoso.inventory_item_id
                                   AND wdd.delivery_detail_id =
                                          xwolst.delivery_detail_id)
                --                AND xoes.spm_no = 'KNS17060048'
                --                AND xwols.trx_type = 'SPM'
                AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
--                AND xwols.license_plate_number = 'FG/170502/07064'
                AND xoes.spm_no = p_spm
--                AND xoes.spm_no = 'KNS17060089';
                --                AND xoes.spm_no = 'KNS17060089'
                AND wlpn.LICENSE_PLATE_NUMBER LIKE p_lpn || '%';
                */
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_LPN_OB_LOV;

   PROCEDURE GET_LPN_OB_LOAD_LOV (x_lpn       OUT NOCOPY t_ref_csr,
                                  p_spm    IN            VARCHAR2,
                                  p_lpn    IN            VARCHAR2,
                                  p_item   IN            VARCHAR2)
   IS
   BEGIN
      OPEN x_lpn FOR
         WITH wdd_data
              AS (SELECT wdd1.delivery_detail_id,
                         wda1.parent_delivery_detail_id,
                         wdd2.container_name,
                         wdd1.lot_number
                    FROM XXSHP_OE_EXD_SPM_ORDER xoso1,
                         wsh_delivery_details wdd1,
                         wsh_delivery_details wdd2,
                         wsh_delivery_assignments wda1,
                         fnd_lookup_values flv_wms,
                         wms_license_plate_numbers wlpn
                   WHERE     1 = 1
                         AND xoso1.spm_header_id =
                                (SELECT spm_header_id
                                   FROM XXSHP_OE_EXD_SPM_HDR
                                  WHERE spm_no = p_spm)
                         AND xoso1.delivery_detail_id =
                                wdd1.delivery_detail_id
                         AND wda1.delivery_detail_id =
                                wdd1.delivery_detail_id
                         AND wda1.parent_delivery_detail_id =
                                wdd2.delivery_detail_id
                         AND flv_wms.lookup_type(+) = 'WMS_LPN_CONTEXT'
                         AND flv_wms.LANGUAGE(+) = USERENV ('LANG')
                         AND wdd1.lpn_id = wlpn.lpn_id(+)
                         AND flv_wms.lookup_code(+) =
                                TO_CHAR (wlpn.lpn_context)
                         AND flv_wms.VIEW_APPLICATION_ID(+) = 700
                         AND flv_wms.SECURITY_GROUP_ID(+) = 0
                         AND DECODE (
                                wdd1.released_status,
                                'X', DECODE (
                                        wlpn.lpn_context,
                                        '9', flv_wms.meaning,
                                        '11', flv_wms.meaning,
                                        '12', flv_wms.meaning,
                                        (SELECT meaning
                                           FROM fnd_lookup_values flv_released
                                          WHERE     flv_released.lookup_type =
                                                       'PICK_STATUS'
                                                AND flv_released.lookup_code =
                                                       wdd1.released_status
                                                AND flv_released.LANGUAGE =
                                                       USERENV ('LANG')
                                                AND flv_released.VIEW_APPLICATION_ID =
                                                       665
                                                AND flv_released.SECURITY_GROUP_ID =
                                                       0)),
                                (SELECT meaning
                                   FROM fnd_lookup_values flv_released
                                  WHERE     flv_released.lookup_type =
                                               'PICK_STATUS'
                                        AND flv_released.lookup_code =
                                               wdd1.released_status
                                        AND flv_released.LANGUAGE =
                                               USERENV ('LANG')
                                        AND flv_released.VIEW_APPLICATION_ID =
                                               665
                                        AND flv_released.SECURITY_GROUP_ID =
                                               0)) NOT IN ('Shipped',
                                                           'Interfaced')
                                                           )
           SELECT a.CONTAINER_NAME license_plate_number,
                  msi.segment1,
                  msi.description,
                  msi.primary_uom_code,
                  msi.secondary_uom_code,
                  xoso.inventory_item_id,
                  SUM (ABS (mmt.primary_quantity)) primary_quantity,
                  xwolln.PRIMARY_LOAD_QTY,
                  xwolln.SECONDARY_LOAD_QTY,
                  xwolln.REMARKS_LOAD,
                  xwolln.NOTES_LOAD,
                  xwols.organization_id,
                  0 DELIVERY_DETAIL_ID
             FROM oe_order_lines_all ool,
                  OE_ORDER_HEADERS_ALL ooh,
                  xxshp_oe_exd_spm_hdr xoes,
                  XXSHP_OE_EXD_SPM_ORDER xoso,
                  WSH_DELIVERY_DETAILS wdd,
                  mtl_system_items msi,
                  wdd_data a,
                  wms_license_plate_numbers wlpn,
                  mtl_material_transactions mmt,
                  XXSHP_WMS_OB_LPN_STG xwols,
                  XXSHP_WMS_OB_LPN_LOAD_NEW xwolln
            WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
                  AND xoso.OE_HEADER_ID = ooh.HEADER_ID
                  AND xoso.OE_LINE_ID = ool.LINE_ID
                  AND ooh.HEADER_ID = ool.HEADER_ID
                  AND a.delivery_detail_id = wdd.delivery_detail_id
                  AND xoso.delivery_detail_id = wdd.delivery_detail_id --update 1/5/2017
                  --update 1/5/2017
                  --       AND ooh.header_ID = wdd.SOURCE_HEADER_ID
                  --       AND ool.line_id = wdd.source_line_id
                  AND msi.inventory_item_id = xoso.inventory_item_id
                  AND msi.organization_id = wdd.organization_id
                  AND a.CONTAINER_NAME = wlpn.license_plate_number
                  AND mmt.transaction_id = wdd.transaction_id
                  AND wlpn.license_plate_number = xwols.license_plate_number
                  AND xwolln.license_plate_number(+) =
                         xwols.license_plate_number
                  AND xwolln.lot_number(+) = a.lot_number
                  AND xoso.delivery_detail_id = wdd.delivery_detail_id
                  AND xwolln.source_doc_num(+) = xwols.source_doc_num
                  --                           AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
                  --   AND xoes.spm_no = 'KNS17060242'
                  AND NOT EXISTS
                             (SELECT 1
                                FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwolst
                               WHERE     xwols.LICENSE_PLATE_NUMBER =
                                            LICENSE_PLATE_NUMBER
                                     AND a.lot_number = xwolst.lot_number
                                     AND xwolst.inventory_item_id =
                                            xoso.inventory_item_id
                                     AND xwolst.primary_qty =
                                            xwolst.primary_load_qty)
                  -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
                  AND NOT EXISTS
                             (SELECT 1
                                FROM XXSHP_WMS_OB_LPN_LOAD_NEW aa
                               WHERE     xwols.LICENSE_PLATE_NUMBER =
                                            aa.LICENSE_PLATE_NUMBER
                                     AND a.lot_number = aa.lot_number
                                     AND aa.inventory_item_id =
                                            xoso.inventory_item_id
                                     AND aa.primary_qty = aa.primary_load_qty)
                  AND xoes.spm_no = p_spm
                  AND wlpn.LICENSE_PLATE_NUMBER LIKE p_lpn || '%'
         GROUP BY a.CONTAINER_NAME,
                  msi.segment1,
                  msi.description,
                  msi.primary_uom_code,
                  msi.secondary_uom_code,
                  xoso.inventory_item_id,
                  xwolln.PRIMARY_LOAD_QTY,
                  xwolln.SECONDARY_LOAD_QTY,
                  xwolln.REMARKS_LOAD,
                  xwolln.NOTES_LOAD,
                  xwols.organization_id;
   --           SELECT a.CONTAINER_NAME license_plate_number,
   --                  msi.segment1,
   --                  msi.description,
   --                  msi.primary_uom_code,
   --                  msi.secondary_uom_code,
   --                  xoso.inventory_item_id,
   --                  SUM (ABS (mmt.primary_quantity)) primary_quantity,
   --                  xwolln.PRIMARY_LOAD_QTY,
   --                  xwolln.SECONDARY_LOAD_QTY,
   --                  xwolln.REMARKS_LOAD,
   --                  xwolln.NOTES_LOAD,
   --                  xwols.organization_id,
   --                  0 DELIVERY_DETAIL_ID
   --             FROM oe_order_lines_all ool,
   --                  OE_ORDER_HEADERS_ALL ooh,
   --                  xxshp_oe_exd_spm_hdr xoes,
   --                  XXSHP_OE_EXD_SPM_ORDER xoso,
   --                  WSH_DELIVERY_DETAILS wdd,
   --                  mtl_system_items msi,
   --                  (SELECT wdv1.parent_container_instance_id,
   --                          wdv1.SOURCE_HEADER_ID,
   --                          wdv1.delivery_detail_id,
   --                          wdv2.CONTAINER_NAME,
   --                          wdv1.LOT_NUMBER,
   --                          wdv1.RELEASED_STATUS_NAME,
   --                          wdv2.RELEASED_STATUS_NAME kl
   --                     FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
   --                    WHERE wdv1.parent_container_instance_id =
   --                             wdv2.CONTAINER_INSTANCE_ID) a,
   --                  wms_license_plate_numbers wlpn,
   --                  mtl_material_transactions mmt,
   --                  XXSHP_WMS_OB_LPN_STG xwols,
   --                  XXSHP_WMS_OB_LPN_LOAD_NEW xwolln
   --            WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
   --                  AND xoso.OE_HEADER_ID = ooh.HEADER_ID
   --                  AND xoso.OE_LINE_ID = ool.LINE_ID
   --                  AND ooh.HEADER_ID = ool.HEADER_ID
   --                  AND a.delivery_detail_id = wdd.delivery_detail_id
   --                  AND xoso.delivery_detail_id = wdd.delivery_detail_id --update 1/5/2017
   --                  --update 1/5/2017
   --                  --       AND ooh.header_ID = wdd.SOURCE_HEADER_ID
   --                  --       AND ool.line_id = wdd.source_line_id
   --                  AND msi.inventory_item_id = xoso.inventory_item_id
   --                  AND msi.organization_id = wdd.organization_id
   --                  AND a.CONTAINER_NAME = wlpn.license_plate_number
   --                  AND mmt.transaction_id = wdd.transaction_id
   --                  AND wlpn.license_plate_number = xwols.license_plate_number
   --                  AND xwolln.license_plate_number(+) =
   --                         xwols.license_plate_number
   --                  AND xwolln.lot_number(+) = a.lot_number
   --                  AND xoso.delivery_detail_id = wdd.delivery_detail_id
   --                  AND xwolln.source_doc_num(+) = xwols.source_doc_num
   --                  --                  AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
   --                  --   AND xoes.spm_no = 'KNS17060242'
   --                  AND NOT EXISTS
   --                             (SELECT 1
   --                                FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwolst
   --                               WHERE     xwols.LICENSE_PLATE_NUMBER =
   --                                            LICENSE_PLATE_NUMBER
   --                                     AND a.lot_number = xwolst.lot_number
   --                                     AND xwolst.inventory_item_id =
   --                                            xoso.inventory_item_id
   --                                     AND xwolst.primary_qty =
   --                                            xwolst.primary_load_qty)
   --                  -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
   --                  AND NOT EXISTS
   --                             (SELECT 1
   --                                FROM XXSHP_WMS_OB_LPN_LOAD_NEW aa
   --                               WHERE     xwols.LICENSE_PLATE_NUMBER =
   --                                            aa.LICENSE_PLATE_NUMBER
   --                                     AND a.lot_number = aa.lot_number
   --                                     AND aa.inventory_item_id =
   --                                            xoso.inventory_item_id
   --                                     AND aa.primary_qty = aa.primary_load_qty)
   --                  AND xoes.spm_no = p_spm
   --                  AND wlpn.LICENSE_PLATE_NUMBER LIKE p_lpn || '%'
   --         GROUP BY a.CONTAINER_NAME,
   --                  msi.segment1,
   --                  msi.description,
   --                  msi.primary_uom_code,
   --                  msi.secondary_uom_code,
   --                  xoso.inventory_item_id,
   --                  xwolln.PRIMARY_LOAD_QTY,
   --                  xwolln.SECONDARY_LOAD_QTY,
   --                  xwolln.REMARKS_LOAD,
   --                  xwolln.NOTES_LOAD,
   --                  xwols.organization_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_LPN_OB_LOAD_LOV;

   FUNCTION GET_ITEM_ID (p_lpn IN VARCHAR2, P_LOT IN VARCHAR2)
      RETURN NUMBER
   IS
      V_ITEM   NUMBER;
   BEGIN
      SELECT DISTINCT XWOLSN.inventory_item_id
        INTO V_ITEM
        FROM XXSHP_WMS_OB_LPN_STG xwols, XXSHP_WMS_OB_LPN_STG_new xwolsn
       WHERE     xwolsn.license_plate_number(+) = xwols.license_plate_number
             AND xwolsn.source_doc_num(+) = xwols.source_doc_num
             AND xwolsn.LOT_NUMBER = P_LOT
             AND xwols.LICENSE_PLATE_NUMBER = p_lpn;

      RETURN V_ITEM;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_ITEM_ID;

   FUNCTION GET_LOAD_ITEM_ID (p_lpn IN VARCHAR2, P_LOT IN VARCHAR2)
      RETURN NUMBER
   IS
      V_ITEM   NUMBER;
   BEGIN
      SELECT DISTINCT XWOLSN.inventory_item_id
        INTO V_ITEM
        FROM XXSHP_WMS_OB_LPN_STG xwols, XXSHP_WMS_OB_LPN_LOAD_new xwolsn
       WHERE     xwolsn.license_plate_number(+) = xwols.license_plate_number
             AND xwolsn.source_doc_num(+) = xwols.source_doc_num
             AND xwolsn.LOT_NUMBER = P_LOT
             AND xwols.LICENSE_PLATE_NUMBER = p_lpn;

      RETURN V_ITEM;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_LOAD_ITEM_ID;

   PROCEDURE GET_LOT_OB_LOV (x_lpn       OUT NOCOPY t_ref_csr,
                             p_spm    IN            VARCHAR2,
                             p_lpn    IN            VARCHAR2,
                             p_item   IN            VARCHAR2,
                             p_lot    IN            VARCHAR2)
   IS
   BEGIN
      OPEN x_lpn FOR
         --         SELECT wdd.lot_number
         --           FROM oe_order_lines_all ool,
         --                OE_ORDER_HEADERS_ALL ooh,
         --                xxshp_oe_exd_spm_hdr xoes,
         --                XXSHP_OE_EXD_SPM_ORDER xoso,
         --                WSH_DELIVERY_DETAILS wdd,
         --                (SELECT wdv1.parent_container_instance_id,
         --                        wdv1.SOURCE_HEADER_ID,
         --                        wdv1.delivery_detail_id,
         --                        wdv2.CONTAINER_NAME,
         --                        wdv1.LOT_NUMBER
         --                   FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
         --                  WHERE wdv1.parent_container_instance_id =
         --                           wdv2.CONTAINER_INSTANCE_ID) a,
         --                mtl_system_items msi,
         --                wms_license_plate_numbers wlpn,
         --                mtl_material_transactions mmt,
         --                XXSHP_WMS_OB_LPN_STG xwols,
         --                XXSHP_WMS_OB_LPN_STG_new xwolsn
         --          WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
         --                AND xoso.OE_HEADER_ID = ooh.HEADER_ID
         --                AND xoso.OE_LINE_ID = ool.LINE_ID
         --                AND ooh.HEADER_ID = ool.HEADER_ID
         --                AND a.delivery_detail_id = wdd.delivery_detail_id
         --                AND ooh.header_ID = wdd.SOURCE_HEADER_ID
         --                AND ool.line_id = wdd.source_line_id
         --                AND msi.inventory_item_id = xoso.inventory_item_id
         --                AND msi.organization_id = wdd.organization_id
         --                AND a.CONTAINER_NAME = wlpn.license_plate_number
         --                AND mmt.transaction_id = wdd.transaction_id
         --                AND wlpn.license_plate_number = xwols.license_plate_number
         --                AND xwolsn.license_plate_number(+) =
         --                       xwols.license_plate_number
         --                AND xwolsn.lot_number(+) = a.lot_number
         --                AND NOT EXISTS
         --                           (SELECT 1
         --                              FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
         --                             WHERE     xwols.LICENSE_PLATE_NUMBER =
         --                                          LICENSE_PLATE_NUMBER
         --                                   AND a.lot_number = xwolst.lot_number
         --                                   AND xwolst.inventory_item_id =
         --                                          xoso.inventory_item_id
         --                                   AND wdd.delivery_detail_id =
         --                                          xwolst.delivery_detail_id)
         --                AND xwols.trx_type = 'SPM'
         --                AND xoes.spm_no = p_spm
         --                AND xoso.INVENTORY_ITEM_ID = p_item
         --                AND xwols.LICENSE_PLATE_NUMBER = p_lpn
         --                AND wdd.lot_number LIKE p_lot || '%';
         --update by iqbal 6-6-2017/ UAT
         SELECT DISTINCT wdd.lot_number
           FROM oe_order_lines_all ool,
                OE_ORDER_HEADERS_ALL ooh,
                xxshp_oe_exd_spm_hdr xoes,
                XXSHP_OE_EXD_SPM_ORDER xoso,
                WSH_DELIVERY_DETAILS wdd,
                mtl_system_items msi,
                (SELECT wdv1.parent_container_instance_id,
                        wdv1.SOURCE_HEADER_ID,
                        wdv1.delivery_detail_id,
                        wdv2.CONTAINER_NAME,
                        wdv1.LOT_NUMBER,
                        wdv1.RELEASED_STATUS_NAME,
                        wdv2.RELEASED_STATUS_NAME kl
                   FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
                  WHERE wdv1.parent_container_instance_id =
                           wdv2.CONTAINER_INSTANCE_ID) a,
                wms_license_plate_numbers wlpn,
                mtl_material_transactions mmt,
                XXSHP_WMS_OB_LPN_STG xwols,
                XXSHP_WMS_OB_LPN_STG_new xwolsn
          WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
                AND xoso.OE_HEADER_ID = ooh.HEADER_ID
                AND xoso.OE_LINE_ID = ool.LINE_ID
                AND ooh.HEADER_ID = ool.HEADER_ID
                AND a.delivery_detail_id = wdd.delivery_detail_id
                AND xoso.delivery_detail_id = wdd.delivery_detail_id --update 1/5/2017
                --update 1/5/2017
                --       AND ooh.header_ID = wdd.SOURCE_HEADER_ID
                --       AND ool.line_id = wdd.source_line_id
                AND msi.inventory_item_id = xoso.inventory_item_id
                AND msi.organization_id = wdd.organization_id
                AND a.CONTAINER_NAME = wlpn.license_plate_number
                AND mmt.transaction_id = wdd.transaction_id
                AND wlpn.license_plate_number = xwols.license_plate_number
                AND xwolsn.license_plate_number(+) =
                       xwols.license_plate_number
                AND xwolsn.lot_number(+) = a.lot_number
                AND xoso.delivery_detail_id = wdd.delivery_detail_id
                AND xwolsn.source_doc_num(+) = xwols.source_doc_num
                AND NOT EXISTS
                           (SELECT 1
                              FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                             WHERE     xwols.LICENSE_PLATE_NUMBER =
                                          LICENSE_PLATE_NUMBER
                                   AND a.lot_number = xwolst.lot_number
                                   AND xwolst.inventory_item_id =
                                          xoso.inventory_item_id)
                AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
                AND xoes.spm_no = p_spm
                AND xoso.INVENTORY_ITEM_ID = p_item
                AND wlpn.LICENSE_PLATE_NUMBER = p_lpn
                AND wdd.lot_number LIKE p_lot || '%';
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_LOT_OB_LOV;


   PROCEDURE GET_LOT_OB_LOAD_LOV (x_lpn       OUT NOCOPY t_ref_csr,
                                  p_spm    IN            VARCHAR2,
                                  p_lpn    IN            VARCHAR2,
                                  p_item   IN            VARCHAR2,
                                  p_lot    IN            VARCHAR2)
   IS
   BEGIN
      OPEN x_lpn FOR
         SELECT DISTINCT wdd.lot_number
           FROM oe_order_lines_all ool,
                OE_ORDER_HEADERS_ALL ooh,
                xxshp_oe_exd_spm_hdr xoes,
                XXSHP_OE_EXD_SPM_ORDER xoso,
                WSH_DELIVERY_DETAILS wdd,
                mtl_system_items msi,
                (SELECT wdv1.parent_container_instance_id,
                        wdv1.SOURCE_HEADER_ID,
                        wdv1.delivery_detail_id,
                        wdv2.CONTAINER_NAME,
                        wdv1.LOT_NUMBER,
                        wdv1.RELEASED_STATUS_NAME,
                        wdv2.RELEASED_STATUS_NAME kl
                   FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
                  WHERE wdv1.parent_container_instance_id =
                           wdv2.CONTAINER_INSTANCE_ID) a,
                wms_license_plate_numbers wlpn,
                mtl_material_transactions mmt,
                XXSHP_WMS_OB_LPN_STG xwols,
                XXSHP_WMS_OB_LPN_LOAD_new xwolln
          WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
                AND xoso.OE_HEADER_ID = ooh.HEADER_ID
                AND xoso.OE_LINE_ID = ool.LINE_ID
                AND ooh.HEADER_ID = ool.HEADER_ID
                AND a.delivery_detail_id = wdd.delivery_detail_id
                AND xoso.delivery_detail_id = wdd.delivery_detail_id --update 1/5/2017
                --update 1/5/2017
                --       AND ooh.header_ID = wdd.SOURCE_HEADER_ID
                --       AND ool.line_id = wdd.source_line_id
                AND msi.inventory_item_id = xoso.inventory_item_id
                AND msi.organization_id = wdd.organization_id
                AND a.CONTAINER_NAME = wlpn.license_plate_number
                AND mmt.transaction_id = wdd.transaction_id
                AND wlpn.license_plate_number = xwols.license_plate_number
                AND xwolln.license_plate_number(+) =
                       xwols.license_plate_number
                AND xwolln.lot_number(+) = a.lot_number
                AND xoso.delivery_detail_id = wdd.delivery_detail_id
                AND xwolln.source_doc_num(+) = xwols.source_doc_num
                AND NOT EXISTS
                           (SELECT 1
                              FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwolst
                             WHERE     xwols.LICENSE_PLATE_NUMBER =
                                          LICENSE_PLATE_NUMBER
                                   AND a.lot_number = xwolst.lot_number
                                   AND xwolst.inventory_item_id =
                                          xoso.inventory_item_id
                                   AND xwolst.primary_qty =
                                          xwolst.primary_load_qty)
                --                AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced')
                AND xoes.spm_no = p_spm
                AND xoso.INVENTORY_ITEM_ID = p_item
                AND wlpn.LICENSE_PLATE_NUMBER = p_lpn
                AND wdd.lot_number LIKE p_lot || '%';
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN LPN LOV ' || SQLERRM);
   END GET_LOT_OB_LOAD_LOV;


   PROCEDURE GET_REMARKS_LOV (x_remarks OUT NOCOPY t_ref_csr)
   IS
   BEGIN
      OPEN x_remarks FOR
         SELECT REASON_ID, REASON_NAME, DESCRIPTION
           FROM mtl_transaction_reasons
          WHERE attribute3 = 'Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_REMARKS_LOV;

   PROCEDURE GET_REMARKS_LOAD_LOV (x_remarks OUT NOCOPY t_ref_csr)
   IS
   BEGIN
      OPEN x_remarks FOR
         SELECT REASON_ID, REASON_NAME, DESCRIPTION
           FROM mtl_transaction_reasons
          WHERE attribute5 = 'Y';
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_REMARKS_LOAD_LOV;

   FUNCTION CONVERTION_QTY (p_inv_item_id   IN NUMBER,
                            p_from_qty      IN NUMBER,
                            p_from_name     IN VARCHAR2,
                            p_to_name       IN VARCHAR2)
      RETURN NUMBER
   IS
      v_result   NUMBER;
   BEGIN
      --      SELECT inv_convert.inv_um_convert (item_id         => p_inv_item_id,
      --                                         precision       => 100,
      --                                         from_quantity   => p_from_qty,
      --                                         from_unit       => p_from_name,
      --                                         to_unit         => p_to_name,
      --                                         from_name       => NULL,
      --                                         to_name         => NULL)
      --        INTO v_result
      --        FROM DUAL;
      --update by iqbal 6-6-2017/ UAT
      SELECT xxshp_general_pkg.get_uom_conv_value (p_inv_item_id,
                                                   p_from_name,
                                                   p_to_name)
        INTO v_result
        FROM DUAL;

      RETURN v_result;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END CONVERTION_QTY;

   FUNCTION GET_REMAINING_LPN (p_source_doc IN VARCHAR2)
      RETURN NUMBER
   IS
      res   NUMBER;
   BEGIN
      --      SELECT COUNT (a.CONTAINER_NAME)
      --        INTO res
      --        FROM oe_order_lines_all ool,
      --             OE_ORDER_HEADERS_ALL ooh,
      --             xxshp_oe_exd_spm_hdr xoes,
      --             XXSHP_OE_EXD_SPM_ORDER xoso,
      --             WSH_DELIVERY_DETAILS wdd,
      --             (SELECT wdv1.parent_container_instance_id,
      --                     wdv1.SOURCE_HEADER_ID,
      --                     wdv1.delivery_detail_id,
      --                     wdv2.CONTAINER_NAME,
      --                     wdv1.LOT_NUMBER
      --                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
      --               WHERE wdv1.parent_container_instance_id =
      --                        wdv2.CONTAINER_INSTANCE_ID) a,
      --             mtl_system_items msi,
      --             wms_license_plate_numbers wlpn,
      --             mtl_material_transactions mmt,
      --             XXSHP_WMS_OB_LPN_STG xwols,
      --             XXSHP_WMS_OB_LPN_STG_new xwolsn
      --       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
      --             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
      --             AND xoso.OE_LINE_ID = ool.LINE_ID
      --             AND ooh.HEADER_ID = ool.HEADER_ID
      --             AND a.delivery_detail_id = wdd.delivery_detail_id
      --             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
      --             AND ool.line_id = wdd.source_line_id
      --             AND msi.inventory_item_id = xoso.inventory_item_id
      --             AND msi.organization_id = wdd.organization_id
      --             AND a.CONTAINER_NAME = wlpn.license_plate_number
      --             AND mmt.transaction_id = wdd.transaction_id
      --             AND wlpn.license_plate_number = xwols.license_plate_number
      --             AND xwolsn.license_plate_number(+) = xwols.license_plate_number
      --             AND xwolsn.lot_number(+) = a.lot_number
      --             AND NOT EXISTS
      --                        (SELECT 1
      --                           FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
      --                          WHERE     xwols.LICENSE_PLATE_NUMBER =
      --                                       LICENSE_PLATE_NUMBER
      --                                AND a.lot_number = xwolst.lot_number
      --                                AND xwolst.inventory_item_id =
      --                                       xoso.inventory_item_id
      --                                AND wdd.delivery_detail_id =
      --                                       xwolst.delivery_detail_id)
      --             --AND xoes.spm_no = 'KNS17030309'
      --             AND xwols.trx_type = 'SPM'
      --             AND xwols.SOURCE_DOC_NUM = p_source_doc;

      --update by iqbal 6-6-2017/ UAT
      /*SELECT COUNT (DISTINCT a.container_name)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             (SELECT wdv1.parent_container_instance_id,
                     wdv1.SOURCE_HEADER_ID,
                     wdv1.delivery_detail_id,
                     wdv2.CONTAINER_NAME,
                     wdv1.LOT_NUMBER,
                     wdv1.RELEASED_STATUS_NAME,
                     wdv2.RELEASED_STATUS_NAME kl
                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
               WHERE wdv1.parent_container_instance_id =
                        wdv2.CONTAINER_INSTANCE_ID) a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_STG_new xwolsn
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolsn.license_plate_number(+) = xwols.license_plate_number
             AND xwolsn.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolsn.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwolst.lot_number
                                AND xwolst.inventory_item_id =
                                       xoso.inventory_item_id)
             AND xwols.trx_type = 'SPM'
             AND xwols.SOURCE_DOC_NUM = p_source_doc
             AND a.RELEASED_STATUS_NAME NOT IN ('Shipped', 'Interfaced');*/

      -- update by ismet 20180816
      SELECT COUNT (DISTINCT a.container_name)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             (SELECT wdv1.parent_container_instance_id,
                     wdv1.SOURCE_HEADER_ID,
                     wdv1.delivery_detail_id,
                     wdv2.CONTAINER_NAME,
                     wdv1.LOT_NUMBER,
                     wdv1.RELEASED_STATUS_NAME,
                     wdv2.RELEASED_STATUS_NAME kl
                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
               WHERE     wdv1.parent_container_instance_id =
                            wdv2.CONTAINER_INSTANCE_ID
                     AND wdv1.RELEASED_STATUS_NAME NOT IN ('Shipped',
                                                           'Interfaced')) a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_STG_new xwolsn
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolsn.license_plate_number(+) = xwols.license_plate_number
             AND xwolsn.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolsn.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwolst.lot_number
                                AND xwolst.inventory_item_id =
                                       xoso.inventory_item_id)
             -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG_new aa
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       aa.LICENSE_PLATE_NUMBER
                                AND a.lot_number = aa.lot_number
                                AND aa.inventory_item_id =
                                       xoso.inventory_item_id
                                AND aa.primary_qty = aa.primary_stg_qty)
             AND xwols.trx_type = 'SPM'
             AND xwols.SOURCE_DOC_NUM = p_source_doc;

      --       AND xwols.license_plate_number = 'FG/170531/0008'
      --       AND xoes.spm_no = p_spm
      --       AND xwols.LICENSE_PLATE_NUMBER LIKE p_lpn || '%';
      RETURN res;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_REMAINING_LPN;

   FUNCTION GET_LOAD_REMAINING_LPN (p_source_doc IN VARCHAR2)
      RETURN NUMBER
   IS
      res   NUMBER;
   BEGIN
      -- update by ismet 20180816
      SELECT COUNT (DISTINCT a.container_name)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             (SELECT wdv1.parent_container_instance_id,
                     wdv1.SOURCE_HEADER_ID,
                     wdv1.delivery_detail_id,
                     wdv2.CONTAINER_NAME,
                     wdv1.LOT_NUMBER,
                     wdv1.RELEASED_STATUS_NAME,
                     wdv2.RELEASED_STATUS_NAME kl
                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
               WHERE     wdv1.parent_container_instance_id =
                            wdv2.CONTAINER_INSTANCE_ID
                     AND wdv1.RELEASED_STATUS_NAME NOT IN ('Shipped',
                                                           'Interfaced')) a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_LOAD_new xwolln
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolln.license_plate_number(+) = xwols.license_plate_number
             AND xwolln.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolln.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwollt
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwollt.lot_number
                                AND xwollt.inventory_item_id =
                                       xoso.inventory_item_id
                                AND xwollt.primary_qty =
                                       xwollt.primary_load_qty)
             -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_LOAD_new aa
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       aa.LICENSE_PLATE_NUMBER
                                AND a.lot_number = aa.lot_number
                                AND aa.inventory_item_id =
                                       xoso.inventory_item_id
                                AND aa.primary_qty = aa.primary_load_qty)
             AND xwols.trx_type = 'SPM'
             AND xwols.SOURCE_DOC_NUM = p_source_doc;

      --       AND xwols.license_plate_number = 'FG/170531/0008'
      --       AND xoes.spm_no = p_spm
      --       AND xwols.LICENSE_PLATE_NUMBER LIKE p_lpn || '%';
      RETURN res;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_LOAD_REMAINING_LPN;

   FUNCTION GET_LOAD_REMAINING_LPN_V2 (p_source_doc IN VARCHAR2)
      RETURN NUMBER
   IS
      res   NUMBER;
   BEGIN
      WITH wdd_data
           AS (SELECT wdd1.delivery_detail_id,
                      wda1.parent_delivery_detail_id,
                      wdd2.container_name,
                      wdd1.lot_number
                 FROM XXSHP_OE_EXD_SPM_ORDER xoso1,
                      wsh_delivery_details wdd1,
                      wsh_delivery_details wdd2,
                      wsh_delivery_assignments wda1,
                      fnd_lookup_values flv_wms,
                      wms_license_plate_numbers wlpn
                WHERE     1 = 1
                      AND xoso1.spm_header_id =
                             (SELECT spm_header_id
                                FROM XXSHP_OE_EXD_SPM_HDR
                               WHERE spm_no = p_source_doc)
                      AND xoso1.delivery_detail_id = wdd1.delivery_detail_id
                      AND wda1.delivery_detail_id = wdd1.delivery_detail_id
                      AND wda1.parent_delivery_detail_id =
                             wdd2.delivery_detail_id
                      AND flv_wms.lookup_type(+) = 'WMS_LPN_CONTEXT'
                      AND flv_wms.LANGUAGE(+) = USERENV ('LANG')
                      AND wdd1.lpn_id = wlpn.lpn_id(+)
                      AND flv_wms.lookup_code(+) = TO_CHAR (wlpn.lpn_context)
                      AND flv_wms.VIEW_APPLICATION_ID(+) = 700
                      AND flv_wms.SECURITY_GROUP_ID(+) = 0
                      AND DECODE (
                             wdd1.released_status,
                             'X', DECODE (
                                     wlpn.lpn_context,
                                     '9', flv_wms.meaning,
                                     '11', flv_wms.meaning,
                                     '12', flv_wms.meaning,
                                     (SELECT meaning
                                        FROM fnd_lookup_values flv_released
                                       WHERE     flv_released.lookup_type =
                                                    'PICK_STATUS'
                                             AND flv_released.lookup_code =
                                                    wdd1.released_status
                                             AND flv_released.LANGUAGE =
                                                    USERENV ('LANG')
                                             AND flv_released.VIEW_APPLICATION_ID =
                                                    665
                                             AND flv_released.SECURITY_GROUP_ID =
                                                    0)),
                             (SELECT meaning
                                FROM fnd_lookup_values flv_released
                               WHERE     flv_released.lookup_type =
                                            'PICK_STATUS'
                                     AND flv_released.lookup_code =
                                            wdd1.released_status
                                     AND flv_released.LANGUAGE =
                                            USERENV ('LANG')
                                     AND flv_released.VIEW_APPLICATION_ID =
                                            665
                                     AND flv_released.SECURITY_GROUP_ID = 0)) NOT IN ('Shipped',
                                                                                      'Interfaced')
                                                                                      )
      SELECT COUNT (DISTINCT a.container_name)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             wdd_data a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_LOAD_new xwolln
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolln.license_plate_number(+) = xwols.license_plate_number
             AND xwolln.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolln.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwollt
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwollt.lot_number
                                AND xwollt.inventory_item_id =
                                       xoso.inventory_item_id
                                AND xwollt.primary_qty =
                                       xwollt.primary_load_qty)
             -- Penambahan where not exist apabila sudah masuk ke table XXSHP_WMS_OB_LPN_STG_new
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_LOAD_new aa
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       aa.LICENSE_PLATE_NUMBER
                                AND a.lot_number = aa.lot_number
                                AND aa.inventory_item_id =
                                       xoso.inventory_item_id
                                AND aa.primary_qty = aa.primary_load_qty)
             AND xwols.trx_type = 'SPM'
             AND xwols.SOURCE_DOC_NUM = p_source_doc;

      --       AND xwols.license_plate_number = 'FG/170531/0008'
      --       AND xoes.spm_no = p_spm
      --       AND xwols.LICENSE_PLATE_NUMBER LIKE p_lpn || '%';
      RETURN res;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_LOAD_REMAINING_LPN_V2;

   FUNCTION GET_REMAINING_LOT (P_LPN IN VARCHAR2)
      RETURN NUMBER
   IS
      res   NUMBER;
   BEGIN
      SELECT COUNT (DISTINCT wdd.LOT_NUMBER)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             (SELECT wdv1.parent_container_instance_id,
                     wdv1.SOURCE_HEADER_ID,
                     wdv1.delivery_detail_id,
                     wdv2.CONTAINER_NAME,
                     wdv1.LOT_NUMBER,
                     wdv1.RELEASED_STATUS_NAME,
                     wdv2.RELEASED_STATUS_NAME kl
                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
               WHERE wdv1.parent_container_instance_id =
                        wdv2.CONTAINER_INSTANCE_ID) a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_STG_new xwolsn
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolsn.license_plate_number(+) = xwols.license_plate_number
             AND xwolsn.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolsn.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG_TEMP xwolst
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwolst.lot_number
                                AND xwolst.inventory_item_id =
                                       xoso.inventory_item_id)
             --AND xoes.spm_no = 'KNS17030309'
             AND xwols.trx_type = 'SPM'
             AND wlpn.LICENSE_PLATE_NUMBER = P_LPN;

      RETURN res;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_REMAINING_LOT;

   FUNCTION GET_LOAD_REMAINING_LOT (P_LPN IN VARCHAR2)
      RETURN NUMBER
   IS
      res   NUMBER;
   BEGIN
      SELECT COUNT (DISTINCT wdd.LOT_NUMBER)
        INTO res
        FROM oe_order_lines_all ool,
             OE_ORDER_HEADERS_ALL ooh,
             xxshp_oe_exd_spm_hdr xoes,
             XXSHP_OE_EXD_SPM_ORDER xoso,
             WSH_DELIVERY_DETAILS wdd,
             mtl_system_items msi,
             (SELECT wdv1.parent_container_instance_id,
                     wdv1.SOURCE_HEADER_ID,
                     wdv1.delivery_detail_id,
                     wdv2.CONTAINER_NAME,
                     wdv1.LOT_NUMBER,
                     wdv1.RELEASED_STATUS_NAME,
                     wdv2.RELEASED_STATUS_NAME kl
                FROM wsh_deliverables_v wdv1, wsh_deliverables_v wdv2
               WHERE wdv1.parent_container_instance_id =
                        wdv2.CONTAINER_INSTANCE_ID) a,
             wms_license_plate_numbers wlpn,
             mtl_material_transactions mmt,
             XXSHP_WMS_OB_LPN_STG xwols,
             XXSHP_WMS_OB_LPN_LOAD_new xwolln
       WHERE     xoes.SPM_HEADER_ID = xoso.SPM_HEADER_ID
             AND xoso.OE_HEADER_ID = ooh.HEADER_ID
             AND xoso.OE_LINE_ID = ool.LINE_ID
             AND ooh.HEADER_ID = ool.HEADER_ID
             AND a.delivery_detail_id = wdd.delivery_detail_id
             AND ooh.header_ID = wdd.SOURCE_HEADER_ID
             AND ool.line_id = wdd.source_line_id
             AND msi.inventory_item_id = xoso.inventory_item_id
             AND msi.organization_id = wdd.organization_id
             AND a.CONTAINER_NAME = wlpn.license_plate_number
             AND mmt.transaction_id = wdd.transaction_id
             AND wlpn.license_plate_number = xwols.license_plate_number
             AND xwolln.license_plate_number(+) = xwols.license_plate_number
             AND xwolln.lot_number(+) = a.lot_number
             AND xoso.delivery_detail_id = wdd.delivery_detail_id
             AND xwolln.source_doc_num(+) = xwols.source_doc_num
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_LOAD_TEMP xwolst
                          WHERE     xwols.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND a.lot_number = xwolst.lot_number
                                AND xwolst.inventory_item_id =
                                       xoso.inventory_item_id)
             --AND xoes.spm_no = 'KNS17030309'
             AND xwols.trx_type = 'SPM'
             AND wlpn.LICENSE_PLATE_NUMBER = P_LPN;

      RETURN res;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END GET_LOAD_REMAINING_LOT;

   FUNCTION GET_CHECKING_LPN (P_LPN        VARCHAR2,
                              P_LOT        VARCHAR2,
                              P_ITEM_ID    NUMBER)
      RETURN NUMBER
   IS
      V_RES   NUMBER;
   BEGIN
      SELECT 1
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_STG_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID = P_ITEM_ID
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG
                          WHERE     XWOLSN.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND XWOLSN.LOT_NUMBER = LOT_NUMBER
                                AND XWOLSN.INVENTORY_ITEM_ID =
                                       INVENTORY_ITEM_ID);

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_RES := 0;
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_CHECKING_LOAD_LPN (P_LPN        VARCHAR2,
                                   P_LOT        VARCHAR2,
                                   P_ITEM_ID    NUMBER)
      RETURN NUMBER
   IS
      V_RES   NUMBER;
   BEGIN
      SELECT 1
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_LOAD_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID = P_ITEM_ID
             AND NOT EXISTS
                        (SELECT 1
                           FROM XXSHP_WMS_OB_LPN_STG
                          WHERE     XWOLSN.LICENSE_PLATE_NUMBER =
                                       LICENSE_PLATE_NUMBER
                                AND XWOLSN.LOT_NUMBER = LOT_NUMBER
                                AND XWOLSN.INVENTORY_ITEM_ID =
                                       INVENTORY_ITEM_ID);

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_RES := 0;
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_PRIM_QTY_STG (P_LPN VARCHAR2, P_LOT VARCHAR2) --P_ITEM_ID    NUMBER
      RETURN VARCHAR2
   IS
      V_RES   VARCHAR2 (10);
      TES     NUMBER;
   BEGIN
      SELECT PRIMARY_STG_QTY
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_STG_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID =
                    (SELECT GET_ITEM_ID (P_LPN, P_LOT) FROM DUAL);

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_PRIM_QTY_LOAD (P_LPN VARCHAR2, P_LOT VARCHAR2) --P_ITEM_ID    NUMBER
      RETURN VARCHAR2
   IS
      V_RES   VARCHAR2 (10);
      TES     NUMBER;
   BEGIN
      SELECT PRIMARY_LOAD_QTY
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_LOAD_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID =
                    (SELECT GET_LOAD_ITEM_ID (P_LPN, P_LOT) FROM DUAL);

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_REMARKS (P_LPN VARCHAR2, P_LOT VARCHAR2, P_ITEM_ID NUMBER)
      RETURN VARCHAR2
   IS
      V_RES   VARCHAR2 (10);
   BEGIN
      SELECT REMARKS_STG
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_STG_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID = P_ITEM_ID;

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_NOTES (P_LPN VARCHAR2, P_LOT VARCHAR2, P_ITEM_ID NUMBER)
      RETURN VARCHAR2
   IS
      V_RES   VARCHAR2 (10);
   BEGIN
      SELECT NOTES_STG
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_STG_NEW XWOLSN
       WHERE     XWOLSN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLSN.LOT_NUMBER = P_LOT
             AND XWOLSN.INVENTORY_ITEM_ID = P_ITEM_ID;

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   FUNCTION GET_LOAD_NOTES (P_LPN VARCHAR2, P_LOT VARCHAR2, P_ITEM_ID NUMBER)
      RETURN VARCHAR2
   IS
      V_RES   VARCHAR2 (10);
   BEGIN
      SELECT NOTES_LOAD
        INTO V_RES
        FROM XXSHP_WMS_OB_LPN_LOAD_NEW XWOLLN
       WHERE     XWOLLN.LICENSE_PLATE_NUMBER = P_LPN
             AND XWOLLN.LOT_NUMBER = P_LOT
             AND XWOLLN.INVENTORY_ITEM_ID = P_ITEM_ID;

      RETURN V_RES;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.PUT_LINE ('ERROR IN DO LOV ' || SQLERRM);
   END;

   PROCEDURE INSERT_NEW_TAB (P_SOURCE_DOC_NUM    VARCHAR2,
                             P_LPN               VARCHAR2,
                             P_LOT               VARCHAR2,
                             P_ITEM_ID           VARCHAR2)
   IS
      P_TRX_TYPE              VARCHAR2 (100);
      P_INVENTORY_ITEM_ID     NUMBER;
      P_LOT_NUMBER            VARCHAR2 (100);
      P_PRIMARY_UOM_CODE      VARCHAR2 (100);
      P_PRIMARY_QTY           NUMBER;
      P_SECONDARY_UOM_CODE    VARCHAR2 (100);
      P_SECONDARY_QTY         NUMBER;
      P_PRIMARY_STG_QTY       NUMBER;
      P_SECONDARY_STG_QTY     NUMBER;
      P_REMARKS_STG           VARCHAR2 (100);
      P_NOTES_STG             VARCHAR2 (100);
      P_USER_ID_STG           NUMBER;
      P_START_DATE_STG        DATE;
      P_END_DATE_STG          DATE;
      P_ORGANIZATION_ID       NUMBER;
      P_LOCATOR_ID            NUMBER;
      P_SHIP_TO_LOCATION_ID   NUMBER;
      V_COUNT                 NUMBER;

      CURSOR x1
      IS
         SELECT TRX_TYPE,
                INVENTORY_ITEM_ID,
                LOT_NUMBER,
                PRIMARY_UOM_CODE,
                PRIMARY_QTY,
                SECONDARY_UOM_CODE,
                SECONDARY_QTY,
                PRIMARY_STG_QTY,
                SECONDARY_STG_QTY,
                REMARKS_STG,
                NOTES_STG,
                USER_ID_STG,
                START_DATE_STG,
                END_DATE_STG,
                ORGANIZATION_ID,
                LOCATOR_ID,
                SHIP_TO_LOCATION_ID
           FROM XXSHP_WMS_OB_LPN_STG_TEMP
          WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                AND LICENSE_PLATE_NUMBER = P_LPN
                AND INVENTORY_ITEM_ID = P_ITEM_ID
                AND LOT_NUMBER = P_LOT;
   BEGIN
      OPEN X1;

      LOOP
         FETCH x1
            INTO P_TRX_TYPE,
                 P_INVENTORY_ITEM_ID,
                 P_LOT_NUMBER,
                 P_PRIMARY_UOM_CODE,
                 P_PRIMARY_QTY,
                 P_SECONDARY_UOM_CODE,
                 P_SECONDARY_QTY,
                 P_PRIMARY_STG_QTY,
                 P_SECONDARY_STG_QTY,
                 P_REMARKS_STG,
                 P_NOTES_STG,
                 P_USER_ID_STG,
                 P_START_DATE_STG,
                 P_END_DATE_STG,
                 P_ORGANIZATION_ID,
                 P_LOCATOR_ID,
                 P_SHIP_TO_LOCATION_ID;

         EXIT WHEN x1%NOTFOUND;

         BEGIN
            SELECT COUNT (*)
              INTO v_count
              FROM XXSHP_WMS_OB_LPN_STG_NEW
             WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                   AND LICENSE_PLATE_NUMBER = P_LPN
                   AND LOT_NUMBER = P_LOT;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_count := 0;
         END;

         IF v_count > 0
         THEN
            UPDATE XXSHP_WMS_OB_LPN_STG_NEW
               SET PRIMARY_QTY = P_PRIMARY_QTY,
                   SECONDARY_QTY = P_SECONDARY_QTY,
                   PRIMARY_STG_QTY = P_PRIMARY_STG_QTY,
                   SECONDARY_STG_QTY = P_SECONDARY_STG_QTY,
                   REMARKS_STG = P_REMARKS_STG,
                   NOTES_STG = P_NOTES_STG,
                   USER_ID_STG = P_USER_ID_STG,
                   START_DATE_STG = P_START_DATE_STG,
                   END_DATE_STG = P_END_DATE_STG,
                   LOCATOR_ID = P_LOCATOR_ID,
                   SHIP_TO_LOCATION_ID = P_SHIP_TO_LOCATION_ID
             WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                   AND LICENSE_PLATE_NUMBER = P_LPN
                   AND LOT_NUMBER = P_LOT
                   AND inventory_item_id = P_ITEM_ID;
         ELSE
            INSERT INTO XXSHP_WMS_OB_LPN_STG_NEW (TRX_TYPE,
                                                  SOURCE_DOC_NUM,
                                                  INVENTORY_ITEM_ID,
                                                  LICENSE_PLATE_NUMBER,
                                                  LOT_NUMBER,
                                                  PRIMARY_UOM_CODE,
                                                  PRIMARY_QTY,
                                                  SECONDARY_UOM_CODE,
                                                  SECONDARY_QTY,
                                                  PRIMARY_STG_QTY,
                                                  SECONDARY_STG_QTY,
                                                  REMARKS_STG,
                                                  NOTES_STG,
                                                  USER_ID_STG,
                                                  START_DATE_STG,
                                                  END_DATE_STG,
                                                  ORGANIZATION_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATED_BY,
                                                  LAST_UPDATE_DATE,
                                                  LAST_UPDATE_LOGIN,
                                                  LOCATOR_ID,
                                                  SHIP_TO_LOCATION_ID)
                 VALUES (P_TRX_TYPE,
                         P_SOURCE_DOC_NUM,
                         P_ITEM_ID,
                         P_LPN,
                         P_LOT_NUMBER,
                         P_PRIMARY_UOM_CODE,
                         P_PRIMARY_QTY,
                         P_SECONDARY_UOM_CODE,
                         P_SECONDARY_QTY,
                         P_PRIMARY_STG_QTY,
                         P_SECONDARY_STG_QTY,
                         P_REMARKS_STG,
                         P_NOTES_STG,
                         P_USER_ID_STG,
                         P_START_DATE_STG,
                         P_END_DATE_STG,
                         P_ORGANIZATION_ID,
                         G_USER_ID,
                         SYSDATE,
                         G_USER_ID,
                         SYSDATE,
                         G_USER_ID,
                         P_LOCATOR_ID,
                         P_SHIP_TO_LOCATION_ID);
         END IF;
      END LOOP;

      CLOSE x1;

      COMMIT;
   END INSERT_NEW_TAB;

   PROCEDURE INSERT_NEW_LOAD_TAB (P_SOURCE_DOC_NUM    VARCHAR2,
                                  P_LPN               VARCHAR2,
                                  P_LOT               VARCHAR2,
                                  P_ITEM_ID           VARCHAR2)
   IS
      P_TRX_TYPE              VARCHAR2 (100);
      P_INVENTORY_ITEM_ID     NUMBER;
      P_LOT_NUMBER            VARCHAR2 (100);
      P_PRIMARY_UOM_CODE      VARCHAR2 (100);
      P_PRIMARY_QTY           NUMBER;
      P_SECONDARY_UOM_CODE    VARCHAR2 (100);
      P_SECONDARY_QTY         NUMBER;
      P_PRIMARY_LOAD_QTY      NUMBER;
      P_SECONDARY_LOAD_QTY    NUMBER;
      P_REMARKS_LOAD          VARCHAR2 (100);
      P_NOTES_LOAD            VARCHAR2 (100);
      P_USER_ID_LOAD          NUMBER;
      P_START_DATE_LOAD       DATE;
      P_END_DATE_LOAD         DATE;
      P_ORGANIZATION_ID       NUMBER;
      P_LOCATOR_ID            NUMBER;
      P_SHIP_TO_LOCATION_ID   NUMBER;
      P_DOCK_ID               NUMBER;
      P_DOCK_DOOR             VARCHAR2 (100);
      V_COUNT                 NUMBER;

      CURSOR x1
      IS
           SELECT TRX_TYPE,
                  INVENTORY_ITEM_ID,
                  LOT_NUMBER,
                  PRIMARY_UOM_CODE,
                  PRIMARY_QTY,
                  SECONDARY_UOM_CODE,
                  SECONDARY_QTY,
                  PRIMARY_LOAD_QTY,
                  SECONDARY_LOAD_QTY,
                  REMARKS_LOAD,
                  NOTES_LOAD,
                  USER_ID_LOAD,
                  START_DATE_LOAD,
                  END_DATE_LOAD,
                  ORGANIZATION_ID,
                  LOCATOR_ID,
                  SHIP_TO_LOCATION_ID,
                  DOCK_ID,
                  DOCK_DOOR
             FROM XXSHP_WMS_OB_LPN_LOAD_TEMP
            WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                  AND LICENSE_PLATE_NUMBER = P_LPN
                  AND INVENTORY_ITEM_ID = P_ITEM_ID
                  AND LOT_NUMBER = P_LOT
         ORDER BY CREATION_DATE;
   BEGIN
      OPEN X1;

      LOOP
         FETCH x1
            INTO P_TRX_TYPE,
                 P_INVENTORY_ITEM_ID,
                 P_LOT_NUMBER,
                 P_PRIMARY_UOM_CODE,
                 P_PRIMARY_QTY,
                 P_SECONDARY_UOM_CODE,
                 P_SECONDARY_QTY,
                 P_PRIMARY_LOAD_QTY,
                 P_SECONDARY_LOAD_QTY,
                 P_REMARKS_LOAD,
                 P_NOTES_LOAD,
                 P_USER_ID_LOAD,
                 P_START_DATE_LOAD,
                 P_END_DATE_LOAD,
                 P_ORGANIZATION_ID,
                 P_LOCATOR_ID,
                 P_SHIP_TO_LOCATION_ID,
                 P_DOCK_ID,
                 P_DOCK_DOOR;

         EXIT WHEN x1%NOTFOUND;

         BEGIN
            SELECT COUNT (*)
              INTO v_count
              FROM XXSHP_WMS_OB_LPN_LOAD_NEW
             WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                   AND LICENSE_PLATE_NUMBER = P_LPN
                   AND LOT_NUMBER = P_LOT;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_count := 0;
         END;

         IF v_count > 0
         THEN
            UPDATE XXSHP_WMS_OB_LPN_LOAD_NEW
               SET PRIMARY_QTY = P_PRIMARY_QTY,
                   SECONDARY_QTY = P_SECONDARY_QTY,
                   PRIMARY_LOAD_QTY = P_PRIMARY_LOAD_QTY,
                   SECONDARY_LOAD_QTY = P_SECONDARY_LOAD_QTY,
                   REMARKS_LOAD = P_REMARKS_LOAD,
                   NOTES_LOAD = P_NOTES_LOAD,
                   USER_ID_LOAD = P_USER_ID_LOAD,
                   START_DATE_LOAD = P_START_DATE_LOAD,
                   END_DATE_LOAD = P_END_DATE_LOAD,
                   LOCATOR_ID = P_LOCATOR_ID,
                   SHIP_TO_LOCATION_ID = P_SHIP_TO_LOCATION_ID,
                   DOCK_ID = P_DOCK_ID,
                   DOCK_DOOR = P_DOCK_DOOR
             WHERE     SOURCE_DOC_NUM = P_SOURCE_DOC_NUM
                   AND LICENSE_PLATE_NUMBER = P_LPN
                   AND LOT_NUMBER = P_LOT
                   AND inventory_item_id = P_ITEM_ID;
         ELSE
            INSERT INTO XXSHP_WMS_OB_LPN_LOAD_NEW (TRX_TYPE,
                                                   SOURCE_DOC_NUM,
                                                   INVENTORY_ITEM_ID,
                                                   LICENSE_PLATE_NUMBER,
                                                   LOT_NUMBER,
                                                   PRIMARY_UOM_CODE,
                                                   PRIMARY_QTY,
                                                   SECONDARY_UOM_CODE,
                                                   SECONDARY_QTY,
                                                   PRIMARY_LOAD_QTY,
                                                   SECONDARY_LOAD_QTY,
                                                   REMARKS_LOAD,
                                                   NOTES_LOAD,
                                                   USER_ID_LOAD,
                                                   START_DATE_LOAD,
                                                   END_DATE_LOAD,
                                                   ORGANIZATION_ID,
                                                   CREATED_BY,
                                                   CREATION_DATE,
                                                   LAST_UPDATED_BY,
                                                   LAST_UPDATE_DATE,
                                                   LAST_UPDATE_LOGIN,
                                                   LOCATOR_ID,
                                                   SHIP_TO_LOCATION_ID,
                                                   DOCK_ID,
                                                   DOCK_DOOR)
                 VALUES (P_TRX_TYPE,
                         P_SOURCE_DOC_NUM,
                         P_ITEM_ID,
                         P_LPN,
                         P_LOT_NUMBER,
                         P_PRIMARY_UOM_CODE,
                         P_PRIMARY_QTY,
                         P_SECONDARY_UOM_CODE,
                         P_SECONDARY_QTY,
                         P_PRIMARY_LOAD_QTY,
                         P_SECONDARY_LOAD_QTY,
                         P_REMARKS_LOAD,
                         P_NOTES_LOAD,
                         P_USER_ID_LOAD,
                         P_START_DATE_LOAD,
                         P_END_DATE_LOAD,
                         P_ORGANIZATION_ID,
                         G_USER_ID,
                         SYSDATE,
                         G_USER_ID,
                         SYSDATE,
                         G_USER_ID,
                         P_LOCATOR_ID,
                         P_SHIP_TO_LOCATION_ID,
                         P_DOCK_ID,
                         P_DOCK_DOOR);
         END IF;
      END LOOP;

      CLOSE x1;

      COMMIT;
   END INSERT_NEW_LOAD_TAB;

   PROCEDURE INSERT_TEMP (P_SPM                  IN     VARCHAR2,
                          P_ITEM_ID              IN     NUMBER,
                          P_LPN                  IN     VARCHAR2,
                          P_LOT                  IN     VARCHAR2,
                          P_UOM                  IN     VARCHAR2,
                          P_PRIMARY_QTY          IN     NUMBER,
                          P_SECONDARY_UOM_CODE   IN     VARCHAR2,
                          P_PRIMARY_STG_QTY      IN     NUMBER,
                          P_SECONDARY_STG_QTY    IN     NUMBER,
                          P_REMARKS_STG          IN     VARCHAR2,
                          P_NOTES_STG            IN     VARCHAR2,
                          P_ORGID                IN     NUMBER,
                          P_START_DATE_STG       IN     VARCHAR2,
                          P_END_DATE_STG         IN     VARCHAR2,
                          P_DELIVERY_DETAIL_ID   IN     NUMBER,
                          P_USER_ID_STG          IN     NUMBER, --update by iqbal 05-09-2017
                          P_RESULT                  OUT VARCHAR2)
   IS
      v_count                 NUMBER;
      V_SHIP_TO_LOCATION_ID   NUMBER;
      V_LOCATOR_ID            NUMBER;
      V_SECONDARY_QTY         NUMBER;
      v_start_date            DATE;
      v_end_date              DATE;
   BEGIN
      BEGIN
         SELECT SHIP_TO_LOCATION_ID, xwols.LOCATOR_ID, SECONDARY_QTY
           INTO V_SHIP_TO_LOCATION_ID, V_LOCATOR_ID, V_SECONDARY_QTY
           FROM XXSHP_WMS_OB_LPN_STG xwols,
                wms_license_plate_numbers wlpn,
                wms_lpn_contents wlc
          WHERE                                     --  SOURCE_DOC_NUM = P_SPM
               wlpn .LICENSE_PLATE_NUMBER = P_LPN
                AND wlc.LOT_NUMBER = P_LOT
                AND wlpn.license_plate_number = xwols.license_plate_number
                AND wlc.parent_lpn_id = wlpn.lpn_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            V_SHIP_TO_LOCATION_ID := 0;
            V_LOCATOR_ID := 0;
            V_SECONDARY_QTY := 0;
      END;

      v_start_date := TO_DATE (P_START_DATE_STG, 'RRRR/MM/DD HH24:MI:SS');
      v_end_date := TO_DATE (P_END_DATE_STG, 'RRRR/MM/DD HH24:MI:SS');

      INSERT INTO XXSHP_WMS_OB_LPN_STG_TEMP (TRX_TYPE,
                                             SOURCE_DOC_NUM,
                                             INVENTORY_ITEM_ID,
                                             LICENSE_PLATE_NUMBER,
                                             LOT_NUMBER,
                                             PRIMARY_UOM_CODE,
                                             PRIMARY_QTY,
                                             SECONDARY_UOM_CODE,
                                             SECONDARY_QTY,
                                             PRIMARY_STG_QTY,
                                             SECONDARY_STG_QTY,
                                             REMARKS_STG,
                                             NOTES_STG,
                                             USER_ID_STG,
                                             START_DATE_STG,
                                             END_DATE_STG,
                                             ORGANIZATION_ID,
                                             CREATED_BY,
                                             CREATION_DATE,
                                             LAST_UPDATED_BY,
                                             LAST_UPDATE_DATE,
                                             LAST_UPDATE_LOGIN,
                                             LOCATOR_ID,
                                             SHIP_TO_LOCATION_ID,
                                             DELIVERY_DETAIL_ID)
           VALUES ('SPM',
                   P_SPM,
                   P_ITEM_ID,
                   P_LPN,
                   P_LOT,
                   P_UOM,
                   P_PRIMARY_QTY,
                   P_SECONDARY_UOM_CODE,
                   V_SECONDARY_QTY,
                   P_PRIMARY_STG_QTY,
                   P_SECONDARY_STG_QTY,
                   P_REMARKS_STG,
                   P_NOTES_STG,
                   P_USER_ID_STG,                --update by iqbal 05-09-2017,
                   v_start_date,
                   v_end_date,
                   P_ORGID,
                   g_user_id,
                   SYSDATE,
                   g_user_id,
                   SYSDATE,
                   g_user_id,
                   V_LOCATOR_ID,
                   V_SHIP_TO_LOCATION_ID,
                   0);

      v_count := SQL%ROWCOUNT;
      INSERT_NEW_TAB (P_SPM,
                      P_LPN,
                      P_LOT,
                      P_ITEM_ID);

      IF v_count <> 0
      THEN
         p_result := 'Succes' || ' ' || v_count;
      ELSE
         p_result := 'Error' || ' ' || v_count;
      END IF;
   END INSERT_TEMP;

   PROCEDURE insert_temp_load (p_spm                  IN     VARCHAR2,
                               p_item_id              IN     NUMBER,
                               p_lpn                  IN     VARCHAR2,
                               p_lot                  IN     VARCHAR2,
                               p_uom                  IN     VARCHAR2,
                               p_primary_qty          IN     NUMBER,
                               p_secondary_uom_code   IN     VARCHAR2,
                               p_primary_load_qty     IN     NUMBER,
                               p_secondary_load_qty   IN     NUMBER,
                               p_remarks_load         IN     VARCHAR2,
                               p_notes_load           IN     VARCHAR2,
                               p_orgid                IN     NUMBER,
                               p_start_date_load      IN     VARCHAR2,
                               p_end_date_load        IN     VARCHAR2,
                               p_delivery_detail_id   IN     NUMBER,
                               P_USER_ID_LOAD         IN     NUMBER, --update by iqbal 05-09-2017
                               p_dock_id              IN     NUMBER,
                               p_dock_door            IN     VARCHAR2,
                               p_result                  OUT VARCHAR2)
   IS
      v_count                 NUMBER;
      V_SHIP_TO_LOCATION_ID   NUMBER;
      V_LOCATOR_ID            NUMBER;
      V_SECONDARY_QTY         NUMBER;
      v_start_date            DATE;
      v_end_date              DATE;
   BEGIN
      BEGIN
         SELECT SHIP_TO_LOCATION_ID, xwols.LOCATOR_ID, SECONDARY_QTY
           INTO V_SHIP_TO_LOCATION_ID, V_LOCATOR_ID, V_SECONDARY_QTY
           FROM XXSHP_WMS_OB_LPN_STG xwols,
                wms_license_plate_numbers wlpn,
                wms_lpn_contents wlc
          WHERE                                     --  SOURCE_DOC_NUM = P_SPM
               wlpn .LICENSE_PLATE_NUMBER = P_LPN
                AND wlc.LOT_NUMBER = P_LOT
                AND wlpn.license_plate_number = xwols.license_plate_number
                AND wlc.parent_lpn_id = wlpn.lpn_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            V_SHIP_TO_LOCATION_ID := 0;
            V_LOCATOR_ID := 0;
            V_SECONDARY_QTY := 0;
      END;

      v_start_date := TO_DATE (P_START_DATE_LOAD, 'RRRR/MM/DD HH24:MI:SS');
      v_end_date := TO_DATE (P_END_DATE_LOAD, 'RRRR/MM/DD HH24:MI:SS');

      INSERT INTO XXSHP_WMS_OB_LPN_LOAD_TEMP (TRX_TYPE,
                                              SOURCE_DOC_NUM,
                                              INVENTORY_ITEM_ID,
                                              LICENSE_PLATE_NUMBER,
                                              LOT_NUMBER,
                                              PRIMARY_UOM_CODE,
                                              PRIMARY_QTY,
                                              SECONDARY_UOM_CODE,
                                              SECONDARY_QTY,
                                              PRIMARY_LOAD_QTY,
                                              SECONDARY_LOAD_QTY,
                                              REMARKS_LOAD,
                                              NOTES_LOAD,
                                              USER_ID_LOAD,
                                              START_DATE_LOAD,
                                              END_DATE_LOAD,
                                              ORGANIZATION_ID,
                                              CREATED_BY,
                                              CREATION_DATE,
                                              LAST_UPDATED_BY,
                                              LAST_UPDATE_DATE,
                                              LAST_UPDATE_LOGIN,
                                              LOCATOR_ID,
                                              SHIP_TO_LOCATION_ID,
                                              DELIVERY_DETAIL_ID,
                                              DOCK_ID,
                                              DOCK_DOOR)
           VALUES ('SPM',
                   P_SPM,
                   P_ITEM_ID,
                   P_LPN,
                   P_LOT,
                   P_UOM,
                   P_PRIMARY_QTY,
                   P_SECONDARY_UOM_CODE,
                   V_SECONDARY_QTY,
                   P_PRIMARY_LOAD_QTY,
                   P_SECONDARY_LOAD_QTY,
                   P_REMARKS_LOAD,
                   P_NOTES_LOAD,
                   P_USER_ID_LOAD,               --update by iqbal 05-09-2017,
                   v_start_date,
                   v_end_date,
                   P_ORGID,
                   g_user_id,
                   SYSDATE,
                   g_user_id,
                   SYSDATE,
                   g_user_id,
                   V_LOCATOR_ID,
                   V_SHIP_TO_LOCATION_ID,
                   0,
                   p_dock_id,
                   p_dock_door);

      v_count := SQL%ROWCOUNT;
      INSERT_NEW_LOAD_TAB (P_SPM,
                           P_LPN,
                           P_LOT,
                           P_ITEM_ID);

      IF v_count <> 0
      THEN
         p_result := 'Succes' || ' ' || v_count;
      ELSE
         p_result := 'Error' || ' ' || v_count;
      END IF;
   END INSERT_TEMP_LOAD;


   PROCEDURE UPDATE_OUTBOUND (p_source_no       IN     VARCHAR2,
                              p_inv_item_id     IN     NUMBER,
                              p_lpn             IN     VARCHAR2,
                              p_lot             IN     VARCHAR2,
                              p_prim_uom        IN     VARCHAR2,
                              p_sec_uom         IN     VARCHAR2,
                              p_prim_qty        IN     NUMBER,
                              p_update_by       IN     NUMBER,
                              P_PRIM_CONF_QTY   IN     NUMBER,
                              P_SEC_CONF_QTY    IN     NUMBER,
                              P_REMARK          IN     VARCHAR2,
                              P_NOTES           IN     VARCHAR2,
                              P_START           IN     VARCHAR2,
                              P_END             IN     VARCHAR2,
                              p_result             OUT VARCHAR2)
   AS
      v_count        NUMBER;
      v_start_date   DATE;
      v_end_date     DATE;
   BEGIN
      v_start_date := TO_DATE (P_START, 'RRRR/MM/DD HH24:MI:SS');
      v_end_date := TO_DATE (P_END, 'RRRR/MM/DD HH24:MI:SS');

      UPDATE XXSHP_WMS_OB_LPN_STG
         SET INVENTORY_ITEM_ID = p_inv_item_id,
             LOT_NUMBER = p_lot,
             PRIMARY_UOM_CODE = p_prim_uom,
             SECONDARY_UOM_CODE = p_sec_uom,
             PRIMARY_QTY = p_prim_qty,
             USER_ID_STG = p_update_by,
             PRIMARY_STG_QTY = P_PRIM_CONF_QTY,
             SECONDARY_STG_QTY = P_SEC_CONF_QTY,
             REMARKS_STG = P_REMARK,
             NOTES_STG = P_NOTES,
             START_DATE_STG = v_start_date,
             END_DATE_STG = v_end_date
       WHERE LICENSE_PLATE_NUMBER = p_LPN AND SOURCE_DOC_NUM = p_source_no;


      v_count := SQL%ROWCOUNT;


      IF v_count <> 0
      THEN
         p_result := 'Succes';
      ELSE
         p_result := 'Error';
      END IF;

      COMMIT;
   END UPDATE_OUTBOUND;
END XXSHP_WMS_OB_LPN_PKG_NEW;
/