CREATE OR REPLACE PACKAGE      XXKHD_PO_SERV_PK IS
--************************************************************************************************
--*   Object   : Automatic PO Service Creation Application 
--*   Author   : Johan Parulian 
--*   Date     : 17-SEP-2007.
--*   Company  : Sigma Solusi Integrasi 
--*   Client   : Kalbe Foods 
--*   Location : Jakarta 
--*   File     : XSHP_PO_SERV_PK.pks and XSHP_PO_SERV_PK.pkb   
--*   Purpose  :  
--*               
--* 
--*   History :
--*
--*   Name                 Ver     Date                Comments 
--*   Johan Parulian       1.0     17-SEP-2006.        Created 
--*   Sigit Prianto        1.0     28-DEC-2012         Add field SJ dan GRN FG utk PO FEE
--************************************************************************************************

   --MSG DI XSHP TEMP BLOM DI AKOMODASi 
   --REMOVING INTERFACE IF ERROR HAPPENs 

   ----VARIABLE------------------------------------------------ 
   ------------------------------------------------------------    
   TYPE mesg_rec_type IS RECORD(mesg VARCHAR2(100));
   TYPE mesg_tab_type IS TABLE OF mesg_rec_type INDEX BY BINARY_INTEGER;
   cust_mesg mesg_tab_type;

   TYPE vendor_rec_type IS RECORD (
     vendor_name    PO_VENDORS.vendor_name%TYPE,
    vendor_site_code  PO_VENDOR_SITES_ALL.vendor_site_code%TYPE,
     vendor_id    PO_VENDORS.vendor_id%TYPE,
    vendor_site_id    PO_VENDOR_SITES_ALL.vendor_site_id%TYPE,
  ship_to_organization_id PLS_INTEGER,
  ship_to_location  HR_LOCATIONS_ALL.location_code%TYPE,  
  segment4    GL_CODE_COMBINATIONS.segment4%TYPE,
  mesg      VARCHAR2(100)
   );

   TYPE item_rec_type IS RECORD (
     item_id             MTL_SYSTEM_ITEMS_B.inventory_item_id%TYPE,
     item_code        MTL_SYSTEM_ITEMS_B.segment1%TYPE,
    item_description      MTL_SYSTEM_ITEMS_B.description%TYPE,
  category_id        MTL_ITEM_CATEGORIES_V.category_id%TYPE,
     unit_price        PO_LINES_ALL.unit_price%TYPE,
  primary_uom_code      MTL_SYSTEM_ITEMS_B.primary_uom_code%TYPE,
  primary_unit_of_measure MTL_SYSTEM_ITEMS_B.primary_unit_of_measure%TYPE,
--  secondary_unit_of_measure MTL_SYSTEM_ITEMS_B.primary_unit_of_measure%TYPE,  
--  secondary_uom_code MTL_SYSTEM_ITEMS_B.secondary_uom_code%TYPE,  
  conversion       NUMBER,
  secondary_conversion  NUMBER,
  secondary_quantity    NUMBER,    
  unit_meas_lookup_code MTL_UNITS_OF_MEASURE_TL.unit_of_measure%TYPE,
  segment1       GL_CODE_COMBINATIONS.segment1%TYPE,
  segment2       GL_CODE_COMBINATIONS.segment2%TYPE,
  segment3       GL_CODE_COMBINATIONS.segment3%TYPE,
  segment5       GL_CODE_COMBINATIONS.segment5%TYPE,
  segment6       GL_CODE_COMBINATIONS.segment6%TYPE,
  segment7       GL_CODE_COMBINATIONS.segment7%TYPE,
  mesg         VARCHAR2(100)  
   );

   ----CONSTANT------------------------------------------------ 
   ------------------------------------------------------------ 
   
   g_hazard_class_id PLS_INTEGER;
   e_exception       EXCEPTION;
   e_bohong          EXCEPTION;
   g_start_date   DATE;
   g_end_date   DATE;
   g_debug    VARCHAR2(1);
   g_currency_code  xxkhd_po_hdr.currency_code%TYPE;
   
   g_hazard_class                      PO_HAZARD_CLASSES_TL.hazard_class%TYPE          DEFAULT 'Toll Fee';
   g_set_of_books_id             PLS_INTEGER                                DEFAULT Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');
   g_max_time               PLS_INTEGER             DEFAULT 259200; --3 hari.
   g_intval_time          PLS_INTEGER             DEFAULT 4;
   g_std_rpt             VARCHAR2(40)            DEFAULT 'POXPIERR';
   g_std_rpt_appl           VARCHAR2(20)            DEFAULT 'PO';
   g_std_iface             VARCHAR2(40)            DEFAULT 'POXPOPDOI';
   g_std_iface_appl         VARCHAR2(20)            DEFAULT 'PO';

   g_hdr_revision_num           xxkhd_po_hdr.revision_num%TYPE               DEFAULT 0;
   g_hdr_action                 xxkhd_po_hdr.action%TYPE                    DEFAULT 'ORIGINAL';
   g_hdr_attribute_category         xxkhd_po_hdr.attribute_category%TYPE            DEFAULT 'PO Service';
   g_dtl_line_attribute_category     XXKHD_po_line.line_attribute_category_lines%TYPE DEFAULT 'PO Service';
   g_dtl_shipment_attr_category       XXKHD_po_line.shipment_attribute_category%TYPE   DEFAULT 'PO Service';
   g_dtl_line_type              XXKHD_po_line.line_type%TYPE              DEFAULT 'Goods';
   g_dtl_action               XXKHD_po_line.action%TYPE               DEFAULT 'ADD';
   g_dist_attribute_category     XXKHD_po_dist.attribute_category%TYPE         DEFAULT 'PO Service';

   ----PROGRAM-------------------------------------------------
   ------------------------------------------------------------    
   
   PROCEDURE generate_po_service(
             p_errbuf          OUT VARCHAR2,
             p_retcode         OUT NUMBER,
             p_start_date     VARCHAR2,
             p_end_date     VARCHAR2,
             p_validate     VARCHAR2,
             p_debug      VARCHAR2);

   -- TRX CURSOR ---------------------------------------------- 
   ------------------------------------------------------------   
   
   CURSOR trx_hdr_cur(p_batch_id VARCHAR2) IS
      SELECT po_header_id,
      segment1      po_number,
      attribute9    interface_header_id
      FROM   PO_HEADERS_ALL
   WHERE  attribute8 = p_batch_id;

   CURSOR trx_line_cur(p_batch_id VARCHAR2) IS
      SELECT po_line_id,
      attribute4 interface_line_id
      FROM   PO_LINES_ALL
   WHERE  attribute3 = p_batch_id;

   CURSOR trx_ship_cur(p_batch_id VARCHAR2) IS
      SELECT line_location_id,
      attribute4 interface_line_id
      FROM   PO_LINE_LOCATIONS_ALL
   WHERE  attribute3 = p_batch_id;

   CURSOR trx_dist_cur(p_batch_id VARCHAR2) IS
      SELECT po_distribution_id,
      attribute4 interface_distribution_id
      FROM   PO_DISTRIBUTIONS_ALL
   WHERE  attribute3 = p_batch_id;

   -- SYNCH CURSOR -------------------------------------------- 
   ------------------------------------------------------------ 
   
   CURSOR hdr_status_cur(p_batch_id PLS_INTEGER)  IS
      SELECT po_status,
      interface_header_id
      FROM   XXKHD_PO_HDR
   WHERE  batch_id = p_batch_id
   ORDER BY interface_header_id;   

   -- SOURCE  CURSOR ------------------------------------------ 
   ------------------------------------------------------------ 
   
   CURSOR source_hdr_cur(p_organization_id PLS_INTEGER DEFAULT NULL)  IS
      SELECT RCV.shipment_header_id,
      RCV.organization_id,
      hdr.packing_slip,
      hdr.comments
      FROM
             RCV_TRANSACTIONS     rcv,
    RCV_SHIPMENT_HEADERS hdr,
        RCV_SHIPMENT_LINES   dtl,
        MTL_SYSTEM_ITEMS_B   itm,
            (SELECT INV.organization_id
             FROM   HR_ORGANIZATION_INFORMATION_V INV,
                    HR_ORGANIZATION_INFORMATION_V ACC
             WHERE  UPPER(INV.org_information1) IN ('INV')
             AND    UPPER(ACC.org_information_context) IN ('ACCOUNTING INFORMATION')
             AND    ACC.organization_id  = INV.organization_id
             AND    INV.organization_id  = NVL(p_organization_id, INV.organization_id)    
             AND    ACC.org_information3 = TO_CHAR(Fnd_Global.org_id /* 996 */)
            ) INV_OU
      WHERE
                   RCV.organization_id      = INV_OU.organization_id
   AND     DTL.shipment_header_id   = HDR.shipment_header_id       
   AND     RCV.shipment_line_id  = DTL.shipment_line_id
   AND     RCV.organization_id  = ITM.organization_id
   AND     DTL.item_id    = ITM.inventory_item_id
   AND     ITM.hazard_class_id  = g_hazard_class_id
   AND     RCV.organization_id IN ( 
                 SELECT ORG.organization_id 
                 FROM   HR_ALL_ORGANIZATION_UNITS org 
                 WHERE  ORG.attribute_category = 'Organization Type' 
        AND ORG.attribute1     <> 'O')      
   AND     DTL.from_organization_id IN (
                 SELECT ORG.organization_id
                 FROM   HR_ALL_ORGANIZATION_UNITS org
                 WHERE  ORG.attribute_category = 'Organization Type'
        AND ORG.attribute1     = 'O')   
   AND        RCV.source_document_code = 'REQ'
      AND        RCV.transaction_type IN ('DELIVER')
      AND        RCV.transaction_date BETWEEN g_start_date AND g_end_date
    AND     HDR.attribute3 IS NULL
   AND     DTL.attribute3 IS NULL
   AND     RCV.attribute3 IS NULL
   --AND     RCV.shipment_header_id NOT IN (263840, 263747, 264634, 263603, 264537)
   --AND hdr.receipt_num IN ('10115') --'10110','10113','10114','10116',       
   -- ++ Updated By ABP : 2012-01-30
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 34685 di exclude di proses PO Fee (TIDAK DIPEROSES)
   -- ++ Updated By ABP : 2012-02-27
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 35028 di exclude di proses PO Fee (TIDAK DIPEROSES)
   -- ++ Updated By ABP : 2012-05-31
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 38644 di exclude di proses PO Fee (TIDAK DIPEROSES)
   -- ++ Updated By ABP : 2012-08-16
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 41937 di exclude di proses PO Fee (TIDAK DIPEROSES)
   -- ++ Updated By SPT : 2012-09-27
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 41937 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2012-10-19
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 41937 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2013-02-20
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 47985 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2013-02-25
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 48176 di exclude di proses PO Fee
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 55608 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2013-09-18
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 58643 di exclude di proses PO Fee
   -- ++ Updated By ABP : 2013-11-27
      -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 64866 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2014-4-14
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 70125 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2014-8-15
      -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 78073 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-2-13
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 79344 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-2-27
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 85254 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-6-29
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 91839 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-11-17
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 94603 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-12-28
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 94680 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2015-12-30
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 100969 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-3-23
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No.'100965','100977','100979','100990','100994','100996','100997','101004','101007','101008','101015','101026','101059','101079'
    -- di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-3-24
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 101151 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-3-30
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 105222, 105422 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-5-20
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 106833, 106847 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-5-31
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 114859, 114861 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-8-31
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 115912, 115916 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-9-20
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 116989 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-9-22
   -- ++ krn kesalahan penerimaan (USER) untuk rcv No. 120797 di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-11-10
   -- ++ krn kesalahan penerimaan (Della) untuk rcv No. '120974','121496' di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-11-15
   -- ++ krn kesalahan penerimaan (Della) untuk rcv No. '122249' di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-11-22
   -- ++ krn kesalahan penerimaan (Della) untuk rcv No. '125118' di exclude di proses PO Fee
   -- ++ Updated By SPT : 2016-11-30
   AND hdr.receipt_num NOT IN ('34685','35028','38644','41937','43199','43808','43810','47895','48176','55608','58643'
   ,'64866','70125','78073','79344','85254','91839','94603','94680','100969','100965','100977','100979','100990'
   ,'100994','100996','100997','101004','101007','101008','101015','101026','101059','101079','101151','105222','105422','106833','106847'
   ,'114859','114861','115912','115916','116989','120797','120974','121496','122249','125118')    
   -- ++ Updated By ABP : 2012-01-30   
   GROUP BY RCV.organization_id, RCV.shipment_header_id, hdr.packing_slip ,hdr.comments;

   CURSOR source_trx_cur(p_shipment_header_id PLS_INTEGER) IS
      SELECT ITM.segment1 item_code,
      DTL.from_organization_id,
    DTL.item_id,
