CREATE OR REPLACE PACKAGE BODY APPS.XXGVN_MISSASSIGN_ITEM_MAIL_PKG
AS
   /*
   REM +=========================================================================================================+
   REM |                                    Copyright (C) 2019  KNITERS                                          |
   REM |                                        All rights Reserved                                              |
   REM +=========================================================================================================+
   REM |                                                                                                         |
   REM |     Program Name: XXGVN_MISSASSIGN_ITEM_MAIL_PKG.pks                                                    |
   REM |     Parameters  :                                                                                       |
   REM |     Description : Untuk merubah status item menjadi phase out                                           |
   REM |     History     : 20 Des 2019 --Ardianto--  create this package                                         |
   REM |     Proposed    :                                                                                       |
   REM |     Updated     :                                                                                       |
   REM +---------------------------------------------------------------------------------------------------------+
   */

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

   FUNCTION get_instance_name
      RETURN VARCHAR2
   IS
      v_inst   v$instance.instance_name%TYPE;
   BEGIN
      SELECT instance_name INTO v_inst FROM v$instance;

      RETURN v_inst;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'NULL';
   END get_instance_name;

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

   PROCEDURE send_mail (p_total IN NUMBER, p_result OUT VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000) := 'ardianto.ardi@kalbenutritionals.com'; --'ardianto.ardi@kalbenutritionals.com'; --
      p_cc                       VARCHAR2 (2000);
      p_bcc                      VARCHAR2 (2000); --:= 'adhi.rizaldi@kalbenutritionals.com,ardianto.ardi@kalbenutritionals.com';
      lv_smtp_server             VARCHAR2 (100) := '172.31.254.246';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100) := 'no-reply@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ld_date                    DATE;
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

      /*--Email To
      SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
         into p_to
         FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
                     FROM (SELECT DESCRIPTION,
                                  ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                  COUNT (*) OVER () cnt
                             FROM FND_LOOKUP_VALUES
                            WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_HALAL_EXPIRY'
                              AND TAG = 'To')
                    WHERE rn = cnt
       START WITH rn = 1
       CONNECT BY rn = PRIOR rn + 1);

       --Email Cc
       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
         into p_cc
         FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
                     FROM (SELECT DESCRIPTION,
                                  ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                  COUNT (*) OVER () cnt
                             FROM FND_LOOKUP_VALUES
                            WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_HALAL_EXPIRY'
                              AND TAG = 'Cc')
                    WHERE rn = cnt
       START WITH rn = 1
       CONNECT BY rn = PRIOR rn + 1);*/

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

         IF TRIM (p_bcc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Bcc: ' || p_bcc || UTL_TCP.crlf);
         END IF;

         UTL_SMTP.write_data (
            v_connection,
            'Subject: Missing Assignment items' || UTL_TCP.crlf);
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
                              'Content-Type: text/plain' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
            'Content-Transfer_Encoding: 7bit' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, '' || UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, 'Dear User,' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Ditemukan beberapa assignment item yang belum lengkap.'
            || CHR (13)
            || CHR (10)
            || 'Silahkan untuk lengkapi assignment-nya di aplikasi Oracle, sesuai masing-masing kategori remarksnya.'
            || UTL_TCP.crlf);

         --v_filename := 'GVN Missing Asign Item-' || TO_CHAR (SYSDATE, 'MON-RR');

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         /*ln_cnt := 1;

         --/*Condition to check for the creation of csv attachment
         IF (ln_cnt <> 0)
         THEN
            UTL_SMTP.write_data (
               v_connection,
                  'Content-Disposition: attachment; filename="'
               || v_filename
               || '.csv'
               || '"'
               || UTL_TCP.crlf);
         END IF;*/

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);

         v_clob := 'Item Code, Description, Remarks' || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, v_clob);

         FOR i IN source_data_cur
         LOOP
            BEGIN
               v_clob :=
                     i.item_code
                  || ','
                  || REPLACE (
                        REPLACE (REPLACE (i.description, CHR (13)), CHR (10)),
                        ',')
                  || ','
                  || i.remarks
                  || UTL_TCP.crlf;
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf (SQLERRM);
                  logf (DBMS_UTILITY.format_error_backtrace);
            END;

            --Writing data in csv attachment.
            UTL_SMTP.write_data (v_connection, v_clob);
         END LOOP;

         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Note : '
            || CHR (13)
            || CHR (10)
            || 'Please do not reply since this is an automatically generated e-mail.'
            || UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error : ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail;

   PROCEDURE send_mail1 (p_result OUT VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000);--:='ardianto.ardi@kalbenutritionals.com'; --
      p_cc                       VARCHAR2 (2000);
      p_bcc                      VARCHAR2 (2000):='ardianto.ardi@kalbenutritionals.com,gendro.saputro@kalbenutritionals.com'; --:= 'adhi.rizaldi@kalbenutritionals.com,ardianto.ardi@kalbenutritionals.com';
      lv_smtp_server             VARCHAR2 (100) := '172.31.254.246';
      lv_domain                  VARCHAR2 (100);
      lv_from                    VARCHAR2 (100) := 'no-reply@kalbenutritionals.com';
      v_connection               UTL_SMTP.connection;
      c_mime_boundary   CONSTANT VARCHAR2 (256) := '--AAAAA000956--';
      v_clob                     CLOB;
      ld_date                    DATE;
   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

      --Email To
      SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                      CHR (09),
                      '')
        INTO p_to
        FROM (    SELECT TRIM (
                            SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                            EMAIL
                    FROM (SELECT DESCRIPTION,
                                 ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                 COUNT (*) OVER () cnt
                            FROM FND_LOOKUP_VALUES
                           WHERE     LOOKUP_TYPE = 'MISS_ITEM_ASSIGN_EMAIL'
                                 AND enabled_flag = 'Y'
                                 AND Tag = 'TO'
                                 AND start_date_active <= SYSDATE
                                 AND (   end_date_active IS NULL
                                      OR end_date_active >= SYSDATE))
                   WHERE rn = cnt
              START WITH rn = 1
              CONNECT BY rn = PRIOR rn + 1);

      --Email Cc
      SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                      CHR (09),
                      '')
        INTO p_cc
        FROM (    SELECT TRIM (
                            SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                            EMAIL
                    FROM (SELECT DESCRIPTION,
                                 ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                 COUNT (*) OVER () cnt
                            FROM FND_LOOKUP_VALUES
                           WHERE     LOOKUP_TYPE = 'MISS_ITEM_ASSIGN_EMAIL'
                                 AND enabled_flag = 'Y'
                                 AND Tag = 'CC'
                                 AND start_date_active <= SYSDATE
                                 AND (   end_date_active IS NULL
                                      OR end_date_active >= SYSDATE))
                   WHERE rn = cnt
              START WITH rn = 1
              CONNECT BY rn = PRIOR rn + 1);

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

         IF TRIM (p_bcc) IS NOT NULL
         THEN
            UTL_SMTP.write_data (v_connection,
                                 'Bcc: ' || p_bcc || UTL_TCP.crlf);
         END IF;

         UTL_SMTP.write_data (
            v_connection,
            'Subject: Missing Assignment Items' || UTL_TCP.crlf);
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
            || 'Ditemukan beberapa assignment item yang belum lengkap.<br>'
            || 'Silahkan untuk lengkapi assignment-nya di aplikasi Oracle, sesuai masing-masing kategori remarksnya.<br><br>'
            || UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);

         UTL_SMTP.write_data (v_connection, '<table border = "1">');
         UTL_SMTP.write_data (v_connection,
                              '<tr style="background-color: cyan">');

         v_clob :=
               '<th>Item Code</th><th>Description</th><th>Remarks</th>'
            || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, '</tr>');
         UTL_SMTP.write_data (v_connection, v_clob);

         FOR i IN source_data_cur
         LOOP
            BEGIN
               UTL_SMTP.write_data (v_connection, '<tr>');
               UTL_SMTP.write_data (v_connection, '<td>' || i.item_code || '</td>');
               UTL_SMTP.write_data (v_connection, '<td>' || i.description || '</td>');
               UTL_SMTP.write_data (v_connection, '<td>' || i.remarks || '</td>');
               UTL_SMTP.write_data (v_connection, '</tr>');
            EXCEPTION
               WHEN OTHERS
               THEN
                  logf (SQLERRM);
                  logf (DBMS_UTILITY.format_error_backtrace);
            END;
         END LOOP;

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

         p_result := 'Success. Email Sent To ' || p_to;
         logf (p_result);
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error : ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail1;

   PROCEDURE proses_email (errbuf    OUT VARCHAR2,
                           retcode    OUT NUMBER)
   IS
      v_instance_name   VARCHAR2 (100);
      v_result          VARCHAR2 (100);
      v_cnt             number := 0;
   BEGIN
      v_instance_name := get_instance_name;
      logf(get_instance_name);

    for i in source_data_cur
    loop
    v_cnt := v_cnt + 1;
    end loop; 

    logf('Data Count : ' || v_cnt);
    
    IF v_cnt > 0 THEN
        IF v_instance_name = 'GVNPROD'
          THEN
            send_mail1(v_result);
             logf('Jalan kok');
        END IF;
    END IF;
   END proses_email;
   
END XXGVN_MISSASSIGN_ITEM_MAIL_PKG;
/
