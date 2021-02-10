CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_NOTIFY_NEED_HALAL_MD
AS
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

   PROCEDURE send_mail (retcode out NUMBER, errbuff OUT VARCHAR2)
   IS
      p_to                       VARCHAR2 (2000) := 'ardianto.ardi@kalbenutritionals.com';--, adhi.rizaldi@kalbenutritionals.com'; --
      p_cc                       VARCHAR2 (2000);-- := 'reza.fajrin@kalbenutritionals.com';
      p_bcc                      VARCHAR2 (2000);-- := 'adhi.rizaldi@kalbenutritionals.com';--,ardianto.ardi@kalbenutritionals.com';
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
      v_filename                 VARCHAR2 (100);

   BEGIN
      mo_global.set_policy_context ('S', g_organization_id);

      --Email To
       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
          into p_to
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
                      FROM (SELECT DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_LOOKUP_VALUES
                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_ITEM_STS_NEED'
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
                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_ITEM_STS_NEED'
                               AND TAG = 'Cc')
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
            'Subject: Notifikasi Item Status Description Need Halal, Need MD, Need MD-Halal' || UTL_TCP.crlf);
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
         UTL_SMTP.write_data (v_connection, 'Dear All,' || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'Please be aware that attached item code status are in "Need MD", "Need Halal", or "Need MD-Halal". '
            || CHR (13)
            || CHR (10)
            || 'Item code status must be updated to Active prior to production.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'To update please contact Admin.'
            || UTL_TCP.crlf);
         UTL_SMTP.write_data (
            v_connection,
               UTL_TCP.crlf
            || 'NOTE - Please do not reply since this is an automatically generated e-mail.'
            || UTL_TCP.crlf);

         v_filename := 'SHP__Notifikasi_Item_Status_Need-' || TO_CHAR (SYSDATE, 'MON-RR');

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.write_data (v_connection,
                              '--' || c_mime_boundary || UTL_TCP.crlf);
         ln_cnt := 1;

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
         END IF;

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);

         v_clob :=
               'Category,Item Code,Item Desc,Organization,Supplier Name,Part,Item Status, MD Number, MD Valid To,Sertificate Halal Number,Halal Valid To,Halal Body,Item Template,Item Type,Manufactur Part Number'
            || UTL_TCP.crlf;

         UTL_SMTP.write_data (v_connection, v_clob);
         
         FOR i IN mpn_info_cur
         LOOP
            BEGIN
               v_clob :=
                     i.kn_lob
                  || ','
                  || i.item_code
                  || ','
                  || REPLACE (REPLACE(REPLACE(i.item_desc,CHR(13)),CHR(10)), ',')
                  || ','
                  || i.organization_code
                  || ','
                  || REPLACE (i.supplier_name, ',')
                  || ','
                  || i.part
                  || ','
                  || i.inventory_item_status_code_tl
                  || ','
                  || '='
                  || '"'
                  || i.md_num
                  || '"'
                  || ','
                  || i.md_valid_to
                  || ','
                  || '='
                  || '"'
                  || i.halal_number
                  || '"'
                  || ','
                  || i.halal_valid_to
                  || ','
                  || i.halal_body
                  || ','
                  || i.item_template
                  || ','
                  || i.item_type
                  || ','
                  || i.mfg_part_num
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

         UTL_SMTP.write_data (v_connection, UTL_TCP.crlf);
         UTL_SMTP.close_data (v_connection);
         UTL_SMTP.quit (v_connection);

      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('Error : ' || SQLERRM);
            logf (DBMS_UTILITY.format_error_backtrace);
      END;
   END send_mail;
END XXSHP_NOTIFY_NEED_HALAL_MD;
/
