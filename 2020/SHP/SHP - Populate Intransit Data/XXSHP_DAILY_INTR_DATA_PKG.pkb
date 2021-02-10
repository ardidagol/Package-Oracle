CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_DAILY_INTR_DATA_PKG
IS
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END;

   PROCEDURE insert_data (errbuf OUT VARCHAR2, retcode OUT NUMBER)
   IS
   BEGIN
      LOGF ('========INSERT DATA=======');

      INSERT INTO XXSHP_DAILY_INTR_DATA
         SELECT   TO_CHAR (SYSDATE, 'DD') dates,
                  SYSDATE curr_date,
                  a.*,
                  b.from_org_id,
                  c.organization_code from_org,
                  b.to_org_id,
                  e.organization_code to_org,
                  d.segment1 item_code,
                  d.description,
                  d.primary_uom_code uom,
                  TO_CHAR (SYSDATE, 'MON-RR') period_name
           FROM   (SELECT   SHIP.shipment_number,
                            SHIP.inventory_item_id,
                            SHIP.ship_qty,
                            NVL (RCV.rcv_qty, 0) RCV_QTY,
                            SHIP.ship_qty - NVL (RCV.rcv_qty, 0) intr_qty
                     FROM   (  SELECT   shipment_number,
                                        inventory_item_id,
                                        -1 * SUM (primary_quantity) SHIP_QTY
                                 FROM   (SELECT   mmt.transaction_date,
                                                  mmt.inventory_item_id,
                                                  TRIM (mmt.shipment_number)
                                                     shipment_number,
                                                  mmt.organization_id
                                                     from_org_id,
                                                  mmt.transfer_organization_id
                                                     to_org_id,
                                                  mmt.primary_quantity
                                           FROM   mtl_material_transactions mmt
                                          WHERE   mmt.transaction_date >=
                                                     add_months(sysdate,-3)--'01-Jun-2019'   /*aar ubah menjadi sysdate -3 28 sep 2020*/
                                                  AND mmt.transaction_type_id IN
                                                           (101,
                                                            102,
                                                            123,
                                                            131,
                                                            132,
                                                            133,
                                                            134,
                                                            135,
                                                            3,
                                                            21,
                                                            62,
                                                            153))
                             GROUP BY   shipment_number, inventory_item_id)
                            SHIP,
                            (  SELECT   shipment_number,
                                        inventory_item_id,
                                        SUM (primary_quantity) RCV_QTY
                                 FROM   (SELECT   mmt.transaction_date,
                                                  mmt.inventory_item_id,
                                                  TRIM (mmt.shipment_number)
                                                     shipment_number,
                                                  mmt.organization_id
                                                     from_org_id,
                                                  mmt.transfer_organization_id
                                                     to_org_id,
                                                  mmt.primary_quantity
                                           FROM   mtl_material_transactions mmt
                                          WHERE   mmt.transaction_date >=
                                                     add_months(sysdate,-3)--'01-Jun-2019'   /*aar ubah menjadi sysdate -3 28 sep 2020*/
                                                  AND mmt.transaction_type_id IN
                                                           (13, 12, 61))
                             GROUP BY   shipment_number, inventory_item_id)
                            RCV
                    WHERE   1 = 1
                            AND SHIP.shipment_number = RCV.shipment_number(+)
                            AND SHIP.inventory_item_id =
                                  RCV.inventory_item_id(+)) A,
                  (  SELECT   shipment_number,
                              period_name,
                              inventory_item_id,
                              from_org_id,
                              to_org_id,
                              SUM (primary_quantity) quantity
                       FROM   (SELECT   TO_CHAR (mmt.transaction_date,
                                                 'MON-RR')
                                           period_name,
                                        mmt.inventory_item_id,
                                        TRIM (mmt.shipment_number)
                                           shipment_number,
                                        mmt.organization_id from_org_id,
                                        mmt.transfer_organization_id to_org_id,
                                        mmt.primary_quantity
                                 FROM   mtl_material_transactions mmt
                                WHERE   mmt.transaction_date >= add_months(sysdate,-3)--'01-Jun-2019'   /*aar ubah menjadi sysdate -3 28 sep 2020*/
                                        AND mmt.transaction_type_id IN
                                                 (101,
                                                  102,
                                                  123,
                                                  131,
                                                  132,
                                                  133,
                                                  134,
                                                  135,
                                                  3,
                                                  21,
                                                  62,
                                                  153))
                   GROUP BY   shipment_number,
                              inventory_item_id,
                              from_org_id,
                              to_org_id,
                              period_name) B,
                  mtl_parameters c,
                  mtl_system_items d,
                  mtl_parameters e
          WHERE       1 = 1
                  AND a.intr_qty > 0
                  AND a.shipment_number = b.shipment_number
                  AND a.inventory_item_id = b.inventory_item_id
                  AND a.inventory_item_id = d.inventory_item_id
                  AND b.from_org_id = d.organization_id
                  AND b.from_org_id = c.organization_id
                  AND b.to_org_id = e.organization_id;

      LOGF ('========END PROCESS INSERT=======');

      BEGIN
         LOGF ('=======DELETE DATA========');

         DELETE FROM   XXSHP_DAILY_INTR_DATA
               WHERE       1 = 1
                       AND curr_date <= SYSDATE - 90
                       AND dates NOT IN ('28', '29', '30', '31');

         LOGF ('========END PROCESS DELETE=======');
      END;

      COMMIT;
   END;
END;
/
