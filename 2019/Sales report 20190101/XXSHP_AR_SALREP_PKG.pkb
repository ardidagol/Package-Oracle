CREATE OR REPLACE PACKAGE APPS.XXSHP_AR_SALREP_PKG
IS

   PROCEDURE Print_rep (
      errbuf           OUT   VARCHAR2,
      retcode          OUT   NUMBER,
      p_type                 VARCHAR2,
      p_period               VARCHAR2,
      p_start_so_num         VARCHAR2,
      p_end_so_num           VARCHAR2,
      p_start_cust           VARCHAR2,
      p_end_cust             VARCHAR2,
      p_org_id               NUMBER,
      p_username             VARCHAR2
   );

   FUNCTION Print_Sales_Order (
      p_period               VARCHAR2,
      p_start_so_num         VARCHAR2,
      p_end_so_num           VARCHAR2,
      p_start_cust           VARCHAR2,
      p_end_cust             VARCHAR2,
      p_org_id               NUMBER,
      p_username             VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION Print_Sales_Return (
      p_period               VARCHAR2,
      p_start_so_num         VARCHAR2,
      p_end_so_num           VARCHAR2,
      p_start_cust           VARCHAR2,
      p_end_cust             VARCHAR2,
      p_org_id               NUMBER,
      p_username             VARCHAR2
   )
   RETURN NUMBER;

   FUNCTION Print_Laporan_Barang_Retur (
      p_period               VARCHAR2,
      p_start_so_num         VARCHAR2,
      p_end_so_num           VARCHAR2,
      p_start_cust           VARCHAR2,
      p_end_cust             VARCHAR2,
      p_org_id               NUMBER,
      p_username             VARCHAR2
   )
   RETURN NUMBER;
END XXSHP_AR_SALREP_PKG;
/
