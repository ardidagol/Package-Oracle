CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_IDC_MAIL_MDEXPIRY_PKG AS
    --g_mail_conn   utl_smtp.connection := utl_smtp.open_connection('knmail.kalbenutritionals.com', 25);
    g_crlf        char(2) default chr(13)||chr(10);
    g_mail_conn   utl_smtp.connection;
    g_mailhost    varchar2(255) := fnd_profile.value('XXSHP_SMTP_CONN');
       PROCEDURE INITIALIZE (p_user_id       IN NUMBER,
                         p_resp_id       IN NUMBER,
                         p_resp_app_id   IN NUMBER)
       IS
          PRAGMA AUTONOMOUS_TRANSACTION;
       BEGIN
          FND_GLOBAL.APPS_INITIALIZE (p_user_id, p_resp_id, p_resp_app_id);
          COMMIT;
       END INITIALIZE;
    PROCEDURE LOGF(V_CHAR VARCHAR2) IS
    BEGIN
        IF FND_GLOBAL.USER_ID IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(V_CHAR);
        ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG, V_CHAR);
        END IF;
    END;  
    PROCEDURE OUTF(V_CHAR VARCHAR2) IS
    BEGIN
        IF FND_GLOBAL.USER_ID IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(V_CHAR);
        ELSE
            FND_FILE.PUT_LINE (FND_FILE.OUTPUT, V_CHAR);
        END IF;
    END;  
    PROCEDURE process_recipients(p_mail_conn IN OUT UTL_SMTP.connection,
                                   p_list      IN     VARCHAR2)
      AS
        l_tab string_api.t_split_array;
      BEGIN
        IF TRIM(p_list) IS NOT NULL THEN
          l_tab := string_api.split_text(p_list);
          FOR i IN 1 .. l_tab.COUNT LOOP
            UTL_SMTP.rcpt(p_mail_conn, TRIM(l_tab(i)));
          END LOOP;
        END IF;
      END;                   
      
      PROCEDURE checking_md_expiry_stag (errbuf       OUT VARCHAR2,
                                           retcode      OUT NUMBER)
   IS 
      r_data_stag   xxshp_md_expiry_stag%ROWTYPE;
      r_data   xxshp_md_expiry_stag%ROWTYPE;
      v_count      NUMBER;
      v_count4m NUMBER;
      v_count3m NUMBER;
   BEGIN  
        ------ 4 Month to go ------
      FOR r_data_stag in data_stag4m
      LOOP
            INSERT INTO XXSHP_MD_EXPIRY_STAG (
                                                   data_id, 
                                                   kn, 
                                                   item_code, 
                                                   item_desc, 
                                                   uom, 
                                                   io, 
                                                   supplier_name, 
                                                   part, 
                                                   md_number, 
                                                   md_expiry_date, 
                                                   first_notification_date, 
                                                   creation_date, 
                                                   last_update_date, 
                                                   type_email, 
                                                   item_template
                                                   )
              VALUES                         (xxshp_md_expiry_stag_s.nextval, 
                                                   r_data_stag.kn_lob, 
                                                   r_data_stag.item_code, 
                                                   r_data_stag.item_desc,
                                                   r_data_stag.uom_code, 
                                                   r_data_stag.organization_code, 
                                                   r_data_stag.supplier_name, 
                                                   r_data_stag.part, 
                                                   r_data_stag.md_num, 
                                                   r_data_stag.md_valid_to,
                                                   sysdate,
                                                   sysdate,     
                                                   sysdate,                                                        
                                                   'B4M', 
                                                   r_data_stag.item_template                                         
                        );
         COMMIT;
      END LOOP;
      ------ 3 Month to go ------
      FOR r_data in data_stag3m
      LOOP
            INSERT INTO XXSHP_MD_EXPIRY_STAG (
                                                   data_id, 
                                                   kn, 
                                                   item_code, 
                                                   item_desc, 
                                                   uom, 
                                                   io, 
                                                   supplier_name, 
                                                   part, 
                                                   md_number, 
                                                   md_expiry_date, 
                                                   first_notification_date, 
                                                   phase_out,
                                                   creation_date, 
                                                   last_update_date, 
                                                   type_email, 
                                                   item_template
                                                   )
              VALUES                         (xxshp_md_expiry_stag_s.nextval, 
                                                   r_data.kn_lob, 
                                                   r_data.item_code, 
                                                   r_data.item_desc,
                                                   r_data.uom_code, 
                                                   r_data.organization_code, 
                                                   r_data.supplier_name, 
                                                   r_data.part, 
                                                   r_data.md_num, 
                                                   r_data.md_valid_to,
                                                   (case when r_data.first_notification_date is not null then r_data.first_notification_date end),
                                                   sysdate,
                                                   sysdate,      
                                                   sysdate,                                                        
                                                   'B3M', 
                                                   r_data.item_template                                     
                        );
         COMMIT;
      END LOOP;
      
        FOR r_data in data_stag3m
         LOOP
                change_status(r_data.inventory_item_id, r_data.organization_id);
         END LOOP;
         
         select count(*) into v_count4m
          from xxshp_md_expiry_stag where trunc(creation_date) = trunc(sysdate) and TYPE_EMAIL = 'B4M';  
        
        select count(*) into v_count3m
          from xxshp_md_expiry_stag where trunc(creation_date) = trunc(sysdate) and TYPE_EMAIL = 'B3M';  
         
        if v_count4m > 0 then
                send_mail_fg_4m;      
        end if;
        
        if v_count3m > 0 then
                send_mail_fg_3m;      
        end if;
      
   END checking_md_expiry_stag;
   PROCEDURE send_mail_fg_4m
    IS
       v_mail_conn       UTL_SMTP.connection;
       v_err            VARCHAR2 (5000);
       v_message        VARCHAR2 (5000);
       crlf             VARCHAR2 (2) := CHR (13) || CHR (10);
       v_attachment     VARCHAR2 (200);
       v_email     VARCHAR2 (32767);
       v_string     VARCHAR2 (200);
       l_string     VARCHAR2 (200);
       v_list     VARCHAR2 (32767);
       v_query     VARCHAR2 (5000);
       v_from   VARCHAR2 (200);
       v_recipient     VARCHAR2 (32767);
       v_recipient1     VARCHAR2 (32767);
       v_subject        VARCHAR2 (200);
       v_rphno        VARCHAR2 (200);
       v_dopots        VARCHAR2 (200);
       v_pono         VARCHAR2 (200);
       v_filename         VARCHAR2 (5000);
       v_mail_host      VARCHAR2 (200) := fnd_profile.value('XXSHP_SMTP_CONN'); ------------'172.31.254.246'; --'knmail.kalbenutritionals.com';
       l_to_list   long;
       v_count      NUMBER;
       p_to array default array();
       v_count_fg  NUMBER;
       v_count_pm NUMBER;
       cursor c_list_emails
        is
        select data_id, kn, item_code, item_desc, uom,io,supplier_name, part, md_number, md_expiry_date, first_notification_date, phase_out, creation_date, last_update_date
        from xxshp_md_expiry_stag where trunc(creation_date) = trunc(sysdate) and TYPE_EMAIL = 'B4M';  
    BEGIN
       select count(*) into v_count_fg from xxshp_data_md_b4m_v where item_template like 'FG%';
       select count(*) into v_count_pm from xxshp_data_md_b4m_v where item_template like 'PM%';
       
       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
          into v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
                      FROM (SELECT DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_LOOKUP_VALUES
                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_MD_EXPIRY')
                     WHERE rn = cnt
        START WITH rn = 1
        CONNECT BY rn = PRIOR rn + 1);
       
       v_filename := ' filename= "MDEXP'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'_B4M'||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ----'no-reply@kalbenutritionals.com';
       v_recipient1 := 'reza.fajrin@kalbenutritionals.com,adhi.rizaldi@kalbenutritionals.com, debby.ardi@kalbenutritionals.com';
