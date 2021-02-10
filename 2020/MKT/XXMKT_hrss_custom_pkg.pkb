CREATE OR REPLACE PACKAGE BODY APPS.xxmkt_hrss_custom_pkg
AS
   PROCEDURE initialize_ap_concurrent
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- Initialize
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'HRSS';
      EXCEPTION
         WHEN NO_DATA_FOUND
         
         THEN
            g_user_id := 1090;
      END;

      g_resp_id := 20639;                                            -- 50778;
      g_resp_appl_id := 200;
      g_group_security_id := 0;
      g_server_id := 13126;
      fnd_global.apps_initialize (g_user_id,
                                  g_resp_id,
                                  g_resp_appl_id,
                                  g_group_security_id,
                                  g_server_id);
      -- USER_ID, RESP_ID, RESP_APPL_ID, GROUP_SECURITY_ID, SERVER_ID                                  -- SHPTEST := 7109
      COMMIT;
   END initialize_ap_concurrent;

   PROCEDURE initialize_pr_concurrent
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- Initialize
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'AMEN';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            g_user_id := 1090;
      END;

      g_resp_id := 20707;                                            -- 50820;
      g_resp_appl_id := 201;
      g_group_security_id := 0;
      g_server_id := 13126;                                 -- SHPTEST := 7109
      fnd_global.apps_initialize (g_user_id,
                                  g_resp_id,
                                  g_resp_appl_id,
                                  g_group_security_id,
                                  g_server_id);
      -- USER_ID, RESP_ID, RESP_APPL_ID, GROUP_SECURITY_ID, SERVER_ID TEST2
      COMMIT;
   END initialize_pr_concurrent;


   PROCEDURE initialize_asset_concurrent
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- Initialize
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'AMEN';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            g_user_id := 1090;
      END;

      g_resp_id := 50820;
      g_resp_appl_id := 201;
      g_group_security_id := 0;
      g_server_id := 13126;                                 -- SHPTEST := 7109
      fnd_global.apps_initialize (g_user_id,
                                  g_resp_id,
                                  g_resp_appl_id,
                                  g_group_security_id,
                                  g_server_id);
      -- USER_ID, RESP_ID, RESP_APPL_ID, GROUP_SECURITY_ID, SERVER_ID TEST2
      COMMIT;
   END initialize_asset_concurrent;


   PROCEDURE run_hrss_ap_concurrent (p_req_id          OUT INT,
                                     p_batch_name   IN     VARCHAR2)
   IS
   BEGIN
      p_req_id := 0;
      --    p_req_id := FND_REQUEST.SUBMIT_REQUEST(
      --                    application   => 'XSHP'
      --                    , program     => 'XSHPAPXIIMPT'
      --                    , description => 'Payables Open Interface Import for Sanghiang AP Invoices Legacy System Import'
      --                    , start_time  => SYSDATE
      --                    , sub_request => FALSE
      --                    , argument1   => 82 -- OPERATING UNIT
      --                    , argument2   => 'HRSS' -- SOURCE
      --                    , argument3   => p_batch_name -- GROUP
      --                    , argument4   => p_batch_name -- BATCH NAME
      --                    , argument5   => NULL -- HOLD NAME
      --                    , argument6   => NULL -- HOLD REASON
      --                    , argument7   => NULL -- GL DATE
      --                    , argument8   => 'Y' -- PURGE
      --                    , argument9   => 'N' -- TRACE SWITCH
      --                    , argument10  => 'N' -- DEBUG SWITCH
      --                    , argument11  => 'N' -- SUMMARIZE REPORT
      --                    , argument12  => 1000 -- COMMIT BATCH SIZE
      --                    , argument13  => NULL --1540 -- USER_ID
      --                    , argument14  => NULL -- LOGIN_ID
      --                    );
      p_req_id :=
         fnd_request.submit_request (
            application   => 'SQLAP',
            program       => 'APXIIMPT',
            description   => 'Payables Open Interface Import',
            start_time    => SYSDATE,
            sub_request   => FALSE,
            argument1     => fnd_profile.VALUE ('ORG_ID')    -- OPERATING UNIT
                                                         ,
            argument2     => 'HRSS'                                  -- SOURCE
                                   ,
            argument3     => p_batch_name                             -- GROUP
                                         ,
            argument4     => p_batch_name                        -- BATCH NAME
                                         ,
            argument5     => NULL                                 -- HOLD NAME
                                 ,
            argument6     => NULL                               -- HOLD REASON
                                 ,
            argument7     => NULL                                   -- GL DATE
                                 ,
            argument8     => 'Y'                                      -- PURGE
                                ,
            argument9     => 'N'                               -- TRACE SWITCH
                                ,
            argument10    => 'N'                               -- DEBUG SWITCH
                                ,
            argument11    => 'N'                           -- SUMMARIZE REPORT
                                ,
            argument12    => 1000                         -- COMMIT BATCH SIZE
                                 ,
            argument13    => NULL                            --1540 -- USER_ID
                                 ,
            argument14    => NULL                                  -- LOGIN_ID
                                 );
   END run_hrss_ap_concurrent;

   PROCEDURE run_hrss_ap_validation (p_ret_id        OUT INT,
                                     p_req_id     IN     INT,
                                     p_batch_id   IN     INT)
   IS
      lb_flag              BOOLEAN;
      ln_inv_vald_req_id   NUMBER;
      x_phase              VARCHAR2 (20);
      x_status             VARCHAR2 (20);
      x_dev_phase          VARCHAR2 (20);
      x_dev_status         VARCHAR2 (20);
      x_message            VARCHAR2 (240);
   BEGIN
      -- Waiting for the Payables Import program to end
      lb_flag :=
         fnd_concurrent.wait_for_request (p_req_id,
                                          g_intval_time,
                                          g_max_time,
                                          x_phase,
                                          x_status,
                                          x_dev_phase,
                                          x_dev_status,
                                          x_message);

      IF (x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL')
      THEN
         -- Submit the Invoice validation program
         ln_inv_vald_req_id :=
            fnd_request.submit_request (
               application   => 'SQLAP',
               program       => 'APPRVL',
               start_time    => SYSDATE,
               sub_request   => FALSE,
               argument1     => fnd_profile.VALUE ('ORG_ID'),
               argument2     => 'NEW',
               argument3     => p_batch_id,
               argument4     => NULL,
               argument5     => NULL,
               argument6     => NULL,
               argument7     => NULL,
               argument8     => NULL,
               argument9     => NULL,
               argument10    => 'N',
               argument11    => 1000,
               argument13    => NULL);

         EXECUTE IMMEDIATE 'COMMIT';

         IF ln_inv_vald_req_id <> 0
         THEN
            lb_flag := NULL;
            -- Wait for Invoice validation program to complete
            lb_flag :=
               fnd_concurrent.wait_for_request (ln_inv_vald_req_id,
                                                g_intval_time,
                                                g_max_time,
                                                x_phase,
                                                x_status,
                                                x_dev_phase,
                                                x_dev_status,
                                                x_message);

            IF (x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL')
            THEN
               p_ret_id := 100;
            ELSE
               p_ret_id := -1;
            END IF;
         END IF;
      ELSE
         p_ret_id := -1;
      END IF;
   END run_hrss_ap_validation;

   PROCEDURE run_hrss_print_ap_rfp (g_req_id       OUT INT,
                                    p_batch_from       VARCHAR2,
                                    p_batch_to         VARCHAR2,
                                    p_user             VARCHAR2)
   IS
   BEGIN
      g_req_id := 0;
      g_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_APRRFP_HRRS',
            description   => 'SHP - AP Request For Payment HRSS',
            start_time    => SYSDATE,
            sub_request   => FALSE,
            argument1     => fnd_profile.VALUE ('ORG_ID')    -- OPERATING UNIT
                                                         ,
            argument2     => p_batch_from                            -- SOURCE
                                         ,
            argument3     => p_batch_to                               -- GROUP
                                       ,
            argument4     => p_user                              -- BATCH NAME
                                   );
   END run_hrss_print_ap_rfp;

   PROCEDURE run_hrss_print_ap_rfa (g_req_id       OUT INT,
                                    p_type             VARCHAR2,
                                    p_batch_name       VARCHAR2,
                                    p_user             VARCHAR2)
   IS
   BEGIN
      g_req_id := 0;
      g_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_APRRFA_HRSS',
            description   => 'SHP - AP Request For Advance HRSS',
            start_time    => SYSDATE,
            sub_request   => FALSE,
            argument1     => fnd_profile.VALUE ('ORG_ID')    -- OPERATING UNIT
                                                         ,
            argument2     => p_type                                  -- SOURCE
                                   ,
            argument3     => p_batch_name                            -- SOURCE
                                         ,
            argument4     => p_batch_name                             -- GROUP
                                         ,
            argument5     => p_user                              -- BATCH NAME
                                   );
   END run_hrss_print_ap_rfa;

   PROCEDURE run_hrss_pr_concurrent (g_req_id2 OUT INT, p_batch_id IN INT)
   IS
   BEGIN
      g_req_id2 := 0;
      -- Submit concurrent program
      --    g_req_id2 := FND_REQUEST.SUBMIT_REQUEST(
      --                    application   => 'PO'
      --                    , program     => 'XSHPREQIMPORT' --'POCIRM'
      --                    , description => 'XSHP Dolphine Requisition Import'
      --                    , start_time  => SYSDATE
      --                    , sub_request => FALSE
      --                    , argument1   => 'AMEN' -- INTERFACE SOURCE CODE
      --                    , argument2   => p_batch_id -- BATCH ID
      --                    , argument3   => 'VENDOR' -- GROUP BY
      --                    , argument4   => NULL -- LAST_REQUISITION_NUMBER
      --                    , argument5   => 'N' -- MULTI_DISTRIBUTIONS
      --                    , argument6   => 'Y' -- INITIATE_REQAPPR_AFTER_REQIMP
      --                   );
      g_req_id2 :=
         fnd_request.submit_request (application   => 'PO',
                                     program       => 'REQIMPORT'   --'POCIRM'
                                                                 ,
                                     description   => 'Requisition Import',
                                     start_time    => SYSDATE,
                                     sub_request   => FALSE,
                                     argument1     => 'AMEN' -- INTERFACE SOURCE CODE
                                                            ,
                                     argument2     => p_batch_id   -- BATCH ID
                                                                ,
                                     argument3     => 'VENDOR'     -- GROUP BY
                                                              ,
                                     argument4     => NULL -- LAST_REQUISITION_NUMBER
                                                          ,
                                     argument5     => 'N' -- MULTI_DISTRIBUTIONS
                                                         ,
                                     argument6     => 'Y' -- INITIATE_REQAPPR_AFTER_REQIMP
                                                         );
   --COMMIT;
   END run_hrss_pr_concurrent;

   PROCEDURE run_hrss_print_requisition (g_req_id    OUT INT,
                                         p_req_num       VARCHAR2,
                                         p_user          VARCHAR2)
   IS
   BEGIN
      g_req_id := 0;
      g_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_REQ',
            description   => 'SHP - Requisition',
            start_time    => SYSDATE,
            sub_request   => FALSE,
            argument1     => fnd_profile.VALUE ('ORG_ID')    -- OPERATING UNIT
                                                         ,
            argument2     => p_user                                  -- SOURCE
                                   ,
            argument3     => NULL,
            argument4     => NULL,
            argument5     => p_req_num                   -- Requisition Number
                                      ,
            argument6     => p_req_num);
   END run_hrss_print_requisition;

   PROCEDURE run_hrss_assetmutation (p_req_id OUT INT)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_FA_MUTATION',
            description   => 'SHP - Interface FA Asset Mutasi',
            start_time    => SYSDATE--                    , sub_request => FALSE
                                    --                    , argument1   => NULL -- OPERATING UNIT
                                    --                    , argument2   => NULL -- SOURCE
                                    --                    , argument3   => NULL -- GROUP
                                    --                    , argument4   => NULL -- BATCH NAME
                                    --                    , argument5   => NULL -- HOLD NAME
                                    --                    , argument6   => NULL -- HOLD REASON
                                    --                    , argument7   => NULL -- GL DATE
                                    --                    , argument8   => 'Y' -- PURGE
                                    --                    , argument9   => 'N' -- TRACE SWITCH
                                    --                    , argument10  => 'N' -- DEBUG SWITCH
                                    --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                    --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                    --                    , argument13  => NULL --1540 -- USER_ID
                                    --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_hrss_assetmutation;

   PROCEDURE run_hrss_assetretirement (p_req_id            OUT INT,
                                       p_retirement_type       VARCHAR2)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_FA_ASSET_RETIREMENT',
            description   => 'SHP - INTERface FA Asset Retirement',
            start_time    => SYSDATE --                    , sub_request => FALSE
                                    ,
            argument1     => 'DISPOSAL/CORRECTION'           -- OPERATING UNIT
                                                  --                    , argument2   => p_retirement_type -- SOURCE
                                                  --                    , argument3   => NULL -- GROUP
                                                  --                    , argument4   => NULL -- BATCH NAME
                                                  --                    , argument5   => NULL -- HOLD NAME
                                                  --                    , argument6   => NULL -- HOLD REASON
                                                  --                    , argument7   => NULL -- GL DATE
                                                  --                    , argument8   => 'Y' -- PURGE
                                                  --                    , argument9   => 'N' -- TRACE SWITCH
                                                  --                    , argument10  => 'N' -- DEBUG SWITCH
                                                  --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                                  --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                                  --                    , argument13  => NULL --1540 -- USER_ID
                                                  --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_hrss_assetretirement;

   PROCEDURE run_hrss_assetsale (p_req_id            OUT INT,
                                 p_retirement_type       VARCHAR2)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_FA_ASSET_RETIREMENT',
            description   => 'SHP - INTERface FA Asset Retirement',
            start_time    => SYSDATE --                    , sub_request => FALSE
                                    ,
            argument1     => 'SALE'                          -- OPERATING UNIT
                                   --                    , argument2   => p_retirement_type -- SOURCE
                                   --                    , argument3   => NULL -- GROUP
                                   --                    , argument4   => NULL -- BATCH NAME
                                   --                    , argument5   => NULL -- HOLD NAME
                                   --                    , argument6   => NULL -- HOLD REASON
                                   --                    , argument7   => NULL -- GL DATE
                                   --                    , argument8   => 'Y' -- PURGE
                                   --                    , argument9   => 'N' -- TRACE SWITCH
                                   --                    , argument10  => 'N' -- DEBUG SWITCH
                                   --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                   --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                   --                    , argument13  => NULL --1540 -- USER_ID
                                   --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_hrss_assetsale;


   PROCEDURE run_hrss_assetaddition (p_req_id OUT INT)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'XXMKT',
            program       => 'XXMKT_FA_INTF_ADDITION',
            description   => 'SHP - Interface FA Asset Addition',
            start_time    => SYSDATE--                    , sub_request => FALSE
                                    --                    , argument1   => NULL -- OPERATING UNIT
                                    --                    , argument2   => NULL -- SOURCE
                                    --                    , argument3   => NULL -- GROUP
                                    --                    , argument4   => NULL -- BATCH NAME
                                    --                    , argument5   => NULL -- HOLD NAME
                                    --                    , argument6   => NULL -- HOLD REASON
                                    --                    , argument7   => NULL -- GL DATE
                                    --                    , argument8   => 'Y' -- PURGE
                                    --                    , argument9   => 'N' -- TRACE SWITCH
                                    --                    , argument10  => 'N' -- DEBUG SWITCH
                                    --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                    --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                    --                    , argument13  => NULL --1540 -- USER_ID
                                    --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_hrss_assetaddition;

   PROCEDURE add_attachment_api (x_status                     OUT NUMBER,
                                 p_file_name               IN     VARCHAR2,
                                 p_requisition_header_id   IN     NUMBER,
                                 p_description             IN     VARCHAR2)
   IS
      l_result_set_curr   result_set_type;
   BEGIN
      -- insert to table staging
      processing_to_fnd_lobs (p_file_name);
      -- start loading the file into FND schema of Oracle Applications
      -- edited by Nosa. fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
      load_file_details (p_name            => p_file_name,
                         result_set_curr   => l_result_set_curr);
      upload_file (v_filename    => p_file_name,
                   x_access_id   => x_access_id,
                   x_file_id     => x_file_id);
      COMMIT;
      -- attach file
      --fnd_global.apps_initialize (1091, 50532, 201);
      attach_file (p_access_id               => x_access_id,
                   p_file_id                 => x_file_id,
                   p_filename                => p_file_name,
                   p_requisition_header_id   => p_requisition_header_id,
                   p_description             => p_description);
      --return
      x_status := 100;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         --return
         x_status := -1;
   END add_attachment_api;

   PROCEDURE processing_to_fnd_lobs (p_file_name IN VARCHAR2)
   IS
      --filename              VARCHAR2(200) := p_file_name;
      x_blob        BLOB;
      fils          BFILE := BFILENAME ('FILEUPLOADS', p_file_name);
      blob_length   INTEGER;
   BEGIN
      -- Obtain the size of the blob file
      DBMS_LOB.fileopen (fils, DBMS_LOB.file_readonly);
      blob_length := DBMS_LOB.getlength (fils);
      DBMS_LOB.fileclose (fils);

      -- Insert a new record into the table containing the
      -- filename you have specified and a LOB LOCATOR.
      -- Return the LOB LOCATOR and assign it to x_blob.
      INSERT INTO XXMKT_TEST_FILES (pl_id, pl_name, pl_file)
           VALUES (1, p_file_name, EMPTY_BLOB ())
        RETURNING pl_file
             INTO x_blob;

      -- Load the file into the database as a BLOB
      DBMS_LOB.OPEN (fils, DBMS_LOB.lob_readonly);
      DBMS_LOB.OPEN (x_blob, DBMS_LOB.lob_readwrite);
      DBMS_LOB.loadfromfile (x_blob, fils, blob_length);
      -- Close handles to blob and file
      DBMS_LOB.CLOSE (x_blob);
      DBMS_LOB.CLOSE (fils);
      COMMIT;
      -- Confirm insert by querying the database
      -- for LOB length information and output results
      blob_length := 0;

      SELECT DBMS_LOB.getlength (pl_file)
        INTO blob_length
        FROM XXMKT_TEST_FILES
       WHERE pl_name = p_file_name;

      DBMS_OUTPUT.put_line (
            'Successfully inserted BLOB '''
         || p_file_name
         || ''' of size '
         || blob_length
         || ' bytes.');
   END processing_to_fnd_lobs;

   PROCEDURE load_file_details (p_name            IN     VARCHAR2,
                                result_set_curr      OUT result_set_type)
   AS
      l_error             VARCHAR2 (2000);
      l_result_set_curr   result_set_type;
   BEGIN
      INSERT INTO fnd_lobs_document (NAME,
                                     mime_type,
                                     doc_size,
                                     content_type,
                                     blob_content)
         SELECT pl_name,
                'application/pdf',
                DBMS_LOB.getlength (pl_file),
                'BINARY',
                pl_file
           FROM XXMKT_TEST_FILES
          WHERE pl_name = p_name;

      OPEN result_set_curr FOR
         SELECT blob_content
           FROM fnd_lobs_document
          WHERE NAME = p_name;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
         l_error := 'LOAD_FILE_DETAILS - OTHERS' || SUBSTR (SQLERRM, 2000);
         DBMS_OUTPUT.put_line (l_error);
   END load_file_details;

   FUNCTION confirm_upload (
      access_id          NUMBER,
      file_name          VARCHAR2,
      program_name       VARCHAR2 DEFAULT NULL,
      program_tag        VARCHAR2 DEFAULT NULL,
      expiration_date    DATE DEFAULT NULL,
      LANGUAGE           VARCHAR2 DEFAULT USERENV ('LANG'),
      wakeup             BOOLEAN DEFAULT FALSE)
      RETURN NUMBER
   IS
      fid          NUMBER := -1;
      fn           VARCHAR2 (256);
      mt           VARCHAR2 (240);
      bloblength   NUMBER; -- bug 3045375, added variable to set length of blob.
      ufslim       NUMBER;
   BEGIN
      IF (fnd_gfm.authenticate (confirm_upload.access_id))
      THEN
         SELECT fnd_lobs_s.NEXTVAL INTO fid FROM DUAL;

         DBMS_OUTPUT.put_line ('fid: ' || fid);
         fn :=
            SUBSTR (confirm_upload.file_name,
                    INSTR (confirm_upload.file_name, '/') + 1);

         -- bug 3045375, added select to get length of BLOB.
         SELECT DBMS_LOB.getlength (blob_content), mime_type
           INTO bloblength, mt
           FROM fnd_lobs_document
          WHERE NAME = confirm_upload.file_name AND ROWNUM = 1;

         -- bug 3045375, added if to check length of blob.
         -- bug 4279252. added UPLOAD_FILE_SIZE_LIMIT check.
         IF fnd_profile.VALUE ('UPLOAD_FILE_SIZE_LIMIT') IS NULL
         THEN
            ufslim := bloblength;
         ELSE
            /* The profile is not limited to being a numeric value.  Stripping off any
               reference to kilobytes. */
            IF (INSTR (UPPER (fnd_profile.VALUE ('UPLOAD_FILE_SIZE_LIMIT')),
                       'K') > 0)
            THEN
               ufslim :=
                  SUBSTR (
                     fnd_profile.VALUE ('UPLOAD_FILE_SIZE_LIMIT'),
                     1,
                       INSTR (
                          UPPER (
                             fnd_profile.VALUE ('UPLOAD_FILE_SIZE_LIMIT')),
                          'K')
                     - 1);
            ELSE
               ufslim := fnd_profile.VALUE ('UPLOAD_FILE_SIZE_LIMIT');
            END IF;

            /* Bug 6490050 - profile is defined to be in KB so we need to convert
             here.  Consistent with the fwk code.  */
            ufslim := ufslim * 1000;
         END IF;

         IF bloblength BETWEEN 1 AND ufslim
         THEN
            INSERT INTO fnd_lobs (file_id,
                                  file_name,
                                  file_content_type,
                                  file_data,
                                  upload_date,
                                  expiration_date,
                                  program_name,
                                  program_tag,
                                  LANGUAGE,
                                  file_format)
               (SELECT confirm_upload.fid,
                       fn,
                       ld.mime_type,
                       ld.blob_content,
                       SYSDATE,
                       confirm_upload.expiration_date,
                       confirm_upload.program_name,
                       confirm_upload.program_tag,
                       confirm_upload.LANGUAGE,
                       fnd_gfm.set_file_format (mt)
                  FROM fnd_lobs_document ld
                 WHERE ld.NAME = confirm_upload.file_name AND ROWNUM = 1);

            IF (SQL%ROWCOUNT <> 1)
            THEN
               RAISE NO_DATA_FOUND;
            END IF;

            UPDATE fnd_lob_access
               SET file_id = fid
             WHERE access_id = confirm_upload.access_id;

            IF wakeup
            THEN
               DBMS_ALERT.signal ('FND_GFM_ALERT' || TO_CHAR (access_id),
                                  TO_CHAR (fid));
            END IF;
         -- bug 3045375, added else to return fid = -2.
         ELSE
            fid := -2;
         END IF;

         DELETE FROM fnd_lobs_document;

         DELETE FROM fnd_lobs_documentpart;
      END IF;

      RETURN fid;
   EXCEPTION
      WHEN OTHERS
      THEN
         DELETE FROM fnd_lobs_document;

         DELETE FROM fnd_lobs_documentpart;

         --fnd_gfm.err_msg('confirm_upload');
         RAISE;
   END;

   PROCEDURE upload_file (v_filename    IN     VARCHAR2,
                          x_access_id      OUT NUMBER,
                          x_file_id        OUT NUMBER)
   AS
      v_access_id   NUMBER;
      v_file_id     NUMBER;
      x_errbuf      VARCHAR2 (200);
   BEGIN
      v_access_id := fnd_gfm.authorize (NULL);
      x_access_id := v_access_id;
      DBMS_OUTPUT.put_line ('Access id :' || v_access_id);
      -- The function fnd_gfm.confirm_upload return the file id
      v_file_id :=
         confirm_upload (access_id         => v_access_id,
                         file_name         => v_filename,
                         program_name      => 'FNDATTCH',
                         program_tag       => NULL,
                         expiration_date   => NULL,
                         LANGUAGE          => 'US',
                         wakeup            => TRUE);
      x_file_id := v_file_id;
      DBMS_OUTPUT.put_line ('File id :' || x_file_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_errbuf :=
               'Procedure upload_file errored out with the following error : '
            || SQLERRM;
         DBMS_OUTPUT.put_line (x_errbuf);
   END upload_file;

   PROCEDURE attach_file (p_access_id               IN NUMBER,
                          p_file_id                 IN NUMBER,
                          p_filename                IN VARCHAR2,
                          p_requisition_header_id   IN NUMBER,
                          p_description             IN VARCHAR2)
   IS
   BEGIN
      fnd_webattch.add_attachment (
         seq_num                => 20,
         category_id            => 38,
         document_description   => p_description              --'TEST PACKAGE'
                                                ,
         datatype_id            => 6,
         text                   => NULL,
         file_name              => p_filename,
         url                    => NULL,
         function_name          => NULL,
         entity_name            => 'REQ_HEADERS',
         pk1_value              => p_requisition_header_id --5619475 --REQUISITION_HEADER
                                                          ,
         pk2_value              => NULL,
         pk3_value              => NULL,
         pk4_value              => NULL,
         pk5_value              => NULL,
         media_id               => p_file_id,
         user_id                => g_user_id,
         usage_type             => 'O');
      DBMS_OUTPUT.put_line ('File Attached!');
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('error in loading the attachement');
   END attach_file;

   PROCEDURE initialize_application
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'HRSS';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            g_user_id := 1090;
      END;

      g_resp_id := 20707;                                            -- 50820;
      g_resp_appl_id := 201;
      g_group_security_id := 0;
      g_server_id := 13126;
      -- Initialize
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
      COMMIT;
   END initialize_application;

   PROCEDURE run_rcv_transactionprocessor (p_req_id        OUT INT,
                                           p_mode       IN     VARCHAR2,
                                           p_group_id   IN     VARCHAR2,
                                           p_org_id     IN     VARCHAR2)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'PO',
            program       => 'RVCTP',
            description   => 'Transaction processing module for Integrated Receiving',
            start_time    => SYSDATE--                    , sub_request => FALSE
            ,
            argument1     => p_mode                          -- OPERATING UNIT
                                   ,
            argument2     => p_group_id                              -- SOURCE
                                       --                             , argument3   => p_org_id -- GROUP
                                       --                    , argument4   => NULL -- BATCH NAME
                                       --                    , argument5   => NULL -- HOLD NAME
                                       --                    , argument6   => NULL -- HOLD REASON
                                       --                    , argument7   => NULL -- GL DATE
                                       --                    , argument8   => 'Y' -- PURGE
                                       --                    , argument9   => 'N' -- TRACE SWITCH
                                       --                    , argument10  => 'N' -- DEBUG SWITCH
                                       --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                       --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                       --                    , argument13  => NULL --1540 -- USER_ID
                                       --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_rcv_transactionprocessor;

   -- Cancel Requisition Header
   PROCEDURE cancel_req (p_req_num VARCHAR2, p_out OUT NUMBER)
   IS
      v_return_status   VARCHAR2 (4000);
      v_msg_count       NUMBER;
      v_msg_data        VARCHAR2 (4000);
      v_header_id       NUMBER;
      v_line_id         NUMBER;

      TYPE req_line_type
         IS TABLE OF po_requisition_lines_all.requisition_line_id%TYPE; -- INDEX BY PLS_INTEGER;

      v_req_line_id     req_line_type;
      v_msg             NUMBER := NULL;
      v_msg_dummy       VARCHAR2 (4000);
      v_output          VARCHAR2 (4000);
   BEGIN
      ------Fetching Requisition Header id for corresponding Requisition Number-----
      BEGIN
         SELECT requisition_header_id
           INTO v_header_id
           FROM po_requisition_headers_all
          WHERE segment1 = p_req_num;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --p_out:='ERROR(ND):Requisition not found for Requisition Number :'||P_REQ_NUM;
            p_out := -1;
            RAISE;
         WHEN OTHERS
         THEN
            --p_out:='ERROR(OTHERS) :'||SQLERRM;
            p_out := -2;
            RAISE;
      END;

        ------Bulk Collect all the Requisition Lines-------------
        SELECT requisition_line_id
          BULK COLLECT INTO v_req_line_id
          FROM po_requisition_lines_all
         WHERE requisition_header_id = v_header_id
      ORDER BY 1;

      FOR i IN v_req_line_id.FIRST .. v_req_line_id.LAST
      LOOP
         BEGIN
            v_msg := 1;
            --DBMS_OUTPUT.put_line (v_req_line_id(i));
            po_req_document_cancel_grp.cancel_requisition (
               p_api_version     => 1.0,
               p_req_header_id   => po_tbl_number (v_header_id),
               p_req_line_id     => po_tbl_number (v_req_line_id (i)),
               p_cancel_date     => SYSDATE,
               p_cancel_reason   => 'Cancelled Requisition',
               p_source          => 'REQUISITION',
               x_return_status   => v_return_status,
               x_msg_count       => v_msg_count,
               x_msg_data        => v_msg_data);

            IF v_return_status <> 'S'
            THEN
               apps.fnd_msg_pub.get (v_msg,
                                     apps.fnd_api.g_false,
                                     v_msg_data,
                                     v_msg_dummy);
               v_output := (TO_CHAR (v_msg) || ': ' || v_msg_data);
               --DBMS_OUTPUT.put_line (v_output);
               --p_out:=v_output;
               --insert into tempHoho2 values(v_msg_data);
               COMMIT;
               p_out := -3;
            ELSE
               --P_OUT := v_return_status;
               p_out := 1;
            END IF;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         --p_out := SQLERRM;
         p_out := -4;
   END cancel_req;

   -- Cancel Requisition Line
   PROCEDURE cancel_req (p_req_num       VARCHAR2,
                         p_line          NUMBER,
                         p_out       OUT VARCHAR2)
   IS
      v_return_status   VARCHAR2 (4000);
      v_msg_count       NUMBER;
      v_msg_data        VARCHAR2 (4000);
      v_header_id       NUMBER;
      v_line_id         NUMBER;

      TYPE req_line_type
         IS TABLE OF po_requisition_lines_all.requisition_line_id%TYPE; -- INDEX BY PLS_INTEGER;

      v_req_line_id     req_line_type;
      v_msg             NUMBER := NULL;
      v_msg_dummy       VARCHAR2 (4000);
      v_output          VARCHAR2 (4000);
   BEGIN
      ------Fetching Requisition Header id for corresponding Requisition Number-----
      BEGIN
         SELECT requisition_header_id
           INTO v_header_id
           FROM po_requisition_headers_all
          WHERE segment1 = p_req_num;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_out :=
                  'ERROR(ND):Requisition not found for Requisition Number :'
               || p_req_num;
            RAISE;
         WHEN OTHERS
         THEN
            p_out := 'ERROR(OTHERS) :' || SQLERRM;
            RAISE;
      END;

      ------Fetching Requisition Line ID for corresponding Requisition Line-----
      BEGIN
         SELECT requisition_line_id
           INTO v_line_id               --v_req_line_id(1).requisition_line_id
           FROM po_requisition_lines_all
          WHERE requisition_header_id = v_header_id AND line_num = p_line;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_out :=
                  'ERROR(ND):Requisition line '
               || p_line
               || ' not found for Requisition Number :'
               || p_req_num;
            RAISE;
         WHEN OTHERS
         THEN
            p_out := 'ERROR(OTHERS) :' || SQLERRM;
            RAISE;
      END;

      BEGIN
         --DBMS_OUTPUT.put_line (v_line_id);
         po_req_document_cancel_grp.cancel_requisition (
            p_api_version     => 1.0,
            p_req_header_id   => po_tbl_number (v_header_id),
            p_req_line_id     => po_tbl_number (v_line_id),
            p_cancel_date     => SYSDATE,
            p_cancel_reason   => 'Cancelled Requisition',
            p_source          => 'REQUISITION',
            x_return_status   => v_return_status,
            x_msg_count       => v_msg_count,
            x_msg_data        => v_msg_data);

         IF v_return_status <> 'S'
         THEN
            apps.fnd_msg_pub.get (v_msg,
                                  apps.fnd_api.g_false,
                                  v_msg_data,
                                  v_msg_dummy);
            v_output := (TO_CHAR (v_msg) || ': ' || v_msg_data);
            --DBMS_OUTPUT.put_line (v_output);
            p_out := v_output;
         ELSE
            p_out := v_msg_data;
         END IF;
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := SQLERRM;
   END cancel_req;

   -- Close Requisition Header
   PROCEDURE close_req (p_req_num       VARCHAR2,
                        p_org_id        NUMBER,
                        p_reason        VARCHAR2,
                        p_out       OUT VARCHAR2)
   IS
      v_req_control_error_rc   VARCHAR2 (500);
      cnt                      NUMBER := 0;

      CURSOR req_cur
      IS
         SELECT prh.segment1 requisition_num,
                prh.requisition_header_id,
                prh.org_id,
                prl.requisition_line_id,
                prh.preparer_id,
                prh.type_lookup_code,
                pdt.document_type_code,
                prh.authorization_status,
                prh.closed_code
           FROM po_requisition_headers_all prh,
                po_requisition_lines_all prl,
                po_document_types_all_b pdt
          WHERE     1 = 1
                AND prh.org_id = p_org_id
                AND pdt.document_type_code = 'REQUISITION'
                --                  AND prh.authorization_status    = 'APPROVED'
                --AND prl.line_location_id is null
                AND prh.requisition_header_id = prl.requisition_header_id
                AND prh.type_lookup_code = pdt.document_subtype
                AND prh.org_id = pdt.org_id
                AND prh.segment1 = p_req_num;
   BEGIN
      --        fnd_global.apps_initialize (user_id         => 1540,  --hilman.rama@kalbe.co.id
      --                                    resp_id         => 50532, --KLB PR INDIRECT ADMIN
      --                                    resp_appl_id    => 201);
      initialize_pr_concurrent;
      mo_global.set_policy_context ('S', p_org_id);

      FOR i IN req_cur
      LOOP
         po_reqs_control_sv.update_reqs_status (
            x_req_header_id          => i.requisition_header_id,
            x_req_line_id            => i.requisition_line_id,
            x_agent_id               => i.preparer_id,
            x_req_doc_type           => i.document_type_code,
            x_req_doc_subtype        => i.type_lookup_code,
            x_req_control_action     => 'FINALLY CLOSE',
            x_req_control_reason     => p_reason,
            x_req_action_date        => SYSDATE,
            x_encumbrance_flag       => 'N',
            x_oe_installed_flag      => 'Y',
            x_req_control_error_rc   => v_req_control_error_rc);

         IF v_req_control_error_rc IS NOT NULL
         THEN
            p_out :=
                  p_out
               || p_req_num
               || ' '
               || v_req_control_error_rc
               || CHR (10);
         ELSE
            p_out := 'S';
         END IF;

         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         p_out := 'No data found';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := 'Error ' || SQLERRM;
   END close_req;

   -- Close Requisition Line
   PROCEDURE close_req_line (p_req_num       VARCHAR2,
                             p_line          NUMBER,
                             p_org_id        NUMBER,
                             p_reason        VARCHAR2,
                             p_out       OUT VARCHAR2)
   IS
      v_req_control_error_rc   VARCHAR2 (500);
      cnt                      NUMBER := 0;

      CURSOR req_line_cur
      IS
         SELECT prh.segment1 requisition_num,
                prh.requisition_header_id,
                prh.org_id,
                prl.requisition_line_id,
                prh.preparer_id,
                prh.type_lookup_code,
                pdt.document_type_code,
                prh.authorization_status,
                prh.closed_code
           FROM po_requisition_headers_all prh,
                po_requisition_lines_all prl,
                po_document_types_all_b pdt
          WHERE     1 = 1
                AND prh.org_id = p_org_id
                AND pdt.document_type_code = 'REQUISITION'
                --                  AND prh.authorization_status    = 'APPROVED'
                --AND prl.line_location_id is null
                AND prh.requisition_header_id = prl.requisition_header_id
                AND prh.type_lookup_code = pdt.document_subtype
                AND prh.org_id = pdt.org_id
                AND prh.segment1 = p_req_num
                AND prl.line_num = p_line;
   BEGIN
      --        fnd_global.apps_initialize (user_id         => 2612,  --hilman.rama@kalbe.co.id
      --                                    resp_id         => 51853, --KLB PR INDIRECT ADMIN
      --                                    resp_appl_id    => 201);
      initialize_pr_concurrent;
      mo_global.set_policy_context ('S', p_org_id);

      FOR i IN req_line_cur
      LOOP
         po_req_lines_sv.update_reqs_lines_status (
            x_req_header_id          => i.requisition_header_id,
            x_req_line_id            => i.requisition_line_id,
            x_req_control_action     => 'FINALLY CLOSE',
            x_req_control_reason     => p_reason,
            x_req_action_date        => SYSDATE,
            x_oe_installed_flag      => 'Y',
            x_req_control_error_rc   => v_req_control_error_rc);

         IF v_req_control_error_rc IS NOT NULL
         THEN
            p_out :=
                  p_out
               || p_req_num
               || ' '
               || v_req_control_error_rc
               || CHR (10);
         ELSE
            p_out := 'S';
         END IF;

         cnt := cnt + 1;
      END LOOP;

      IF cnt = 0
      THEN
         p_out := 'No data found';
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := 'Error ' || SQLERRM;
   END close_req_line;

   -- Retur To Vendor
   PROCEDURE populate_return (p_rcv_transaction_id       NUMBER,
                              p_qty                      NUMBER,
                              p_dest_type                VARCHAR2,
                              p_trx_type                 VARCHAR2,
                              p_out                  OUT NUMBER)
   IS
      g_exception                EXCEPTION;
      l_rcv_trx                  rcv_transactions_interface%ROWTYPE;
      l_location_code            VARCHAR2 (60);
      l_valid                    BOOLEAN;
      p_rcv_trx_interface_id     NUMBER DEFAULT 0;
      p_rcv_interface_group_id   NUMBER DEFAULT 0;

      CURSOR cur_po_lns
      IS
         SELECT trx.*, dtl.item_id
           FROM rcv_transactions trx,
                rcv_shipment_headers hdr,
                po_lines_all dtl
          WHERE     trx.shipment_header_id = hdr.shipment_header_id
                AND trx.po_line_id = dtl.po_line_id
                AND trx.transaction_id = p_rcv_transaction_id;
   BEGIN
      FOR c_lns IN cur_po_lns
      LOOP
         NULL;

         SELECT rcv_transactions_interface_s.NEXTVAL
           INTO p_rcv_trx_interface_id
           FROM DUAL;

         SELECT rcv_interface_groups_s.NEXTVAL
           INTO p_rcv_interface_group_id
           FROM DUAL;

         --dbms_output.put_line(p_rcv_trx_interface_id);
         --dbms_output.put_line(p_rcv_interface_group_id);
         l_rcv_trx := NULL;
         --            l_rcv_trx.header_interface_id       := l_rcv_hdr.header_interface_id;
         l_rcv_trx.interface_transaction_id := p_rcv_trx_interface_id;
         l_rcv_trx.GROUP_ID := p_rcv_interface_group_id;
         l_rcv_trx.last_update_date := SYSDATE;
         l_rcv_trx.last_updated_by := c_lns.created_by;
         l_rcv_trx.creation_date := SYSDATE;
         l_rcv_trx.created_by := c_lns.created_by;
         l_rcv_trx.last_update_login := c_lns.last_update_login;
         l_rcv_trx.transaction_type := 'RETURN TO VENDOR'; --'RETURN TO VENDOR';    ----g_transaction_type_receive;
         l_rcv_trx.transaction_date := SYSDATE;
         l_rcv_trx.processing_status_code := 'PENDING'; --g_processing_status_pending;
         l_rcv_trx.processing_mode_code := 'BATCH'; --g_processing_mode_batch;
         l_rcv_trx.receipt_source_code := 'VENDOR'; --g_receipt_source_vendor; -- g_receipt_source_customer; --??
         l_rcv_trx.source_document_code := 'PO'; --g_source_document_po; -- g_source_document_rma;--??
         l_rcv_trx.destination_type_code := p_dest_type; ----g_dest_type_inventory;
         l_rcv_trx.validation_flag := 'Y';            --g_validation_flag_yes;
         l_rcv_trx.transaction_status_code := 'PENDING'; --g_transaction_status_pending;
         l_rcv_trx.quantity := NVL (p_qty, c_lns.quantity);
         l_rcv_trx.item_id := c_lns.item_id;
         l_rcv_trx.uom_code := c_lns.uom_code;
         --            l_rcv_trx.po_header_id              := c_lns.po_header_id;
         --            l_rcv_trx.po_line_location_id       := c_lns.po_line_location_id;
         --l_rcv_trx.to_organization_id        := c_lns.ship_to_organization_id;
         l_rcv_trx.parent_transaction_id := c_lns.transaction_id;
         insert_rcv_transactions_iface (l_rcv_trx);
      END LOOP;

      p_out := p_rcv_interface_group_id;
      COMMIT;
   END populate_return;

   PROCEDURE submit_rcv_open_interface (p_rcv_transaction_id       NUMBER,
                                        p_qty                      NUMBER,
                                        p_dest_type                VARCHAR2,
                                        p_trx_type                 VARCHAR2,
                                        p_processing_mode          VARCHAR2,
                                        p_org_id                   NUMBER,
                                        p_roi_desc                 VARCHAR2,
                                        p_out                  OUT NUMBER)
   IS
      l_request_id   NUMBER;
      l_result       BOOLEAN;
      x_status       VARCHAR2 (25);
      x_phase        VARCHAR2 (1);
      x_dev_phase    VARCHAR2 (1);
      x_dev_status   VARCHAR2 (25);
      x_message      VARCHAR2 (250);
      v_out          NUMBER;
   BEGIN
      populate_return (p_rcv_transaction_id,
                       p_qty,
                       p_dest_type,
                       p_trx_type,
                       v_out);

      --dbms_output.put_line(v_out);
      IF v_out <> 0
      THEN
         initialize_pr_concurrent;
         --         l_request_id := fnd_request.submit_request ('PO', 'RVCTP', p_roi_desc, SYSDATE, FALSE, p_processing_mode, v_out, fnd_profile.value('ORG_ID'));
         l_request_id :=
            fnd_request.submit_request ('PO',
                                        'RVCTP',
                                        p_roi_desc,
                                        SYSDATE,
                                        FALSE,
                                        p_processing_mode,
                                        v_out);

         --dbms_output.put_line(l_request_id);
         p_out := l_request_id;
         COMMIT;
      --dbms_output.put_line(l_request_id);

      --            l_result := wait_for_request_custom(l_request_id,
      --                                                        g_intval_time,
      --                                                        g_max_time,
      --                                                        x_phase,
      --                                                        x_status,
      --                                                        x_dev_phase,
      --                                                        x_dev_status,
      --                                                        x_message);
      --
      --            IF (x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL')
      --            THEN
      --                p_out := 'S';
      --            ELSE
      --                p_out := 'Error';
      --            END IF;
      ELSE
         p_out := 0;
      END IF;
   --        fnd_global.apps_initialize (
   --                            user_id         => 1540,  --yohanes.parulian
   --                            resp_id         => 50532, --Purchasing Super User
   --                            resp_appl_id    => 201);

   --        return 'l_request_id '||l_request_id||' x_dev_phase '||x_dev_phase||' x_dev_status '||x_dev_status||' x_message '||x_message;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_out := 0;
   END submit_rcv_open_interface;

   PROCEDURE insert_rcv_transactions_iface (
      p_rec   IN rcv_transactions_interface%ROWTYPE)
   AS
   BEGIN
      INSERT INTO rcv_transactions_interface (interface_transaction_id,
                                              GROUP_ID,
                                              last_update_date,
                                              last_updated_by,
                                              creation_date,
                                              created_by,
                                              last_update_login,
                                              request_id,
                                              program_application_id,
                                              program_id,
                                              program_update_date,
                                              transaction_type,
                                              transaction_date,
                                              processing_status_code,
                                              processing_mode_code,
                                              processing_request_id,
                                              transaction_status_code,
                                              category_id,
                                              quantity,
                                              unit_of_measure,
                                              interface_source_code,
                                              interface_source_line_id,
                                              inv_transaction_id,
                                              item_id,
                                              item_description,
                                              item_revision,
                                              uom_code,
                                              employee_id,
                                              auto_transact_code,
                                              shipment_header_id,
                                              shipment_line_id,
                                              ship_to_location_id,
                                              primary_quantity,
                                              primary_unit_of_measure,
                                              receipt_source_code,
                                              vendor_id,
                                              vendor_site_id,
                                              from_organization_id,
                                              from_subinventory,
                                              to_organization_id,
                                              intransit_owning_org_id,
                                              routing_header_id,
                                              routing_step_id,
                                              source_document_code,
                                              parent_transaction_id,
                                              po_header_id,
                                              po_revision_num,
                                              po_release_id,
                                              po_line_id,
                                              po_line_location_id,
                                              po_unit_price,
                                              currency_code,
                                              currency_conversion_type,
                                              currency_conversion_rate,
                                              currency_conversion_date,
                                              po_distribution_id,
                                              requisition_line_id,
                                              req_distribution_id,
                                              charge_account_id,
                                              substitute_unordered_code,
                                              receipt_exception_flag,
                                              accrual_status_code,
                                              inspection_status_code,
                                              inspection_quality_code,
                                              destination_type_code,
                                              deliver_to_person_id,
                                              location_id,
                                              deliver_to_location_id,
                                              subinventory,
                                              locator_id,
                                              wip_entity_id,
                                              wip_line_id,
                                              department_code,
                                              wip_repetitive_schedule_id,
                                              wip_operation_seq_num,
                                              wip_resource_seq_num,
                                              bom_resource_id,
                                              shipment_num,
                                              freight_carrier_code,
                                              bill_of_lading,
                                              packing_slip,
                                              shipped_date,
                                              expected_receipt_date,
                                              actual_cost,
                                              transfer_cost,
                                              transportation_cost,
                                              transportation_account_id,
                                              num_of_containers,
                                              waybill_airbill_num,
                                              vendor_item_num,
                                              vendor_lot_num,
                                              rma_reference,
                                              comments,
                                              attribute_category,
                                              attribute1,
                                              attribute2,
                                              attribute3,
                                              attribute4,
                                              attribute5,
                                              attribute6,
                                              attribute7,
                                              attribute8,
                                              attribute9,
                                              attribute10,
                                              attribute11,
                                              attribute12,
                                              attribute13,
                                              attribute14,
                                              attribute15,
                                              ship_head_attribute_category,
                                              ship_head_attribute1,
                                              ship_head_attribute2,
                                              ship_head_attribute3,
                                              ship_head_attribute4,
                                              ship_head_attribute5,
                                              ship_head_attribute6,
                                              ship_head_attribute7,
                                              ship_head_attribute8,
                                              ship_head_attribute9,
                                              ship_head_attribute10,
                                              ship_head_attribute11,
                                              ship_head_attribute12,
                                              ship_head_attribute13,
                                              ship_head_attribute14,
                                              ship_head_attribute15,
                                              ship_line_attribute_category,
                                              ship_line_attribute1,
                                              ship_line_attribute2,
                                              ship_line_attribute3,
                                              ship_line_attribute4,
                                              ship_line_attribute5,
                                              ship_line_attribute6,
                                              ship_line_attribute7,
                                              ship_line_attribute8,
                                              ship_line_attribute9,
                                              ship_line_attribute10,
                                              ship_line_attribute11,
                                              ship_line_attribute12,
                                              ship_line_attribute13,
                                              ship_line_attribute14,
                                              ship_line_attribute15,
                                              ussgl_transaction_code,
                                              government_context,
                                              reason_id,
                                              destination_context,
                                              source_doc_quantity,
                                              source_doc_unit_of_measure,
                                              movement_id,
                                              header_interface_id,
                                              vendor_cum_shipped_qty,
                                              item_num,
                                              document_num,
                                              document_line_num,
                                              truck_num,
                                              ship_to_location_code,
                                              container_num,
                                              substitute_item_num,
                                              notice_unit_price,
                                              item_category,
                                              location_code,
                                              vendor_name,
                                              vendor_num,
                                              vendor_site_code,
                                              from_organization_code,
                                              to_organization_code,
                                              intransit_owning_org_code,
                                              routing_code,
                                              routing_step,
                                              release_num,
                                              document_shipment_line_num,
                                              document_distribution_num,
                                              deliver_to_person_name,
                                              deliver_to_location_code,
                                              use_mtl_lot,
                                              use_mtl_serial,
                                              LOCATOR,
                                              reason_name,
                                              validation_flag,
                                              substitute_item_id,
                                              quantity_shipped,
                                              quantity_invoiced,
                                              tax_name,
                                              tax_amount,
                                              req_num,
                                              req_line_num,
                                              req_distribution_num,
                                              wip_entity_name,
                                              wip_line_code,
                                              resource_code,
                                              shipment_line_status_code,
                                              barcode_label,
                                              transfer_percentage,
                                              qa_collection_id,
                                              country_of_origin_code,
                                              oe_order_header_id,
                                              oe_order_line_id,
                                              customer_id,
                                              customer_site_id,
                                              customer_item_num,
                                              create_debit_memo_flag,
                                              put_away_rule_id,
                                              put_away_strategy_id,
                                              lpn_id,
                                              transfer_lpn_id,
                                              cost_group_id,
                                              mobile_txn,
                                              mmtt_temp_id,
                                              transfer_cost_group_id,
                                              secondary_quantity,
                                              secondary_unit_of_measure,
                                              secondary_uom_code,
                                              qc_grade,
                                              from_locator,
                                              from_locator_id,
                                              parent_source_transaction_num,
                                              interface_available_qty,
                                              interface_transaction_qty,
                                              interface_available_amt,
                                              interface_transaction_amt,
                                              license_plate_number,
                                              source_transaction_num,
                                              transfer_license_plate_number,
                                              lpn_group_id,
                                              order_transaction_id,
                                              customer_account_number,
                                              customer_party_name,
                                              oe_order_line_num,
                                              oe_order_num,
                                              parent_interface_txn_id,
                                              customer_item_id,
                                              amount,
                                              job_id,
                                              timecard_id,
                                              timecard_ovn,
                                              erecord_id,
                                              project_id,
                                              task_id,
                                              asn_attach_id,
                                              org_id,
                                              operating_unit,
                                              requested_amount,
                                              material_stored_amount,
                                              amount_shipped,
                                              matching_basis,
                                              replenish_order_line_id,
                                              express_transaction,
                                              lcm_shipment_line_id,
                                              unit_landed_cost)
           VALUES (p_rec.interface_transaction_id,
                   p_rec.GROUP_ID,
                   p_rec.last_update_date,
                   p_rec.last_updated_by,
                   p_rec.creation_date,
                   p_rec.created_by,
                   p_rec.last_update_login,
                   p_rec.request_id,
                   p_rec.program_application_id,
                   p_rec.program_id,
                   p_rec.program_update_date,
                   p_rec.transaction_type,
                   p_rec.transaction_date,
                   p_rec.processing_status_code,
                   p_rec.processing_mode_code,
                   p_rec.processing_request_id,
                   p_rec.transaction_status_code,
                   p_rec.category_id,
                   p_rec.quantity,
                   p_rec.unit_of_measure,
                   p_rec.interface_source_code,
                   p_rec.interface_source_line_id,
                   p_rec.inv_transaction_id,
                   p_rec.item_id,
                   p_rec.item_description,
                   p_rec.item_revision,
                   p_rec.uom_code,
                   p_rec.employee_id,
                   p_rec.auto_transact_code,
                   p_rec.shipment_header_id,
                   p_rec.shipment_line_id,
                   p_rec.ship_to_location_id,
                   p_rec.primary_quantity,
                   p_rec.primary_unit_of_measure,
                   p_rec.receipt_source_code,
                   p_rec.vendor_id,
                   p_rec.vendor_site_id,
                   p_rec.from_organization_id,
                   p_rec.from_subinventory,
                   p_rec.to_organization_id,
                   p_rec.intransit_owning_org_id,
                   p_rec.routing_header_id,
                   p_rec.routing_step_id,
                   p_rec.source_document_code,
                   p_rec.parent_transaction_id,
                   p_rec.po_header_id,
                   p_rec.po_revision_num,
                   p_rec.po_release_id,
                   p_rec.po_line_id,
                   p_rec.po_line_location_id,
                   p_rec.po_unit_price,
                   p_rec.currency_code,
                   p_rec.currency_conversion_type,
                   p_rec.currency_conversion_rate,
                   p_rec.currency_conversion_date,
                   p_rec.po_distribution_id,
                   p_rec.requisition_line_id,
                   p_rec.req_distribution_id,
                   p_rec.charge_account_id,
                   p_rec.substitute_unordered_code,
                   p_rec.receipt_exception_flag,
                   p_rec.accrual_status_code,
                   p_rec.inspection_status_code,
                   p_rec.inspection_quality_code,
                   p_rec.destination_type_code,
                   p_rec.deliver_to_person_id,
                   p_rec.location_id,
                   p_rec.deliver_to_location_id,
                   p_rec.subinventory,
                   p_rec.locator_id,
                   p_rec.wip_entity_id,
                   p_rec.wip_line_id,
                   p_rec.department_code,
                   p_rec.wip_repetitive_schedule_id,
                   p_rec.wip_operation_seq_num,
                   p_rec.wip_resource_seq_num,
                   p_rec.bom_resource_id,
                   p_rec.shipment_num,
                   p_rec.freight_carrier_code,
                   p_rec.bill_of_lading,
                   p_rec.packing_slip,
                   p_rec.shipped_date,
                   p_rec.expected_receipt_date,
                   p_rec.actual_cost,
                   p_rec.transfer_cost,
                   p_rec.transportation_cost,
                   p_rec.transportation_account_id,
                   p_rec.num_of_containers,
                   p_rec.waybill_airbill_num,
                   p_rec.vendor_item_num,
                   p_rec.vendor_lot_num,
                   p_rec.rma_reference,
                   p_rec.comments,
                   p_rec.attribute_category,
                   p_rec.attribute1,
                   p_rec.attribute2,
                   p_rec.attribute3,
                   p_rec.attribute4,
                   p_rec.attribute5,
                   p_rec.attribute6,
                   p_rec.attribute7,
                   p_rec.attribute8,
                   p_rec.attribute9,
                   p_rec.attribute10,
                   p_rec.attribute11,
                   p_rec.attribute12,
                   p_rec.attribute13,
                   p_rec.attribute14,
                   p_rec.attribute15,
                   p_rec.ship_head_attribute_category,
                   p_rec.ship_head_attribute1,
                   p_rec.ship_head_attribute2,
                   p_rec.ship_head_attribute3,
                   p_rec.ship_head_attribute4,
                   p_rec.ship_head_attribute5,
                   p_rec.ship_head_attribute6,
                   p_rec.ship_head_attribute7,
                   p_rec.ship_head_attribute8,
                   p_rec.ship_head_attribute9,
                   p_rec.ship_head_attribute10,
                   p_rec.ship_head_attribute11,
                   p_rec.ship_head_attribute12,
                   p_rec.ship_head_attribute13,
                   p_rec.ship_head_attribute14,
                   p_rec.ship_head_attribute15,
                   p_rec.ship_line_attribute_category,
                   p_rec.ship_line_attribute1,
                   p_rec.ship_line_attribute2,
                   p_rec.ship_line_attribute3,
                   p_rec.ship_line_attribute4,
                   p_rec.ship_line_attribute5,
                   p_rec.ship_line_attribute6,
                   p_rec.ship_line_attribute7,
                   p_rec.ship_line_attribute8,
                   p_rec.ship_line_attribute9,
                   p_rec.ship_line_attribute10,
                   p_rec.ship_line_attribute11,
                   p_rec.ship_line_attribute12,
                   p_rec.ship_line_attribute13,
                   p_rec.ship_line_attribute14,
                   p_rec.ship_line_attribute15,
                   p_rec.ussgl_transaction_code,
                   p_rec.government_context,
                   p_rec.reason_id,
                   p_rec.destination_context,
                   p_rec.source_doc_quantity,
                   p_rec.source_doc_unit_of_measure,
                   p_rec.movement_id,
                   p_rec.header_interface_id,
                   p_rec.vendor_cum_shipped_qty,
                   p_rec.item_num,
                   p_rec.document_num,
                   p_rec.document_line_num,
                   p_rec.truck_num,
                   p_rec.ship_to_location_code,
                   p_rec.container_num,
                   p_rec.substitute_item_num,
                   p_rec.notice_unit_price,
                   p_rec.item_category,
                   p_rec.location_code,
                   p_rec.vendor_name,
                   p_rec.vendor_num,
                   p_rec.vendor_site_code,
                   p_rec.from_organization_code,
                   p_rec.to_organization_code,
                   p_rec.intransit_owning_org_code,
                   p_rec.routing_code,
                   p_rec.routing_step,
                   p_rec.release_num,
                   p_rec.document_shipment_line_num,
                   p_rec.document_distribution_num,
                   p_rec.deliver_to_person_name,
                   p_rec.deliver_to_location_code,
                   p_rec.use_mtl_lot,
                   p_rec.use_mtl_serial,
                   p_rec.LOCATOR,
                   p_rec.reason_name,
                   p_rec.validation_flag,
                   p_rec.substitute_item_id,
                   p_rec.quantity_shipped,
                   p_rec.quantity_invoiced,
                   p_rec.tax_name,
                   p_rec.tax_amount,
                   p_rec.req_num,
                   p_rec.req_line_num,
                   p_rec.req_distribution_num,
                   p_rec.wip_entity_name,
                   p_rec.wip_line_code,
                   p_rec.resource_code,
                   p_rec.shipment_line_status_code,
                   p_rec.barcode_label,
                   p_rec.transfer_percentage,
                   p_rec.qa_collection_id,
                   p_rec.country_of_origin_code,
                   p_rec.oe_order_header_id,
                   p_rec.oe_order_line_id,
                   p_rec.customer_id,
                   p_rec.customer_site_id,
                   p_rec.customer_item_num,
                   p_rec.create_debit_memo_flag,
                   p_rec.put_away_rule_id,
                   p_rec.put_away_strategy_id,
                   p_rec.lpn_id,
                   p_rec.transfer_lpn_id,
                   p_rec.cost_group_id,
                   p_rec.mobile_txn,
                   p_rec.mmtt_temp_id,
                   p_rec.transfer_cost_group_id,
                   p_rec.secondary_quantity,
                   p_rec.secondary_unit_of_measure,
                   p_rec.secondary_uom_code,
                   p_rec.qc_grade,
                   p_rec.from_locator,
                   p_rec.from_locator_id,
                   p_rec.parent_source_transaction_num,
                   p_rec.interface_available_qty,
                   p_rec.interface_transaction_qty,
                   p_rec.interface_available_amt,
                   p_rec.interface_transaction_amt,
                   p_rec.license_plate_number,
                   p_rec.source_transaction_num,
                   p_rec.transfer_license_plate_number,
                   p_rec.lpn_group_id,
                   p_rec.order_transaction_id,
                   p_rec.customer_account_number,
                   p_rec.customer_party_name,
                   p_rec.oe_order_line_num,
                   p_rec.oe_order_num,
                   p_rec.parent_interface_txn_id,
                   p_rec.customer_item_id,
                   p_rec.amount,
                   p_rec.job_id,
                   p_rec.timecard_id,
                   p_rec.timecard_ovn,
                   p_rec.erecord_id,
                   p_rec.project_id,
                   p_rec.task_id,
                   p_rec.asn_attach_id,
                   p_rec.org_id,
                   p_rec.operating_unit,
                   p_rec.requested_amount,
                   p_rec.material_stored_amount,
                   p_rec.amount_shipped,
                   p_rec.matching_basis,
                   p_rec.replenish_order_line_id,
                   p_rec.express_transaction,
                   p_rec.lcm_shipment_line_id,
                   p_rec.unit_landed_cost);
   END insert_rcv_transactions_iface;

   FUNCTION get_gl_codename (p_segment1 IN NUMBER)
      RETURN VARCHAR2
   IS
      strcodecombinationname   VARCHAR2 (50);
   BEGIN
      SELECT    gcc.segment1
             || '-'
             || gcc.segment2
             || '-'
             || gcc.segment3
             || '-'
             || gcc.segment4
             || '-'
             || gcc.segment5
             || '-'
             || gcc.segment6
             || '-'
             || gcc.segment7
        INTO strcodecombinationname
        FROM gl_code_combinations gcc
       WHERE 1 = 1 AND gcc.code_combination_id = p_segment1;

      RETURN strcodecombinationname;
   END;

   FUNCTION wait_for_request_custom (
      request_id   IN            NUMBER DEFAULT NULL,
      INTERVAL     IN            NUMBER DEFAULT 60,
      max_wait     IN            NUMBER DEFAULT 0,
      phase           OUT NOCOPY VARCHAR2,
      status          OUT NOCOPY VARCHAR2,
      dev_phase       OUT NOCOPY VARCHAR2,
      dev_status      OUT NOCOPY VARCHAR2,
      MESSAGE         OUT NOCOPY VARCHAR2)
      RETURN BOOLEAN
   IS
      call_status   BOOLEAN;
      time_out      BOOLEAN := FALSE;
      pipename      VARCHAR2 (60);
      req_phase     VARCHAR2 (15);
      stime         NUMBER (30);
      etime         NUMBER (30);
      i             NUMBER;
   BEGIN
      IF (request_id IS NULL)
      THEN
         RETURN FALSE;
      END IF;

      IF (max_wait > 0)
      THEN
         time_out := TRUE;

         SELECT TO_NUMBER (
                     ( (TO_CHAR (SYSDATE, 'J') - 1) * 86400)
                   + TO_CHAR (SYSDATE, 'SSSSS'))
           INTO stime
           FROM SYS.DUAL;
      END IF;

      LOOP
         SELECT phase_code, status_code                     --Completion_Text,
           --Phase.Lookup_Code,
           --Status.Lookup_Code,
           --Phase.Meaning,
           --Status.Meaning
           INTO phase, status                                      --comptext,
           --phase_code, status_code,
           --phasem, statusm
           FROM fnd_concurrent_requests r,
                fnd_concurrent_programs p,
                fnd_lookups phase,
                fnd_lookups status
          WHERE     phase.lookup_type = 'CP_PHASE_CODE'
                AND phase.lookup_code =
                       DECODE (status.lookup_code,
                               'H', 'I',
                               'S', 'I',
                               'U', 'I',
                               'M', 'I',
                               r.phase_code)
                AND status.lookup_type = 'CP_STATUS_CODE'
                AND status.lookup_code =
                       DECODE (
                          r.phase_code,
                          'P', DECODE (
                                  r.hold_flag,
                                  'Y', 'H',
                                  DECODE (
                                     p.enabled_flag,
                                     'N', 'U',
                                     DECODE (
                                        SIGN (
                                           r.requested_start_date - SYSDATE),
                                        1, 'P',
                                        r.status_code))),
                          'R', DECODE (
                                  r.hold_flag,
                                  'Y', 'S',
                                  DECODE (r.status_code,
                                          'Q', 'B',
                                          'I', 'B',
                                          r.status_code)),
                          r.status_code)
                AND (    r.concurrent_program_id = p.concurrent_program_id
                     AND r.program_application_id = p.application_id)
                AND request_id = request_id;

         get_dev_phase_status (phase,
                               status,
                               dev_phase,
                               dev_status);
         DBMS_OUTPUT.put_line (dev_phase);
         DBMS_OUTPUT.put_line (dev_status);

         IF (dev_phase = 'COMPLETE')
         THEN
            RETURN TRUE;
         END IF;

         DBMS_LOCK.sleep (INTERVAL);
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         --oraerrmesg := substr(SQLERRM, 1, 80);
         fnd_message.set_name ('FND', 'CP-Generic oracle error');
         fnd_message.set_token ('ERROR', SUBSTR (SQLERRM, 1, 80), FALSE);
         fnd_message.set_token ('ROUTINE',
                                'FND_CONCURRENT.WAIT_FOR_REQUEST',
                                FALSE);
         RETURN FALSE;
   END;

   PROCEDURE get_dev_phase_status (phase_code    IN            VARCHAR2,
                                   status_code   IN            VARCHAR2,
                                   dev_phase        OUT NOCOPY VARCHAR2,
                                   dev_status       OUT NOCOPY VARCHAR2)
   IS
   BEGIN
      IF (phase_code = 'R')
      THEN
         dev_phase := 'RUNNING';
      ELSIF (phase_code = 'P')
      THEN
         dev_phase := 'PENDING';
      ELSIF (phase_code = 'C')
      THEN
         dev_phase := 'COMPLETE';
      ELSIF (phase_code = 'I')
      THEN
         dev_phase := 'INACTIVE';
      END IF;

      IF (status_code = 'R')
      THEN
         dev_status := 'NORMAL';
      ELSIF (status_code = 'T')
      THEN
         dev_status := 'TERMINATING';
      ELSIF (status_code = 'A')
      THEN
         dev_status := 'WAITING';
      ELSIF (status_code = 'B')
      THEN
         dev_status := 'RESUMING';
      ELSIF (status_code = 'I')
      THEN
         dev_status := 'NORMAL';                             -- Pending normal
      ELSIF (status_code = 'Q')
      THEN
         dev_status := 'STANDBY';         -- Pending, due to incompatabilities
      ELSIF (status_code = 'F' OR status_code = 'P')
      THEN
         dev_status := 'SCHEDULED';                                         --
      ELSIF (status_code = 'W')
      THEN
         dev_status := 'PAUSED';                                            --
      ELSIF (status_code = 'H')
      THEN
         dev_status := 'ON_HOLD';               -- Request Pending and on hold
      ELSIF (status_code = 'S')
      THEN
         dev_status := 'SUSPENDED';                                         --
      ELSIF (status_code = 'U')
      THEN
         dev_status := 'DISABLED';                -- Program has been disabled
      ELSIF (status_code = 'M')
      THEN
         dev_status := 'NO_MANAGER';          -- No defined manager can run it
      ELSIF (status_code = 'C')
      THEN
         dev_status := 'NORMAL';                         -- Completed normally
      ELSIF (status_code = 'G')
      THEN
         dev_status := 'WARNING';                    -- Completed with warning
      ELSIF (status_code = 'E')
      THEN
         dev_status := 'ERROR';                        -- Completed with error
      ELSIF (status_code = 'X')
      THEN
         dev_status := 'TERMINATED';                 -- Was terminated by user
      ELSIF (status_code = 'D')
      THEN
         --Bug8795072
         --Dev_Status := 'DELETED';    -- Was deleted when pending
         dev_status := 'CANCELLED';                -- Was deleted when pending
      END IF;
   END;

   PROCEDURE run_rcv_transactionprocessor (p_req_id        OUT INT,
                                           p_mode       IN     VARCHAR2,
                                           p_group_id   IN     VARCHAR2)
   IS
   BEGIN
      p_req_id := 0;
      p_req_id :=
         fnd_request.submit_request (
            application   => 'PO',
            program       => 'RVCTP',
            description   => 'Transaction processing module for Integrated Receiving',
            start_time    => SYSDATE--                    , sub_request => FALSE
            ,
            argument1     => p_mode                          -- OPERATING UNIT
                                   ,
            argument2     => p_group_id                              -- SOURCE
                                       --                             , argument3   => p_org_id -- GROUP
                                       --                    , argument4   => NULL -- BATCH NAME
                                       --                    , argument5   => NULL -- HOLD NAME
                                       --                    , argument6   => NULL -- HOLD REASON
                                       --                    , argument7   => NULL -- GL DATE
                                       --                    , argument8   => 'Y' -- PURGE
                                       --                    , argument9   => 'N' -- TRACE SWITCH
                                       --                    , argument10  => 'N' -- DEBUG SWITCH
                                       --                    , argument11  => 'N' -- SUMMARIZE REPORT
                                       --                    , argument12  => 1000 -- COMMIT BATCH SIZE
                                       --                    , argument13  => NULL --1540 -- USER_ID
                                       --                    , argument14  => NULL -- LOGIN_ID
            );
   END run_rcv_transactionprocessor;
END;
/