CREATE OR REPLACE PACKAGE BODY APPS.XXSHP_INV_ITEMS_API_PKG
IS
   PROCEDURE logf (v_char VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, v_char);
   END;

   PROCEDURE outf (p_message IN VARCHAR2)
   IS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_message);
   END;

   FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
   
    --this function is based on one by Connor McDonald
    --http://www.jlcomp.demon.co.uk/faq/base_convert.html
    
   RETURN NUMBER
   IS
      v_dec   NUMBER;
      v_hex   VARCHAR2 (16) := '0123456789ABCDEF';
      
   BEGIN
      v_dec := 0;

      FOR indx IN 1 .. LENGTH (p_hex_str) LOOP
         v_dec := v_dec * 16 + INSTR (v_hex, UPPER (SUBSTR (p_hex_str, indx, 1))) - 1;
      END LOOP;

      RETURN v_dec;
   END hex_to_decimal;

   PROCEDURE delimstring_to_table (
                                      p_delimstring   IN       VARCHAR2,
                                      p_table         OUT      varchar2_table,
                                      p_nfields       OUT      INTEGER,
                                      p_a             OUT      NUMBER,
                                      p_delim         IN       VARCHAR2 DEFAULT ','
                                   )
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER      := 1;
      v_table      varchar2_table;
      v_delimpos   PLS_INTEGER      := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER      := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0 THEN
         logf ('Delimiter '','' not Found');
      END IF;

      WHILE v_delimpos > 0 LOOP
         v_table (v_nfields)    := SUBSTR (v_string, 1, v_delimpos - 1);
         v_string               := SUBSTR (v_string, v_delimpos + v_delimlen);
         v_nfields              := v_nfields + 1;
         v_delimpos             := INSTR (v_string, p_delim);
      END LOOP;

      v_table (v_nfields)   := v_string;
      p_table               := v_table;
      p_nfields             := v_nfields;
      
   END delimstring_to_table;
   
   PROCEDURE print_result_upd_DataPOSM (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.item_code
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_upd4_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
            and xou.error_message is not null
         group by 
              xou.org_code       
            , xou.item_code
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_upd4_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Item Master Data POSM LOB status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        STATUS ERROR_MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.item_code,              15,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result_upd_DataPOSM;       
   
   PROCEDURE print_result_upd_itemcat (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.item_code
            , xou.category_set_name
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_upd3_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
            and xou.error_message is not null
         group by 
              xou.org_code       
            , xou.item_code
            , xou.category_set_name
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_upd3_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload item category status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        CATEGORY NAME                             STATUS ERROR_MESSAGE                                                              ');       
      outF('      '||'---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.item_code,              15,' ')||'  ' ||
                        RPAD(i.category_set_name,      40,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         160,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- ----------------------------------------- ------ ---------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result_upd_itemcat;    
   
   PROCEDURE print_result_upd_DataTMB (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.item_code
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_upd2_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
            and xou.error_message is not null
         group by 
              xou.org_code       
            , xou.item_code
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_upd2_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Item Master Data TMB status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        STATUS ERROR_MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.item_code,              15,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result_upd_DataTMB;    
   
   PROCEDURE print_result_upd_ppsize (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50) item_description
            , xou.attribute20
            , xou.attribute21
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_upd_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
         group by 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50)
            , xou.attribute20
            , xou.attribute21
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_upd_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Item EPM Mapping status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- --------------------------------------------------- ----------- ------------ ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        ITEM_DESCRIPTION                                    PALLET_SIZE PACKING_SIZE STATUS ERROR_MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- --------------------------------------------------- ----------- ------------ ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.segment1,               15,' ')||'  ' ||
                        RPAD(i.item_description,       50,' ')||'  ' ||
                        RPAD(i.attribute20,            10,' ')||'  ' ||
                        RPAD(i.attribute21,            10,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- --------------------------------------------------- ----------- ------------ ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result_upd_ppsize;     
   
   PROCEDURE print_result_upd_epm (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50) item_description
            , substr(xou.attribute16, 1, 10) attribute16
            , substr(xou.attribute17, 1, 10) attribute17
            , substr(xou.attribute18, 1, 10) attribute18
            , substr(xou.attribute19, 1, 35) attribute19
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_upd_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
         group by 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50)
            , substr(xou.attribute16, 1, 10)
            , substr(xou.attribute17, 1, 10)
            , substr(xou.attribute18, 1, 10)
            , substr(xou.attribute19, 1, 35)
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_upd_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Item EPM Mapping status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ---------- ---------- ----------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        ITEM_DESCRIPTION                                    EPM_CODE   EPM_CONV   EPM_ALIAS  ITEM_DESCRIPTION                    STATUS ERROR_MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ---------- ---------- ----------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.segment1,               15,' ')||'  ' ||
                        RPAD(i.item_description,       50,' ')||'  ' ||
                        RPAD(i.attribute16,            10,' ')||'  ' ||
                        RPAD(i.attribute17,            10,' ')||'  ' ||
                        RPAD(i.attribute18,            10,' ')||'  ' ||
                        RPAD(i.attribute19,            35,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ---------- ---------- ----------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result_upd_epm;         
   
   PROCEDURE print_result2 (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50) item_description
            , xou.subinv_code
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_assign_itemtosubinv_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
         group by 
              xou.org_code       
            , xou.segment1
            , substr(xou.description, 1, 50)
            , xou.subinv_code            
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_assign_itemtosubinv_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Assign Item to subinventories status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM_CODE        ITEM_DESCRIPTION                                    SUB_INV    STATUS ERROR_MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.org_code,                3,' ')||'  ' ||
                        RPAD(i.segment1,               15,' ')||'  ' ||
                        RPAD(i.item_description,       50,' ')||'  ' ||
                        RPAD(i.subinv_code,            10,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- --------------------------------------------------- ---------- ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result2;       
   
   PROCEDURE process_data_upd_dataPOSM(
                                        p_file_id      NUMBER
                                      )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;      
   
   l_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_message_list               Error_Handler.Error_Tbl_Type;
   
 
   i                            NUMBER:= 1;
   l_inventory_item_id          NUMBER:= 0;
   l_org_id                     NUMBER:= 0;
                  
   l_counter                    NUMBER:= 0;
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize
            (
                  user_id       => g_user_id
                , resp_id       => g_resp_id
                , resp_appl_id  => g_resp_appl_id
            );   
          
       l_counter :=0;
       
       for dt in c_upd_item_posm(p_file_id) loop
       
           l_org_id             := null;
           l_inventory_item_id  := null;         
           
           l_counter            := l_counter + 1;        
                
           l_item_table(l_counter).transaction_type                := 'UPDATE'; -- replace this with 'update' for update transaction.
           l_item_table(l_counter).organization_code               := dt.org_code;
           l_item_table(l_counter).segment1                        := dt.item_code;
           l_item_table(l_counter).attribute22                     := dt.attribute22; 
                                              
       end loop;   
       
       x_return_status  := NULL;
       x_msg_count      := NULL;
       x_msg_data       := NULL;
       x_msg_data2      := NULL;
       x_loop_cnt       := NULL;
       x_dummy_cnt      := NULL;
       x_msg_index_out  := NULL;   
       logf ('');
       logf ('Calling API to Update Item ');
                        
       ego_item_pub.process_items(
                                      p_api_version      => 1.0
                                    , p_init_msg_list    => FND_API.g_TRUE
                                    , p_commit           => FND_API.g_TRUE
                                    , p_Item_Tbl         => l_item_table
                                    , x_Item_Tbl         => x_item_table
                                    , x_return_status    => x_return_status
                                    , x_msg_count        => x_msg_count
                                 );                      
             

       if (x_return_status = fnd_api.g_ret_sts_success) then

          logf ('API to update all items -> S');
          
          update xxshp_inv_upd4_items_stg
          set status = 'S',flag = 'N'
          where 1=1
            and file_id      = p_file_id;                  

       else

          logf ('API to update all items -> E');                   
                
          update xxshp_inv_upd4_items_stg
          set   status        = 'E'
              , flag          = 'N'
              , error_message = x_msg_data2
          where 1=1
             and file_id      = p_file_id;                  
                           
       end if;                                                     
            
       commit;
       
       select count(1)                       
       into l_error
       from xxshp_inv_upd4_items_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result_upd_dataPOSM(p_file_id);

      else
        
         logf ('Successfully , API Update data Item Master POSM LOB for data all ...!!!');           
                   
      end if;       
                           
   END process_data_upd_dataPOSM;               

   PROCEDURE process_data_upd_itemcat(
                                    p_file_id      NUMBER
                                 )   
   IS    
   
   x_return_status              VARCHAR2 (80);
   x_error_code                 NUMBER;
   x_msg_count                  NUMBER;
   x_msg_data                   VARCHAR2 (250);

   l_msg_index_out              NUMBER;
   l_error_message              VARCHAR2 (2000);
      
   i                            NUMBER:= 1;

   l_new_category_id            NUMBER;
   l_old_category_id            NUMBER;
   l_category_set_id            NUMBER;
   l_inventory_item_id          NUMBER;
   l_organization_id            NUMBER;   
                  
   l_counter                    NUMBER:= 0;
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize
            (
                  user_id       => g_user_id
                , resp_id       => g_resp_id
                , resp_appl_id  => g_resp_appl_id
            );   
          
       l_counter :=0;
       
       FOR dt IN c_upd3_item_inv_stg(p_file_id) 
       LOOP
       
           l_organization_id    := NULL;
           l_inventory_item_id  := NULL;    
           l_category_set_id    := NULL;     
           l_new_category_id    := NULL;
           l_old_category_id    := NULL;
           
           l_msg_index_out      := 0;
           l_error_message      := '';
           
                     
           SELECT mcs_tl.category_set_id
           INTO l_category_set_id
           FROM mtl_category_sets_tl mcs_tl
           WHERE mcs_tl.category_set_name = dt.category_set_name;
           
           IF l_category_set_id IS NOT NULL
           THEN 
                     
               BEGIN
               
                   SELECT mcb.category_id
                   INTO l_new_category_id
                   FROM mtl_categories_b mcb
                   WHERE 1=1 
                      AND NVL(mcb.segment1,dt.new_segment1) = dt.new_segment1
                      AND NVL(mcb.segment2,dt.new_segment2) = dt.new_segment2
                      AND NVL(mcb.segment3,dt.new_segment3) = dt.new_segment3
                      AND NVL(mcb.segment4,dt.new_segment4) = dt.new_segment4
                      AND NVL(mcb.segment5,dt.new_segment5) = dt.new_segment5
                      AND NVL(mcb.segment6,dt.new_segment6) = dt.new_segment6
                      AND mcb.structure_id = (SELECT mcs.structure_id
                                                FROM mtl_category_sets_b mcs
                                               WHERE mcs.category_set_id = l_category_set_id);
               END;
               
               BEGIN                                           
                                           
                   SELECT mcb.category_id
                   INTO l_old_category_id
                   FROM mtl_categories_b mcb
                   WHERE 1=1 
                      AND NVL(mcb.segment1,dt.old_segment1)  = dt.old_segment1
                      AND NVL(mcb.segment2,dt.old_segment2)  = dt.old_segment2
                      AND NVL(mcb.segment3,dt.old_segment3)  = dt.old_segment3
                      AND NVL(mcb.segment4,dt.old_segment4)  = dt.old_segment4
                      AND NVL(mcb.segment5,dt.old_segment5) = dt.old_segment5
                      AND NVL(mcb.segment6,dt.old_segment6) = dt.old_segment6
                      AND mcb.structure_id = (SELECT mcs.structure_id
                                                FROM mtl_category_sets_b mcs
                                               WHERE mcs.category_set_id = l_category_set_id);                                   
               END;
                          
           END IF;           

           BEGIN
           
               SELECT organization_id
                 INTO l_organization_id
               FROM mtl_parameters
               WHERE organization_code = dt.org_code;               
           END;
           
           BEGIN

               SELECT inventory_item_id
                 INTO l_inventory_item_id
               FROM mtl_system_items_b
               WHERE 1=1
                  AND segment1          = dt.item_code
                  AND organization_id   = l_organization_id;
              
           END;   

           inv_item_category_pub.update_category_assignment 
                            (   
                                  p_api_version                  => 1.0
                                , p_init_msg_list               => fnd_api.g_true
                                , p_commit                      => fnd_api.g_true
                                , x_return_status               => x_return_status
                                , x_errorcode                   => x_error_code
                                , x_msg_count                   => x_msg_count
                                , x_msg_data                    => x_msg_data
                                , p_old_category_id             => l_old_category_id
                                , p_category_id                 => l_new_category_id
                                , p_category_set_id             => l_category_set_id
                                , p_inventory_item_id           => l_inventory_item_id
                                , p_organization_id             => l_organization_id
                            );                   

           IF (x_return_status = fnd_api.g_ret_sts_success)
           THEN
              
              UPDATE xxshp_inv_upd3_items_stg
              SET status = 'S',flag = 'N'
              WHERE 1=1
                 AND org_code            = dt.org_code
                 AND item_code           = dt.item_code
                 AND category_set_name   = dt.category_set_name
                 AND file_id             = p_file_id;                  

           ELSE

              FOR i IN 1 .. x_msg_count
              LOOP
                 
                 apps.fnd_msg_pub.get (p_msg_index                   => i
                                     , p_encoded                     => fnd_api.g_false
                                     , p_data                        => x_msg_data
                                     , p_msg_index_out               => l_msg_index_out
                                      );

                 IF l_error_message IS NULL
                 THEN
                    l_error_message := SUBSTR (x_msg_data, 1, 250);
                 ELSE
                    l_error_message := l_error_message || ' /' || SUBSTR (x_msg_data, 1, 250);
                 END IF;
                 
              END LOOP;
                    
           
              UPDATE xxshp_inv_upd3_items_stg
              SET   status        = 'E'
                  , flag          = 'N'
                  , error_message = l_error_message
              WHERE 1=1
                 AND org_code            = dt.org_code
                 AND item_code           = dt.item_code
                 AND category_set_name   = dt.category_set_name
                 AND file_id             = p_file_id;                  
                               
           END IF;                                                     
                
           COMMIT;
                                              
           
       END LOOP;   
       
             
       SELECT COUNT(1)                       
       INTO l_error
       FROM xxshp_inv_upd3_items_stg
       WHERE 1=1
          AND NVL(status,'E')   = 'E' 
          AND NVL(flag,  'N')   = 'N'
          AND file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      IF l_error > 0 
      THEN
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result_upd_itemcat(p_file_id);

      ELSE
        
         logf ('Successfully , API Update item category for data all ...!!!');           
                   
      END IF;       
                           
   END process_data_upd_itemcat; 


   PROCEDURE process_data_upd_dataTMB(
                                        p_file_id      NUMBER
                                     )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;      
   
   l_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_message_list               Error_Handler.Error_Tbl_Type;
   
 
   i                            NUMBER:= 1;
   l_inventory_item_id          NUMBER:= 0;
   l_org_id                     NUMBER:= 0;
                  
   l_counter                    NUMBER:= 0;
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize
            (
                  user_id       => g_user_id
                , resp_id       => g_resp_id
                , resp_appl_id  => g_resp_appl_id
            );   
          
       l_counter :=0;
       
       for dt in c_upd2_item_inv_stg(p_file_id) loop
       
           l_org_id             := null;
           l_inventory_item_id  := null;         
           
           l_counter            := l_counter + 1;        
                
           l_item_table(l_counter).transaction_type                := 'UPDATE'; -- replace this with 'update' for update transaction.
           l_item_table(l_counter).organization_code               := dt.org_code;
           l_item_table(l_counter).segment1                        := dt.item_code;
           l_item_table(l_counter).purchasing_item_flag            := dt.purchasing_item_flag;
           l_item_table(l_counter).purchasing_enabled_flag         := dt.purchasing_enabled_flag;
           l_item_table(l_counter).must_use_approved_vendor_flag   := dt.must_use_approved_vendor_flag;
           l_item_table(l_counter).planning_make_buy_code          := dt.planning_make_buy_code;
           l_item_table(l_counter).default_lot_status_id           := dt.default_lot_status_id; 
           l_item_table(l_counter).list_price_per_unit             := dt.list_price_per_unit;
           l_item_table(l_counter).preprocessing_lead_time         := dt.preprocessing_lead_time;
           l_item_table(l_counter).full_lead_time                  := dt.full_lead_time;
           l_item_table(l_counter).postprocessing_lead_time        := dt.postprocessing_lead_time;  
           l_item_table(l_counter).attribute13                     := dt.attribute13; 
           l_item_table(l_counter).attribute20                     := dt.attribute20; 
           l_item_table(l_counter).attribute21                     := dt.attribute21; 
                                              
       end loop;   
       
       x_return_status  := NULL;
       x_msg_count      := NULL;
       x_msg_data       := NULL;
       x_msg_data2      := NULL;
       x_loop_cnt       := NULL;
       x_dummy_cnt      := NULL;
       x_msg_index_out  := NULL;   
       logf ('');
       logf ('Calling API to Update Item ');
                        
       ego_item_pub.process_items(
                                      p_api_version      => 1.0
                                    , p_init_msg_list    => FND_API.g_TRUE
                                    , p_commit           => FND_API.g_TRUE
                                    , p_Item_Tbl         => l_item_table
                                    , x_Item_Tbl         => x_item_table
                                    , x_return_status    => x_return_status
                                    , x_msg_count        => x_msg_count
                                 );                      
             

       if (x_return_status = fnd_api.g_ret_sts_success) then

          logf ('API to update all items -> S');
          
          update xxshp_inv_upd2_items_stg
          set status = 'S',flag = 'N'
          where 1=1
            and file_id      = p_file_id;                  

       else

          logf ('API to update all items -> E');                   
                
          update xxshp_inv_upd2_items_stg
          set   status        = 'E'
              , flag          = 'N'
              , error_message = x_msg_data2
          where 1=1
             and file_id      = p_file_id;                  
                           
       end if;                                                     
            
       commit;
       
       select count(1)                       
       into l_error
       from xxshp_inv_upd2_items_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result_upd_dataTMB(p_file_id);

      else
        
         logf ('Successfully , API Update data Item Master TMB for data all ...!!!');           
                   
      end if;       
                           
   END process_data_upd_dataTMB; 

   PROCEDURE process_data_upd_ppsize(
                                    p_file_id      NUMBER
                                 )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;      
   
 
   i                     NUMBER:= 1;
   l_inventory_item_id   NUMBER:= 0;
   l_org_id              NUMBER:= 0;
                  
   l_counter             NUMBER:= 0;
   x_return_status       VARCHAR2(2); 
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize(user_id=>g_user_id,resp_id=>g_resp_id,resp_appl_id=>g_resp_appl_id);   
          
       for dt in c_upd_item_inv_stg2(p_file_id) loop
       
           l_org_id             := null;
           l_inventory_item_id  := null;
       
           select organization_id
           into l_org_id
           from mtl_parameters
           where 1=1
              and organization_code = dt.org_code;                            
            
            select inventory_item_id
            into l_inventory_item_id
            from mtl_system_items 
            where 1=1
                and segment1        = dt.segment1
                and organization_id = l_org_id;  
                
            -- update attribute untuk Pallet and Packing Size   
            update mtl_system_items    
            set attribute20 = dt.attribute20,
                attribute21 = dt.attribute21
            where 1=1
                and organization_id     = l_org_id
                and inventory_item_id   = l_inventory_item_id;       

                         
            update xxshp_inv_upd_items_stg
            set status = 'S',flag = 'N'
            where 1=1
               and segment1     = dt.segment1
               and org_code     = dt.org_code
               and file_id      = p_file_id;                  

       end loop;   
            
       commit;
       
       select count(1)                       
       into l_error
       from xxshp_inv_upd_items_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result_upd_ppsize(p_file_id);

      else
        
         logf ('Successfully , API Update Packing and Pallet Size for data all ...!!!');           
                   
      end if;       
                           
   END process_data_upd_ppsize;         
   PROCEDURE process_data_upd_epm(
                                    p_file_id      NUMBER
                                 )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;      
   
 
   i                     NUMBER:= 1;
   l_inventory_item_id   NUMBER:= 0;
   l_org_id              NUMBER:= 0;
                  
   l_counter             NUMBER:= 0;
   x_return_status       VARCHAR2(2); 
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize(user_id=>g_user_id,resp_id=>g_resp_id,resp_appl_id=>g_resp_appl_id);   
          
       for dt in c_upd_item_inv_stg(p_file_id) loop
       
           l_org_id             := null;
           l_inventory_item_id  := null;
       
           select organization_id
           into l_org_id
           from mtl_parameters
           where 1=1
              and organization_code = dt.org_code;                            
            
            select inventory_item_id
            into l_inventory_item_id
            from mtl_system_items 
            where 1=1
                and segment1        = dt.segment1
                and organization_id = l_org_id;  
                
            -- update attribute untuk Item EPM Mapping dan conversion     
            update mtl_system_items    
            set attribute16 = dt.attribute16,
                attribute17 = dt.attribute17,
                attribute18 = dt.attribute18,
                attribute19 = dt.attribute19
            where 1=1
                and organization_id     = l_org_id
                and inventory_item_id   = l_inventory_item_id;       

                         
            update xxshp_inv_upd_items_stg
            set status = 'S',flag = 'N'
            where 1=1
               and segment1     = dt.segment1
               and org_code     = dt.org_code
               and file_id      = p_file_id;                  

       end loop;   
            
       commit;
       
       select count(*)                       
       into l_error
       from xxshp_inv_upd_items_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result_upd_epm(p_file_id);

      else
        
         logf ('Successfully , API Update Item Mapping for data all ...!!!');           
                   
      end if;       
                           
   END process_data_upd_epm;        
   PROCEDURE process_data2(
                             p_file_id      NUMBER
                          )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;      
   
 
   i                     NUMBER:= 1;
   l_inventory_item_id   NUMBER:= 0;
   l_type                VARCHAR2(10):='IOM';   
   l_org_id              NUMBER:= 0;
                  
   l_counter             NUMBER:= 0;
   x_return_status       VARCHAR2(2); 
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;   
   
   
   BEGIN
   
       fnd_global.apps_initialize(user_id=>g_user_id,resp_id=>g_resp_id,resp_appl_id=>g_resp_appl_id);   
          
       for dt in c_item_inv_stg(p_file_id) loop
       
           l_org_id             := null;
           l_inventory_item_id  := null;
       
           select organization_id
           into l_org_id
           from mtl_parameters
           where 1=1
              and organization_code = dt.org_code;                            
            
            select inventory_item_id
            into l_inventory_item_id
            from mtl_system_items 
            where 1=1
                and segment1        = dt.segment1
                and organization_id = l_org_id;  
                
            insert into mtl_item_sub_inventories
                (inventory_item_id, organization_id, secondary_inventory, inventory_planning_code, last_update_date, last_updated_by, creation_date, created_by)
            values
                (l_inventory_item_id, l_org_id, dt.subinv_code, 6, sysdate, g_user_id, sysdate, g_user_id);
                         
            update xxshp_assign_itemtosubinv_stg
            set status = 'S',flag = 'N'
            where 1=1
               and segment1     = dt.segment1
               and org_code     = dt.org_code
               and subinv_code  = dt.subinv_code
               and file_id      = p_file_id;                  

       end loop;   
            
       commit;
       
       select count(*)                       
       into l_error
       from xxshp_assign_itemtosubinv_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result2(p_file_id);

      else
        
         logf ('Successfully , API Assign Item to subinventories for data all  ...!!!');           
                   
      end if;       
                           
   END process_data2;      
   
   PROCEDURE print_result (p_file_id NUMBER)
   IS
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.organization_code       
            , xou.segment1
            , substr(xou.description, 1, 50) item_description
            , xou.status
            , substr(xou.error_message, 1, 200) error_message           
         from xxshp_inv_items_stg xou         
         where 1=1      
            and nvl(status,'E') = 'E' 
            and nvl(flag,  'N') = 'N'   
            and file_id         = p_file_id
         group by 
              xou.organization_code       
            , xou.segment1
            , substr(xou.description, 1, 50)
            , xou.status
            , substr(xou.error_message, 1, 200);
            
   BEGIN
              
         select file_name, user_created_by, creation_date
         into l_file_name, l_user_created_by, l_creation_date                
         from
            (                 
                 select
                          xou.file_name                  
                        , (
                             select user_name
                             from fnd_user
                             where 1=1
                                and user_id = xou.created_by
                          ) user_created_by
                        , to_char (xou.creation_date   , 'DD-MON-RR HH24:MI:SS') creation_date
                 from xxshp_inv_items_stg xou         
                 where 1=1                 
                    and nvl(status,'E') = 'E' 
                    and nvl(flag,  'N') = 'N'   
                    and file_id         = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload Master Item status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'ORG  ITEM CODE        ITEM DESCRIPTION                                    STATUS ERROR MESSAGE                                                                                                           ');       
      outF('      '||'---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.organization_code,       3,' ')||'  ' ||
                        RPAD(i.segment1,               15,' ')||'  ' ||
                        RPAD(i.item_description,       50,' ')||'  ' ||
                        RPAD(i.status,                  5,' ')||'  ' ||
                        RPAD(i.error_message,         200,' ')
                     );              
           
      END LOOP;
      outF('      '||'---- ---------------- --------------------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result;      
   
   PROCEDURE process_data(
                           p_file_id      NUMBER
                         )   
   IS
   
   x_return_status              VARCHAR2 (2);
   x_msg_count                  NUMBER    := 0;
   x_msg_data                   VARCHAR2 (2000);
   x_msg_data2                  VARCHAR2 (2000);
   x_loop_cnt                   NUMBER(10):= 0;
   x_dummy_cnt                  NUMBER(10):= 0;
   x_msg_index_out              NUMBER;   
       
   l_counter                    NUMBER    := 0; 
   l_sales_account_id           NUMBER    := 0;
   l_expense_account_id         NUMBER    := 0;
   
   
   x_ledger_id                  NUMBER:=0;
   x_chart_of_accounts_id       NUMBER:=0;   
   
   l_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_item_table                 EGO_Item_PUB.Item_Tbl_Type;
   x_message_list               Error_Handler.Error_Tbl_Type;
    
   i                            NUMBER:= 1;
   l_init_msg_list              BOOLEAN;
   l_commit                     BOOLEAN;
   return_sts                   BOOLEAN;
   
   l_error                      PLS_INTEGER:=0;
   l_conc_status                BOOLEAN;

   
   BEGIN
   
       fnd_global.apps_initialize(user_id=>g_user_id,resp_id=>g_resp_id,resp_appl_id=>g_resp_appl_id);
   
       select ledger_id,chart_of_accounts_id
       into x_ledger_id,x_chart_of_accounts_id
       from gl_ledgers
       where 1=1
           and upper(ledger_category_code)='PRIMARY';  
           
        FOR i IN c_items_stg(p_file_id) LOOP                         
            
            l_counter :=  l_counter + 1;        
            
            l_sales_account_id := null;
            
            if i.sales_account_code is not null then                       

                select code_combination_id
                into l_sales_account_id
                from gl_code_combinations_kfv
                where 1=1
                    and chart_of_accounts_id    =x_chart_of_accounts_id
                    and concatenated_segments   =i.sales_account_code;

            end if;  
                                                          
            l_expense_account_id := null;
            
            if i.expense_account_code is not null then                       

                select code_combination_id
                into l_expense_account_id
                from gl_code_combinations_kfv
                where 1=1
                    and chart_of_accounts_id    =x_chart_of_accounts_id
                    and concatenated_segments   =i.expense_account_code;

            end if;  

            --FIRST Item definition
            l_item_table(1).transaction_type                := 'CREATE'; -- replace this with 'update' for update transaction.
            l_item_table(1).segment1                        := i.segment1;
            l_item_table(1).description                     := i.description;  
            l_item_table(1).long_description                := i.long_description;  
            l_item_table(1).organization_code               := i.organization_code;
            l_item_table(1).primary_uom_code                := i.primary_uom_code;
            l_item_table(1).secondary_uom_code              := i.secondary_uom_code;
            
            if upper(i.attribute_category)='DIRECT' then

                l_item_table(1).auto_lot_alpha_prefix       := i.auto_lot_alpha_prefix;
                l_item_table(1).start_auto_lot_number       := i.start_auto_lot_number;                    

                if i.sales_account_code is not null then
                                    
                    l_item_table(1).sales_account           := l_sales_account_id;
                    
                end if;
                
                if i.expense_account_code is not null then
                 
                    l_item_table(1).expense_account         := l_expense_account_id;
                     
                end if;
                                      
            end if;
            
            l_item_table(1).template_name                   := i.template_name;                        
            l_item_table(1).encumbrance_account             := i.encumbrance_account;
            l_item_table(1).list_price_per_unit             := i.list_price_per_unit;
            l_item_table(1).preprocessing_lead_time         := i.preprocessing_lead_time; 
            l_item_table(1).full_lead_time                  := i.full_lead_time; 
            l_item_table(1).postprocessing_lead_time        := i.postprocessing_lead_time; 
            l_item_table(1).minimum_order_quantity          := i.minimum_order_quantity; 
            l_item_table(1).maximum_order_quantity          := i.maximum_order_quantity; 
            l_item_table(1).min_minmax_quantity             := i.min_minmax_quantity; 
            l_item_table(1).max_minmax_quantity             := i.max_minmax_quantity; 
            l_item_table(1).fixed_lot_multiplier            := i.fixed_lot_multiplier; 
            l_item_table(1).fixed_order_quantity            := i.fixed_order_quantity; 
            l_item_table(1).weight_uom_code                 := i.weight_uom_code; 
            l_item_table(1).unit_weight                     := i.unit_weight; 
            l_item_table(1).attribute6                      := i.attribute6; 
            l_item_table(1).attribute9                      := i.attribute9; 
            l_item_table(1).attribute13                     := i.attribute13;
            l_item_table(1).attribute8                      := i.attribute8; 
            l_item_table(1).attribute20                     := i.attribute20;
            l_item_table(1).attribute11                     := i.attribute11;
            l_item_table(1).attribute21                     := i.attribute21;
            l_item_table(1).attribute3                      := i.attribute3;
            l_item_table(1).attribute1                      := i.attribute1;
            l_item_table(1).attribute2                      := i.attribute2;
            l_item_table(1).attribute4                      := i.attribute4;
            l_item_table(1).attribute10                     := i.attribute10;
            l_item_table(1).attribute7                      := i.attribute7;
            l_item_table(1).attribute12                     := i.attribute12;
            l_item_table(1).volume_uom_code                 := i.volume_uom_code;
            l_item_table(1).unit_volume                     := i.unit_volume;
            l_item_table(1).attribute_category              := i.attribute_category;
            l_item_table(1).restrict_subinventories_code    := i.restrict_subinventories_code;
            l_item_table(1).planner_code                    := i.planner_code;
            l_item_table(1).attribute14                     := i.attribute14;
            l_item_table(1).attribute5                      := i.attribute5;
            l_item_table(1).serial_number_control_code      := i.serial_number_control_code;
            l_item_table(1).auto_serial_alpha_prefix        := i.auto_serial_alpha_prefix;
            l_item_table(1).start_auto_serial_number        := i.start_auto_serial_number;
            l_item_table(1).attribute16                     := i.attribute16; -- Mapping EPM Item
            l_item_table(1).attribute17                     := i.attribute17; -- Mapping EPM Qty Conversion
            
            if  upper(i.attribute_category)='INDIRECT' then
            
                l_item_table(1).attribute25                 := i.attribute25;
                
            end if;
            
           x_return_status  := NULL;
           x_msg_count      := NULL;
           x_msg_data       := NULL;
           x_msg_data2      := NULL;
           x_loop_cnt       := NULL;
           x_dummy_cnt      := NULL;
           x_msg_index_out  := NULL;   
                        
            ego_item_pub.process_items(
                                          p_api_version      => 1.0
                                         ,p_init_msg_list    => FND_API.g_TRUE
                                         ,p_commit           => FND_API.g_TRUE
                                         ,p_Item_Tbl         => l_item_table
                                         ,x_Item_Tbl         => x_item_table
                                         ,x_return_status    => x_return_status
                                         ,x_msg_count        => x_msg_count
                                      );                      
             
            if x_return_status='S' then
                
              update xxshp_inv_items_stg
                  set status = 'S',flag = 'N'
              where 1=1
                  and segment1          = i.segment1
                  and organization_code = i.organization_code
                  and file_id           = p_file_id;                  
                  
            else
            
                if x_msg_count = 1 then
                   update xxshp_inv_items_stg
                      set error_message = substr(x_msg_data, 1, 2000),
                          status = 'E',flag = 'N'
                   where 1=1
                      and segment1          = i.segment1
                      and organization_code = i.organization_code
                      and file_id           = p_file_id;
                else
                
                   for i in 1 .. x_msg_count loop
                      fnd_msg_pub.get (
                                            p_msg_index       => i
                                          , p_data            => x_msg_data 
                                          , p_encoded         => fnd_api.g_false 
                                          , p_msg_index_out   => x_msg_index_out
                                      );
                                      
                      x_msg_data2 := x_msg_data2 || substr (x_msg_data, 1, 255);
                      
                   end loop;

                   update xxshp_inv_items_stg
                      set error_message = substr (x_msg_data2, 1, 2000),
                          status = 'E',flag = 'N'
                   where 1=1
                      and segment1          = i.segment1
                      and organization_code = i.organization_code
                      and file_id           = p_file_id;
                
                end if;
                
            end if;
                                                                              
       END LOOP;        
            
       commit;
       
       select count(1)                       
       into l_error
       from xxshp_inv_items_stg
       where 1=1
          and nvl(status,'E')   = 'E' 
          and nvl(flag,  'N')   = 'N'
          and file_id           = p_file_id;
          
      logf ('API error count : '||l_error);              

      if l_error > 0 then
      
         l_conc_status := fnd_concurrent.set_completion_status('WARNING',2);
         
         print_result(p_file_id);

      else
        
         logf ('API Master Item successfully for all data..!!!');           
                   
      end if;
   
   END;
   
   PROCEDURE final_validation_upd_itemcat (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_upd3_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_upd3_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_upd3_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result_upd_itemcat(p_file_id);

           logf ('Error, Update Item Categories for data all ..!!!');   
           
        else
        
           logf ('Successfully, Update Item Categories for data all ..!!!');              
                     
        end if;            
           
   END final_validation_upd_itemcat;  
   
   PROCEDURE final_validation_upd_dataPOSM (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_upd4_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_upd4_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_upd4_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result_upd_DataPOSM(p_file_id);

           logf ('Error, Update Item Master data POSM LOB for data all ..!!!');   
           
        else
        
           logf ('Successfully, Update Item Master data POSM LOB for data all ..!!!');              
                     
        end if;            
           
   END final_validation_upd_dataPOSM;      
      
   PROCEDURE final_validation_upd_dataTMB (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_upd2_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_upd2_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_upd2_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result_upd_DataTMB(p_file_id);

           logf ('Error, Update Item Master data TMB for data all ..!!!');   
           
        else
        
           logf ('Successfully, Update Item Master data TMB for data all ..!!!');              
                     
        end if;            
           
   END final_validation_upd_dataTMB;     

   PROCEDURE final_validation_upd_ppsize (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_upd_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_upd_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_upd_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result2(p_file_id);

           logf ('Error, Update Item Pallet and Packing Size for data all ..!!!');   
           
        else
        
           logf ('Successfully, Update Item Pallet and Packing Size for data all ..!!!');              
                     
        end if;            
           
   END final_validation_upd_ppsize;  
           
   
   PROCEDURE final_validation_upd_epm (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_upd_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_upd_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_upd_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result2(p_file_id);

           logf ('Error, Update Item EPM Mapping for data all ..!!!');   
           
        else
        
           logf ('Successfully, Update Item EPM for data all ..!!!');              
                     
        end if;            
           
   END final_validation_upd_epm;      
      
   PROCEDURE final_validation2 (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_assign_itemtosubinv_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_assign_itemtosubinv_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(*)                       
        into l_error
        from xxshp_assign_itemtosubinv_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result2(p_file_id);

           logf ('Error, Master Item for data all ..!!!');   
           
        else
        
           logf ('Successfully, Master Item for data all ..!!!');              
                     
        end if;            
           
   END final_validation2;      
   
   PROCEDURE final_validation (p_file_id NUMBER)
   IS
   
   l_conc_status    BOOLEAN;
   l_nextproceed    BOOLEAN    :=FALSE;

   l_error          PLS_INTEGER:=0;
   l_jml_data       NUMBER     :=0;

   
   cursor c_notvalid_items
   is         
         select 
              file_id      
            , status
         from xxshp_inv_items_stg xou         
         where 1=1
            and nvl(status,'E') ='E'
            and nvl(flag,  'Y') ='Y'
            and file_id         = p_file_id
         group by   
               file_id      
             , status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_notvalid_items loop
            
            exit when c_notvalid_items%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data>0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxshp_inv_items_stg
                set status='E', flag='N'
            where 1=1
                and nvl(flag,'Y')   ='Y'
                and file_id  = p_file_id;
                
            commit;                
        
        end if;                                         
                
        select count(1)                       
        into l_error
        from xxshp_inv_items_stg
        where 1=1
           and nvl(status,'E')  = 'E' 
            and nvl(flag, 'N')  = 'N'
            and file_id         = p_file_id;
            
       logf ('Error validation count : '||l_error);              
            
        if l_error > 0 then
        
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);
           
           print_result(p_file_id);

           logf ('Error, Master Item for data all ..!!!');   
           
        else
        
           logf ('Successfully, Master Item for data all ..!!!');              
                     
        end if;            
           
   END final_validation;          
   
   
   PROCEDURE insert_data (
                            errbuf      OUT VARCHAR2, 
                            retcode     OUT NUMBER, 
                            p_file_id   NUMBER
                         )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_segment1                  VARCHAR2(40);     
        l_organization_id           NUMBER;
        l_organization_code         VARCHAR2(10);
        l_description               VARCHAR2(240);
        l_long_description          VARCHAR2(2000); 
        l_primary_uom_code          VARCHAR2(10);
        l_secondary_uom_code        VARCHAR2(10); 
        l_template_name             VARCHAR2(30);
        l_expense_account           NUMBER;
        l_encumbrance_account       NUMBER;
        l_list_price_per_unit       NUMBER;
        l_auto_lot_alpha_prefix     VARCHAR2(30);
        l_start_auto_lot_number     VARCHAR2(30);
        l_preprocessing_lead_time   NUMBER;
        l_full_lead_time            NUMBER;
        l_postprocessing_lead_time  NUMBER;
        l_minimum_order_quantity    NUMBER;
        l_maximum_order_quantity    NUMBER;
        l_min_minmax_quantity       NUMBER;
        l_max_minmax_quantity       NUMBER;
        l_fixed_lot_multiplier      NUMBER;
        l_fixed_order_quantity      NUMBER;
        l_weight_uom_code           VARCHAR2(3);     
        l_unit_weight               NUMBER;
        l_attribute1                VARCHAR2(240);
        l_attribute2                VARCHAR2(240);
        l_attribute3                VARCHAR2(240);
        l_attribute4                VARCHAR2(240);
        l_attribute5                VARCHAR2(240);
        l_attribute6                VARCHAR2(240);
        l_attribute7                VARCHAR2(240);
        l_attribute8                VARCHAR2(240);
        l_attribute9                VARCHAR2(240);
        l_attribute10               VARCHAR2(240);
        l_attribute11               VARCHAR2(240);
        l_attribute12               VARCHAR2(240);
        l_attribute13               VARCHAR2(240);
        l_attribute14               VARCHAR2(240);
        l_attribute16               VARCHAR2(240);
        l_attribute17               VARCHAR2(240);
        l_attribute18               VARCHAR2(240);
        l_attribute19               VARCHAR2(240);
        l_attribute20               VARCHAR2(240);
        l_attribute21               VARCHAR2(240);
        l_attribute22               VARCHAR2(240);
        l_attribute23               VARCHAR2(240);
        l_volume_uom_code           VARCHAR2(3);
        l_unit_volume                   NUMBER;
        l_attribute_category            VARCHAR2(30);
        l_restrict_subinventories_code  NUMBER;
        l_planner_code                  VARCHAR2(10);
        l_sales_account_code            VARCHAR2(50);
        l_expense_account_code          VARCHAR2(50);
        l_serial_number_control_code    NUMBER;
        l_auto_serial_alpha_prefix      VARCHAR2(30);
        l_start_auto_serial_number      VARCHAR2(30);
        

        l_comments                VARCHAR2(200);
        l_status                  VARCHAR2(20);
        l_error_message           VARCHAR2(200);
      
      l_err_cnt                 NUMBER;
      l_stg_cnt                 NUMBER:= 0;
      l_item_cnt                NUMBER:= 0;
      l_cnt_err_format          NUMBER:= 0;
      l_sql                     VARCHAR2(32767);
      
      l_ledger_id               NUMBER:=0;
      l_org_id                  NUMBER:=0;
      l_chart_of_accounts_id    NUMBER:=0;   
      l_code_combination_id     NUMBER:=0;
      l_inventory_item_id       NUMBER:=0;
      l_template_id             NUMBER:=0;
      
      l_set_process_id          NUMBER:=0;
      
      l_uom_code                VARCHAR2(10);
      l_planner                 VARCHAR2(20);
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      BEGIN
           SELECT ledger_id,chart_of_accounts_id
           INTO l_ledger_id, l_chart_of_accounts_id
           FROM GL_LEDGERS
           WHERE 1=1
               AND UPPER(ledger_category_code)='PRIMARY';   
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;      
      END;

      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 52 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_segment1                      := TRIM (v_tab (1));                                                
                     ELSIF i = 2 THEN
                        l_organization_code             := TRIM (v_tab (2));
                     ELSIF i = 3 THEN
                        l_description                   := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_long_description              := TRIM (v_tab (4));
                     ELSIF i = 5 THEN
                        l_primary_uom_code              := TRIM (v_tab (5));
                    ELSIF  i = 6 THEN
                        l_secondary_uom_code            := TRIM (v_tab (6));
                     ELSIF i = 7 THEN
                        l_auto_lot_alpha_prefix         := TRIM (v_tab (7));
                     ELSIF i = 8 THEN
                        l_start_auto_lot_number         := TRIM (v_tab (8));
                     ELSIF i = 9 THEN
                        l_template_name                 := TRIM (v_tab (9));
                     ELSIF i = 10 THEN
                        l_expense_account               := TRIM (v_tab (10));
                     ELSIF i = 11 THEN
                        l_encumbrance_account           := TRIM (v_tab (11));
                     ELSIF i = 12 THEN
                        l_list_price_per_unit           := TRIM (v_tab (12));
                     ELSIF i = 13 THEN
                        l_preprocessing_lead_time       := TRIM (v_tab (13));
                     ELSIF i = 14 THEN
                        l_full_lead_time                := TRIM (v_tab (14));
                     ELSIF i = 15 THEN
                        l_postprocessing_lead_time      := TRIM (v_tab (15));
                     ELSIF i = 16 THEN
                        l_minimum_order_quantity        := TRIM (v_tab (16));
                     ELSIF i = 17 THEN
                        l_maximum_order_quantity        := TRIM (v_tab (17));
                     ELSIF i = 18 THEN
                        l_min_minmax_quantity           := TRIM (v_tab (18));
                     ELSIF i = 19 THEN
                        l_max_minmax_quantity           := TRIM (v_tab (19));
                     ELSIF i = 20 THEN
                        l_fixed_lot_multiplier          := TRIM (v_tab (20));
                     ELSIF i = 21 THEN
                        l_fixed_order_quantity          := TRIM (v_tab (21));
                     ELSIF i = 22 THEN
                        l_weight_uom_code               := TRIM (v_tab (22));
                     ELSIF i = 23 THEN
                        l_unit_weight                   := TRIM (v_tab (23));
                     ELSIF i = 24 THEN
                        l_volume_uom_code               := TRIM (v_tab (24));
                     ELSIF i = 25 THEN
                        l_unit_volume                   := TRIM (v_tab (25));
                     ELSIF i = 26 THEN
                        l_attribute6                    := TRIM (v_tab (26));
                     ELSIF i = 27 THEN
                        l_attribute9                    := TRIM (v_tab (27));
                     ELSIF i = 28 THEN
                        l_attribute13                   := TRIM (v_tab (28));
                     ELSIF i = 29 THEN
                        l_attribute8                    := TRIM (v_tab (29));
                     ELSIF i = 30 THEN
                        l_attribute20                   := TRIM (v_tab (30));
                     ELSIF i = 31 THEN
                        l_attribute11                   := TRIM (v_tab (31));
                     ELSIF i = 32 THEN
                        l_attribute21                   := TRIM (v_tab (32));
                     ELSIF i = 33 THEN
                        l_attribute3                    := TRIM (v_tab (33));
                     ELSIF i = 34 THEN
                        l_attribute1                    := TRIM (v_tab (34));
                     ELSIF i = 35 THEN
                        l_attribute4                    := TRIM (v_tab (35));
                     ELSIF i = 36 THEN
                        l_attribute10                   := TRIM (v_tab (36));
                     ELSIF i = 37 THEN
                        l_attribute7                    := TRIM (v_tab (37));
                     ELSIF i = 38 THEN
                        l_attribute12                   := TRIM (v_tab (38));
                     ELSIF i = 39 THEN
                        l_attribute14                   := TRIM (v_tab (39));
                     ELSIF i = 40 THEN
                        l_attribute_category            := TRIM (v_tab (40));
                     ELSIF i = 41 THEN
                        l_restrict_subinventories_code  := TRIM (v_tab (41));
                     ELSIF i = 42 THEN
                        l_planner_code                  := TRIM (v_tab (42));
                     ELSIF i = 43 THEN
                        l_sales_account_code            := TRIM (v_tab (43));
                     ELSIF i = 44 THEN
                        l_attribute5                    := TRIM (v_tab (44));                        
                     ELSIF i = 45 THEN
                        l_expense_account_code          := TRIM (v_tab (45));
                     ELSIF i = 46 THEN
                        l_serial_number_control_code    := TRIM (v_tab (46));
                     ELSIF i = 47 THEN
                        l_auto_serial_alpha_prefix      := TRIM (v_tab (47));
                     ELSIF i = 48 THEN
                        l_start_auto_serial_number      := TRIM (v_tab (48));
                     ELSIF i = 49 THEN
                        l_attribute16                   := TRIM (v_tab (49));
                     ELSIF i = 50 THEN
                        l_attribute17                   := TRIM (v_tab (50));
                     ELSIF i = 51 THEN
                        l_attribute18                   := TRIM (v_tab (51));
                     ELSIF i = 52 THEN
                        l_attribute19                   := TRIM (v_tab (52));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := NULL;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := NULL;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_organization_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
              --/*   
                  --validasi item
                  BEGIN
                  
                       l_item_cnt := 0;
                                              
                       select count(*)
                       into l_item_cnt
                       from mtl_system_items    msi,
                            mtl_parameters      mp
                       where 1=1
                            and msi.organization_id     = mp.organization_id
                            and msi.organization_id     = l_org_id
                            and msi.segment1            = l_segment1;
                            
                       if l_item_cnt > 0 then
                       
                            l_error_message := l_error_message || 'Duplicate item code in organization : '||l_organization_code||', ';
                            l_err_cnt       := l_err_cnt + 1;
                       
                       end if;
                        
                  END;
               
              
                                    
                  --validasi primary_uom_code
                  BEGIN
                  
                     l_uom_code := NULL;
                                                      
                     select uom_code
                     into l_uom_code
                     from mtl_units_of_measure 
                     where 1=1
                        and uom_code = l_primary_uom_code
                        and uom_class in ('Weight','Volume','Count','Length','Area');
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message || 'Invalid primary_uom_code, ';
                        l_err_cnt       := l_err_cnt + 1;                  
                  END;                           
                  
                  --validasi secondary_uom_code
                  
                  IF l_secondary_uom_code IS NOT NULL THEN
                                        
                      BEGIN
                      
                      
                         l_uom_code := NULL;
                                                          
                         select uom_code
                         into l_uom_code
                         from mtl_units_of_measure 
                         where 1=1
                            and uom_code = l_secondary_uom_code
                            and uom_class in ('Weight','Volume','Count','Length','Area');
                                                      
                      EXCEPTION
                         WHEN OTHERS THEN
                            l_error_message := l_error_message || 'Invalid secondary_uom_code, ';
                            l_err_cnt       := l_err_cnt + 1;                  
                      END;     
                  
                  END IF;                      

                  --validasi Template Name
                  BEGIN

                     l_template_id := NULL;
                     
                     -- update fajrin 19-Jul-2017 : jika ada penambahan item template baru,data tidak ditemukan di mtl_item_templates_b  
                     select template_id
                     into l_template_id
                     from mtl_item_templates
                     where 1=1
                        and upper(template_name) = upper(l_template_name);                          
                                                                        
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message || 'Invalid template name, ';
                        l_err_cnt       := l_err_cnt + 1;                  
                  END;   
                  
                  --validasi Planner code
                  BEGIN

                     l_planner := NULL;
                     
                     if l_planner_code is not null then

                         select planner_code
                         into l_planner
                         from mtl_planners
                         where 1=1
                            and upper(planner_code) = upper(l_planner_code)
                            and organization_id     = l_org_id;                   
                     
                     end if;
                                                                        
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message || 'Invalid planner code, ';
                        l_err_cnt       := l_err_cnt + 1;                  
                  END;                                            
                  
                                                           
                  --validasi l_sales_account_code                                   
                  
                  BEGIN
                  
                       l_code_combination_id := NULL;
                  
                       if l_sales_account_code is not null then

                           select code_combination_id
                           into l_code_combination_id
                           from gl_code_combinations_kfv
                           where 1=1
                                and chart_of_accounts_id    = l_chart_of_accounts_id
                                and concatenated_segments   = l_sales_account_code;
                       
                       end if;

                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message || 'Invalid sales_account_code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;                
                
                 --validasi l_expense_account_code                                   
                  
                  BEGIN
                  
                       l_code_combination_id := NULL;
                  
                       if l_expense_account_code is not null then

                           select code_combination_id
                           into l_code_combination_id
                           from gl_code_combinations_kfv
                           where 1=1
                                and chart_of_accounts_id    = l_chart_of_accounts_id
                                and concatenated_segments   = l_expense_account_code;
                       
                       end if;

                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message || 'Invalid expense_account_code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;
                                
              --*/
                 
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_items_stg(
                            file_id                         ,
                            file_name                       ,
                            set_process_id                  ,
                            segment1                        ,
                            organization_code               ,
                            description                     ,
                            long_description                ,
                            primary_uom_code                ,
                            secondary_uom_code              ,   
                            template_name                   ,
                            expense_account                 ,
                            encumbrance_account             ,
                            list_price_per_unit             ,
                            auto_lot_alpha_prefix           ,
                            start_auto_lot_number           ,
                            preprocessing_lead_time         ,   
                            full_lead_time                  ,
                            postprocessing_lead_time        ,
                            minimum_order_quantity          ,
                            maximum_order_quantity          ,
                            min_minmax_quantity             ,
                            max_minmax_quantity             ,
                            fixed_lot_multiplier            ,
                            fixed_order_quantity            ,
                            weight_uom_code                 ,
                            unit_weight                     ,
                            attribute6                      ,
                            attribute9                      ,
                            attribute13                     ,
                            attribute8                      ,
                            attribute20                     ,
                            attribute11                     ,
                            attribute21                     ,
                            attribute3                      ,
                            attribute1                      ,
                            attribute2                      ,
                            attribute4                      ,
                            attribute10                     ,
                            attribute7                      ,
                            attribute12                     ,
                            volume_uom_code                 ,
                            unit_volume                     ,
                            attribute_category              ,
                            restrict_subinventories_code    ,
                            planner_code                    ,
                            sales_account_code              ,
                            attribute14                     ,
                            attribute5                      ,
                            expense_account_code            ,
                            serial_number_control_code      , 
                            auto_serial_alpha_prefix        ,  
                            start_auto_serial_number        ,  
                            attribute16                     ,
                            attribute17                     ,
                            attribute18                     ,
                            attribute19                     ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_set_process_id
                     || ''','''
                     || l_segment1
                     || ''','''
                     || l_organization_code
                     || ''','''
                     || l_description
                     || ''','''
                     || l_long_description
                     || ''','''
                     || l_primary_uom_code
                     || ''','''
                     || l_secondary_uom_code
                     || ''','''
                     || l_template_name
                     || ''','''
                     || l_expense_account
                     || ''','''
                     || l_encumbrance_account
                     || ''','''
                     || l_list_price_per_unit
                     || ''','''
                     || l_auto_lot_alpha_prefix
                     || ''','''
                     || l_start_auto_lot_number
                     || ''','''
                     || l_preprocessing_lead_time
                     || ''','''
                     || l_full_lead_time
                     || ''','''
                     || l_postprocessing_lead_time
                     || ''','''
                     || l_minimum_order_quantity
                     || ''','''
                     || l_maximum_order_quantity
                     || ''','''
                     || l_min_minmax_quantity
                     || ''','''
                     || l_max_minmax_quantity
                     || ''','''
                     || l_fixed_lot_multiplier
                     || ''','''
                     || l_fixed_order_quantity
                     || ''','''
                     || l_weight_uom_code
                     || ''','''
                     || l_unit_weight
                     || ''','''
                     || l_attribute6
                     || ''','''
                     || l_attribute9
                     || ''','''
                     || l_attribute13
                     || ''','''
                     || l_attribute8
                     || ''','''
                     || l_attribute20
                     || ''','''
                     || l_attribute11
                     || ''','''
                     || l_attribute21
                     || ''','''
                     || l_attribute3
                     || ''','''
                     || l_attribute1
                     || ''','''
                     || l_template_name
                     || ''','''
                     || l_attribute4
                     || ''','''
                     || l_attribute10
                     || ''','''
                     || l_attribute7
                     || ''','''
                     || l_attribute12
                     || ''','''
                     || l_volume_uom_code
                     || ''','''
                     || l_unit_volume
                     || ''','''
                     || l_attribute_category
                     || ''','''
                     || l_restrict_subinventories_code
                     || ''','''
                     || l_planner_code
                     || ''','''
                     || l_sales_account_code
                     || ''','''
                     || l_attribute14
                     || ''','''
                     || l_attribute5
                     || ''','''
                     || l_expense_account_code            
                     || ''','''
                     || l_serial_number_control_code            
                     || ''','''
                     || l_auto_serial_alpha_prefix            
                     || ''','''
                     || l_start_auto_serial_number            
                     || ''','''
                     || l_attribute16
                     || ''','''
                     || l_attribute17
                     || ''','''
                     || l_attribute18
                     || ''','''
                     || l_attribute19
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data;   
   
   
   PROCEDURE insert_data2 (
                            errbuf      OUT VARCHAR2, 
                            retcode     OUT NUMBER, 
                            p_file_id   NUMBER
                         )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_segment1                  VARCHAR2(40);     
        l_org_code                  VARCHAR2(10);
        l_description               VARCHAR2(240);
        l_subinv_code               VARCHAR2(10);        

        l_comments                VARCHAR2(200);
        l_status                  VARCHAR2(20);
        l_error_message           VARCHAR2(200);
      
        l_err_cnt                 NUMBER;
        l_stg_cnt                 NUMBER:= 0;
        l_item_cnt                NUMBER:= 0;
        l_cnt_err_format          NUMBER:= 0;
        l_sql                     VARCHAR2(32767);
      
        l_org_id                  NUMBER:=0;
        l_inventory_item_id       NUMBER:=0;
        l_sub_inv_code            VARCHAR2(10);
      
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 4 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code          := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_segment1          := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_description       := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_subinv_code       := TRIM (v_tab (4));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
              --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := null;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_segment1;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Invalid item code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              --/*   
                  --validasi subinventory                  
                                              
                  BEGIN
                  
                      l_sub_inv_code := null;
                  
                      select secondary_inventory_name
                      into l_sub_inv_code                     
                      from mtl_secondary_inventories 
                      where 1=1
                        and organization_id                     = l_org_id
                        and upper(secondary_inventory_name)     = upper(l_subinv_code);
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Invalid sub_inventory_code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;                      
               
                                                  
                  --validasi item and subinventory_code
                  BEGIN
                  
                       l_item_cnt := 0;
                                              
                       select count(*)
                       into l_item_cnt
                       from mtl_item_sub_inventories 
                       where 1=1
                          and organization_id               = l_org_id
                          and inventory_item_id             = l_inventory_item_id
                          and upper(secondary_inventory)    = upper(l_subinv_code);
                            
                       if l_item_cnt > 0 then
                       
                            l_error_message := l_error_message || 'item_code in subinventory : '||l_subinv_code||' already exist, ';
                            l_err_cnt       := l_err_cnt + 1;
                       
                       end if;
                        
                  END;                          
                                
              --*/
                 
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_assign_itemtosubinv_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            segment1                        ,
                            description                     ,
                            subinv_code                     ,       
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_segment1
                     || ''','''
                     || l_description
                     || ''','''
                     || l_subinv_code   
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation2(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_assign_itemtosubinv_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data2(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_data2;      
   
   PROCEDURE insert_upd_epm (
                                errbuf      OUT VARCHAR2, 
                                retcode     OUT NUMBER, 
                                p_file_id   NUMBER
                            )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_segment1                  VARCHAR2(40);     
        l_org_code                  VARCHAR2(10);
        l_description               VARCHAR2(240);
        l_attribute16               VARCHAR2(20);        
        l_attribute17               VARCHAR2(20);        
        l_attribute18               VARCHAR2(20);        
        l_attribute19               VARCHAR2(35);        

        l_comments                VARCHAR2(200);
        l_status                  VARCHAR2(20);
        l_error_message           VARCHAR2(200);
      
        l_err_cnt                 NUMBER;
        l_stg_cnt                 NUMBER:= 0;
        l_item_cnt                NUMBER:= 0;
        l_cnt_err_format          NUMBER:= 0;
        l_sql                     VARCHAR2(32767);
      
        l_org_id                  NUMBER:=0;
        l_inventory_item_id       NUMBER:=0;
        l_sub_inv_code            VARCHAR2(10);
      
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 7 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code          := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_segment1          := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_description       := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_attribute16       := TRIM (v_tab (4));
                     ELSIF i = 5 THEN
                        l_attribute17       := TRIM (v_tab (5));
                     ELSIF i = 6 THEN
                        l_attribute18       := TRIM (v_tab (6));
                     ELSIF i = 7 THEN
                        l_attribute19       := TRIM (v_tab (7));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
              --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := null;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_segment1;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Invalid item code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                                   
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_upd_items_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            segment1                        ,
                            description                     ,
                            attribute16                     ,       
                            attribute17                     ,       
                            attribute18                     ,       
                            attribute19                     ,       
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_segment1
                     || ''','''
                     || l_description
                     || ''','''
                     || l_attribute16   
                     || ''','''
                     || l_attribute17   
                     || ''','''
                     || l_attribute18   
                     || ''','''
                     || l_attribute19   
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation_upd_epm(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_upd_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data_upd_epm(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_upd_epm;

   PROCEDURE insert_upd_ppsize (
                                  errbuf      OUT VARCHAR2, 
                                  retcode     OUT NUMBER, 
                                  p_file_id   NUMBER
                               )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_segment1                  VARCHAR2(40);     
        l_org_code                  VARCHAR2(10);
        l_description               VARCHAR2(240);
        l_attribute20               VARCHAR2(20);        
        l_attribute21               VARCHAR2(20);        

        l_comments                VARCHAR2(200);
        l_status                  VARCHAR2(20);
        l_error_message           VARCHAR2(200);
      
        l_err_cnt                 NUMBER;
        l_stg_cnt                 NUMBER:= 0;
        l_item_cnt                NUMBER:= 0;
        l_cnt_err_format          NUMBER:= 0;
        l_sql                     VARCHAR2(32767);
      
        l_org_id                  NUMBER:=0;
        l_inventory_item_id       NUMBER:=0;
        l_sub_inv_code            VARCHAR2(10);
      
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 5 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code          := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_segment1          := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_description       := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_attribute20       := TRIM (v_tab (4));
                     ELSIF i = 5 THEN
                        l_attribute21       := TRIM (v_tab (5));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
              --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := null;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_segment1;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Invalid item code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                                   
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_upd_items_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            segment1                        ,
                            description                     ,
                            attribute20                     ,       
                            attribute21                     ,       
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_segment1
                     || ''','''
                     || l_description
                     || ''','''
                     || l_attribute20   
                     || ''','''
                     || l_attribute21   
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation_upd_ppsize(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_upd_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data_upd_ppsize(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_upd_ppsize;
   
   PROCEDURE insert_upd_dataPOSM (
                                  errbuf      OUT VARCHAR2, 
                                  retcode     OUT NUMBER, 
                                  p_file_id   NUMBER
                                )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_org_code                  VARCHAR2(10);
        l_item_code                 VARCHAR2(40);                                                
        l_posm_lob                  VARCHAR2(10);  
        
        l_comments                  VARCHAR2(200);
        l_status                    VARCHAR2(20);        
        l_error_message             VARCHAR2(200);
      
        l_err_cnt                   NUMBER;
        l_stg_cnt                   NUMBER:= 0;
        l_item_cnt                  NUMBER:= 0;
        l_cnt_err_format            NUMBER:= 0;
        l_sql                       VARCHAR2(32767);
      
        l_org_id                    NUMBER:=0;
        l_inventory_item_id         NUMBER:=0;
        l_sub_inv_code              VARCHAR2(10);
        l_status_code               VARCHAR2(20);        
      
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 3 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code              := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_item_code             := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_posm_lob              := TRIM (v_tab (3));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
                  --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := null;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_item_code;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Item code : '||l_item_code||' no exist in Organization : '||l_org_code||', ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
                                   
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status 
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_upd4_items_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            item_code                       ,
                            attribute22                     ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_item_code
                     || ''','''
                     || l_posm_lob 
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation_upd_dataPOSM(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_upd4_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data_upd_dataPOSM(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_upd_dataPOSM;     
      
   PROCEDURE insert_upd_dataTMB (
                                  errbuf      OUT VARCHAR2, 
                                  retcode     OUT NUMBER, 
                                  p_file_id   NUMBER
                                )
                         
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_org_code                  VARCHAR2(10);
        l_item_code                 VARCHAR2(40);                                                
        l_purchased                 VARCHAR2(1);
        l_purchasable               VARCHAR2(1);
        l_use_asl                   VARCHAR2(1);  
        l_list_price                NUMBER;
        l_make_or_buy               NUMBER;
        l_prepro_lead_time          NUMBER;
        l_pro_lead_time             NUMBER;
        l_postpro_lead_time         NUMBER;
        l_default_lot_status_id     NUMBER; 
        l_need_COA                  VARCHAR2(10);  
        l_pallet_size               NUMBER;
        l_packing_size              NUMBER;
        
        l_comments                  VARCHAR2(200);
        l_status                    VARCHAR2(20);        
        l_error_message             VARCHAR2(200);
      
        l_err_cnt                   NUMBER;
        l_stg_cnt                   NUMBER:= 0;
        l_item_cnt                  NUMBER:= 0;
        l_cnt_err_format            NUMBER:= 0;
        l_sql                       VARCHAR2(32767);
      
        l_org_id                    NUMBER:=0;
        l_inventory_item_id         NUMBER:=0;
        l_sub_inv_code              VARCHAR2(10);
        l_status_code               VARCHAR2(20);        
      
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 14 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code              := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_item_code             := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_purchased             := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_purchasable           := TRIM (v_tab (4));
                     ELSIF i = 5 THEN
                        l_use_asl               := TRIM (v_tab (5));
                     ELSIF i = 6 THEN
                        l_list_price            := TRIM (v_tab (6));
                     ELSIF i = 7 THEN
                        l_make_or_buy           := TRIM (v_tab (7));
                     ELSIF i = 8 THEN
                        l_prepro_lead_time      := TRIM (v_tab (8));
                     ELSIF i = 9 THEN
                        l_pro_lead_time         := TRIM (v_tab (9));
                     ELSIF i = 10 THEN
                        l_postpro_lead_time     := TRIM (v_tab (10));
                     ELSIF i = 11 THEN
                        l_default_lot_status_id := TRIM (v_tab (11));
                     ELSIF i = 12 THEN
                        l_need_COA              := TRIM (v_tab (12));
                     ELSIF i = 13 THEN
                        l_packing_size          := TRIM (v_tab (13));
                     ELSIF i = 14 THEN
                        l_pallet_size           := TRIM (v_tab (14));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
                  --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := null;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_item_code;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Item code : '||l_item_code||' no exist in Organization : '||l_org_code||', ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    

                  --validasi lot status                   
                                              
                  BEGIN
                  
                      l_status_code := null;
                  
                      select status_code
                      into l_status_code                      
                      from mtl_material_statuses mms
                      where 1=1
                        and status_id   = l_default_lot_status_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||'Invalid default_lot_status_id, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    

                  
                                   
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status 
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_upd2_items_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            item_code                       ,
                            purchasing_item_flag            ,
                            purchasing_enabled_flag         ,
                            must_use_approved_vendor_flag   ,
                            planning_make_buy_code          ,
                            list_price_per_unit             ,
                            preprocessing_lead_time         ,
                            full_lead_time                  ,
                            postprocessing_lead_time        ,
                            default_lot_status_id           ,
                            attribute20                     ,
                            attribute21                     ,
                            attribute13                     ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_item_code
                     || ''','''
                     || l_purchased
                     || ''','''
                     || l_purchasable   
                     || ''','''
                     || l_use_asl   
                     || ''','''
                     || l_make_or_buy   
                     || ''','''
                     || l_list_price   
                     || ''','''
                     || l_prepro_lead_time   
                     || ''','''
                     || l_pro_lead_time   
                     || ''','''
                     || l_postpro_lead_time   
                     || ''','''
                     || l_default_lot_status_id   
                     || ''','''
                     || l_pallet_size 
                     || ''','''
                     || l_packing_size
                     || ''','''
                     || l_need_coa                                          
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation_upd_dataTMB(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_upd2_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data_upd_dataTMB(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_upd_dataTMB;   
               
   procedure insert_upd_itemcat(
                                  errbuf      OUT VARCHAR2, 
                                  retcode     OUT NUMBER,
                                  p_file_id   NUMBER
                               )
   IS
        v_filename                  VARCHAR2 (50);
        v_plan_name                 VARCHAR2 (50);
        v_blob_data                 BLOB;
        v_blob_len                  NUMBER;
        v_position                  NUMBER;
        v_loop                      NUMBER;
        v_raw_chunk                 RAW (10000);
        c_chunk_len                 NUMBER:= 1;
        v_char                      CHAR(1);
        v_line                      VARCHAR2(32767):= NULL;
        v_tab                       VARCHAR2_TABLE;
        v_tablen                    NUMBER;
        x                           NUMBER;
        l_err                       NUMBER:= 0;
      
        l_org_code                  VARCHAR2(10);
        l_item_code                 VARCHAR2(20);     
        l_category_set_name         VARCHAR2(30);     
                                                   
        l_new_segment1              VARCHAR2(50);
        l_new_segment2              VARCHAR2(50);
        l_new_segment3              VARCHAR2(50);
        l_new_segment4              VARCHAR2(50);
        l_new_segment5              VARCHAR2(50);
        l_new_segment6              VARCHAR2(50);

        l_old_segment1              VARCHAR2(50);
        l_old_segment2              VARCHAR2(50);
        l_old_segment3              VARCHAR2(50);
        l_old_segment4              VARCHAR2(50);
        l_old_segment5              VARCHAR2(50);
        l_old_segment6              VARCHAR2(50);
        
        l_comments                  VARCHAR2(200);
        l_status                    VARCHAR2(20);        
        l_error_message             VARCHAR2(200);
      
        l_err_cnt                   NUMBER;
        l_stg_cnt                   NUMBER:= 0;
        l_item_cnt                  NUMBER:= 0;
        l_cnt_err_format            NUMBER:= 0;
        l_sql                       VARCHAR2(32767);
      
        l_org_id                    NUMBER:=0;
        l_inventory_item_id         NUMBER:=0;
        l_sub_inv_code              VARCHAR2(10);
        l_status_code               VARCHAR2(20);       
        
        l_category_set_id           NUMBER;
        l_new_category_id           NUMBER; 
        l_old_category_id           NUMBER;
                  
   BEGIN
   
      BEGIN
      
         SELECT file_data, file_name
         INTO v_blob_data, v_filename
         FROM fnd_lobs
         WHERE 1=1
            AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;
      
      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len) LOOP
      
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10) THEN         
            IF v_position <> v_blob_len THEN              
               v_line := REPLACE (REPLACE (SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1), CHR (13), ''), CHR (10), '');               
            END IF;

            --DBMS_OUTPUT.put_line ('v_line: ' || v_line);

            delimstring_to_table (v_line, v_tab, x, v_tablen);
            
--            logf ('x : ' || x);
            IF x = 15 THEN
               
               IF v_loop >= 2 THEN
               
                  FOR i IN 1 .. x  LOOP

                     IF i = 1 THEN                     
                        l_org_code              := TRIM (v_tab (1));
                     ELSIF i = 2 THEN
                        l_item_code             := TRIM (v_tab (2));                                                
                     ELSIF i = 3 THEN
                        l_category_set_name     := TRIM (v_tab (3));
                     ELSIF i = 4 THEN
                        l_old_segment1          := TRIM (v_tab (4));
                     ELSIF i = 5 THEN
                        l_old_segment2          := TRIM (v_tab (5));
                     ELSIF i = 6 THEN
                        l_old_segment3          := TRIM (v_tab (6));
                     ELSIF i = 7 THEN
                        l_old_segment4          := TRIM (v_tab (7));
                     ELSIF i = 8 THEN
                        l_old_segment5          := TRIM (v_tab (8));
                     ELSIF i = 9 THEN
                        l_old_segment6          := TRIM (v_tab (9));
                     ELSIF i = 10 THEN
                        l_new_segment1          := TRIM (v_tab (10));
                     ELSIF i = 11 THEN
                        l_new_segment2          := TRIM (v_tab (11));
                     ELSIF i = 12 THEN
                        l_new_segment3          := TRIM (v_tab (12));
                     ELSIF i = 13 THEN
                        l_new_segment4          := TRIM (v_tab (13));
                     ELSIF i = 14 THEN
                        l_new_segment5          := TRIM (v_tab (14));
                     ELSIF i = 15 THEN
                        l_new_segment6          := TRIM (v_tab (15));
                     END IF;
                     
                  END LOOP;
                                     

                  l_err_cnt         := 0;
                  l_error_message   := null;
               
                  
                  --validasi org_code
                  BEGIN
                  
                      l_org_id := null;
                  
                      select mp.organization_id
                      into l_org_id                     
                      from mtl_parameters mp
                      where 1=1
                        and mp.organization_code = l_org_code
                      group by mp.organization_id;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := 'Invalid organization code, ';
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
              
                  --/*   
                  --validasi item                  
                                              
                  BEGIN
                  
                      l_inventory_item_id := NULL;
                  
                      select msi.inventory_item_id
                      into l_inventory_item_id                     
                      from mtl_system_items msi
                      where 1=1
                        and msi.organization_id = l_org_id
                        and msi.segment1        = l_item_code;
                      
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||', Item code : '||l_item_code||' no exist in Organization : '||l_org_code;
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    

                                              
                  BEGIN
                        l_category_set_id := NULL;
                  
                        SELECT mcs_tl.category_set_id
                        INTO l_category_set_id
                        FROM mtl_category_sets_tl mcs_tl
                        WHERE mcs_tl.category_set_name = l_category_set_name;
                                                 
                  EXCEPTION
                     WHEN OTHERS THEN
                        l_error_message := l_error_message||', Invalid category_set_name : '||l_category_set_name;
                        l_err_cnt       := l_err_cnt + 1;
                        
                  END;    
                  
                  
                  IF l_category_set_id IS NOT NULL
                  THEN

                          BEGIN
                          
                               SELECT mcb.category_id
                                 INTO l_old_category_id
                               FROM mtl_categories_b mcb
                               WHERE 1=1 
                                  AND NVL(mcb.segment1,'ABP')          = l_old_segment1
                                  AND NVL(mcb.segment2,'ABP')          = l_old_segment2
                                  AND NVL(mcb.segment3,'ABP')          = l_old_segment3
                                  AND NVL(mcb.segment4,'ABP')          = l_old_segment4
                                  AND NVL(mcb.segment5,l_old_segment5) = l_old_segment5
                                  AND NVL(mcb.segment6,l_old_segment6) = l_old_segment6
                                  AND mcb.structure_id = (SELECT mcs.structure_id
                                                            FROM mtl_category_sets_b mcs
                                                           WHERE mcs.category_set_id = l_category_set_id);                                                                                                             
                          EXCEPTION
                             WHEN OTHERS THEN
                                l_error_message := l_error_message||', Invalid old category_name';
                                l_err_cnt       := l_err_cnt + 1;
                                
                          END;    

                          BEGIN
                          
                               SELECT mcb.category_id
                                 INTO l_new_category_id
                               FROM mtl_categories_b mcb
                               WHERE 1=1 
                                  AND NVL(mcb.segment1,'ABP')          = l_new_segment1
                                  AND NVL(mcb.segment2,'ABP')          = l_new_segment2
                                  AND NVL(mcb.segment3,'ABP')          = l_new_segment3
                                  AND NVL(mcb.segment4,'ABP')          = l_new_segment4
                                  AND NVL(mcb.segment5,l_new_segment5) = l_new_segment5
                                  AND NVL(mcb.segment6,l_new_segment6) = l_new_segment6
                                  AND mcb.structure_id = (SELECT mcs.structure_id
                                                            FROM mtl_category_sets_b mcs
                                                           WHERE mcs.category_set_id = l_category_set_id);                                                                                                           
                          EXCEPTION
                             WHEN OTHERS THEN
                                l_error_message := l_error_message||', Invalid new category_name';
                                l_err_cnt       := l_err_cnt + 1;
                                
                          END;
                  
                  END IF;  

                  
                                   
                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                  INTO l_status 
                  FROM DUAL;

                  --insert to staging
                  
                  l_sql :=
                        'insert into xxshp_inv_upd3_items_stg(
                            file_id                         ,
                            file_name                       ,
                            org_code                        ,
                            item_code                       ,
                            category_set_name               ,
                            old_segment1                    ,
                            old_segment2                    ,
                            old_segment3                    ,
                            old_segment4                    ,
                            old_segment5                    ,
                            old_segment6                    ,
                            new_segment1                    ,
                            new_segment2                    ,
                            new_segment3                    ,
                            new_segment4                    ,
                            new_segment5                    ,
                            new_segment6                    ,
                            status                          ,
                            error_message                   ,
                            created_by                      ,
                            last_updated_by                 ,
                            creation_date                   ,
                            last_update_date                ,
                            last_update_login  ) 
                         VALUES('
                     || p_file_id
                     || ','''
                     || v_filename
                     || ''','''
                     || l_org_code
                     || ''','''
                     || l_item_code
                     || ''','''
                     || l_category_set_name
                     || ''','''
                     || l_old_segment1   
                     || ''','''
                     || l_old_segment2   
                     || ''','''
                     || l_old_segment3   
                     || ''','''
                     || l_old_segment4   
                     || ''','''
                     || l_old_segment5   
                     || ''','''
                     || l_old_segment6   
                     || ''','''
                     || l_new_segment1   
                     || ''','''
                     || l_new_segment2   
                     || ''','''
                     || l_new_segment3 
                     || ''','''
                     || l_new_segment4
                     || ''','''
                     || l_new_segment5                                          
                     || ''','''
                     || l_new_segment6                                          
                     || ''','''
                     || l_status
                     || ''','''
                     || l_error_message
                     || ''','
                     || g_user_id
                     || ','
                     || g_user_id
                     || ', SYSDATE'
                     || ', SYSDATE,'
                     || g_login_id
                     || ')';

--                  logf ('l_sql : ' || l_sql);
                  BEGIN
                     EXECUTE IMMEDIATE l_sql;
--                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        logf (SQLERRM);
                        DBMS_OUTPUT.put_line (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

--               logf ('Row: ' || v_loop || ' can be read');
--               DBMS_OUTPUT.put_line ('Row: ' || v_loop || ' can be read');
               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len THEN
                  logf ('Upload File Finished');
               ELSE
                  logf ('Wrong file,please check the comma delimiter has ' || x || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);
      DBMS_OUTPUT.put_line ('v_err : ' || l_err);

      IF l_err > 0 THEN
         ROLLBACK;
         logf ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' has 0 rows inserting to staging table, ROLLBACK');
         
         retcode := 2;
      ELSE
         COMMIT;
         logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan
         
         final_validation_upd_itemcat(p_file_id);         
     --/*
         select count(1)                       
         into l_stg_cnt
         from xxshp_inv_upd3_items_stg
         where 1=1
            and nvl(status,'N')  = 'N' 
            and file_id = p_file_id;
                           
         if nvl(l_stg_cnt,0) > 0 then
         
            process_data_upd_itemcat(p_file_id);
         
         end if;

         update fnd_lobs
         set expiration_date = sysdate,
             upload_date = sysdate
         where 1=1
            and file_id = p_file_id;
    --*/
            
      END IF;

      --print_result(p_file_id);
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         logf ('error no data found');
         ROLLBACK;
      WHEN OTHERS THEN
         logf ('Error others : ' || SQLERRM);
         logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
         logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
   END insert_upd_itemcat;   
                                  
END XXSHP_INV_ITEMS_API_PKG;
/