--       v_recipient := 'ardianto.ardi@kalbenutritionals.com';
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'MD Number Expiry Date : Notification - 4 Months To Go';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
          DBMS_OUTPUT.put_line ('POINT 1: ');
           UTL_SMTP.open_data (v_mail_conn);
          v_email :=
                'Date: '
             || TO_CHAR (SYSDATE, 'Dy, DD Mon YYYY hh24:mi:ss')
             || crlf
             || 'From: '
             || v_from
             || crlf
             || 'Subject: '
             || v_subject
             || crlf
             || 'To: '
             || v_recipient
             || crlf
             || 'CC: '
             || v_recipient1
             || crlf
             || 'MIME-Version: 1.0'
             || crlf
             ||                                          -- Use MIME mail standard
               'Content-Type: multipart/mixed;'
             || crlf
             || ' boundary="-----SECBOUND" '
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: text/plain;'
             || crlf
             || 'Content-Transfer_Encoding: 7bit'
             || crlf
             || crlf
             || ''                                    -- Mail Message text
             || crlf
             || 'Dear All,'
             || crlf
             || 'Please be aware that attached Finished Good and Packaging Material items MD Number would shortly expired in ' || to_char(add_months(sysdate,4),'MON-YYYY')
             || crlf
             || 'These item would be change to PHASE OUT in ' || to_char(add_months(add_months(sysdate,4),-3),'MON-YYYY')
             || crlf
             || 'All PR (Purchase Requisition), PO (Purchase Order), BO (Batch Order) using these items can not be created when the item status is in phase out'
             || crlf
             || 'Finished Good items : ' || v_count_fg
             || crlf
             || 'Packaging materials items : ' || v_count_pm
             || crlf
             || 'Phase out periode : ' || ADD_MONTHS(TO_CHAR(TRUNC((SYSDATE), 'Day')-1,'DD-MON-YYYY'),1) ||'  s/d  ' ||  ADD_MONTHS(TO_CHAR(TRUNC((SYSDATE), 'Day')+5,'DD-MON-YYYY'),1)
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: text/csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || crlf
             || 'KN, ITEM CODE, ITEM DESC, UOM, IO, MD NUMBER, MD EXPIRY DATE (DD+MMM+YYYY), FIRST NOTIFICATION DATE (DD+MMM+YYYY), PHASE OUT (DD+MMM+YYYY)'
             || crlf;
             DBMS_OUTPUT.put_line ('POINT 2: ');
          UTL_SMTP.write_data (v_mail_conn, v_email);
          DBMS_OUTPUT.put_line ('POINT 3: ');
          FOR i IN c_list_emails
        LOOP
            v_list := v_list || i.KN || ',' || i.ITEM_CODE || ',' || REPLACE (REPLACE(REPLACE(i.item_desc,CHR(13)),CHR(10)), ',') || ',' || i.UOM || ',' ||
                    i.IO || ',' || i.MD_NUMBER || ',' || to_char(i.MD_EXPIRY_DATE,'DD-MON-YYYY') || ',' || 
                    CASE WHEN i.FIRST_NOTIFICATION_DATE IS NOT NULL THEN to_char(i.FIRST_NOTIFICATION_DATE,'DD-MON-YYYY') END || ',' || 
                    CASE WHEN i.PHASE_OUT IS NOT NULL THEN to_char(i.PHASE_OUT,'DD-MON-YYYY') END || crlf;
           DBMS_OUTPUT.put_line ('v_list: ' || v_list);
        END LOOP;  
        
            v_email := v_list;
           
           UTL_SMTP.write_data (v_mail_conn, v_email);
          
           DBMS_OUTPUT.put_line ('POINT 4: ');
           
           UTL_SMTP.close_data (v_mail_conn);
          UTL_SMTP.quit (v_mail_conn);
          DBMS_OUTPUT.put_line ('v_message: ' ||v_email );
    EXCEPTION
       WHEN OTHERS
       THEN
          v_err := SQLERRM;
    DBMS_OUTPUT.put_line ('v_err: ' ||v_err );
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;
    PROCEDURE send_mail_fg_3m
    IS
       v_mail_conn       UTL_SMTP.connection;
       v_err            VARCHAR2 (5000);
       v_message        VARCHAR2 (5000);
       crlf             VARCHAR2 (2) := CHR (13) || CHR (10);
       v_attachment     VARCHAR2 (200);
       v_email     VARCHAR2 (32767);
       v_string     VARCHAR2 (200);
       l_string     VARCHAR2 (200);
       v_list     VARCHAR2 (32767);
       v_query     VARCHAR2 (5000);
       v_from   VARCHAR2 (200);
       v_recipient     VARCHAR2 (32767);
       v_recipient1     VARCHAR2 (32767);
       v_subject        VARCHAR2 (200);
       v_rphno        VARCHAR2 (200);
       v_dopots        VARCHAR2 (200);
       v_pono         VARCHAR2 (200);
       v_filename         VARCHAR2 (5000);
       v_mail_host      VARCHAR2 (200) := fnd_profile.value('XXSHP_SMTP_CONN'); ------------'172.31.254.246'; --'knmail.kalbenutritionals.com';
       l_to_list   long;
       v_count      NUMBER;
       p_to array default array();
       v_count_fg NUMBER;
       v_count_pm NUMBER;
       cursor c_list_emails
        is
        select data_id, kn, item_code, item_desc, uom,io,supplier_name, part, md_number, md_expiry_date, first_notification_date, phase_out, creation_date, last_update_date
        from xxshp_md_expiry_stag where trunc(creation_date) = trunc(sysdate) and TYPE_EMAIL = 'B3M';
    BEGIN
        select count(*) into v_count_fg from xxshp_data_md_b3m_v where item_template like 'FG%';
       select count(*) into v_count_pm from xxshp_data_md_b3m_v where item_template like 'PM%';
       
       SELECT REPLACE(REPLACE(REPLACE(EMAIL, CHR(10), ''), CHR(13), ''), CHR(09), '')
          into v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2)) EMAIL
                      FROM (SELECT DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_LOOKUP_VALUES
                             WHERE LOOKUP_TYPE = 'XXSHP_LIST_EMAIL_MD_EXPIRY')
                     WHERE rn = cnt
        START WITH rn = 1
        CONNECT BY rn = PRIOR rn + 1);
    
       v_filename := ' filename= "MDEXP'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'_B3M'||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       v_recipient1 := 'reza.fajrin@kalbenutritionals.com,adhi.rizaldi@kalbenutritionals.com, debby.ardi@kalbenutritionals.com';
