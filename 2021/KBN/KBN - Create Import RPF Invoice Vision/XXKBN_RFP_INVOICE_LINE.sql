/* Formatted on 1/13/2021 3:31:01 PM (QP5 v5.256.13226.35538) */
DROP TABLE XXKBN.XXKBN_RFP_INVOICE_LINE CASCADE CONSTRAINTS;

CREATE TABLE XXKBN.XXKBN_RFP_INVOICE_LINE
(
   INVOICE_ID                 NUMBER,
   INVOICE_NUM                VARCHAR2 (100 BYTE),
   INVOICE_LINE_ID            NUMBER,
   LINE_NUMBER                NUMBER,
   LINE_TYPE_LOOKUP_CODE      VARCHAR2 (100 BYTE),
   AMOUNT                     NUMBER,
   ACCOUNTING_DATE            DATE,
   DESCRIPTION                VARCHAR2 (100 BYTE),
   DIST_CODE_COMBINATION_ID   NUMBER,
   DIST_CODE_CONCATENATED     VARCHAR2 (100 BYTE),
   ORG_ID                     NUMBER,
   ORG_CODE                   VARCHAR2 (10 BYTE),
   AWT_GROUP_NAME             VARCHAR2 (250 BYTE),
   VAT_CODE                   VARCHAR2 (250 BYTE),
   ATTRIBUTE1            VARCHAR2 (250 BYTE),
   ATTRIBUTE2            VARCHAR2 (250 BYTE),
   ATTRIBUTE3            VARCHAR2 (250 BYTE),
   ATTRIBUTE4            VARCHAR2 (250 BYTE),
   ATTRIBUTE5            VARCHAR2 (250 BYTE),
   ATTRIBUTE6            VARCHAR2 (250 BYTE),
   ATTRIBUTE7            VARCHAR2 (250 BYTE),
   ATTRIBUTE8            VARCHAR2 (250 BYTE),
   ATTRIBUTE9            VARCHAR2 (250 BYTE),
   ATTRIBUTE10           VARCHAR2 (250 BYTE),
   ATTRIBUTE11           VARCHAR2 (250 BYTE),
   ATTRIBUTE12           VARCHAR2 (250 BYTE),
   ATTRIBUTE13           VARCHAR2 (250 BYTE),
   ATTRIBUTE14           VARCHAR2 (250 BYTE),
   ATTRIBUTE15           VARCHAR2 (250 BYTE),
   ERROR_MSG                  VARCHAR2 (500),
   FLAG_PROCESS               VARCHAR2 (1),
   CREATED_BY                 NUMBER DEFAULT -1,
   CREATION_DATE              DATE DEFAULT SYSDATE,
   LAST_UPDATED_BY            NUMBER DEFAULT -1,
   LAST_UPDATE_DATE           DATE DEFAULT SYSDATE,
   LAST_UPDATE_LOGIN          NUMBER DEFAULT -1
)
TABLESPACE XXKBND
RESULT_CACHE (MODE DEFAULT)
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (MAXSIZE UNLIMITED
         PCTINCREASE 0
         BUFFER_POOL DEFAULT
         FLASH_CACHE DEFAULT
         CELL_FLASH_CACHE DEFAULT)
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;


CREATE OR REPLACE SYNONYM APPS.XXKBN_RFP_INVOICE_LINE FOR XXKBN.XXKBN_RFP_INVOICE_LINE;
