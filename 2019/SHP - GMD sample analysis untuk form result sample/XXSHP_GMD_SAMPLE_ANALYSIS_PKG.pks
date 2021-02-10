CREATE OR REPLACE PACKAGE APPS.xxshp_gmd_sample_analysis_pkg
   AUTHID CURRENT_USER
/* $Header: xxshp_gmd_sample_analysis_pkg.pks 122.5.1.0 2017/1/26 14:03:10 Farry Ciptono $ */
AS
   /******************************************************************************
       NAME: xxshp_gmd_sample_analysis_pkg
       PURPOSE:
       402 Custom  Form    Sample Analysis In Scope            1. Form untuk pembuatan sampel Incoming/Inline/FG
       403  Custom   Form  Sample Analysis   In Scope       2. Pencatatan penerimaan sampel oleh Admin Requestor melalui hand scanner
       404  Custom   Form  Sample Analysis   In Scope       3. Pencatatan penerimaan sampel oleh Admin Laboratory melalui hand scanner
       405  Custom   Form  Sample Analysis   In Scope       4. Pencatatan penerimaan sampel oleh Admin Sub Lab melalui hand scanner
       406  Custom   Form  Sample Analysis   In Scope       5. Inquiry nomor sampel untuk input result sesuai Sub Lab (lab dashboard)

       REVISIONS:
       Ver         Date             Author                Description
       ---------   -----------      ---------------       ------------------------------------
       1.0         26-Jan-2016      Farry Ciptono         1. Created this package.
       1.2         10-Apr-2019 AND  Ardianto              1. i.target_value_char IS NOT NULL --comented
      ******************************************************************************/
   g_org_id                 NUMBER := fnd_profile.VALUE ('ORG_ID');
   g_user_id                NUMBER := fnd_profile.VALUE ('USER_ID');
   g_login_id               NUMBER := fnd_profile.VALUE ('LOGIN_ID');
   g_resp_id                NUMBER := fnd_profile.VALUE ('RESP_ID');
   g_application_id         NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   g_user_name              VARCHAR2 (100) := fnd_global.user_name;
   g_sample_desc            VARCHAR2 (50) := 'Automatic Sample Creation';
   g_delete_mark            NUMBER := 0;
   --g_source_supplier        VARCHAR2 (1) := 'S';
   --g_priority_normal        VARCHAR2 (2) := '5N';
   --g_disposition_planned    VARCHAR2 (3) := '0PL';
   g_type_inventory         VARCHAR2 (1) := 'I';
   --g_sample_inv_trans_ind   VARCHAR2 (1) := 'N';
   --g_sample_instance       number          := 1;
   g_sample_qty             NUMBER := 1;
   g_rdc_flag               BOOLEAN := FALSE;
   --g_sample_remaining      number          := 1;
   g_api_version            NUMBER := 3.0;
   g_find_matching_spec     VARCHAR2 (1) := 'Y';
   --g_item_opm_category      VARCHAR2 (25) := 'KFG INV GL Class';                                                                 -- 'KF OPM GL Class';
   g_err_msg                VARCHAR2 (2000);
   g_user_exception         EXCEPTION;

   PROCEDURE logf (p_msg IN VARCHAR2);

   PROCEDURE outf (p_msg IN VARCHAR2);

   PROCEDURE get_error_msg (p_msg_count IN NUMBER, p_msg_index IN OUT NUMBER, x_msg_data OUT VARCHAR2);

   FUNCTION is_number (p_str IN VARCHAR2)
      RETURN VARCHAR2
      DETERMINISTIC
      PARALLEL_ENABLE;

   FUNCTION get_status_desc (p_status VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_promise_date (p_received_date DATE, p_sample_id NUMBER)
      RETURN DATE;

   FUNCTION get_sample_source (p_sample_id NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_lab_promise_date (p_receive_date IN DATE, p_sublab IN VARCHAR2, p_leadtime NUMBER)
      RETURN DATE;
 FUNCTION get_lab_promise_date20180524 (p_receive_date IN DATE, p_sublab IN VARCHAR2, p_leadtime NUMBER)
      RETURN DATE;
   FUNCTION check_weekday (p_date DATE, p_day NUMBER)
      RETURN DATE;

   PROCEDURE update_result (p_hdr_id NUMBER, p_status OUT VARCHAR2, p_message OUT VARCHAR2);

   PROCEDURE update_lines (p_hdr_id       NUMBER,
                           p_line_id      NUMBER,
                           p_sample_id    NUMBER,
                           p_status       VARCHAR2,
                           p_msg          VARCHAR2);

   PROCEDURE insert_resample (p_hdr_id OUT NUMBER, p_sample_id IN NUMBER);

   PROCEDURE create_sample (p_hdr_id                     NUMBER,
                            p_line_id                    NUMBER,
                            p_rec                 IN     gmd_samples%ROWTYPE,
                            x_sampling_event_id      OUT NUMBER,
                            x_result                 OUT gmd_samples%ROWTYPE,
                            p_valid               IN OUT BOOLEAN);

   PROCEDURE run_process_create_sample (p_status           OUT VARCHAR2,
                                        p_message          OUT VARCHAR2,
                                        p_resample_id      OUT NUMBER,
                                        p_sample_id     IN     NUMBER);

   PROCEDURE update_void (p_status           OUT VARCHAR2,
                          p_message          OUT VARCHAR2,
                          p_resample_id   IN     NUMBER,
                          p_sample_id     IN     NUMBER);

   PROCEDURE add_test (p_status           OUT VARCHAR2,
                       p_message          OUT VARCHAR2,
                       p_resample_id   IN     NUMBER,
                       p_sample_id     IN     NUMBER);
END;
/
