--DROP TABLE XXMKT.XXMKT_TEST_FILES CASCADE CONSTRAINTS;

CREATE TABLE XXMKT.XXMKT_TEST_FILES
(
  PL_ID    NUMBER,
  PL_NAME  VARCHAR2(100 BYTE),
  PL_FILE  BLOB
)
LOB (PL_FILE) STORE AS SECUREFILE (
  TABLESPACE  XXMKTX
  ENABLE      STORAGE IN ROW
  CHUNK       8192
  NOCACHE
  LOGGING
      STORAGE    (
                  INITIAL          128K
                  NEXT             128K
                  MINEXTENTS       1
                  MAXEXTENTS       UNLIMITED
                  PCTINCREASE      0
                  BUFFER_POOL      DEFAULT
                  FLASH_CACHE      DEFAULT
                  CELL_FLASH_CACHE DEFAULT
                 ))
TABLESPACE XXMKTX
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          40K
            NEXT             40K
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
