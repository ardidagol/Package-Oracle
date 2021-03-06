DROP VIEW XXMKT.XXMKT_FA_SERIAL_NUM_STG#;

/* Formatted on 7/28/2020 2:13:35 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE EDITIONING VIEW XXMKT.XXMKT_FA_SERIAL_NUM_STG#
(
   BOOK_TYPE_CODE,
   EXPENSE_CODE_COMBINATION_ID,
   VENDOR_ID,
   PO_NUMBER,
   RECEIPT_NUMBER,
   RECEIPT_DATE,
   PO_LINE,
   DESCRIPTION,
   ASSET_CATEGORY_ID,
   FIXED_ASSETS_UNITS,
   LOCATION_ID,
   FIXED_ASSETS_COST,
   DATE_PLACED_IN_SERVICE,
   SERIAL_NUMBER,
   REQUEST_ID,
   STATUS,
   ERROR_MESSAGE,
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_DATE,
   LAST_UPDATE_LOGIN
)
AS
   SELECT BOOK_TYPE_CODE BOOK_TYPE_CODE,
          EXPENSE_CODE_COMBINATION_ID EXPENSE_CODE_COMBINATION_ID,
          VENDOR_ID VENDOR_ID,
          PO_NUMBER PO_NUMBER,
          RECEIPT_NUMBER RECEIPT_NUMBER,
          RECEIPT_DATE RECEIPT_DATE,
          PO_LINE PO_LINE,
          DESCRIPTION DESCRIPTION,
          ASSET_CATEGORY_ID ASSET_CATEGORY_ID,
          FIXED_ASSETS_UNITS FIXED_ASSETS_UNITS,
          LOCATION_ID LOCATION_ID,
          FIXED_ASSETS_COST FIXED_ASSETS_COST,
          DATE_PLACED_IN_SERVICE DATE_PLACED_IN_SERVICE,
          SERIAL_NUMBER SERIAL_NUMBER,
          REQUEST_ID REQUEST_ID,
          STATUS STATUS,
          ERROR_MESSAGE ERROR_MESSAGE,
          CREATED_BY CREATED_BY,
          CREATION_DATE CREATION_DATE,
          LAST_UPDATED_BY LAST_UPDATED_BY,
          LAST_UPDATE_DATE LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN LAST_UPDATE_LOGIN
     FROM "XXMKT"."XXMKT_FA_SERIAL_NUM_STG";


CREATE OR REPLACE SYNONYM APPS.XXMKT_FA_SERIAL_NUM_STG FOR XXMKT.XXMKT_FA_SERIAL_NUM_STG#;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, READ, DEBUG ON XXMKT.XXMKT_FA_SERIAL_NUM_STG# TO APPS WITH GRANT OPTION;
