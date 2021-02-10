DROP TABLE XXSHP.XXSHP_TRX_SMPL_GIMMICK_STG CASCADE CONSTRAINTS;

CREATE TABLE XXSHP.XXSHP_TRX_SMPL_GIMMICK_STG
(
  FILE_ID                    NUMBER             NOT NULL,
  FILE_NAME                  VARCHAR2(200 BYTE) NOT NULL,
  SET_PROCESS_ID             NUMBER,
  REFERENCE_NO               VARCHAR2(100 BYTE),
  DESCRIPTION                VARCHAR2(400 BYTE),
  CURRENCY_CODE              CHAR(5 BYTE),
  AMOUNT                     NUMBER,
  CUSTOMER_NAME              VARCHAR2(240 BYTE),
  BILL_TO                    VARCHAR2(240 BYTE),
  SHIP_TO                    VARCHAR2(240 BYTE),
  TRX_DATE                   DATE,
  TRX_NUMBER                 VARCHAR2(100 BYTE),
  LINE_NUMBER                NUMBER,
  QUANTITY                   NUMBER,
  INTERFACE_LINE_ATTRIBUTE3  VARCHAR2(200 BYTE),
  UNIT_SELLING_PRICE         NUMBER,
  FLAG                       CHAR(1 BYTE),
  STATUS                     CHAR(1 BYTE),
  ERROR_MESSAGE              VARCHAR2(4000 BYTE),
  CREATED_BY                 NUMBER             DEFAULT -1                    NOT NULL,
  CREATION_DATE              DATE               DEFAULT SYSDATE               NOT NULL,
  LAST_UPDATED_BY            NUMBER             DEFAULT -1                    NOT NULL,
  LAST_UPDATE_DATE           DATE               DEFAULT SYSDATE               NOT NULL,
  LAST_UPDATE_LOGIN          NUMBER             DEFAULT -1                    NOT NULL,
  TRANSACTION_TYPE           VARCHAR2(50 BYTE)
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


CREATE OR REPLACE SYNONYM APPS.XXSHP_TRX_SMPL_GIMMICK_STG FOR XXSHP.XXSHP_TRX_SMPL_GIMMICK_STG;