--    DTl.shipment_line_id,
    ITM.primary_uom_code,
    RCV.unit_of_measure,
--    decode( nvl(RCV.location_id,0), 0, HDR.ship_to_location_id, RCV.location_id) ship_to_location_id, 
             SUM(RCV.quantity) quantity
      FROM
             RCV_SHIPMENT_HEADERS hdr,
             RCV_SHIPMENT_LINES   dtl,
             RCV_TRANSACTIONS     rcv,
        MTL_SYSTEM_ITEMS_B   itm
      WHERE
                   DTL.shipment_header_id       = HDR.shipment_header_id
      AND        RCV.shipment_line_id         = DTL.shipment_line_id
   AND     DTL.from_organization_id  = ITM.organization_id
   AND     DTL.item_id     = ITM.inventory_item_id
   AND     ITM.hazard_class_id   = g_hazard_class_id
   AND     RCV.organization_id IN ( 
                 SELECT ORG.organization_id 
                 FROM   HR_ALL_ORGANIZATION_UNITS org 
                 WHERE  ORG.attribute_category = 'Organization Type' 
        AND ORG.attribute1     <> 'O')      
   AND     DTL.from_organization_id IN (
                 SELECT ORG.organization_id
                 FROM   HR_ALL_ORGANIZATION_UNITS org
                 WHERE  ORG.attribute_category = 'Organization Type'
        AND ORG.attribute1     = 'O')    
   AND     RCV.shipment_header_id       = p_shipment_header_id
   AND          RCV.source_document_code  = 'REQ'
      AND        RCV.transaction_type IN ('DELIVER')
      AND        RCV.transaction_date BETWEEN g_start_date AND g_end_date
   AND     HDR.attribute3 IS NULL
   AND     DTL.attribute3 IS NULL
   AND     RCV.attribute3 IS NULL
--   and     RCV.shipment_header_id in (8031)
   GROUP BY 
      ITM.segment1,
      DTL.from_organization_id,
--    DTL.to_organization_id,
    DTL.item_id,
    ITM.primary_uom_code,
    RCV.unit_of_measure
--    DTl.shipment_line_id
--    decode( nvl(RCV.location_id,0), 0, HDR.ship_to_location_id, RCV.location_id)     
   ORDER BY ITM.segment1; 

END; 
/

