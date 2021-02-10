DROP TABLE XXSHP.XXSHP_UPD_PO_STG CASCADE CONSTRAINTS;

CREATE TABLE XXSHP.XXSHP_UPD_PO_STG
(
  FILE_ID              NUMBER                   NOT NULL,
  FILE_NAME            VARCHAR2(250 BYTE),
  BATCH_GROUP          VARCHAR2(250 BYTE),
  INTERFACE_HEADER_ID  NUMBER,
  PO_NUMBER            VARCHAR2(50 BYTE),
  ORGANIZATION_ID      NUMBER,
  ORGANIZATION_CODE    VARCHAR2(3 BYTE),
  VENDOR_NAME          VARCHAR2(250 BYTE),
  VENDOR_SITE_CODE     VARCHAR2(250 BYTE),
  SHIP_TO_LOCATION     VARCHAR2(250 BYTE),
  BILL_TO_LOCATION     VARCHAR2(250 BYTE),
  AGENT_NAME           VARCHAR2(100 BYTE),
  SHIP_TO_ORG_CODE     VARCHAR2(25 BYTE),
  CURRENCY_CODE        VARCHAR2(25 BYTE),
  OLD_PO_NUMBER        VARCHAR2(50 BYTE),
  BPA_NUMBER           VARCHAR2(250 BYTE),
  LINE_NUMBER          NUMBER,
  LINE_TYPE            VARCHAR2(25 BYTE),
  LINE_ACTION          VARCHAR2(25 BYTE),
  INVENTORY_ITEM_ID    NUMBER,
  ITEM_CODE            VARCHAR2(25 BYTE),
  ITEM_DESCRIPTION     VARCHAR2(240 BYTE),
  QUANTITY             NUMBER,
  UNIT_PRICE           NUMBER,
  UNIT_OF_MEASURE      VARCHAR2(25 BYTE),
  PROMISE_DATE         DATE,
  NEED_BY_DATE         DATE,
  SHIPMENT_NUMBER      VARCHAR2(25 BYTE),
  REQ_HEADER_REF_NUM   VARCHAR2(25 BYTE),
  REQ_LINE_REF_NUM     VARCHAR2(25 BYTE),
  DELIVER_TO_LOCATION  VARCHAR2(50 BYTE),
  DELIVER_TO_PERSON    VARCHAR2(50 BYTE),
  PO_STATUS            VARCHAR2(25 BYTE),
  FLAG                 VARCHAR2(1 BYTE),
  STATUS               VARCHAR2(250 BYTE),
  ERROR_MESSAGE        VARCHAR2(4000 BYTE),
  CREATED_BY           NUMBER,
  CREATION_DATE        DATE,
  LAST_UPDATE_DATE     DATE,
  LAST_UPDATED_BY      NUMBER,
  LAST_UPDATE_LOGIN    NUMBER
)
TABLESPACE XXSHPD
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          128K
            NEXT             128K
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE OR REPLACE SYNONYM APPS.XXSHP_UPD_PO_STG FOR XXSHP.XXSHP_UPD_PO_STG;
