/* Formatted on 12/28/2020 11:12:00 AM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE PACKAGE APPS.xxshp_upd_crt_po_pkg
   AUTHID CURRENT_USER
AS
   /*
      REM +=========================================================================================================+
      REM |                                    Copyright (C) 2017  KNITERS                                          |
      REM |                                        All rights Reserved                                              |
      REM +=========================================================================================================+
      REM |                                                                                                         |
      REM |     Program Name: XXSHP_UPD_CRT_PO.pks                                                                  |
      REM |     Concurrent  : SHP - Uploader Create Purchase Orders                                                 |
      REM |     Parameters  :                                                                                       |
      REM |     Description : Planning Parameter New all in this Package                                            |
      REM |     History     : 1 OCT 2020  --Ardianto--                                                              |
      REM |     Proposed    :                                                                                       |
      REM |     Updated     :                                                                                       |
      REM +---------------------------------------------------------------------------------------------------------+
      */
   g_resp_appl_id                  NUMBER DEFAULT fnd_global.resp_appl_id;
   g_resp_id                       NUMBER DEFAULT fnd_global.resp_id;
   g_conc_program_id               NUMBER DEFAULT fnd_global.conc_program_id;
   g_conc_request_id               NUMBER DEFAULT fnd_global.conc_request_id;
   g_org_id                        NUMBER DEFAULT fnd_global.org_id;
   g_user_id                       NUMBER DEFAULT fnd_global.user_id;
   g_username                      VARCHAR2 (100) DEFAULT fnd_global.user_name;
   g_login_id                      NUMBER := fnd_global.login_id;
   g_end_date                      DATE;

   g_set_of_books_id               PLS_INTEGER
                                      DEFAULT Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');
   g_max_time                      PLS_INTEGER DEFAULT 259200;       --3 hari.
   g_intval_time                   PLS_INTEGER DEFAULT 4;

   g_hdr_revision_num              NUMBER DEFAULT 0;
   g_hdr_action                    VARCHAR2 (20) DEFAULT 'ORIGINAL';
   g_dtl_line_type                 VARCHAR2 (50) DEFAULT 'Goods';
   g_dtl_action                    VARCHAR2 (10) DEFAULT 'ADD';
   g_conversion_rate_type          VARCHAR2 (50) DEFAULT 'Corporate';

   g_debug                         VARCHAR2 (1) DEFAULT 'N';
   e_exception                     EXCEPTION;
   e_bohong                        EXCEPTION;

   TYPE mesg_rec_type IS RECORD (mesg VARCHAR2 (100));

   TYPE mesg_tab_type IS TABLE OF mesg_rec_type
      INDEX BY BINARY_INTEGER;

   cust_mesg                       mesg_tab_type;

   CURSOR valid_pr_po_hdr (
      p_file_id    NUMBER)
   IS
      SELECT pha.po_header_id,
             pha.segment1 po_number,
             phi.interface_header_id
        FROM po_headers_interface phi,
             xxshp_upd_po_stg stg,
             po_headers_all pha
       WHERE     phi.interface_header_id = stg.interface_header_id
             AND pha.po_header_id = phi.po_header_id
             AND stg.file_id = p_file_id;

   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
      INDEX BY BINARY_INTEGER;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER);
END xxshp_upd_crt_po_pkg;
/