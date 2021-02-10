CREATE OR REPLACE PACKAGE APPS.XXSHP_DAILY_INTR_DATA_PKG
IS
/* Created By GDS 25-JUL-2019 */
   PROCEDURE insert_data(errbuf      OUT VARCHAR2,
                       retcode     OUT NUMBER);
END;
/
