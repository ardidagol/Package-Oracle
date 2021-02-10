CREATE OR REPLACE PACKAGE APPS.xxshp_po_rcv_tollfee_pkg
   AUTHID CURRENT_USER
/* $Header: xxshp_po_rcv_tollfee_pkg.pks 122.5.1.0 2017/02/08 10:34:00 Puguh MS $ */
AS
   /**************************************************************************************************
      NAME: xxshp_po_rcv_tollfee_pkg
      PURPOSE:

      REVISIONS:
      Ver         Date                 Author              Description
      ---------   ----------          ---------------     ------------------------------------
      1.0         08-Feb-2017          Puguh MS            1. Created this package
  **************************************************************************************************/
   g_resp_appl_id      NUMBER DEFAULT fnd_global.resp_appl_id;
   g_resp_id           NUMBER DEFAULT fnd_global.resp_id;
   g_conc_program_id   NUMBER DEFAULT fnd_global.conc_program_id;
   g_conc_request_id   NUMBER DEFAULT fnd_global.conc_request_id;
   g_org_id            NUMBER DEFAULT fnd_global.org_id;
   g_user_id           NUMBER DEFAULT fnd_global.user_id;
   g_username          VARCHAR2 (100) DEFAULT fnd_global.user_name;
   g_login_id          NUMBER := fnd_global.login_id;

   PROCEDURE main_process (errbuf           OUT VARCHAR2,
                           retcode          OUT NUMBER,
                           p_trx_id             NUMBER,
                           p_po_header_id       NUMBER);
END xxshp_po_rcv_tollfee_pkg;
/
