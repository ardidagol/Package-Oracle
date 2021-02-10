CREATE OR REPLACE PACKAGE APPS.xxmkt_sequences_pkg AUTHID CURRENT_USER
/* $Header: xxmkt_sequences_pkg.pks 122.5.1.6 2017/03/01 15:25:00 Edi Yanto $ */
AS
    /**************************************************************************************************
       NAME: xxmkt_sequences_pkg
       PURPOSE:

       REVISIONS:
       Ver         Date                 Author              Description
       ---------   ----------          ---------------     ------------------------------------
       1.0         01-Nov-2016          Edi Yanto           1. Created this package.
       1.1         27-Dec-2016          Edi Yanto           1. Add gen_ap_cmp_num procedure
       1.2         30-Dec-2016          Edi Yanto           1. Add gen_wms_lpn_lot_num and gen_wms_lpn_split_num procedures
       1.3         16-Jan-2017          Edi Yanto           1. Add g_wms_lpn_outbound_type
       1.4         24-Jan-2017          Edi Yanto           1. Add seq_type from GMD and gen_gmd_sample_num procedure
       1.5         26-Jan-2017          Edi Yanto           1. Add g_oe_spm_num and gen_oe_spm_num procedure
       1.6         01-Mar-2017          Edi Yanto           1. Add g_ap_rfp and gen_ap_rfp_num procedure
       1.7         13-Mar-2017          Edi Yanto           1. Add seq_type from QM (g_gmd_qa_inc, g_gmd_qa_inl, g_gmd_qa_inv, g_gmd_qa_ncr)
       1.8         20-Mar-2017          Edi Yanto           1. Add seq_type SALOK and gen_oe_surat_alokasi_num proc.
       1.9         15-Sep-2017          Michael Leonard     1. Add gen_ap_rfa_num and gen_ap_rfs_num
       2.0        27-Mar-2019           Michael Leonard     1. Add gen_custom_num
       2.1         06-JAN-2020          Michael Leonard     1. Add gen_opi_doc_num
   **************************************************************************************************/
   g_ledger_id               NUMBER        DEFAULT fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
   g_user_id                 NUMBER        DEFAULT fnd_global.user_id;
   g_resp_id                 NUMBER        DEFAULT fnd_global.resp_id;
   g_resp_appl_id            NUMBER        DEFAULT fnd_global.resp_appl_id;
   g_login_id                NUMBER        DEFAULT fnd_global.login_id;
   g_underlying_type         VARCHAR2 (3)  := 'UDL';
   g_cmp_type                VARCHAR2 (3)  := 'CMP';
   g_cmp_ppn                 VARCHAR2 (10) := 'PPN';
   g_cmp_non_ppn             VARCHAR2 (10) := 'NON-PPN';
   g_wms_lpn_type            VARCHAR2 (3)  := 'LPN';
   g_wms_lot_type            VARCHAR2 (3)  := 'LOT';
   g_wms_lpn_split_type      VARCHAR2 (10) := 'LPN-SPLIT';
   g_wms_lpn_outbound_type   VARCHAR2 (10) := 'LPN-OB';
   g_gmd_incoming            VARCHAR2 (10) := 'ICM';
   g_gmd_inline              VARCHAR2 (10) := 'BL';
   g_gmd_fg                  VARCHAR2 (10) := 'FG';
   g_gmd_monitoring          VARCHAR2 (10) := 'MN';
   g_gmd_ncr_sample          VARCHAR2 (10) := 'NCRS';
   g_gmd_sample_adm_req      VARCHAR2 (10) := 'SAR';
   g_oe_spm_num              VARCHAR2 (10) := 'SPM';
   g_wms_lpn_inv             VARCHAR2 (10) := 'LPN-INV';
   g_gmd_inc                 VARCHAR2 (10) := 'INC';
   g_gmd_inl                 VARCHAR2 (10) := 'INL';
   g_gmd_fgs                 VARCHAR2 (10) := 'FGS';
   g_gmd_inv                 VARCHAR2 (10) := 'INV';
   g_gmd_ncr                 VARCHAR2 (10) := 'NCR';
   g_ap_rfp                  VARCHAR2 (10) := 'RFP';
   g_ap_rfa                  VARCHAR2 (10) := 'RFA';
   g_ap_rfs                  VARCHAR2 (10) := 'RFS';
   g_ap_epay_sufin           VARCHAR2 (10) := 'ESF';
   g_gmd_grpkn               VARCHAR2 (10) := 'GRPKN';
   g_gmd_grplt               VARCHAR2 (10) := 'GRPLT';
   g_gmd_qa_inc              VARCHAR2 (10) := 'QA INC';
   g_gmd_qa_inl              VARCHAR2 (10) := 'QA INL';
   g_gmd_qa_ncr              VARCHAR2 (10) := 'QA NCR';
   g_gmd_qa_inv              VARCHAR2 (10) := 'QA TPP';
   g_oe_salok_num            VARCHAR2 (10) := 'SALOK';                                                                                --Surat Alokasi
   g_vms_sample              VARCHAR2 (10) := 'SAMPLE';
   g_vms_batch               VARCHAR2 (10) := 'BATCH';
   g_opi_doc_num             VARCHAR2 (10) := 'DOC_NUM';

   PROCEDURE gen_ce_underlying_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);

   PROCEDURE gen_ap_cmp_num (
      p_source          IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_trx_date        IN       DATE,
      p_ppn             IN       VARCHAR2 DEFAULT 'N',
      p_monthly_reset   IN       VARCHAR2,
      x_trx_num         OUT      VARCHAR2
   );

   PROCEDURE gen_wms_lpn_lot_num (p_source IN VARCHAR2, p_organization_id IN NUMBER, p_trx_date IN DATE, x_trx_num OUT VARCHAR2);

   PROCEDURE gen_wms_lpn_split_num (p_source_lpn IN VARCHAR2, p_organization_id IN NUMBER, x_trx_num OUT VARCHAR2);

   PROCEDURE gen_gmd_sample_num (
      p_source_code       IN       VARCHAR2,
      p_sample_type       IN       VARCHAR2,
      p_organization_id   IN       NUMBER,
      p_trx_date          IN       DATE,
      x_trx_num           OUT      VARCHAR2
   );

   PROCEDURE gen_oe_spm_num (p_source_code IN VARCHAR2, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2);

   PROCEDURE gen_ap_rfp_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_ap_rfa_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_ap_rfs_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_ap_epay_sufin_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);

   PROCEDURE gen_oe_surat_alokasi_num (
      p_source          IN       VARCHAR2,
      p_trx_date        IN       DATE,
      p_monthly_reset   IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_segment1        IN       VARCHAR2,
      p_segment2        IN       VARCHAR2,
      x_trx_num         OUT      VARCHAR2
   );
   
   PROCEDURE gen_table_b2b (p_source IN VARCHAR2, p_table_name IN VARCHAR2, p_start_seq_num IN NUMBER, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_table_custom (p_source IN VARCHAR2, p_table_name IN VARCHAR2, p_start_seq_num IN NUMBER, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_vms_sample_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_vms_batch_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_opi_doc_num (p_source IN VARCHAR2, p_lob_name IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
   
   PROCEDURE gen_star_mo_repl (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2);
END xxmkt_sequences_pkg;
/
