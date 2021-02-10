CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_NOTIF_ITEM_MASTER_PKG AS

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
      PROCEDURE send_mail_notification_pm(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'PM'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'PM'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
        --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,budi.prastowo@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,gitta@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com,rachmat.ardianto@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com';
        --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,tantawi.jauhari@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
        --AAR change Recipient with Lookup 20200723
        --v_recipient := 'chittania.devitasari@kalbenutritionals.com, nengky.ayani@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,muhammad.amri@kalbenutritionals.com,yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,labkemas@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,try.hutomo@kalbenutritionals.com,budi.prastowo@kalbenutritionals.com,gitta@kalbenutritionals.com,rachmat.ardianto@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com';
        --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,tantawi.jauhari@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
        SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PM'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PM'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
               
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE PM';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template PM'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190711*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_rm(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'RM'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'RM'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'glenn.chandra@kalbenutritionals.com,gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,gilang.wibisono@kalbenutritionals.com,junnior@kalbenutritionals.com,cathrine.aantosa@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com,isep.surya@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --v_recipient1 := 'agung.wirakusuma@kalbenutritionals.com,tantawi.jauhari@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,finalita.sufianti@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,wiwin.listyorini@kalbenutritionals.com,juli.astuti@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, glenn.chandra@kalbenutritionals.com,Gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com,isep.surya@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com,fiona@kalbenutritionals.com,bisma.pramundita@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,muhammad.amri@kalbenutritionals.com,patricia.tanu@kalbenutritionals.com,gita.giantina@kalbenutritionals.com,stefani.hartono@kalbenutritionals.com,dhi.harnanda@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,tantawi.jauhari@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,juli@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ari.ramdan@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_RM'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_RM'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE RM';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template RM'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_base(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'BASE MAKE'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'BASE MAKE'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'glenn.chandra@kalbenutritionals.com,gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,gilang.wibisono@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com';
       --v_recipient1 := 'agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,finalita.sufianti@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,wiwin.listyorini@kalbenutritionals.com,juli.astuti@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, glenn.chandra@kalbenutritionals.com,gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,famela.apriyanto@kalbenutritionals.com,isep.surya@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com,fiona@kalbenutritionals.com,bisma.pramundita@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,muhammad.amri@kalbenutritionals.com,patricia.tanu@kalbenutritionals.com,gita.giantina@kalbenutritionals.com,stefani.hartono@kalbenutritionals.com,dhi.harnanda@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,juli@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ari.ramdan@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_BASE'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_BASE'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE BASE MAKE';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template BASE MAKE'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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

PROCEDURE send_mail_notification_fgsam(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'FGSA MAKE'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'FGSA MAKE'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com';
       --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, nengky.ayani@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,labkemas@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,try.hutomo@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_zrita@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_FGSA_MAKE'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_FGSA_MAKE'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE FGSA MAKE';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template FGSA MAKE'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_fgsab(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'FGSA BUY'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'FGSA BUY'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,cathrine.santosa@kalbenutritionals.com';
       --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, nengky.ayani@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,labkemas@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,try.hutomo@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_FGSA_BUY'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_FGSA_BUY'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE FGSA BUY';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template FGSA BUY'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_int(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'INTERMEDIATE'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and mit.template_name = 'INTERMEDIATE'
                  and xis.status <> 'E'; -- Add by AAR 06012020;
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,cathrine.santosa@kalbenutritionals.com';
       --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, nengky.ayani@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,labkemas@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,try.hutomo@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ari.ramdan@kalbenutritionals.com,ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_INTERMEDIATE'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_INTERMEDIATE'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE INTERMEDIATE';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template INTERMEDIATE'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_prc(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'PREMIX COMPILE'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and xis.status <> 'E' -- Add by AAR 06012020
                  and mit.template_name = 'PREMIX COMPILE';
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,cathrine.santosa@kalbenutritionals.com';
       --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, glenn.chandra@kalbenutritionals.com,gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,isep.surya@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com,fiona@kalbenutritionals.com,bisma.pramundita@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,patricia.tanu@kalbenutritionals.com,gita.giantina@kalbenutritionals.com,stefani.hartono@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,dhi.harnanda@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,juli@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ari.ramdan@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PREMIX_COMPILE'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PREMIX_COMPILE'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
       
       --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE PREMIX COMPILE';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template PREMIX COMPILE'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE send_mail_notification_prm(errbuf OUT VARCHAR2, retcode OUT NUMBER)
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
       v_Submission_date_from DATE;
       v_Submission_date_to DATE;
       --p_to array default array();
       v_item_code varchar2(40);
       
       --untuk isi dalam xls
       cursor c_list_emails
        is
        select   
                  xim.item_code 
                , xim.item_description
                , xim.primary_uom
                , mit.template_name
                , xim.status_reg
                , fu1.user_name submitted_by
                , xis.creation_date submission_date
                , fu2.user_name last_update_by
                , xim.last_update_date last_update_on
                , (trunc(xim.last_update_date) - trunc(xis.creation_date)) process_lead_time
                , case when (select count(*) from xxshp_inv_master_item_toll where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_toll_fee
                , case when (select count(*) from xxshp_inv_master_item_unstd where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_unstandard
                , mp.organization_code org_assignment
                , case when (select count(*) from xxshp_inv_master_item_kn where reg_hdr_id = xim.reg_hdr_id) > 0 then 'Y' else 'N' end item_pecah_kn
                , status_idc
                , status_quality
                , status_planning
                , status_fa
                , status_cat_inv
                , status_cat_gl
                , status_cat_pur
                , status_cat_wms
                , status_cat_mar_fa
                , status_uom_conv
                , status_subinv
                , status_asl
                , status_mfg
                , status_bod
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and mit.template_name = 'PREMIX MIX'
             and xis.status <> 'E' -- Add by AAR 06012020
        order by xim.item_code, mp.organization_code;

    BEGIN
        --select count(item_code) into v_item_code from xxshp_inv_master_item_reg where status_reg <> 'SUCCESS';
        select   
                count(xim.item_code) into v_item_code
        from 
                  xxshp_inv_master_item_reg xim
                  , mtl_item_templates mit
                  , xxshp_inv_master_item_stg xis
                  , xxshp_inv_master_item_org xio
                  , mtl_parameters mp
                  , fnd_user fu1, fnd_user fu2
        where 1=1
                  and xim.template_id = mit.template_id
                  and xim.item_code = xis.segment1
                  and xim.reg_hdr_id = xio.reg_hdr_id
                  and xio.asgn_organization_id = mp.organization_id
                  and xis.created_by = fu1.user_id
                  and xim.last_updated_by = fu2.user_id
                  and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
                  and mp.organization_code = 'KNS'
                  and xis.status <> 'E' -- Add by AAR 06012020
                  and mit.template_name = 'PREMIX MIX';
        
        SELECT
                 (SELECT distinct min(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)
                ,(SELECT distinct max(TO_DATE(xis.creation_date)) FROM xxshp_inv_master_item_stg xis)              
        INTO      v_Submission_date_from
                , v_Submission_date_to
        from    
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
             and rownum < 2;
             
    --untuk nama file attachment xls nya
       v_filename := ' filename= "NOTIFIKASI_ITEM_MASTER_REGISTER'|| TO_CHAR(SYSDATE,'DDMONYYYY')||'.csv"';
       v_from := fnd_profile.value('XXSHP_EMAIL_FROM');   ------'no-reply@kalbenutritionals.com';
       
       -- 20190305 Ardianto change recipient
       --v_recipient := 'yulius.putra@kalbenutritionals.com,astuti@kalbenutritionals.com,dini.faza@kalbenutritionals.com,lab.kemas1@kalbenutritionals.com,lab.kemas2@kalbenutritionals.com,surati@kalbenutritionals.com,mega.fridayanti@kalbenutritionals.com,rivan.juniawan@kalbenutritionals.com,maulana.assayidin@kalbenutritionals.com,wilson.christoper@kalbenutritionals.com,devi.ardelia@kalbenutritionals.com,dini.anggraini@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,cathrine.santosa@kalbenutritionals.com';
       --v_recipient1 := 'ihsan.hanifa@kalbenutritionals.com,ahmad.muttaqin@kalbenutritionals.com,emiliana.yulianti@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,evi.rachmaniatun@kalbenutritionals.com,dwina.azrita@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,agung.wirakusuma@kalbenutritionals.com,debby.ardi@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       --v_recipient := 'chittania.devitasari@kalbenutritionals.com, glenn.chandra@kalbenutritionals.com,gabrielya.karmadi@kalbenutritionals.com,yulany.indeswari@kalbenutritionals.com,yohana.nareswari@kalbenutritionals.com,mariella.ardiyanti@kalbenutritionals.com,stella.kurniawan@kalbenutritionals.com,florentina.laut@kalbenutritionals.com,muhammad.firhani@kalbenutritionals.com,endy.hermawan@kalbenutritionals.com,albert.cahya@kalbenutritionals.com,felicia.kusnakhin@kalbenutritionals.com,pradhini.aripin@kalbenutritionals.com,ratu.mawaddah@kalbenutritionals.com,theresia.austin@kalbenutritionals.com,angguni.fauziah@kalbenutritionals.com,suryati@kalbenutritionals.com,ari.widiastuti@kalbenutritionals.com,anggita.septina@kalbenutritionals.com,lab.prodev2@kalbenutritionals.com,nana.sumarna@kalbenutritionals.com,nengky.ayani@kalbenutritionals.com,Famela.apriyanto@kalbenutritionals.com,isep.surya@kalbenutritionals.com,heru.herdiana@kalbenutritionals.com,fiona@kalbenutritionals.com,bisma.pramundita@kalbenutritionals.com,ayulia.setiawan@kalbenutritionals.com,clement.eugene@kalbenutritionals.com,pitra.jaya@kalbenutritionals.com,marisa.helen@kalbenutritionals.com,rizka.hapsari@kalbenutritionals.com,patricia.tanu@kalbenutritionals.com,gita.giantina@kalbenutritionals.com,stefani.hartono@kalbenutritionals.com,Wachid.sadali@kalbenutritionals.com,Husni.thamrin@kalbenutritionals.com,Irfan.warehouse@kalbenutritionals.com,richardus.ismanto@kalbenutritionals.com,dhi.harnanda@kalbenutritionals.com';
       --v_recipient1 := 'adhi.rizaldi@kalbenutritionals.com, agung.wirakusuma@kalbenutritionals.com,decee.aryani@kalbenutritionals.com,aman.rustaman@kalbenutritionals.com,d_azrita@kalbenutritionals.com,ria.suryani@kalbenutritionals.com,juli@kalbenutritionals.com,evi@kalbenutritionals.com,debby.ardi@kalbenutritionals.com,ari.ramdan@kalbenutritionals.com';
       --AAR change Recipient with Lookup 20200723
       -- 20190305 Ardianto change recipient
       
       --AAR change Recipient with Lookup 20200723
       
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PREMIX'
                                   AND val.hierarchy_level = 1)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
                
       SELECT REPLACE (REPLACE (REPLACE (EMAIL, CHR (10), ''), CHR (13), ''),
                        CHR (09),
                        '')
          INTO v_recipient1
          FROM (    SELECT TRIM (SUBSTR (SYS_CONNECT_BY_PATH (DESCRIPTION, ','), 2))
                              EMAIL
                      FROM (SELECT VAL.DESCRIPTION,
                                   ROW_NUMBER () OVER (ORDER BY VAL.DESCRIPTION) rn,
                                   COUNT (*) OVER () cnt
                              FROM FND_FLEX_VALUES_VL val, FND_FLEX_VALUE_SETS vset
                             WHERE     1 = 1
                                   AND vset.flex_value_set_id = val.flex_value_set_id
                                   AND val.enabled_flag = 'Y'
                                   AND (   val.start_date_active IS NULL
                                        OR val.start_date_active <= SYSDATE)
                                   AND (   val.end_date_active IS NULL
                                        OR val.end_date_active >= SYSDATE)
                                   AND flex_value_set_name = 'MAIL_ITEMREG_PREMIX'
                                   AND val.hierarchy_level = 2)
                     WHERE rn = cnt
                START WITH rn = 1
                CONNECT BY rn = PRIOR rn + 1);
          
         --AAR change Recipient with Lookup 20200723
       
       --subject email
       DBMS_OUTPUT.put_line ('POINT AA: ');
       v_subject := 'NOTIFIKASI ITEM MASTER REGISTRATION: NOTIFICATION - TEMPLATE PREMIX MIX';
       v_attachment := 'erer';
       DBMS_OUTPUT.put_line ('POINT CC: ');
       UTL_TCP.close_all_connections;
          
          v_mail_conn := UTL_SMTP.open_connection (v_mail_host, 25); -- Opens a connection to an SMTP server
          UTL_SMTP.helo (v_mail_conn, v_mail_host); -- Performs initial handshaking with SMTP server after connecting
          UTL_SMTP.mail (v_mail_conn, v_from); -- Initiates a mail transaction with the server
          --UTL_SMTP.rcpt(v_mail_conn, 'damara.muharami@kalbenutritionals.com');
          process_recipients(v_mail_conn, v_recipient);
          process_recipients(v_mail_conn, v_recipient1);
--          LOGF('v_receipt'||v_recipient);
          
          DBMS_OUTPUT.put_line ('POINT 1: ');
          --isi body email
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
             || 'You have '||v_item_code || ' Item Code registration need to be completed (details can be found in the attachment).'   
             || crlf
             || 'Please find the task in your ORACLE account.'
             || crlf
             || crlf
             || 'NOTE - Please do not reply since this is an automatically generated e-mail.' -- Message text
             || crlf
             || crlf
             || '-------SECBOUND'
             || crlf
             || 'Content-Type: csv;'
             || crlf
             || ' name="excel.csv"'
             || crlf
             || 'Content-Transfer_Encoding: 8bit'
             || crlf
             || 'Content-Disposition: attachment;'
             || crlf
             || v_filename
             || crlf
             || 'Report Item Master Registration Status - Template PREMIX MIX'
             || crlf
             || 'PT. Sanghiang Perkasa'
             || crlf
             || crlf
             || 'Submission Date:  ' || v_Submission_date_from || ' - ' || v_Submission_date_to
             || crlf
             || crlf
             || 'Item Code, Item Desc, UOM, Item Template, Registration Status, Submitted By, Submission Date, Latest Update By, Latest Update On, Process Lead Time (Days), Item Toll Fee (Y/N), Item Unstandard (Y/N), Org Assignment (IO), Item Pecah KN (Y/N), IDC Status, Quality Status,    Planning Status,    FA Status,    Item Category Inventory Status,    Item Category GL Class Status,    Item Category Purchasing Status,    Item Category WMS Status,    Item Category MAR & FA Status,    UOM Conversion Status,    Item Subinventory Status,    Approved Supplier List Status,    Manufacturers Status,    Bill of Distribution Status'/*edit by GDS 20190722*/
             || crlf;
             
             DBMS_OUTPUT.put_line ('POINT 2: ');

          UTL_SMTP.write_data (v_mail_conn, v_email);
          
          DBMS_OUTPUT.put_line ('POINT 3: ');
          
          FOR i IN c_list_emails

        LOOP
            v_list := v_list || i.item_code || ',' || REPLACE (i.item_description, UNISTR('\002C')) || ',' 
                    || i.primary_uom || ',' || i.template_name ||',' 
                    || i.status_reg || ',' || i.submitted_by ||',' 
                    || i.submission_date || ',' || i.last_update_by ||',' 
                    || i.last_update_on || ',' 
                    || i.process_lead_time ||',' 
                    || i.item_toll_fee || ',' || i.item_unstandard ||',' 
                    || i.org_assignment || ',' || i.item_pecah_kn ||',' 
                    || i.status_idc || ',' || i.status_quality ||',' 
                    || i.status_planning || ',' || i.status_fa ||',' 
                    || i.status_cat_inv || ',' || i.status_cat_gl ||',' 
                    || i.status_cat_pur || ',' || i.status_cat_wms ||',' 
                    || i.status_cat_mar_fa || ',' || i.status_uom_conv ||',' 
                    || i.status_subinv || ',' || i.status_asl ||',' 
                    || i.status_mfg || ',' || i.status_bod || crlf;
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
    
PROCEDURE validations(errbuf OUT VARCHAR2, retcode OUT NUMBER)
IS
    y varchar2(100);
    x number;
BEGIN    
    FOR i IN (select distinct mit.template_name
        from 
                  xxshp_inv_master_item_reg xim
                , mtl_item_templates mit
                , xxshp_inv_master_item_stg xis
                , xxshp_inv_master_item_org xio
                , mtl_parameters mp
                , fnd_user fu1, fnd_user fu2
        where 1=1
             and xim.template_id = mit.template_id
             and xim.item_code = xis.segment1
             and xim.reg_hdr_id = xio.reg_hdr_id
             and xio.asgn_organization_id = mp.organization_id
             and xis.created_by = fu1.user_id
             and xim.last_updated_by = fu2.user_id
             and xim.status_reg not in ( 'SUCCESS', 'OBSOLETE')
             and mp.organization_code = 'KNS'
        order by mit.template_name)
        
        LOOP
        if i.template_name = 'PM'
            then 
            begin
            XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_pm(y,x);
            end;
            elsif
              i.template_name = 'RM'
              then
              begin
              XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_rm(y,x);
              end;
              elsif
                i.template_name = 'BASE MAKE'
                then
                begin
                XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_base(y,x);
                end;
                    elsif
                    i.template_name = 'FGSA MAKE'
                    then
                    begin
                    XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_fgsam(y,x);
                    end;
                        elsif
                        i.template_name = 'FGSA BUY'
                        then
                        begin
                        XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_fgsab(y,x);
                        end;
                           elsif
                           i.template_name = 'INTERMEDIATE'
                           then
                           begin
                           XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_int(y,x);
                           end;
                             elsif
                             i.template_name = 'PREMIX COMPILE'
                             then
                             begin
                             XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_prc(y,x);
                             end;
                               elsif
                               i.template_name = 'PREMIX MIX'
                               then
                               begin
                               XXSHP_NOTIF_ITEM_MASTER_PKG.send_mail_notification_prm(y,x);
                               end;
                        end if;
                        LOGF(i.template_name||' TEST');
        END LOOP;
        
END;
END XXSHP_NOTIF_ITEM_MASTER_PKG;
/
