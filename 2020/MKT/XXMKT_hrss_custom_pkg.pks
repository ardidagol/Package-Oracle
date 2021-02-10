CREATE OR REPLACE PACKAGE APPS.xxmkt_hrss_custom_pkg
IS
   -- GLOBAL VARIABLE
   g_user_id             NUMBER;
   g_resp_id             NUMBER;
   g_resp_appl_id        NUMBER;
   g_group_security_id   NUMBER;
   g_server_id           NUMBER;
   g_max_time            PLS_INTEGER DEFAULT 259200;                 --3 hari.
   g_intval_time         PLS_INTEGER DEFAULT 4;
   x_access_id           NUMBER;
   x_file_id             NUMBER;

   TYPE result_set_type IS REF CURSOR;

   -- INITIALIZE
   PROCEDURE initialize_ap_concurrent;

   PROCEDURE initialize_pr_concurrent;

   -- RUN CONCURRENT
   PROCEDURE run_hrss_ap_concurrent (p_req_id OUT INT, p_batch_name VARCHAR2);

   PROCEDURE run_hrss_ap_validation (p_ret_id        OUT INT,
                                     p_req_id     IN     INT,
                                     p_batch_id   IN     INT);

   PROCEDURE run_hrss_print_ap_rfp (g_req_id       OUT INT,
                                    p_batch_from       VARCHAR2,
                                    p_batch_to         VARCHAR2,
                                    p_user             VARCHAR2);

   PROCEDURE run_hrss_print_ap_rfa (g_req_id       OUT INT,
                                    p_type             VARCHAR2,
                                    p_batch_name       VARCHAR2,
                                    p_user             VARCHAR2);

   -- Purchase Requisition
   PROCEDURE run_hrss_pr_concurrent (g_req_id2 OUT INT, p_batch_id INT);

   PROCEDURE run_hrss_print_requisition (g_req_id    OUT INT,
                                         p_req_num       VARCHAR2,
                                         p_user          VARCHAR2);

   -- ASSET MUTATION
   PROCEDURE initialize_asset_concurrent;

   PROCEDURE run_hrss_assetmutation (p_req_id OUT INT);

   PROCEDURE run_hrss_assetretirement (p_req_id            OUT INT,
                                       p_retirement_type       VARCHAR2);

   PROCEDURE run_hrss_assetsale (p_req_id            OUT INT,
                                 p_retirement_type       VARCHAR2);

   PROCEDURE run_hrss_assetaddition (p_req_id OUT INT);

   -- UPLOAD ATTACHMENT PR
   PROCEDURE add_attachment_api (x_status                     OUT NUMBER,
                                 p_file_name               IN     VARCHAR2,
                                 p_requisition_header_id   IN     NUMBER,
                                 p_description             IN     VARCHAR2);

   PROCEDURE processing_to_fnd_lobs (p_file_name IN VARCHAR2);

   --
   PROCEDURE load_file_details (p_name            IN     VARCHAR2,
                                result_set_curr      OUT result_set_type);

   FUNCTION confirm_upload (
      access_id          NUMBER,
      file_name          VARCHAR2,
      program_name       VARCHAR2 DEFAULT NULL,
      program_tag        VARCHAR2 DEFAULT NULL,
      expiration_date    DATE DEFAULT NULL,
      LANGUAGE           VARCHAR2 DEFAULT USERENV ('LANG'),
      wakeup             BOOLEAN DEFAULT FALSE)
      RETURN NUMBER;

   PROCEDURE upload_file (v_filename    IN     VARCHAR2,
                          x_access_id      OUT NUMBER,
                          x_file_id        OUT NUMBER);

   PROCEDURE attach_file (p_access_id               IN NUMBER,
                          p_file_id                 IN NUMBER,
                          p_filename                IN VARCHAR2,
                          p_requisition_header_id   IN NUMBER,
                          p_description             IN VARCHAR2);

   PROCEDURE initialize_application;

   PROCEDURE run_rcv_transactionprocessor (p_req_id        OUT INT,
                                           p_mode       IN     VARCHAR2,
                                           p_group_id   IN     VARCHAR2,
                                           p_org_id     IN     VARCHAR2);

   -- Cancel Requisition
   PROCEDURE cancel_req (p_req_num VARCHAR2, p_out OUT NUMBER);

   PROCEDURE cancel_req (p_req_num       VARCHAR2,
                         p_line          NUMBER,
                         p_out       OUT VARCHAR2);

   -- Close Requisition
   PROCEDURE close_req (p_req_num       VARCHAR2,
                        p_org_id        NUMBER,
                        p_reason        VARCHAR2,
                        p_out       OUT VARCHAR2);

   PROCEDURE close_req_line (p_req_num       VARCHAR2,
                             p_line          NUMBER,
                             p_org_id        NUMBER,
                             p_reason        VARCHAR2,
                             p_out       OUT VARCHAR2);

   -- Retur To Vendor
   PROCEDURE populate_return (p_rcv_transaction_id       NUMBER,
                              p_qty                      NUMBER,
                              p_dest_type                VARCHAR2,
                              p_trx_type                 VARCHAR2,
                              p_out                  OUT NUMBER);

   PROCEDURE submit_rcv_open_interface (p_rcv_transaction_id       NUMBER,
                                        p_qty                      NUMBER,
                                        p_dest_type                VARCHAR2,
                                        p_trx_type                 VARCHAR2,
                                        p_processing_mode          VARCHAR2,
                                        p_org_id                   NUMBER,
                                        p_roi_desc                 VARCHAR2,
                                        p_out                  OUT NUMBER);

   PROCEDURE insert_rcv_transactions_iface (
      p_rec   IN rcv_transactions_interface%ROWTYPE);

   FUNCTION wait_for_request_custom (
      request_id   IN            NUMBER DEFAULT NULL,
      INTERVAL     IN            NUMBER DEFAULT 60,
      max_wait     IN            NUMBER DEFAULT 0,
      phase           OUT NOCOPY VARCHAR2,
      status          OUT NOCOPY VARCHAR2,
      dev_phase       OUT NOCOPY VARCHAR2,
      dev_status      OUT NOCOPY VARCHAR2,
      MESSAGE         OUT NOCOPY VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION get_gl_codename (p_segment1 IN NUMBER)
      RETURN VARCHAR2;

   PROCEDURE get_dev_phase_status (phase_code    IN            VARCHAR2,
                                   status_code   IN            VARCHAR2,
                                   dev_phase        OUT NOCOPY VARCHAR2,
                                   dev_status       OUT NOCOPY VARCHAR2);

   PROCEDURE run_rcv_transactionprocessor (p_req_id        OUT INT,
                                           p_mode       IN     VARCHAR2,
                                           p_group_id   IN     VARCHAR2);
END;
/