--       v_recipient := 'ardianto.ardi@kalbenutritionals.com';
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'MD Number Expiry Date : Notification - 3 Months To Go';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          
           UTL_SMTP.open_data (v_mail_conn);
          v_email :=
                'Date: '
             || TO_CHAR (SYSDATE, 'Dy, DD Mon YYYY hh24:mi:ss')
             || crlf
             || 'From: '
             || v_from
             || crlf
             || 'Subject: '
             || v_subject
             || crlf
             || 'To: '
             || v_recipient
             || crlf
             || 'CC: '
             || v_recipient1
             || crlf
             || 'MIME-Version: 1.0'
             || crlf
             ||                                          -- Use MIME mail standard
               'Content-Type: multipart/mixed;'
             || crlf
             || ' boundary="-----SECBOUND" '
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: text/plain;'
             || crlf
             || 'Content-Transfer_Encoding: 7bit'
             || crlf
             || crlf
             || ''                                    -- Mail Message text
             || crlf
             || 'Dear All,'
             || crlf
             || 'Please be aware that attached Finished Good and Packaging Material items MD Number would shortly expired in ' || to_char(add_months(sysdate,3),'MON-YYYY')
             || crlf
             || 'These item status has been changed to PHASE OUT '
             || crlf
             || 'Finished Good items : ' || v_count_fg
             || crlf
             || 'Packaging materials items : ' || v_count_pm
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: text/csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || crlf
             || 'KN, ITEM CODE, ITEM DESC, UOM, IO, MD NUMBER, MD EXPIRY DATE (DD+MMM+YYYY), FIRST NOTIFICATION DATE (DD+MMM+YYYY), PHASE OUT (DD+MMM+YYYY)'
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');   
          FOR i IN c_list_emails
        LOOP
            v_list := v_list || i.KN || ',' || i.ITEM_CODE || ',' || REPLACE (REPLACE(REPLACE(i.item_desc,CHR(13)),CHR(10)), ',') || ',' || i.UOM || ',' ||
                    i.IO || ',' || i.MD_NUMBER || ',' || to_char(i.MD_EXPIRY_DATE,'DD-MON-YYYY') || ',' || 
                    CASE WHEN i.FIRST_NOTIFICATION_DATE IS NOT NULL THEN to_char(i.FIRST_NOTIFICATION_DATE,'DD-MON-YYYY') END || ',' || 
                    CASE WHEN i.PHASE_OUT IS NOT NULL THEN to_char(i.PHASE_OUT,'DD-MON-YYYY') END || crlf;
           DBMS_OUTPUT.put_line ('v_list: ' || v_list); 

        END LOOP;  
        
            v_email := v_list;
           
           UTL_SMTP.write_data (v_mail_conn, v_email);
          
           DBMS_OUTPUT.put_line ('POINT 4: ');
           
           UTL_SMTP.close_data (v_mail_conn);
          UTL_SMTP.quit (v_mail_conn);
          DBMS_OUTPUT.put_line ('v_message: ' ||v_email );
          FOR r_data in data_change_status
         LOOP
                change_status(r_data.inventory_item_id, r_data.organization_id);
         END LOOP;
    EXCEPTION
       WHEN OTHERS
       THEN
          v_err := SQLERRM;
    DBMS_OUTPUT.put_line ('v_err: ' ||v_err );
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END; 
  PROCEDURE change_status(v_inventory_item_id NUMBER, v_organization_id NUMBER)
    IS
      l_item_table       EGO_Item_PUB.Item_Tbl_Type;
      x_item_table      EGO_Item_PUB.Item_Tbl_Type;
      x_return_status  VARCHAR2(1);
      x_msg_count     NUMBER(10);
      x_msg_data       VARCHAR2(1000);
      x_message_list   Error_Handler.Error_Tbl_Type;
    BEGIN
        --Apps Initialize
        fnd_global.apps_initialize
                                    (user_id      => 1554,                                  
                                     resp_id      => 50757,    
                                     resp_appl_id => 401); 

          -- Item definition
          l_item_table(1).Transaction_Type := 'UPDATE';
          l_item_table(1).Inventory_item_id := v_inventory_item_id;
          l_item_table(1).Organization_id := v_organization_id;
          l_item_table(1).Inventory_item_status_code := 'Phase Out';

        -- Calling procedure EGO_ITEM_PUB.Process_Items
          EGO_ITEM_PUB.Process_Items(
        --Input Parameters
                                     p_api_version   => 1.0,
                                     p_init_msg_list => FND_API.g_TRUE,
                                     p_commit        => FND_API.g_TRUE,
                                     p_Item_Tbl      => l_item_table,

        --Output Parameters
                                     x_Item_Tbl      => x_item_table,
                                     x_return_status => x_return_status,
                                     x_msg_count     => x_msg_count);

          DBMS_OUTPUT.PUT_LINE('Items updated Status ==>' || x_return_status);
          logf('Items updated Status ==>' || x_return_status);

          IF (x_return_status = FND_API.G_RET_STS_SUCCESS) THEN
            FOR i IN 1 .. x_item_table.COUNT LOOP
              DBMS_OUTPUT.PUT_LINE('Inventory Item Id :' ||to_char(x_item_table(i).Inventory_Item_Id));
              DBMS_OUTPUT.PUT_LINE('Organization Id   :' ||to_char(x_item_table(i).Organization_Id));
              logf('Inventory Item Id :' ||to_char(x_item_table(i).Inventory_Item_Id));
              logf('Organization Id   :' ||to_char(x_item_table(i).Organization_Id));
            END LOOP;
          ELSE
            DBMS_OUTPUT.PUT_LINE('Error Messages :');
            logf('Error Messages :');
            Error_Handler.GET_MESSAGE_LIST(x_message_list => x_message_list);
            FOR i IN 1 .. x_message_list.COUNT LOOP
              DBMS_OUTPUT.PUT_LINE(x_message_list(i).message_text);
              logf(x_message_list(i).message_text);
            END LOOP;
          END IF;
     END;
END;
/
