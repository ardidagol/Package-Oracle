DROP TABLE XXSHP.XXSHP_INV_MFG_PARTS_STG CASCADE CONSTRAINTS;

CREATE TABLE XXSHP.XXSHP_INV_MFG_PARTS_STG
(
  FILE_ID                       NUMBER,
  FILE_NAME                     VARCHAR2(100 BYTE),
  MANUFACTURER_GROUP            VARCHAR2(200 BYTE),
  MANUFACTURER_NAME             VARCHAR2(200 BYTE),
  DESCRIPTION                   VARCHAR2(200 BYTE),
  COUNTRY                       VARCHAR2(60 BYTE),
  FACTORY_CODE                  VARCHAR2(60 BYTE),
  COMMENTS                      VARCHAR2(300 BYTE),
  MFG_STATUS                    VARCHAR2(25 BYTE),
  VENDOR_NAME                   VARCHAR2(60 BYTE),
  VENDOR_ID                     NUMBER,
  VENDOR_SITE_CODE              VARCHAR2(60 BYTE),
  VENDOR_SITE_ID                NUMBER,
  STATUS_MANUFACTURER           VARCHAR2(1 BYTE),
  MESSAGE_MANUFACTURER          VARCHAR2(2000 BYTE),
  MFG_PART_NUM                  VARCHAR2(60 BYTE),
  ITEM_CODE                     VARCHAR2(60 BYTE),
  ORG_CODE                      VARCHAR2(60 BYTE),
  ALLERGEN_NUM                  VARCHAR2(60 BYTE),
  ALLERGEN_VALID_TO             DATE,
  CERTIFICATE_MD_NUM            VARCHAR2(60 BYTE),
  CERTIFICATE_MD_VALID_TO       DATE,
  AKASIA_NUM                    VARCHAR2(150 BYTE),
  PROD_QM_VERSION               VARCHAR2(150 BYTE),
  PROD_QM_VALID_TO              DATE,
  ORGANIC_CERTIFICATE_NUM       VARCHAR2(60 BYTE),
  ORGANIC_CERTIFICATE_VALID_TO  DATE,
  ORGANIC_BODY                  VARCHAR2(60 BYTE),
  NEED_HALAL_CERTIFICATE        VARCHAR2(50 BYTE),
  HALAL_CERTIFICATE_NUM         VARCHAR2(100 BYTE),
  HALAL_CERTIFICATE_VALID_TO    DATE,
  HALAL_LOGO                    VARCHAR2(25 BYTE),
  HALAL_BODY                    VARCHAR2(50 BYTE),
  STATUS_MPN                    VARCHAR2(1 BYTE),
  MESSAGE_MPN                   VARCHAR2(2000 BYTE),
  FLAG                          VARCHAR2(1 BYTE),
  STATUS                        VARCHAR2(1 BYTE),
  CREATED_BY                    NUMBER          DEFAULT -1,
  CREATION_DATE                 DATE            DEFAULT SYSDATE,
  LAST_UPDATED_BY               NUMBER          DEFAULT -1,
  LAST_UPDATE_DATE              DATE            DEFAULT SYSDATE,
  LAST_UPDATE_LOGIN             NUMBER          DEFAULT -1
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


CREATE OR REPLACE SYNONYM APPS.XXSHP_INV_MFG_PARTS_STG FOR XXSHP.XXSHP_INV_MFG_PARTS_STG;
