CREATE OR REPLACE PACKAGE BODY APPS.xxshp_gmd_sample_analysis_pkg
/* $Header: xxshp_gmd_sample_analysis_pkg.pkb 122.5.1.0 2017/1/26 14:03:10 Farry Ciptono $ */
AS
   /******************************************************************************
       NAME: xxshp_gmd_sample_analysis_pkg
       PURPOSE:
       402 Custom  Form    Sample Analysis    In Scope            1. Form untuk pembuatan sampel Incoming/Inline/FG
       403 Custom  Form    Sample Analysis    In Scope            2. Pencatatan penerimaan sampel oleh Admin Requestor melalui hand scanner
       404 Custom  Form    Sample Analysis    In Scope            3. Pencatatan penerimaan sampel oleh Admin Laboratory melalui hand scanner
       405 Custom  Form    Sample Analysis    In Scope            4. Pencatatan penerimaan sampel oleh Admin Sub Lab melalui hand scanner
       406 Custom  Form    Sample Analysis    In Scope            5. Inquiry nomor sampel untuk input result sesuai Sub Lab (lab dashboard)

       REVISIONS:
       Ver         Date             Author                Description
       ---------   -----------      ---------------       ------------------------------------
       1.0         26-Jan-2016      Farry Ciptono         1. Created this package.
       1.1         24-May-2018      Wilson Chandra        1.     
       1.2         10-Apr-2019 AND  Wrdianto              1. i.target_value_char IS NOT NULL --comented
      ******************************************************************************/
   PROCEDURE logf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
   --DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   --DBMS_OUTPUT.put_line (p_msg);
   END outf;

   PROCEDURE get_error_msg (p_msg_count   IN     NUMBER,
                            p_msg_index   IN OUT NUMBER,
                            x_msg_data       OUT VARCHAR2)
   IS
      l_msg             VARCHAR2 (2000);
      l_data            VARCHAR2 (2000);
      l_err             VARCHAR2 (2000);
      l_msg_index_out   NUMBER;
   BEGIN
      FOR i IN 1 .. p_msg_count - p_msg_index
      LOOP
         fnd_msg_pub.get (p_msg_index       => (p_msg_index + 1),
                          p_encoded         => fnd_api.g_false,
                          p_data            => l_data,
                          p_msg_index_out   => l_msg_index_out);
         l_msg := SUBSTR (l_msg || ',' || l_data, 1, 2000);
         logf (i || ':' || l_data);
         l_err := l_err || i || ':' || l_data;
      END LOOP;

      g_err_msg := l_err;
      p_msg_index := l_msg_index_out;
      x_msg_data := l_msg;
   END get_error_msg;

   FUNCTION is_number (p_str IN VARCHAR2)
      RETURN VARCHAR2
      DETERMINISTIC
      PARALLEL_ENABLE
   IS
      l_num   NUMBER;
   BEGIN
      l_num := TO_NUMBER (p_str);
      RETURN 'Y';
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN 'N';
   END is_number;

   FUNCTION get_status_desc (p_status VARCHAR2)
      RETURN VARCHAR2
   IS
      p_return   VARCHAR2 (80);
   BEGIN
      IF (p_status IS NOT NULL)
      THEN
         SELECT meaning
           INTO p_return
           FROM fnd_lookup_values flv, fnd_application fa
          WHERE     flv.view_application_id = fa.application_id
                AND fa.application_short_name = 'XXSHP'
                AND flv.lookup_type = 'XXSHP_GMD_SAMPLE_STATUS'
                AND flv.enabled_flag = 'Y'
                AND flv.lookup_code = p_status;
      ELSE
         p_return := NULL;
      END IF;

      RETURN p_return;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'error retrieving lookup status ' || SQLERRM;
   END get_status_desc;

   FUNCTION get_promise_date (p_received_date DATE, p_sample_id NUMBER)
      RETURN DATE
   IS
      v_promise_date   DATE;
   BEGIN
      SELECT xxshp_general_pkg.check_weekday (
                'QC CAL',
                (  p_received_date
                 + (SELECT MAX (NVL (days, 0))
                      FROM gmd_results gr, gmd_test_methods gtm
                     WHERE gr.sample_id = p_sample_id AND gr.test_method_id = gtm.test_method_id)))
        INTO v_promise_date
        FROM DUAL;

      RETURN v_promise_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_promise_date;

   FUNCTION get_sample_source (p_sample_id NUMBER)
      RETURN VARCHAR2
   IS
      v_sample_source   VARCHAR2 (30);
      v_sample_no       VARCHAR2 (80);
   BEGIN
      SELECT sample_no
        INTO v_sample_no
        FROM gmd_samples
       WHERE sample_id = p_sample_id;

      IF (v_sample_no IS NOT NULL)
      THEN
         BEGIN
            SELECT DISTINCT h.sample_source
              INTO v_sample_source
              FROM xxshp_gmd_smpl_crt_hdr h, xxshp_gmd_smpl_crt_lns l, gmd_samples gs
             WHERE     h.sample_hdr_id = l.sample_hdr_id --AND l.sample_no = v_sample_no --AND h.status = 'S'
                   AND gs.sample_id = p_sample_id
                   AND gs.sample_id = l.sample_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               SELECT lookup_code
                 INTO v_sample_source
                 FROM fnd_lookup_values
                WHERE lookup_type = 'XXSHP_GMD_SAMPLE_SOURCE' AND lookup_code = 'STANDARD';
            WHEN OTHERS
            THEN
               v_sample_source := NULL;
         END;
      ELSE
         v_sample_source := NULL;
      END IF;

      RETURN v_sample_source;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_sample_source;

   FUNCTION get_lab_promise_date (p_receive_date IN DATE, p_sublab IN VARCHAR2, p_leadtime NUMBER)
      RETURN DATE
   IS
      v_prom_date   DATE := NULL;
   BEGIN
      BEGIN
         /*IF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := p_receive_date + 1 + 16;
         ELSIF p_sublab = 'PHYSICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'INSTR' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 5);
         ELSIF p_sublab = 'CHEMICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'PCKG PHY' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'PCKG INS' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := p_receive_date + 16;
         ELSIF p_sublab = 'PHYSICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'INSTR' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 5);
         ELSIF p_sublab = 'CHEMICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'PCKG PHY' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'PCKG INS' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSE
            v_prom_date := p_receive_date;
         END IF;*/

         IF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, 1 + p_leadtime + 1);
         ELSIF p_sublab <> 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, 1 + p_leadtime + 1);
         ELSIF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, p_leadtime + 1);
         ELSIF p_sublab <> 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, p_leadtime + 1);
         ELSE
            v_prom_date := p_receive_date + 1;
         END IF;

         RETURN v_prom_date;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN p_receive_date;
      END;
   END get_lab_promise_date;
   
   
   
     FUNCTION get_lab_promise_date20180524 (p_receive_date IN DATE, p_sublab IN VARCHAR2, p_leadtime NUMBER)
      RETURN DATE
   IS
      v_prom_date   DATE := NULL;
   BEGIN
      BEGIN
         /*IF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := p_receive_date + 1 + 16;
         ELSIF p_sublab = 'PHYSICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'INSTR' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 5);
         ELSIF p_sublab = 'CHEMICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'PCKG PHY' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'PCKG INS' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 1 + 2);
         ELSIF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := p_receive_date + 16;
         ELSIF p_sublab = 'PHYSICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'INSTR' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 5);
         ELSIF p_sublab = 'CHEMICAL' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'PCKG PHY' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSIF p_sublab = 'PCKG INS' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := xxshp_general_pkg.check_weekday ('QC CAL', p_receive_date + 2);
         ELSE
            v_prom_date := p_receive_date;
         END IF;*/

         IF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := p_receive_date + 1 + p_leadtime + 1;
         ELSIF p_sublab <> 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') > '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, 1 + p_leadtime + 1);
         ELSIF p_sublab = 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := p_receive_date + p_leadtime + 1;
         ELSIF p_sublab <> 'MICRO' AND TO_CHAR (p_receive_date, 'HH24:MI:SS') <= '17:00:00'
         THEN
            v_prom_date := check_weekday (p_receive_date, p_leadtime + 1);
         ELSE
            v_prom_date := p_receive_date + 1;
         END IF;

         RETURN v_prom_date;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN p_receive_date;
      END;
   END get_lab_promise_date20180524;


   FUNCTION check_weekday (p_date DATE, p_day NUMBER)
      RETURN DATE
   IS
      v_date      DATE := NULL;
      v_weekend   NUMBER := 0;
   BEGIN
      BEGIN
         v_date := p_date;

         FOR i IN 1 .. p_day
         LOOP
            IF TO_CHAR (v_date, 'DY') IN ('SAT', 'SUN')
            THEN
               v_date := v_date + 1;
               v_weekend := v_weekend + 1;
            ELSE
               v_date := v_date + 1;
            END IF;
         END LOOP;

         v_date := v_date + v_weekend;
         v_weekend := 0;


         IF (TO_CHAR (v_date, 'DY') = 'SAT')
         THEN
            v_weekend := v_weekend + 2;
         ELSIF (TO_CHAR (v_date, 'DY') = 'SUN')
         THEN
            v_weekend := v_weekend + 1;
         END IF;

         v_date := v_date + v_weekend;

         RETURN v_date;
      EXCEPTION
         WHEN OTHERS
         THEN
            RETURN p_date;
      END;
   END check_weekday;

   PROCEDURE update_result (p_hdr_id NUMBER, p_status OUT VARCHAR2, p_message OUT VARCHAR2)
   IS
      v_result             VARCHAR2 (80);
      v_result_char        VARCHAR2 (80);
      v_result_num         NUMBER;
      v_prev_result_char   VARCHAR2 (80);
      v_prev_result_num    NUMBER;
      v_sample_id          NUMBER;
      v_total              NUMBER;
      v_accept             NUMBER;
      v_null               NUMBER;

      CURSOR c_data
      IS
         (SELECT gs.attribute25 sample_group,
                 gs.sample_id,
                 gr.result_id,
                 xgl.RESULT,
                 gqt.test_id,
                 xgl.inq_line_id,
                 xgh.organization_id,
                 NVL (gst.min_value_num, gqt.min_value_num) min_value_num,
                 NVL (gst.max_value_num, gqt.max_value_num) max_value_num,
                 gst.target_value_char,        --, xgl.last_updated_by user_id, xgl.last_update_login
                 gqt.test_type,
                 gst.min_value_char,
                 gst.max_value_char,
                 xgh.ORGANIZATION_ID org_id
            FROM xxshp_gmd_smpl_adm_inq_hdr xgh,
                 xxshp_gmd_smpl_adm_inq_line xgl,
                 gmd_qc_tests gqt,
                 gmd_test_classes gtc,
                 gmd_samples gs,
                 gmd_event_spec_disp gesd,
                 gmd_spec_tests gst,
                 gmd_test_methods gtm,
                 gmd_results gr,
                 gmd_spec_results gsr
           WHERE     xgh.inq_hdr_id = xgl.inq_hdr_id
                 AND xgh.sub_lab = gtc.test_class
                 AND xgl.result_id = gr.result_id
                 AND gqt.test_class = gtc.test_class
                 AND gqt.test_id = gst.test_id(+)
                 AND gs.sampling_event_id = gesd.sampling_event_id
                 AND gesd.spec_id = gst.spec_id(+)
                 AND gqt.test_class = gtc.test_class
                 AND gtm.test_method_id = gqt.test_method_id
                 AND gs.sample_id = gr.sample_id
                 AND gqt.test_id = gr.test_id
                 AND gr.result_id = gsr.result_id
                 AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                 AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                 AND xgh.inq_hdr_id = p_hdr_id
                 /* Start Update By MLR 29 Nov 2017 */
                 AND (   xgl.status IS NULL
                         OR (    xgl.status IS NOT NULL
                             AND NVL (gr.result_value_char,
                                      TO_CHAR (gr.result_value_num))
                                    IS NULL))
                 /* End Update By MLR 29 Nov 2017 */
--                 AND xgl.status IS NULL
                 AND xgl.start_date IS NOT NULL
                 AND xgl.end_date IS NOT NULL
                 AND xgl.RESULT IS NOT NULL);
   BEGIN
      p_status := 'S';
      p_message := 'Result updated successfully';

      FOR i IN c_data
      LOOP
         v_result_num := NULL;
         v_result_char := NULL;

         /*IF (xxshp_gmd_sample_analysis_pkg.is_number (i.RESULT) = 'Y')
         THEN
            v_result_num := TO_NUMBER (i.RESULT);
         ELSE
            v_result_char := i.RESULT;
         END IF;*/

         IF (i.test_type = 'V')
         THEN
            v_result_char := i.RESULT;
         ELSIF (i.test_type = 'N')
         THEN
            v_result_num := TO_NUMBER (i.RESULT);
         ELSIF (i.test_type = 'T')
         THEN
            v_result_char := i.RESULT;

            SELECT MAX (text_range_seq)
              INTO v_result_num
              FROM GMD_QC_TEST_VALUES
             WHERE test_id = i.test_id AND value_char = i.RESULT;
         END IF;


         -----------NUMBER-----------------
         IF (    i.test_type = 'N'
             AND v_result_num IS NOT NULL
             AND i.min_value_num IS NOT NULL
             AND i.max_value_num IS NOT NULL)
         THEN
            IF (v_result_num BETWEEN i.min_value_num AND i.max_value_num)
            THEN
               BEGIN
                  SELECT result_value_num
                    INTO v_prev_result_num
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_num = v_prev_result_num
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id
                                           AND gr.result_value_num IS NULL);

                     UPDATE gmd_results gr
                        SET result_value_num = v_result_num,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_num IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     UPDATE gmd_spec_results
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;

                     UPDATE gmd_results
                        SET result_value_num = v_result_num,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_num ' || SQLERRM;
               END;
            ELSE
               BEGIN
                  SELECT result_value_num
                    INTO v_prev_result_num
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_num = v_prev_result_num
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     /*UPDATE gmd_spec_results gsr
                      SET evaluation_ind = '1V',
                          --in_spec_ind = 'Y',
                          last_updated_by = g_user_id,
                          last_update_date = SYSDATE,
                          last_update_login = g_login_id
                    WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                          AND EXISTS
                                 (SELECT 1
                                    FROM gmd_qc_tests gqt,
                                         gmd_test_classes gtc,
                                         gmd_samples gs,
                                         gmd_event_spec_disp gesd,
                                         gmd_spec_tests gst,
                                         gmd_test_methods gtm,
                                         gmd_results gr
                                   WHERE     gqt.test_class = gtc.test_class
                                         AND gqt.test_id = gst.test_id(+)
                                         AND gs.sampling_event_id = gesd.sampling_event_id
                                         AND gesd.spec_id = gst.spec_id(+)
                                         AND gqt.test_class = gtc.test_class
                                         AND gtm.test_method_id = gqt.test_method_id
                                         AND gs.sample_id = gr.sample_id
                                         AND gqt.test_id = gr.test_id
                                         AND gr.result_id = gsr.result_id
                                         and gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                         AND gs.organization_id = i.organization_id
                                         AND gs.attribute25 = i.sample_group
                                         and  gqt.test_id = i.test_id
                                         );*/

                     UPDATE gmd_results gr
                        SET result_value_num = v_result_num,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_num IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     /*UPDATE gmd_spec_results
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;*/

                     UPDATE gmd_results
                        SET result_value_num = v_result_num,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_num ' || SQLERRM;
               END;
            END IF;
         ELSIF (    i.test_type = 'T'
                AND v_result_num IS NOT NULL
                AND i.min_value_num IS NOT NULL
                AND i.max_value_num IS NOT NULL)
         THEN
            IF (v_result_num BETWEEN i.min_value_num AND i.max_value_num)
            THEN
               BEGIN
                  SELECT result_value_num, result_value_char
                    INTO v_prev_result_num, v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_num = v_prev_result_num, prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id
                                           AND gr.result_value_num IS NULL);

                     UPDATE gmd_results gr
                        SET result_value_num = v_result_num,
                            result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_num IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     UPDATE gmd_spec_results
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;

                     UPDATE gmd_results
                        SET result_value_num = v_result_num,
                            result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_num ' || SQLERRM;
               END;
            ELSE
               BEGIN
                  SELECT result_value_num, result_value_char
                    INTO v_prev_result_num, v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_num = v_prev_result_num, prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     /*UPDATE gmd_spec_results gsr
                      SET evaluation_ind = '1V',
                          --in_spec_ind = 'Y',
                          last_updated_by = g_user_id,
                          last_update_date = SYSDATE,
                          last_update_login = g_login_id
                    WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                          AND EXISTS
                                 (SELECT 1
                                    FROM gmd_qc_tests gqt,
                                         gmd_test_classes gtc,
                                         gmd_samples gs,
                                         gmd_event_spec_disp gesd,
                                         gmd_spec_tests gst,
                                         gmd_test_methods gtm,
                                         gmd_results gr
                                   WHERE     gqt.test_class = gtc.test_class
                                         AND gqt.test_id = gst.test_id(+)
                                         AND gs.sampling_event_id = gesd.sampling_event_id
                                         AND gesd.spec_id = gst.spec_id(+)
                                         AND gqt.test_class = gtc.test_class
                                         AND gtm.test_method_id = gqt.test_method_id
                                         AND gs.sample_id = gr.sample_id
                                         AND gqt.test_id = gr.test_id
                                         AND gr.result_id = gsr.result_id
                                         and gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                         AND gs.organization_id = i.organization_id
                                         AND gs.attribute25 = i.sample_group
                                         and  gqt.test_id = i.test_id
                                         );*/

                     UPDATE gmd_results gr
                        SET result_value_num = v_result_num,
                            result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_num IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     /*UPDATE gmd_spec_results
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;*/

                     UPDATE gmd_results
                        SET result_value_num = v_result_num,
                            result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_num ' || SQLERRM;
               END;
            END IF;
         ----------------Character---------------------------
         ELSIF ( (    i.test_type = 'V'
                  AND v_result_char IS NOT NULL
                  --AND i.target_value_char IS NOT NULL --comented by Ardi 2019-04-10
                  ) --OR (i.test_type = 'T' AND v_result_char IS NOT NULL AND i.min_value_char IS NOT NULL AND i.max_value_char IS NOT NULL)
                                                      )
         THEN
            IF ( (i.test_type = 'V' AND v_result_char = i.target_value_char) --OR (i.test_type = 'T' AND v_result_char BETWEEN i.min_value_char AND i.max_value_char)
                                                                            )
            THEN
               BEGIN
                  SELECT result_value_char
                    INTO v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id
                                           AND gr.result_value_char IS NULL);

                     UPDATE gmd_results gr
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_char IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     UPDATE gmd_spec_results
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;

                     UPDATE gmd_results
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_char ' || SQLERRM;
               END;
            ELSE
               BEGIN
                  SELECT result_value_char
                    INTO v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     /*UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           and gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           and  gqt.test_id = i.test_id
                                           );*/
                     UPDATE gmd_results gr
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_char IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     /*UPDATE gmd_spec_results
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;*/

                     UPDATE gmd_results
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_char ' || SQLERRM;
               END;
            END IF;
         ELSIF ( (    i.test_type = 'V'
                  AND v_result_char IS NOT NULL
                  AND i.target_value_char IS NULL
                  AND i.org_id = 109) --OR (i.test_type = 'T' AND v_result_char IS NOT NULL AND i.min_value_char IS NOT NULL AND i.max_value_char IS NOT NULL)
                                                      )
         THEN
            IF ( (i.test_type = 'V' AND v_result_char IS NOT NULL) --OR (i.test_type = 'T' AND v_result_char BETWEEN i.min_value_char AND i.max_value_char)
                                                                            )
            THEN
               BEGIN
                  SELECT result_value_char
                    INTO v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id
                                           AND gr.result_value_char IS NULL);

                     UPDATE gmd_results gr
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_char IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     UPDATE gmd_spec_results
                        SET evaluation_ind = '0A',
                            in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;

                     UPDATE gmd_results
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_char ' || SQLERRM;
               END;
            ELSE
               BEGIN
                  SELECT result_value_char
                    INTO v_prev_result_char
                    FROM gmd_results
                   WHERE result_id = i.result_id;

                  UPDATE xxshp_gmd_smpl_adm_inq_line
                     SET prev_result_char = v_prev_result_char
                   WHERE inq_line_id = i.inq_line_id;

                  IF (i.sample_group LIKE 'GRPKN%')
                  THEN
                     /*UPDATE gmd_spec_results gsr
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_results gr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           and gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           and  gqt.test_id = i.test_id
                                           );*/
                     UPDATE gmd_results gr
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE     gr.result_value_char IS NULL
                            AND EXISTS
                                   (SELECT 1
                                      FROM gmd_qc_tests gqt,
                                           gmd_test_classes gtc,
                                           gmd_samples gs,
                                           gmd_event_spec_disp gesd,
                                           gmd_spec_tests gst,
                                           gmd_test_methods gtm,
                                           gmd_spec_results gsr
                                     WHERE     gqt.test_class = gtc.test_class
                                           AND gqt.test_id = gst.test_id(+)
                                           AND gs.sampling_event_id = gesd.sampling_event_id
                                           AND gesd.spec_id = gst.spec_id(+)
                                           AND gqt.test_class = gtc.test_class
                                           AND gtm.test_method_id = gqt.test_method_id
                                           AND gs.sample_id = gr.sample_id
                                           AND gqt.test_id = gr.test_id
                                           AND gr.result_id = gsr.result_id
                                           AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                                           AND (   gsr.evaluation_ind <> '5O'
                                                OR gsr.evaluation_ind IS NULL)
                                           AND gs.organization_id = i.organization_id
                                           AND gs.attribute25 = i.sample_group
                                           AND gqt.test_id = i.test_id);
                  ELSE
                     -- lookup : GMD_QC_EVALUATION
                     -- 0A = Accept
                     -- 2R = Reject
                     -- 1V = Accept with Variance
                     /*UPDATE gmd_spec_results
                        SET evaluation_ind = '1V',
                            --in_spec_ind = 'Y',
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;*/

                     UPDATE gmd_results
                        SET result_value_char = v_result_char,
                            result_date = SYSDATE,
                            tester_id = g_user_id,
                            last_updated_by = g_user_id,
                            last_update_date = SYSDATE,
                            last_update_login = g_login_id
                      WHERE result_id = i.result_id;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_status := 'E';
                     p_message := 'Error when updating result_value_char ' || SQLERRM;
               END;
            END IF;
         END IF;
      END LOOP;

      ---update sample_disposition
      FOR i
         IN (SELECT DISTINCT gs.sample_id, gs.attribute25 sample_group, xgh.organization_id
               FROM xxshp_gmd_smpl_adm_inq_hdr xgh,
                    xxshp_gmd_smpl_adm_inq_line xgl,
                    gmd_qc_tests gqt,
                    gmd_test_classes gtc,
                    gmd_samples gs,
                    gmd_event_spec_disp gesd,
                    gmd_spec_tests gst,
                    gmd_test_methods gtm,
                    gmd_results gr,
                    gmd_spec_results gsr
              WHERE     xgh.inq_hdr_id = xgl.inq_hdr_id
                    AND xgh.sub_lab = gtc.test_class
                    AND xgl.result_id = gr.result_id
                    AND gqt.test_class = gtc.test_class
                    AND gqt.test_id = gst.test_id(+)
                    AND gs.sampling_event_id = gesd.sampling_event_id
                    AND gesd.spec_id = gst.spec_id(+)
                    AND gqt.test_class = gtc.test_class
                    AND gtm.test_method_id = gqt.test_method_id
                    AND gs.sample_id = gr.sample_id
                    AND gqt.test_id = gr.test_id
                    AND gr.result_id = gsr.result_id
                    AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                    AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                    AND xgh.inq_hdr_id = p_hdr_id
                    /* Start Update By MLR 29 Nov 2017 */
--                    AND (   xgl.status IS NULL
--                         OR (    xgl.status IS NOT NULL
--                             AND NVL (gr.result_value_char,
--                                      TO_CHAR (gr.result_value_num))
--                                    IS NOT NULL)) -- Update By MLR jadi IS NOT NULL 12-Dec-2017
                    /* End Update By MLR 29 Nov 2017 */
                    AND xgl.status IS NULL
                    AND xgl.start_date IS NOT NULL
                    AND xgl.end_date IS NOT NULL
                    AND xgl.RESULT IS NOT NULL)
      LOOP
         BEGIN
            SELECT COUNT (1)
              INTO v_total
              FROM                                                 --xxshp_gmd_smpl_adm_inq_hdr xgh,
                   --xxshp_gmd_smpl_adm_inq_line xgl,
                   gmd_qc_tests gqt,
                   gmd_test_classes gtc,
                   gmd_samples gs,
                   gmd_event_spec_disp gesd,
                   gmd_spec_tests gst,
                   gmd_test_methods gtm,
                   gmd_results gr,
                   gmd_spec_results gsr
             WHERE     1 = 1
                   --AND xgh.inq_hdr_id = xgl.inq_hdr_id
                   --AND xgh.sub_lab = gtc.test_class
                   --AND xgl.result_id = gr.result_id
                   AND gqt.test_class = gtc.test_class
                   AND gqt.test_id = gst.test_id(+)
                   AND gs.sampling_event_id = gesd.sampling_event_id
                   AND gesd.spec_id = gst.spec_id(+)
                   AND gqt.test_class = gtc.test_class
                   AND gtm.test_method_id = gqt.test_method_id
                   AND gs.sample_id = gr.sample_id
                   AND gqt.test_id = gr.test_id
                   AND gr.result_id = gsr.result_id
                   AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                   AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                   AND gs.sample_id = i.sample_id;

            SELECT COUNT (1)
              INTO v_accept
              FROM                                                 --xxshp_gmd_smpl_adm_inq_hdr xgh,
                   --xxshp_gmd_smpl_adm_inq_line xgl,
                   gmd_qc_tests gqt,
                   gmd_test_classes gtc,
                   gmd_samples gs,
                   gmd_event_spec_disp gesd,
                   gmd_spec_tests gst,
                   gmd_test_methods gtm,
                   gmd_results gr,
                   gmd_spec_results gsr
             WHERE     1 = 1
                   --AND xgh.inq_hdr_id = xgl.inq_hdr_id
                   --AND xgh.sub_lab = gtc.test_class
                   --AND xgl.result_id = gr.result_id
                   AND gqt.test_class = gtc.test_class
                   AND gqt.test_id = gst.test_id(+)
                   AND gs.sampling_event_id = gesd.sampling_event_id
                   AND gesd.spec_id = gst.spec_id(+)
                   AND gqt.test_class = gtc.test_class
                   AND gtm.test_method_id = gqt.test_method_id
                   AND gs.sample_id = gr.sample_id
                   AND gqt.test_id = gr.test_id
                   AND gr.result_id = gsr.result_id
                   AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                   AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                   AND gs.sample_id = i.sample_id
                   --AND gsr.evaluation_ind = '0A'
                   AND gsr.evaluation_ind IS NOT NULL;

            SELECT COUNT (1)
              INTO v_null
              FROM                                                 --xxshp_gmd_smpl_adm_inq_hdr xgh,
                   --xxshp_gmd_smpl_adm_inq_line xgl,
                   gmd_qc_tests gqt,
                   gmd_test_classes gtc,
                   gmd_samples gs,
                   gmd_event_spec_disp gesd,
                   gmd_spec_tests gst,
                   gmd_test_methods gtm,
                   gmd_results gr,
                   gmd_spec_results gsr
             WHERE     1 = 1
                   --AND xgh.inq_hdr_id = xgl.inq_hdr_id
                   --AND xgh.sub_lab = gtc.test_class
                   --AND xgl.result_id = gr.result_id
                   AND gqt.test_class = gtc.test_class
                   AND gqt.test_id = gst.test_id(+)
                   AND gs.sampling_event_id = gesd.sampling_event_id
                   AND gesd.spec_id = gst.spec_id(+)
                   AND gqt.test_class = gtc.test_class
                   AND gtm.test_method_id = gqt.test_method_id
                   AND gs.sample_id = gr.sample_id
                   AND gqt.test_id = gr.test_id
                   AND gr.result_id = gsr.result_id
                   AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                   --AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                   AND gs.sample_id = i.sample_id
                   AND gsr.evaluation_ind IS NULL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_status := 'E';
               p_message := 'Error when count total result ' || SQLERRM;
         END;

         --GMD_QC_SAMPLE_DISP
         --LOOKUP_CODE  MEANING
         --1P  Pending
         --2I  In Progress
         --3C  Complete
         BEGIN
            IF (v_total = v_accept)
            THEN
               IF (i.sample_group LIKE 'GRPKN%')
               THEN
                  UPDATE gmd_sample_spec_disp gssd
                     SET disposition = '3C',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE EXISTS
                            (SELECT 1
                               FROM gmd_samples gs
                              WHERE     gs.sample_id = gssd.sample_id
                                    AND gs.organization_id = i.organization_id
                                    AND gs.attribute25 = i.sample_group);
               ELSE
                  UPDATE gmd_sample_spec_disp
                     SET disposition = '3C',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE sample_id = i.sample_id;
               END IF;
            ELSIF (v_total = v_null)
            THEN
               --NULL;
               IF (i.sample_group LIKE 'GRPKN%')
               THEN
                  UPDATE gmd_sample_spec_disp gssd
                     SET disposition = '2I',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE     disposition <> '2I'
                         AND EXISTS
                                (SELECT 1
                                   FROM gmd_samples gs
                                  WHERE     gs.sample_id = gssd.sample_id
                                        AND gs.organization_id = i.organization_id
                                        AND gs.attribute25 = i.sample_group);
               ELSE
                  UPDATE gmd_sample_spec_disp
                     SET disposition = '2I',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE sample_id = i.sample_id AND disposition <> '2I';
               END IF;
            ELSIF (v_total > v_accept)
            THEN
               IF (i.sample_group LIKE 'GRPKN%')
               THEN
                  UPDATE gmd_sample_spec_disp gssd
                     SET disposition = '2I',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE     disposition <> '2I'
                         AND EXISTS
                                (SELECT 1
                                   FROM gmd_samples gs
                                  WHERE     gs.sample_id = gssd.sample_id
                                        AND gs.organization_id = i.organization_id
                                        AND gs.attribute25 = i.sample_group);
               ELSE
                  UPDATE gmd_sample_spec_disp
                     SET disposition = '2I',
                         last_updated_by = g_user_id,
                         last_update_date = SYSDATE,
                         last_update_login = g_login_id
                   WHERE sample_id = i.sample_id AND disposition <> '2I';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_status := 'E';
               p_message := 'Error when update sample disposition ' || SQLERRM;
         END;
      END LOOP;

      IF (p_status = 'S')
      THEN
         FOR i
            IN (SELECT xgl.inq_line_id
                  FROM xxshp_gmd_smpl_adm_inq_hdr xgh,
                       xxshp_gmd_smpl_adm_inq_line xgl,
                       gmd_qc_tests gqt,
                       gmd_test_classes gtc,
                       gmd_samples gs,
                       gmd_event_spec_disp gesd,
                       gmd_spec_tests gst,
                       gmd_test_methods gtm,
                       gmd_results gr,
                       gmd_spec_results gsr
                 WHERE     xgh.inq_hdr_id = xgl.inq_hdr_id
                       AND xgh.sub_lab = gtc.test_class
                       AND xgl.result_id = gr.result_id
                       AND gqt.test_class = gtc.test_class
                       AND gqt.test_id = gst.test_id(+)
                       AND gs.sampling_event_id = gesd.sampling_event_id
                       AND gesd.spec_id = gst.spec_id(+)
                       AND gqt.test_class = gtc.test_class
                       AND gtm.test_method_id = gqt.test_method_id
                       AND gs.sample_id = gr.sample_id
                       AND gqt.test_id = gr.test_id
                       AND gr.result_id = gsr.result_id
                       AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                       AND (gsr.evaluation_ind <> '5O' OR gsr.evaluation_ind IS NULL)
                       AND xgh.inq_hdr_id = p_hdr_id
                       /* Start Update By MLR 29 Nov 2017 */
--                       AND (   xgl.status IS NULL
--                         OR (    xgl.status IS NOT NULL
--                             AND NVL (gr.result_value_char,
--                                      TO_CHAR (gr.result_value_num))
--                                    IS NOT NULL)) -- Update By MLR jadi IS NOT NULL 11-Des-2017
                       /* End Update By MLR 29 Nov 2017 */
                       AND xgl.status IS NULL
                       AND xgl.start_date IS NOT NULL
                       AND xgl.end_date IS NOT NULL
                       AND xgl.RESULT IS NOT NULL)
         LOOP
            UPDATE xxshp_gmd_smpl_adm_inq_line
               SET status = 'S',
                   last_updated_by = g_user_id,
                   last_update_date = SYSDATE,
                   last_update_login = g_login_id
             WHERE inq_line_id = i.inq_line_id;
         END LOOP;
      END IF;
   /*FOR i IN c_group
   LOOP
      IF (i.sample_group LIKE 'GRPKN%')
      THEN
         FOR j IN c_data_item_kn (i.sample_group)
         LOOP
            NULL;
         END LOOP;
      ELSIF (i.sample_group IS NULL)
      THEN
         FOR j IN c_data_non_kn (i.sample_group)
         LOOP
            NULL;
         END LOOP;
      ELSE
         FOR j IN c_data_non_kn_null
         LOOP
            NULL;
         END LOOP;
      END IF;
   END LOOP;*/
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := 'E';
         p_message := 'Error when run update_result ' || SQLERRM;
   END update_result;

   PROCEDURE update_lines (p_hdr_id       NUMBER,
                           p_line_id      NUMBER,
                           p_sample_id    NUMBER,
                           p_status       VARCHAR2,
                           p_msg          VARCHAR2)
   IS
   --PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE xxshp_gmd_smpl_crt_lns
         SET sample_id = NVL (p_sample_id, sample_id),
             status = p_status,
             error_msg = NVL (p_msg, error_msg)
       WHERE sample_line_id = p_line_id AND sample_hdr_id = p_hdr_id;

      COMMIT;
   END;

   PROCEDURE insert_resample (p_hdr_id OUT NUMBER, p_sample_id IN NUMBER)
   IS
      v_lns_id             NUMBER;
      v_count              NUMBER;
      v_sample_no          VARCHAR2 (80);
      v_length             NUMBER;
      v_last_char          VARCHAR2 (2);
      v_inserted_hdr_id    NUMBER;
      v_parent_sample      VARCHAR2 (80);
      v_parent_sample_id   VARCHAR2 (240);
      v_resample_id        NUMBER;
   BEGIN
      BEGIN
         --get last resample
         SELECT resample_id
           INTO v_resample_id
           FROM xxshp_gmd_smpl_inq_dsp_line
          WHERE sample_id = p_sample_id;

         IF (v_resample_id IS NOT NULL)
         THEN
            SELECT sample_no, attribute30
              INTO v_parent_sample, v_parent_sample_id
              FROM gmd_samples
             WHERE sample_id = v_resample_id;
         ELSE
            SELECT sample_no, attribute30
              INTO v_parent_sample, v_parent_sample_id
              FROM gmd_samples
             WHERE sample_id = p_sample_id;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_sample_no := NULL;
      END;

      SELECT COUNT (1)
        INTO v_count
        FROM xxshp_gmd_smpl_crt_hdr h, xxshp_gmd_smpl_crt_lns l
       WHERE l.sample_hdr_id = h.sample_hdr_id AND sample_id = p_sample_id;


      IF (v_parent_sample_id IS NULL)
      THEN
         v_sample_no := v_parent_sample || '-01';
      ELSE
         BEGIN
            SELECT sample_no
              INTO v_sample_no
              FROM gmd_samples
             WHERE sample_id = v_resample_id;

            SELECT sample_no
              INTO v_parent_sample
              FROM gmd_samples
             WHERE sample_id = p_sample_id;

            --A : 65
            --Z : 90
            --v_last_char := SUBSTR (v_sample_no, -1);

            /*IF (TO_NUMBER (ASCII (v_last_char)) BETWEEN 65 AND 90)
            THEN
               v_sample_no := SUBSTR (v_sample_no, 1, LENGTH (v_sample_no) - 1) || CHR (TO_NUMBER (ASCII (v_last_char)) + 1);
            ELSE
               v_sample_no := v_sample_no || '-A';
            END IF;*/

            v_last_char := TO_NUMBER (SUBSTR (v_sample_no, -2)) + 1;

            v_sample_no := v_parent_sample || '-' || LPAD (v_last_char, 2, '0');
         EXCEPTION
            WHEN OTHERS
            THEN
               v_sample_no := NULL;
         END;
      END IF;

      IF (v_count = 1 AND v_sample_no IS NOT NULL)
      THEN
         BEGIN
            SELECT sample_hdr_id
              INTO v_inserted_hdr_id
              FROM xxshp_gmd_smpl_crt_lns
             WHERE sample_no = v_sample_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_inserted_hdr_id := 0;
         END;

         IF (v_inserted_hdr_id = 0)
         THEN
            p_hdr_id := xxshp_gmd_smpl_crt_hdr_s.NEXTVAL;
            v_lns_id := xxshp_gmd_smpl_crt_lns_s.NEXTVAL;

            INSERT INTO xxshp_gmd_smpl_crt_hdr (sample_hdr_id,
                                                document_number,
                                                sample_source,
                                                organization_id,
                                                status,
                                                po_header_id,
                                                receipt_num,
                                                vendor_id,
                                                vendor_site_id,
                                                batch_id,
                                                recipe_id,
                                                formula_id,
                                                routing_id,
                                                batchstep_id,
                                                oprn_id,
                                                inventory_item_id,
                                                lot_number,
                                                mvo_header_id,
                                                shipment_header_id,
                                                created_by,
                                                creation_date,
                                                last_updated_by,
                                                last_update_date,
                                                last_update_login)
               SELECT p_hdr_id,
                      h.document_number,
                      h.sample_source,
                      h.organization_id,
                      'N',
                      h.po_header_id,
                      h.receipt_num,
                      h.vendor_id,
                      h.vendor_site_id,
                      h.batch_id,
                      h.recipe_id,
                      h.formula_id,
                      h.routing_id,
                      h.batchstep_id,
                      h.oprn_id,
                      h.inventory_item_id,
                      gs.lot_number,
                      h.mvo_header_id,
                      h.shipment_header_id,
                      g_user_id,
                      SYSDATE,
                      g_user_id,
                      SYSDATE,
                      g_login_id
                 FROM xxshp_gmd_smpl_crt_hdr h, xxshp_gmd_smpl_crt_lns l, gmd_samples gs
                WHERE     l.sample_hdr_id = h.sample_hdr_id
                      AND gs.sample_id = l.sample_id
                      AND l.sample_id = p_sample_id;

            INSERT INTO xxshp.xxshp_gmd_smpl_crt_lns (sample_hdr_id,
                                                      sample_line_id,
                                                      organization_id,
                                                      status,
                                                      error_msg,
                                                      inventory_item_id,
                                                      sample_id,
                                                      sample_group,
                                                      lot_number,
                                                      spec_id,
                                                      requestor_id,
                                                      packaging_type,
                                                      storage_temperature,
                                                      supplier_lot_number,
                                                      incoming_sample_type,
                                                      shipment_line_id,
                                                      sample_no,
                                                      lab_organization_id,
                                                      priority,
                                                      created_by,
                                                      creation_date,
                                                      last_updated_by,
                                                      last_update_date,
                                                      last_update_login)
               SELECT p_hdr_id,
                      v_lns_id,
                      l.organization_id,
                      'N' status,
                      NULL error_msg,
                      l.inventory_item_id,
                      NULL sample_id,
                      NULL,                                                        --l.sample_group,
                      gs.lot_number,
                      l.spec_id,
                      l.requestor_id,
                      l.packaging_type,
                      l.storage_temperature,
                      gs.supplier_lot_no,
                      l.incoming_sample_type,
                      l.shipment_line_id,
                      v_sample_no,
                      l.lab_organization_id,
                      l.priority,
                      g_user_id,
                      SYSDATE,
                      g_user_id,
                      SYSDATE,
                      g_login_id
                 FROM xxshp_gmd_smpl_crt_hdr h, xxshp_gmd_smpl_crt_lns l, gmd_samples gs
                WHERE     l.sample_hdr_id = h.sample_hdr_id
                      AND l.sample_id = p_sample_id
                      AND gs.sample_id = l.sample_id;


            INSERT INTO xxshp_gmd_smpl_crt_test (sample_test_id,
                                                 sample_line_id,
                                                 check_flag,
                                                 test_id,
                                                 created_by,
                                                 creation_date,
                                                 last_updated_by,
                                                 last_update_date,
                                                 last_update_login)
               SELECT xxshp_gmd_smpl_crt_test_s.NEXTVAL,
                      v_lns_id,
                      t.check_flag,
                      t.test_id,
                      g_user_id,
                      SYSDATE,
                      g_user_id,
                      SYSDATE,
                      g_login_id
                 FROM xxshp_gmd_smpl_crt_hdr h,
                      xxshp_gmd_smpl_crt_lns l,
                      gmd_samples gs,
                      xxshp_gmd_smpl_crt_test t
                WHERE     l.sample_hdr_id = h.sample_hdr_id
                      AND l.sample_id = p_sample_id
                      AND gs.sample_id = l.sample_id
                      AND l.sample_line_id = t.sample_line_id;
         ELSE
            p_hdr_id := v_inserted_hdr_id;
         END IF;
      ELSE
         p_hdr_id := 0;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_hdr_id := -1;
   END insert_resample;

   PROCEDURE create_sample (p_hdr_id                     NUMBER,
                            p_line_id                    NUMBER,
                            p_rec                 IN     gmd_samples%ROWTYPE,
                            x_sampling_event_id      OUT NUMBER,
                            x_result                 OUT gmd_samples%ROWTYPE,
                            p_valid               IN OUT BOOLEAN)
   AS
      x_sample             gmd_samples%ROWTYPE;
      x_sampling_event     gmd_sampling_events%ROWTYPE;
      x_sample_spec        gmd_sample_spec_disp%ROWTYPE;
      x_event_spec         gmd_event_spec_disp%ROWTYPE;
      x_results_tab        gmd_api_pub.gmd_results_tab;
      x_spec_results_tab   gmd_api_pub.gmd_spec_results_tab;
      x_return_status      VARCHAR2 (1);
      x_msg_count          NUMBER;
      x_msg_data           VARCHAR2 (1000);
      l_msg_index_out      NUMBER := 0;
   BEGIN
      gmd_samples_pub.create_samples (p_api_version           => g_api_version,
                                      p_init_msg_list         => fnd_api.g_true,
                                      p_commit                => fnd_api.g_false,
                                      p_validation_level      => fnd_api.g_valid_level_full,
                                      p_qc_samples_rec        => p_rec,
                                      p_user_name             => g_user_name,
                                      p_find_matching_spec    => g_find_matching_spec,
                                      p_grade                 => NULL,
                                      p_lpn                   => NULL,
                                      x_qc_samples_rec        => x_sample,
                                      x_sampling_events_rec   => x_sampling_event,
                                      x_sample_spec_disp      => x_sample_spec,
                                      x_event_spec_disp_rec   => x_event_spec,
                                      x_results_tab           => x_results_tab,
                                      x_spec_results_tab      => x_spec_results_tab,
                                      x_return_status         => x_return_status,
                                      x_msg_count             => x_msg_count,
                                      x_msg_data              => x_msg_data);

      --logf('API Create Sample Result : '||x_return_status);
      IF x_return_status = 'S'
      THEN
         p_valid := TRUE;
         x_sampling_event_id := x_sampling_event.sampling_event_id;
         x_result := x_sample;
         update_lines (p_hdr_id,
                       p_line_id,
                       x_sample.sample_id,
                       'S',
                       'Success');
      --logf ('Sample# ' || x_sample.sample_no);
      --outf ('Sample# ' || x_sample.sample_no || ' Created');
      ELSE
         p_valid := FALSE;

         IF x_msg_count - l_msg_index_out > 0
         THEN
            get_error_msg (x_msg_count, l_msg_index_out, x_msg_data);
         END IF;

         --DBMS_OUTPUT.put_line ('Sample# ' || p_rec.sample_no || ' Error : ' || x_msg_data);
         update_lines (p_hdr_id,
                       p_line_id,
                       NULL,
                       'E',
                       x_msg_data);
      END IF;
   --commit;
   END create_sample;

   PROCEDURE run_process_create_sample (p_status           OUT VARCHAR2,
                                        p_message          OUT VARCHAR2,
                                        p_resample_id      OUT NUMBER,
                                        p_sample_id     IN     NUMBER)
   AS
      l_sample              gmd_samples%ROWTYPE;
      l_sample_null         gmd_samples%ROWTYPE;
      x_sampling_event_id   NUMBER;
      x_sample_no           VARCHAR2 (80);
      l_valid               BOOLEAN;
      l_traslated_lot_no    VARCHAR2 (100);
      l_delivered_qty       NUMBER;
      l_delivered_uom       VARCHAR2 (200);
      l_pack_uom            VARCHAR2 (200);
      l_err_m               VARCHAR2 (200);
      l_shipment_num        VARCHAR2 (200);
      l_receipt_num         VARCHAR2 (200);
      l_item_num            VARCHAR2 (100);
      l_lpn_num             VARCHAR2 (100);
      l_exists              VARCHAR2 (10);
      l_sample_qty          NUMBER;
      l_sample_qty_uom      VARCHAR2 (3);
      l_mmt_lot             VARCHAR (50);
      l_transaction_id      NUMBER;
      x_result              gmd_samples%ROWTYPE;
      l_sqlerrm             VARCHAR2 (1000);
      l_uom                 VARCHAR2 (10);
      v_hdr_id              NUMBER;

      CURSOR c_data
      IS
         SELECT h.sample_hdr_id,
                h.document_number,
                h.sample_source,
                DECODE (h.sample_source,  'INCOMING', 'S',  'INLINE', 'W',  'I') gmd_source,
                h.po_header_id,
                h.receipt_num,
                h.vendor_id,
                h.vendor_site_id,
                h.batch_id,
                h.recipe_id,
                h.formula_id,
                h.routing_id,
                h.batchstep_id,
                h.oprn_id,
                h.mvo_header_id,
                h.shipment_header_id,
                l.sample_line_id,
                l.organization_id,
                l.status,
                l.error_msg,
                l.inventory_item_id,
                l.sample_id,
                l.sample_group,
                l.lot_number,
                l.spec_id,
                l.requestor_id,
                l.packaging_type,
                l.storage_temperature,
                l.supplier_lot_number,
                l.incoming_sample_type,
                l.created_by,
                l.creation_date,
                l.last_updated_by,
                l.last_update_date,
                l.last_update_login,
                l.sample_no,
                l.shipment_line_id,
                l.lab_organization_id,
                CASE
                   WHEN h.sample_source = 'INLINE'
                   THEN
                      'BATCH NO-' || h.batch_no || '-MIXING-' || l.line_no
                   WHEN h.sample_source = 'FG'
                   THEN
                      'BATCH NO-' || h.batch_no || '-' || l.line_no
                   ELSE
                      ''
                END
                   sample_desc,
                l.priority
           FROM xxshp_gmd_smpl_crt_hdr_v h, xxshp_gmd_smpl_crt_lns_v l
          WHERE     l.sample_hdr_id = h.sample_hdr_id
                AND l.sample_hdr_id = v_hdr_id
                AND l.status IN ('N', 'E');
   BEGIN
      insert_resample (v_hdr_id, p_sample_id);
      p_status := 'S';

      IF (v_hdr_id > 0)
      THEN
         FOR c_rcd IN c_data
         LOOP
            l_sample := l_sample_null;
            l_sample.sample_no := c_rcd.sample_no;
            --l_sample.sample_desc := c_rcd.sample_desc;
            l_sample.inventory_item_id := c_rcd.inventory_item_id;
            l_sample.organization_id := c_rcd.organization_id;
            l_sample.SOURCE := c_rcd.gmd_source;
            l_sample.sample_disposition := '1P';
            --l_sample.PRIORITY := '5N';
            l_sample.priority := c_rcd.priority;
            l_sample.delete_mark := g_delete_mark;
            l_sample.created_by := g_user_id;
            l_sample.creation_date := SYSDATE;
            l_sample.last_updated_by := g_user_id;
            l_sample.last_update_date := SYSDATE;
            l_sample.sampler_id := g_user_id;
            l_sample.sample_type := g_type_inventory;
            l_sample.delete_mark := g_delete_mark;
            l_sample.date_drawn := SYSDATE;
            l_sample.lab_organization_id := c_rcd.lab_organization_id;
            l_sample.sample_qty := 1;

            BEGIN
               SELECT primary_uom_code
                 INTO l_sample.sample_qty_uom
                 FROM mtl_system_items
                WHERE     inventory_item_id = l_sample.inventory_item_id
                      AND organization_id = l_sample.organization_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_message :=
                        p_message
                     || 'Error get UoM, ItemID:'
                     || l_sample.inventory_item_id
                     || ', OrgID:'
                     || l_sample.organization_id
                     || ';';
                  p_status := 'E';
            END;

            l_sample.lot_number := c_rcd.lot_number;
            l_sample.attribute21 := c_rcd.packaging_type;
            l_sample.attribute22 := c_rcd.storage_temperature;
            --l_sample.attribute25 := c_rcd.sample_group;  --updated on 22 Aug 17;
            l_sample.attribute30 := p_sample_id;

            BEGIN
               SELECT last_name
                 INTO l_sample.attribute23
                 FROM per_all_people_f
                WHERE person_id = c_rcd.requestor_id AND ROWNUM = 1;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_sample.attribute23 := c_rcd.requestor_id;
            END;


            IF l_sample.SOURCE = 'W'
            THEN
               l_sample.batch_id := c_rcd.batch_id;
               l_sample.recipe_id := c_rcd.recipe_id;
               l_sample.formula_id := c_rcd.formula_id;
               l_sample.routing_id := c_rcd.routing_id;
               l_sample.oprn_id := c_rcd.oprn_id;
               l_sample.lot_number := c_rcd.lot_number;
            ELSIF l_sample.SOURCE = 'I'
            THEN
               l_sample.lot_number := c_rcd.lot_number;
            ELSIF l_sample.SOURCE = 'S'
            THEN
               l_sample.supplier_id := c_rcd.vendor_id;
               l_sample.supplier_site_id := c_rcd.vendor_site_id;
               l_sample.po_header_id := c_rcd.po_header_id;
               l_sample.receipt_id := c_rcd.shipment_header_id;                        --receipt_id;
               l_sample.receipt_line_id := c_rcd.shipment_line_id;                     --receipt_id;
               l_sample.supplier_lot_no := c_rcd.supplier_lot_number;

               BEGIN
                  SELECT po_line_id
                    INTO l_sample.po_line_id
                    FROM rcv_shipment_lines
                   WHERE shipment_line_id = l_sample.receipt_line_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_message :=
                           p_message
                        || 'Error get POLineID, shipment_line_id:'
                        || l_sample.receipt_line_id
                        || ';';
                     p_status := 'E';
               END;
            END IF;

            create_sample (c_rcd.sample_hdr_id,
                           c_rcd.sample_line_id,
                           l_sample,
                           x_sampling_event_id,
                           x_result,
                           l_valid);
            COMMIT;

            IF l_valid
            THEN
               UPDATE mtl_lot_numbers
                  SET sampling_event_id = NVL (x_sampling_event_id, -1),
                      c_attribute20 = x_result.sample_no
                WHERE     inventory_item_id = l_sample.inventory_item_id
                      AND organization_id = l_sample.organization_id
                      AND lot_number = l_sample.lot_number;
            ELSE
               EXIT;
            END IF;
         END LOOP;

         IF l_valid IS NULL
         THEN
            p_message := p_message || 'No sample created' || ';';
            ROLLBACK;

            UPDATE xxshp_gmd_smpl_crt_hdr
               SET status = 'E'
             WHERE sample_hdr_id = v_hdr_id;

            p_status := 'E';
            COMMIT;
         END IF;

         IF l_valid
         THEN
            p_message := p_message || 'New sample created: ' || x_result.sample_no;
            p_resample_id := x_result.sample_id;

            UPDATE xxshp_gmd_smpl_crt_hdr
               SET status = 'S'
             WHERE sample_hdr_id = v_hdr_id;

            COMMIT;
         ELSE
            p_message := p_message || 'Error when creating new sample;';
            ROLLBACK;

            UPDATE xxshp_gmd_smpl_crt_hdr
               SET status = 'E'
             WHERE sample_hdr_id = v_hdr_id;

            UPDATE xxshp_gmd_smpl_crt_lns
               SET sample_id = NULL, status = 'E'
             WHERE sample_hdr_id = v_hdr_id;

            p_status := 'E';
            COMMIT;
         END IF;
      ELSE
         p_message := 'Failed when inserting resample record';
         p_status := 'E';
      END IF;
   EXCEPTION
      WHEN g_user_exception
      THEN
         p_message := p_message || 'G USER EXCEPTION - ' || SQLERRM || ';';
         p_status := 'E';
      WHEN OTHERS
      THEN
         l_sqlerrm := SQLERRM || CHR (10) || DBMS_UTILITY.format_error_backtrace;
         p_message := p_message || 'Error when creating sample - ' || l_sqlerrm || ';';
         ROLLBACK;

         UPDATE xxshp_gmd_smpl_crt_lns
            SET sample_id = NULL, error_msg = error_msg || ' - ' || l_sqlerrm
          WHERE sample_hdr_id = v_hdr_id;

         UPDATE xxshp_gmd_smpl_crt_hdr
            SET status = 'E'
          WHERE sample_hdr_id = v_hdr_id;

         p_status := 'E';
         RAISE;
   END run_process_create_sample;

   PROCEDURE update_void (p_status           OUT VARCHAR2,
                          p_message          OUT VARCHAR2,
                          p_resample_id   IN     NUMBER,
                          p_sample_id     IN     NUMBER)
   IS
      CURSOR c_data
      IS
         SELECT gsr.*
           FROM gmd_qc_tests gqt,
                gmd_test_classes gtc,
                gmd_samples gs,
                gmd_event_spec_disp gesd,
                gmd_spec_tests gst,
                gmd_test_methods gtm,
                gmd_results gr,
                gmd_spec_results gsr
          WHERE     gqt.test_class = gtc.test_class
                AND gqt.test_id = gst.test_id(+)
                AND gs.sampling_event_id = gesd.sampling_event_id
                AND gesd.spec_id = gst.spec_id(+)
                AND gqt.test_class = gtc.test_class
                AND gtm.test_method_id = gqt.test_method_id
                AND gs.sample_id = gr.sample_id
                AND gqt.test_id = gr.test_id
                AND gr.result_id = gsr.result_id
                AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                AND gs.sample_id = p_resample_id
                AND gr.test_id IN (SELECT gr1.test_id
                                     FROM gmd_qc_tests gqt1,
                                          gmd_test_classes gtc1,
                                          gmd_samples gs1,
                                          gmd_event_spec_disp gesd1,
                                          gmd_spec_tests gst1,
                                          gmd_test_methods gtm1,
                                          gmd_results gr1,
                                          gmd_spec_results gsr1
                                    WHERE     gqt1.test_class = gtc1.test_class
                                          AND gqt1.test_id = gst1.test_id(+)
                                          AND gs1.sampling_event_id = gesd1.sampling_event_id
                                          AND gesd1.spec_id = gst1.spec_id(+)
                                          AND gqt1.test_class = gtc1.test_class
                                          AND gtm1.test_method_id = gqt1.test_method_id
                                          AND gs1.sample_id = gr1.sample_id
                                          AND gqt1.test_id = gr1.test_id
                                          AND gr1.result_id = gsr1.result_id
                                          AND gsr1.event_spec_disp_id = gesd1.event_spec_disp_id
                                          AND (   gsr1.evaluation_ind IS NOT NULL
                                               OR (    gr1.result_value_num IS NULL
                                                   AND gr1.result_value_char IS NULL))
                                          AND gs1.sample_id = p_sample_id);
   BEGIN
      p_status := 'S';

      FOR i IN c_data
      LOOP
         BEGIN
            UPDATE gmd_spec_results
               SET evaluation_ind = '5O'
             WHERE result_id = i.result_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_status := 'E';
               p_message := 'Error when updating gmd_spec_results ' || SQLERRM;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := 'E';
         p_message := 'Error when run update_void ' || SQLERRM;
   END update_void;

   PROCEDURE add_test (p_status           OUT VARCHAR2,
                       p_message          OUT VARCHAR2,
                       p_resample_id   IN     NUMBER,
                       p_sample_id     IN     NUMBER)
   IS
      v_sample               gmd_samples%ROWTYPE;
      v_test_ids             gmd_api_pub.number_tab;
      v_add_rslt_tab_out     gmd_api_pub.gmd_results_tab;
      v_add_spec_tab_out     gmd_api_pub.gmd_spec_results_tab;
      --FOUND_TEST         BOOLEAN ;
      --FOUND_LAST_REP     BOOLEAN ;
      --retest_qc_lab_id      gmd_results.lab_organization_id%TYPE;
      -- just copy existing orgn if this is a retest
      --l_sts BOOLEAN;
      --i INTEGER;
      --l_test_type gmd_qc_tests.test_type%TYPE;
      v_event_spec_disp_id   NUMBER;
      v_return_status        VARCHAR2 (200);
      v_loop                 NUMBER := 0;
      v_err                  NUMBER := 0;

      CURSOR c_data
      IS
         SELECT gqt.test_id,
                gr.test_replicate_cnt,
                gr.test_qty,
                gr.test_qty_uom
           FROM gmd_qc_tests gqt,
                gmd_test_classes gtc,
                gmd_samples gs,
                gmd_event_spec_disp gesd,
                gmd_spec_tests gst,
                gmd_test_methods gtm,
                gmd_results gr,
                gmd_spec_results gsr
          WHERE     gqt.test_class = gtc.test_class
                AND gqt.test_id = gst.test_id(+)
                AND gs.sampling_event_id = gesd.sampling_event_id
                AND gesd.spec_id = gst.spec_id(+)
                AND gqt.test_class = gtc.test_class
                AND gtm.test_method_id = gqt.test_method_id
                AND gs.sample_id = gr.sample_id
                AND gqt.test_id = gr.test_id
                AND gr.result_id = gsr.result_id
                AND gsr.event_spec_disp_id = gesd.event_spec_disp_id
                AND gs.sample_id = p_sample_id
         MINUS
         SELECT gqt.test_id,
                1,
                NULL,
                NULL
           FROM gmd_qc_tests gqt, gmd_spec_tests gst
          WHERE     gqt.test_id = gst.test_id
                AND EXISTS
                       (SELECT 1
                          FROM gmd_samples gs, gmd_event_spec_disp gesd
                         WHERE     gs.sampling_event_id = gesd.sampling_event_id
                               AND gst.spec_id = gesd.spec_id
                               AND gs.sample_id = p_sample_id);
   BEGIN
      p_status := 'S';

      BEGIN
         v_sample.sample_id := p_resample_id;

         SELECT event_spec_disp_id
           INTO v_event_spec_disp_id
           FROM gmd_samples gs, gmd_event_spec_disp gesd
          WHERE gs.sampling_event_id = gesd.sampling_event_id AND gs.sample_id = p_resample_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err := 1;
            p_message := 'Error when get event_spec_disp_id ' || SQLERRM;
      END;

      IF (v_err = 0)
      THEN
         FOR i IN c_data
         LOOP
            v_test_ids (1) := i.test_id;

            gmd_results_grp.add_tests_to_sample (p_sample               => v_sample,
                                                 p_test_ids             => v_test_ids,
                                                 p_event_spec_disp_id   => v_event_spec_disp_id,
                                                 x_results_tab          => v_add_rslt_tab_out,
                                                 x_spec_results_tab     => v_add_spec_tab_out,
                                                 x_return_status        => v_return_status,
                                                 p_test_qty             => i.test_qty,
                                                 p_test_qty_uom         => i.test_qty_uom);

            IF NVL (v_return_status, 'E') <> 'S'
            THEN
               v_err := 1;
               p_message := p_message || 'Error when add test id:' || i.test_id || '; ';
            END IF;
         END LOOP;
      ELSE
         p_status := 'E';
      END IF;


      IF (v_err = 1)
      THEN
         p_status := 'E';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_status := 'E';
         p_message := 'Error when run update_void ' || SQLERRM;
   END add_test;
END xxshp_gmd_sample_analysis_pkg;
/
