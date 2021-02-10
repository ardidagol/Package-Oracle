CREATE OR REPLACE PACKAGE XXKHD_PO_IFACE_PKG
IS

/*
REM +=========================================================================================================+
REM | Copyright (C) 2018 KN IT |
REM | All rights Reserved |
REM +=========================================================================================================+
REM | |
REM | Program Name: APPS.XXKHD_PO_IFACE_PKG.pks |
REM | Parameters : |
REM | Description : |
REM | History : 10 Oct 2018 Agus Budi Pramono Created Initial Coding |
REM | Proposed : PO - GRN Interface Data Source from Mocha |
REM +---------------------------------------------------------------------------------------------------------+
*/
           
   g_max_time            PLS_INTEGER      DEFAULT 3600; 
   g_interval            PLS_INTEGER      DEFAULT 5;   
   
   g_user_id             NUMBER := fnd_global.user_id;
   g_resp_id             NUMBER := fnd_global.resp_id;
   g_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
   g_request_id          NUMBER := fnd_global.conc_request_id;
   g_login_id            NUMBER := fnd_global.login_id;    
   g_org_code            VARCHAR2 (50):= 'OTH';
      
   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
   INDEX BY BINARY_INTEGER;

procedure insert_data(
                        errbuf      out varchar2,
                        retcode     out number,
                        p_file_id   number
                     );
                            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
END XXKHD_PO_IFACE_PKG; 
/

