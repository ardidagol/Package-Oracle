CREATE OR REPLACE PACKAGE APPS.XXSHP_INV_ITEMS_API_PKG
IS

/*
REM +=========================================================================================================+
REM |                                    Copyright (C) 2017  KNITERS                                          |
REM |                                        All rights Reserved                                              |
REM +=========================================================================================================+
REM |                                                                                                         |
REM |     Program Name: XXSHP_INV_ITEMS_API_PKG.pks                                                           |
REM |     Parameters  :                                                                                       |
REM |     Description :                                                                                       |
REM |     History     : 26 Jul 2017       Agus Budi Pramono  Created Initial Coding                           |
REM |     Proposed    : API Upload Item Master for Indirect Items                                             |
REM |     Updated     : 27 Jul 2017 - Penambahan 3 field for EAM Items                                        |
REM |                   16 Aug 2017 - Penambahan 2 field for EPM Item and qty conversion Mapping              |
REM |                   18 Aug 2017 - Penambahan concurent untuk update EPM Item and qty conversion Mapping   |
REM |                   21 Aug 2017 - Penambahan concurent untuk update Pallet size dan Packing size          |
REM |                   13 Aug 2018 - Penambahan concurent untuk update Item Master                           |                  
REM |                                 project KN-GVN Integration                                              |
REM |                   01 Oct 2018 - Penambahan concurent untuk update Item Categories                       |                  
REM |                   05 Apr 2019 - Penambahan concurent untuk update Item Indirect : POSM LOB              |                  
REM +---------------------------------------------------------------------------------------------------------+
*/
           
   g_max_time            PLS_INTEGER      DEFAULT 3600; 
   g_intval_time         PLS_INTEGER      DEFAULT 5;   
   
   g_user_id             NUMBER := fnd_global.user_id;
   g_resp_id             NUMBER := fnd_global.resp_id;
   g_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
   g_request_id          NUMBER := fnd_global.conc_request_id;
   g_login_id            NUMBER := fnd_global.login_id;   
       
   
   TYPE VARCHAR2_TABLE IS TABLE OF VARCHAR2 (32767)
   INDEX BY BINARY_INTEGER;
  
    cursor c_item_inv_stg(p_file_id NUMBER)
    is
    
         select 
            org_code,
            segment1,
            description,
            subinv_code
        from xxshp_assign_itemtosubinv_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
            org_code,
            segment1,
            description,
            subinv_code;            


    cursor c_upd_item_inv_stg(p_file_id NUMBER)
    is
    
         select 
            org_code,
            segment1,
            description,
            attribute16, -- EPM Item code Mapping
            attribute17, -- EPM Qty Conversion Mapping
            attribute18, -- EPM Qty Alih satuan
            attribute19  -- EPM Item Description
        from xxshp_inv_upd_items_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
            org_code,
            segment1,
            description,
            attribute16,
            attribute17,
            attribute18,
            attribute19;
 
    cursor c_upd_item_inv_stg2(p_file_id NUMBER) -- updated packing size dan pallet size
    is
    
         select 
            org_code,
            segment1,
            description,
            attribute20,--Pallet Size
            attribute21 --Packing Size
        from xxshp_inv_upd_items_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
            org_code,
            segment1,
            description,
            attribute20,
            attribute21;

    -- ++ ada ABP : 20180813
    -- updated for Project KN-GVN Integration
    cursor c_upd2_item_inv_stg(p_file_id NUMBER) 
    is
    
         select 
              org_code
            , item_code
            , purchasing_item_flag          
            , purchasing_enabled_flag       
            , must_use_approved_vendor_flag 
            , planning_make_buy_code        
            , list_price_per_unit 
            , preprocessing_lead_time       
            , full_lead_time                
            , postprocessing_lead_time      
            , default_lot_status_id           
            , attribute20 --Pallet Size
            , attribute21 --Packing Size
            , attribute13 --need_coa 
        from xxshp_inv_upd2_items_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
              org_code
            , item_code
            , purchasing_item_flag          
            , purchasing_enabled_flag       
            , must_use_approved_vendor_flag 
            , planning_make_buy_code        
            , list_price_per_unit 
            , preprocessing_lead_time       
            , full_lead_time                
            , postprocessing_lead_time      
            , default_lot_status_id           
            , attribute20
            , attribute21
            , attribute13;
    -- ++ ada ABP : 20180813

    -- ++ ada ABP : 20181001
    -- updated for Project KN-GVN Integration
    cursor c_upd3_item_inv_stg(p_file_id NUMBER) 
    is
    
         select 
              org_code
            , item_code
            , category_set_name               
            , old_segment1                   
            , old_segment2                    
            , old_segment3                    
            , old_segment4                    
            , old_segment5                    
            , old_segment6                    
            , new_segment1                    
            , new_segment2                    
            , new_segment3                    
            , new_segment4                    
            , new_segment5                    
            , new_segment6                    
        from xxshp_inv_upd3_items_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
              org_code
            , item_code
            , category_set_name               
            , old_segment1                   
            , old_segment2                    
            , old_segment3                    
            , old_segment4                    
            , old_segment5                    
            , old_segment6                    
            , new_segment1                    
            , new_segment2                    
            , new_segment3                    
            , new_segment4                    
            , new_segment5                    
            , new_segment6;
                                
    -- ++ ada ABP : 20181001
    
    -- ++ ada ABP : 2019-04-05
    -- updated for Project Revamp BIP : Mapping LOB untuk item POSM (POSM LOB (attribute22))
    cursor c_upd_item_posm(p_file_id NUMBER) 
    is
         select 
              org_code
            , item_code
            , attribute22 -- POSM LOB
        from xxshp_inv_upd4_items_stg 
        where 1=1                
            and nvl(flag,'Y')   = 'Y'            
            and file_id         = p_file_id
        group by
              org_code
            , item_code
            , attribute22;            
   -- ++ ada ABP : 2019-04-05                

    cursor c_items_stg(p_file_id NUMBER)
    is
    
        select 
            msi.segment1,
            msi.description,
            msi.long_description,
            --msi.organization_id,
            msi.organization_code,
            msi.primary_uom_code,
            msi.secondary_uom_code,
            msi.auto_lot_alpha_prefix,  --lot prefix
            msi.start_auto_lot_number,  --lot_starting_number
            msi.template_name,
            decode(msi.expense_account    ,'',null, 0, null,msi.expense_account) expense_account,
            decode(msi.encumbrance_account,'',null, 0, null,msi.encumbrance_account) encumbrance_account,
            --msi.expense_account,
            --msi.encumbrance_account,
            msi.list_price_per_unit,
            msi.preprocessing_lead_time,
            msi.full_lead_time,
            msi.postprocessing_lead_time,
            msi.minimum_order_quantity,
            msi.maximum_order_quantity,
            msi.min_minmax_quantity,
            msi.max_minmax_quantity,
            msi.fixed_lot_multiplier,
            --msi.fixed_order_quantity,
            decode(msi.fixed_order_quantity,0,null,msi.fixed_order_quantity) fixed_order_quantity,
            msi.weight_uom_code,
            msi.unit_weight,
            msi.attribute6, --Kode item trial
            msi.attribute9, --Cost Allocation
            msi.attribute13,--Need CoA
            msi.attribute8, --Reference Item FG
            msi.attribute20,--Pallet Size
            msi.attribute11,--Parent Item Pecah KN
            msi.attribute21,--Packing Size
            msi.attribute3, --LT Release
            msi.attribute1, --General Item
            msi.attribute2, --Item Template
            msi.attribute4, --
            msi.attribute10, --
            msi.attribute7, --
            msi.attribute12, --
            msi.volume_uom_code,
            --msi.unit_volume,           
            decode(msi.unit_volume,0,null,msi.unit_volume) unit_volume,  
            msi.attribute_category,
            msi.restrict_subinventories_code,
            msi.planner_code,
            decode(msi.sales_account_code,'',null,msi.sales_account_code) sales_account_code,            
            msi.attribute14, --- Alias 
            msi.attribute5,  --- Buffer packaging 
            msi.attribute25,  --- old item code Indirect
            decode(msi.expense_account_code,'',null,msi.expense_account_code) expense_account_code,            
            msi.serial_number_control_code, 
            msi.auto_serial_alpha_prefix,  
            msi.start_auto_serial_number,                                       
            msi.attribute16, -- mapping EPM item
            msi.attribute17, -- EPM qty conversion
            msi.attribute18, -- EPM Qty Alih satuan            
            msi.attribute19  -- EPM Item Description       
        from xxshp_inv_items_stg msi
        where 1=1
            and nvl(flag,'Y')   = 'Y'                        
            and file_id         = p_file_id;
                                                          
   procedure insert_upd_itemcat(
                                  errbuf      OUT VARCHAR2, 
                                  retcode     OUT NUMBER,
                                  p_file_id   NUMBER
                               );

   procedure insert_upd_dataPOSM(
                                   errbuf      OUT VARCHAR2, 
                                   retcode     OUT NUMBER,
                                   p_file_id   NUMBER
                                );

   procedure insert_upd_dataTMB(
                                 errbuf      OUT VARCHAR2, 
                                 retcode     OUT NUMBER,
                                 p_file_id   NUMBER
                               );

   procedure insert_upd_ppsize(
                                 errbuf      OUT VARCHAR2, 
                                 retcode     OUT NUMBER,
                                 p_file_id   NUMBER
                              );
   procedure insert_upd_epm(
                                errbuf      OUT VARCHAR2, 
                                retcode     OUT NUMBER,
                                p_file_id   NUMBER
                           );

   procedure insert_data2(
                             errbuf      OUT VARCHAR2, 
                             retcode     OUT NUMBER,
                             p_file_id   NUMBER
                         );

   procedure insert_data(
                            errbuf      OUT VARCHAR2, 
                            retcode     OUT NUMBER,
                            p_file_id   NUMBER
                        );
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
END XXSHP_INV_ITEMS_API_PKG;
/
