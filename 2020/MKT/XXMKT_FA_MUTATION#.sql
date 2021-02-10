--DROP VIEW XXMKT.XXMKT_FA_MUTATION#;

/* Formatted on 8/4/2020 2:19:29 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE EDITIONING VIEW XXMKT.XXMKT_FA_MUTATION#
(
   BOOK_TYPE_CODE,
   SERIAL_NUMBER,
   DEPRE_CCID,
   LOCATION_ID,
   REQUEST_ID,
   ASSET_ID,
   TRANSACTION_HEADER_ID,
   STATUS,
   ERROR_MESSAGE,
   GROUP_ID,
   CREATED_BY,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN,
   CREATION_DATE,
   LAST_UPDATE_DATE
)
AS
   SELECT BOOK_TYPE_CODE BOOK_TYPE_CODE,
          SERIAL_NUMBER SERIAL_NUMBER,
          DEPRE_CCID DEPRE_CCID,
          LOCATION_ID LOCATION_ID,
          REQUEST_ID REQUEST_ID,
          ASSET_ID ASSET_ID,
          TRANSACTION_HEADER_ID TRANSACTION_HEADER_ID,
          STATUS STATUS,
          ERROR_MESSAGE ERROR_MESSAGE,
          GROUP_ID GROUP_ID,
          CREATED_BY CREATED_BY,
          LAST_UPDATED_BY LAST_UPDATED_BY,
          LAST_UPDATE_LOGIN LAST_UPDATE_LOGIN,
          CREATION_DATE CREATION_DATE,
          LAST_UPDATE_DATE LAST_UPDATE_DATE
     FROM "XXMKT"."XXMKT_FA_MUTATION";


CREATE OR REPLACE SYNONYM APPS.XXMKT_FA_MUTATION FOR XXMKT.XXMKT_FA_MUTATION#;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, READ, DEBUG ON XXMKT.XXMKT_FA_MUTATION# TO APPS WITH GRANT OPTION;
