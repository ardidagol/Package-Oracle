CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_MAIL_AVAILABLE_FP_PKG
AS

    /***************************************************************************************************
      NAME: XXSHP_WH_MTRG_PICK_PKG
      PURPOSE:

      REVISIONS:
      Ver         Date            Author                        Description
      ---------   ----------      ---------------               ------------------------------------
      1.0         4-MAY-2020     Ardie                         1. Created this package.
     *************************************************************************************************/
     
   PROCEDURE logf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   PROCEDURE process_recipients (p_mail_conn   IN OUT UTL_SMTP.connection,
                                 p_list        IN     VARCHAR2)
   AS
      l_tab   string_api.t_split_array;
   BEGIN
      IF TRIM (p_list) IS NOT NULL
      THEN
         l_tab := string_api.split_text (p_list);

         FOR i IN 1 .. l_tab.COUNT
         LOOP
            UTL_SMTP.rcpt (p_mail_conn, TRIM (l_tab (i)));
         END LOOP;
      END IF;
   END process_recipients;

   PROCEDURE check_available (errbuf OUT VARCHAR2, retcode OUT NUMBER)
   IS
      v_year       NUMBER;
      v_avail_fp   NUMBER;
   BEGIN
        SELECT FP_YEAR, (SUM (FP_SEQ_NUM_TO - LAST_NUM)) FP_NUMBER_AVAILABLE
          INTO v_year, v_avail_fp
          FROM XXSHP_ZX_FPSEQ_V
         WHERE 1 = 1 AND FP_YEAR = TO_CHAR (SYSDATE, 'YYYY')
      GROUP BY FP_YEAR
      ORDER BY FP_YEAR;

      IF v_avail_fp < 250
      THEN
         send_mail (v_avail_fp, v_year);
      END IF;
   END;

   PROCEDURE send_mail (p_total_fp IN NUMBER, p_year IN VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000) := 'dwi.suciaty@kalbenutritionals.com,drajat.perdana@kalbenutritionals.com,fajrika.kofala@kalbenutritionals.com';
      p_cc                       VARCHAR2 (2000);
      p_bcc                      VARCHAR2 (2000) :='rumantiningtyas@kalbenutritionals.com';--ardianto.ardi@kalbenutritionals.com,
      lv_smtp_server             VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_SMTP_CONN'); --'10.171.8.88';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100)
                                    := fnd_profile.VALUE ('XXSHP_EMAIL_FROM'); --'oracle@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ln_cnt                     NUMBER;
      ld_date                    DATE;
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

      logf ('request ID : ' || fnd_global.conc_request_id);

      ld_date := SYSDATE;
      lv_domain := lv_smtp_server;

      BEGIN
         v_connection := UTL_SMTP.open_connection (lv_smtp_server, 25); --To open the connection
         UTL_SMTP.helo (v_connection, lv_smtp_server);
         UTL_SMTP.mail (v_connection, lv_from);
         process_recipients (v_connection, p_to);
         process_recipients (v_connection, p_cc);
         process_recipients (v_connection, p_bcc);
         UTL_SMTP.open_data (v_connection);
         UTL_SMTP.write_data (
            v_connection,
               'Date: '
            || TO_CHAR (SYSDATE, 'Dy, DD Mon YYYY hh24:mi:ss')
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'From: ' || lv_from || UTL_TCP.crlf);

         IF TRIM (p_to) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'To: ' || p_to || UTL_TCP.crlf);
         END IF;

         IF TRIM (p_cc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Cc: ' || p_cc || UTL_TCP.crlf);
         END IF;

         UTL_SMTP.write_data (
            v_connection,
            'Subject: Check FP Number Available' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'MIME-Version: 1.0' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               'Content-Type: multipart/mixed; boundary="'
            || c_mime_boundary
            || '"'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'This is a multi-part message in MIME format.' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              'Content-Type: text/html' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'Content-Transfer_Encoding: 7bit' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, '' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            '<font size="3" color="black">Dear User,<font><br>');

         UTL_SMTP.write_data (v_connection, '' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Jumlah Available FP sudah kurang dari 250<br><br>'
            || UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, '<table border = "1">');
         UTL_SMTP.write_data (v_connection,
                              '<tr style="background-color: cyan">');

         v_clob :=
            '<th>Tahun</th><th>FP Number Available</th>' || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, '</tr>');
         UTL_SMTP.write_data (v_connection, v_clob);


         BEGIN
            UTL_SMTP.write_data (v_connection, '<tr>');
            UTL_SMTP.write_data (v_connection, '<td>' || p_year || '</td>');
            UTL_SMTP.write_data (v_connection,
                                 '<td>' || p_total_fp || '</td>');
            UTL_SMTP.write_data (v_connection, '</tr>');
         EXCEPTION
            WHEN OTHERS
            THEN
               logf (SQLERRM);
               logf (DBMS_UTILITY.format_error_backtrace);
         END;

         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Print Date '||sysdate||'<br><br>'
            || UTL_TCP.crlf);
         
         UTL_SMTP.write_data (v_connection, '</table>');

         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || '<br>Note : <br>'
            || 'Please do not reply since this is an automatically generated e-mail.'
            || UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

         logf ('Success. Email Sent To ' || p_to);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error : ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail;
END XXSHP_MAIL_AVAILABLE_FP_PKG;
/
