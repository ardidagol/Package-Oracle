CREATE OR REPLACE PACKAGE BODY      XXKHD_PO_SERV_PK AS

------------------------------------------------------------------------------------------------
    PROCEDURE logF(v_char VARCHAR2) IS
    BEGIN
      Fnd_File.put_line(Fnd_File.LOG, v_char);
    END;
 
------------------------------------------------------------------------------------------------
 PROCEDURE outF (p_message   IN   VARCHAR2) IS 
 BEGIN
     Fnd_File.PUT_LINE(Fnd_File.OUTPUT ,p_message);
 END;
 
------------------------------------------------------------------------------------------------
    PROCEDURE print_output(p_batch_id PLS_INTEGER) IS

    i   PLS_INTEGER DEFAULT 0;
 j   PLS_INTEGER;
  
    CURSOR batch_cur IS    
  SELECT  BATCH.batch_id,
    BATCH.batch_status,
    BATCH.start_date,
       BATCH.end_date,
    BATCH.iface_header_count,
    BATCH.iface_line_count,
    BATCH.iface_dist_count,
    BATCH.success_header_count,
    BATCH.success_line_count,
    BATCH.success_dist_count,
       BATCH.import_request_id,
    BATCH.iface_request_id,
    BATCH.std_rpt_request_id,
       BATCH.message
  FROM XXKHD_PO_BATCH batch
  WHERE   BATCH.batch_id = p_batch_id;
      
    CURSOR hdr_cur IS  
  SELECT  hdr.interface_header_id,
    hdr.interface_source_code,
    hdr.vendor_name,
    hdr.vendor_site_code,
    hdr.bill_to_location,
    hdr.agent_name,
    hdr.currency_code,
    hdr.attribute1              receipt_num,
    hdr.attribute2          shipment_num,
    hdr.message,
    NVL(hdr.po_number, hdr.message)   po_number,
    hdr.po_header_id
  FROM    XXKHD_PO_HDR hdr
  WHERE   HDR.batch_id  = p_batch_id
  ORDER BY hdr.po_number DESC, hdr.interface_header_id;
      
    CURSOR dtl_cur(p_interface_header_id PLS_INTEGER) IS 
  SELECT  LINE.interface_line_id,
    LINE.item_code,
    LINE.unit_of_measure,
    LINE.quantity,
    LINE.unit_price,
    LINE.promised_date,
    LINE.ship_to_location,
    LINE.ship_to_organization_code,
    LINE.line_attribute1        line_item_code_receipt,
    LINE.line_attribute2     line_qty_receipt,
    LINE.line_attribute5     inventory_item_id,
    LINE.message,
    LINE.po_line_id,
    LINE.line_location_id,
    DIST.interface_distribution_id,
    DIST.charge_account_segment1||'.'||
    DIST.charge_account_segment2||'.'||
    DIST.charge_account_segment3||'.'||
    DIST.charge_account_segment4||'.'||
    DIST.charge_account_segment5||'.'||
    DIST.charge_account_segment6||'.'||
    DIST.charge_account_segment7            acc, 
    DIST.message           dist_message,
    DIST.po_distribution_id,
    DIST.ccid    
  FROM    XXKHD_PO_LINE line,
    XXKHD_PO_DIST  dist
  WHERE   LINE.interface_header_id  = p_interface_header_id
  AND  LINE.interface_line_id    = DIST.interface_line_id
  ORDER BY LINE.interface_line_id;
  
    BEGIN
      outF('/* START */'); 
   
   outF(' '); outF(' '); 
   FOR hdr IN batch_cur LOOP
     outF ('BATCH DATA');
--     outF ('-------------------------------------------------------------------------------------------------------------------------------------------------');
     outF ('                                                 INTERFACE         SUCCESS                   REQUEST                        ');
     outF ('-------------------------------------------------------------------------------------------------------------------------------------------------');
     outF ('BATCH ID  STATUS       START      END        HDR   DTL   DIST  HDR   DTL   DIST  REQUEST ID      IMPORT   EXCEPTION  MESSAGE');    
     outF ('--------  -----------  ---------  ---------  ----  ----- ----  ----  ----  ----  ----------  ----------  ----------  ----------------------------');
     
     outF (LPAD(HDR.batch_id,             8,' ')||'  ' ||
         RPAD(HDR.batch_status,      11,' ')||'  ' ||
         RPAD(HDR.start_date,        9,' ')||'  ' ||        
         RPAD(HDR.end_date,       9,' ')||'  ' ||  
         LPAD(HDR.iface_header_count,   4,' ')||'  ' ||
         LPAD(HDR.iface_line_count,   4,' ')||'  ' ||
         LPAD(HDR.iface_dist_count,   4,' ')||'  ' ||                
         LPAD(HDR.success_header_count, 4,' ')||'  ' ||
         LPAD(HDR.success_line_count,   4,' ')||'  ' ||
         LPAD(HDR.success_dist_count,   4,' ')||'  ' ||                
         LPAD(HDR.iface_request_id,  10,' ')||'  ' ||  
         LPAD(HDR.import_request_id,   10,' ')||'  ' ||  
         LPAD(HDR.std_rpt_request_id,  10,' ')||'  ' ||
         RPAD(HDR.message,    28,' ')
       );                                        
   END LOOP;   
      
   outF(' '); outF(' ');  outF(' ');
         outF('PURCHASE ORDER');           
   FOR HDR IN hdr_cur LOOP   
           i := i +1;    
     j := 0;    
           outF('------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
           outF('  NO  HEADER ID   SOURCE                      VENDOR                      SITE           RECEIPT        SHIPMENT       PO NUMBER      PO_HEADER_ID  MESSAGE                                                 ');    
           outF('----  ----------  --------------------------  --------------------------  -------------  -------------  -------------  -------------  ------------  --------------------------------------------------------');
     outF (LPAD(i,                                             4,' ')||'  ' ||
         LPAD(HDR.interface_header_id,             10,' ')||'  ' ||
         RPAD(HDR.interface_source_code,              26,' ')||'  ' ||
         RPAD(HDR.vendor_name,                     26,' ')||'  ' || 
         RPAD(HDR.vendor_site_code,             13,' ')||'  ' ||           
         RPAD(HDR.receipt_num,              13,' ')||'  ' ||
         RPAD(HDR.shipment_num,              13,' ')||'  ' ||  
         RPAD(HDR.po_number   ,               13,' ')||'  ' ||
         LPAD(HDR.po_header_id,             12,' ')||'  ' ||    
         RPAD(HDR.message,           56,' ')
       );  
          outF('      '||'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    outF(' ');    
          outF('      '||'  NO  LINE ID  DIST ID  ITEM CODE        UNIT OF MEASURE  QUANTITY         PRICE   NEED BY DATE  ORG  LOCATION      ITEM RECEIPT     ACCOUNT                                ITEM RECEIPT ID             CCID        PO_LINE_ID  LINE_LOCATION_ID        PO_DIST_ID');    
          outF('      '||'----  -------  -------  ---------------  ---------------  --------  ------------  -------------  ---  ------------  ---------------  -------------------------------------  ---------------  ---------------  ----------------  ----------------  ----------------');
      
    FOR DTL IN dtl_cur(HDR.interface_header_id) LOOP

            j := j +1;        
      outF ('      '||
            LPAD(j,                                             4,' ')||'  ' ||
          LPAD(DTL.interface_line_id,              7,' ')||'  ' ||
             LPAD(DTL.interface_distribution_id,           7,' ')||'  ' ||         
          RPAD(DTL.item_code,                   15,' ')||'  ' ||
          RPAD(DTL.unit_of_measure,                 15,' ')||'  ' || 
          LPAD(DTL.quantity,                  8,' ')||'  ' ||           
          LPAD(DTL.unit_price,                 12,' ')||'  ' ||
          RPAD(DTL.promised_date,              13,' ')||'  ' ||  
          RPAD(DTL.ship_to_organization_code,       3,' ')||'  ' ||
          RPAD(DTL.ship_to_location,             12,' ')||'  ' ||
          RPAD(DTL.line_item_code_receipt,       15,' ')||'  ' ||
          LPAD(DTL.acc,             37,' ')||'  ' ||         
          LPAD(DTL.inventory_item_id,            15,' ')||'  ' ||
          LPAD(DTL.ccid,                  15,' ')||'  ' ||         
          LPAD(NVL(DTL.po_line_id, 0),          16,' ')||'  ' ||
          LPAD(DTL.line_location_id,             16,' ')||'  ' ||
          LPAD(DTL.po_distribution_id,          16,' ')
        );  
--      outF(' ');
          
    END LOOP;
    outF(' ');                                                  
   END LOOP;   
             
   outF(' '); outF(' '); outF(' '); 
   outF('/* END */'); 

  END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_XXKHD_PO_BATCH(rec XXKHD_PO_BATCH%ROWTYPE) IS
 BEGIN
  INSERT INTO XXKHD_PO_BATCH (
     batch_id, batch_status, start_date,
     end_date, 
--     iface_header_count, iface_line_count,iface_dist_count, 
--     success_header_count, success_line_count, success_dist_count, 
     org_id, 
--     organization_id,
--     iface_request_id, cust_rpt_request_id, std_rpt_request_id, 
     import_request_id,
     created_by, creation_date, last_updated_by,
     last_update_date, last_update_login, message)
  VALUES (
  REC.batch_id,REC.batch_status,REC.start_date,--
  REC.end_date,
--  REC.iface_header_count,REC.iface_line_count,REC.iface_dist_count,
--  REC.success_header_count,REC.success_line_count,REC.success_dist_count,
  REC.org_id,
--  REC.organization_id,--
--  REC.iface_request_id,REC.cust_rpt_request_id,REC.std_rpt_request_id, 
  REC.import_request_id,--
  REC.created_by,REC.creation_date,REC.last_updated_by,--
  REC.last_update_date,REC.last_update_login,REC.message) ;
    END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_XXKHD_PO_HDR(rec XXKHD_PO_HDR%ROWTYPE) IS
 BEGIN
  INSERT INTO XXKHD_PO_HDR (
     interface_header_id, batch_id, po_status,
     org_id, interface_source_code, revision_num,
     action, vendor_name, vendor_site_code,
     ship_to_location, bill_to_location, agent_name, agent_id,
     currency_code, created_by, creation_date,
     last_updated_by, last_update_date, last_update_login,
     attribute_category, attribute1, attribute2,
     attribute8, attribute9, 
     attribute3, attribute14,   --add info SJ dan no POL, 29-NOV-2012
     message, po_number, po_header_id, 
     shipment_header_id)
  VALUES (
  REC.interface_header_id,REC.batch_id,REC.po_status,--
  REC.org_id,REC.interface_source_code,REC.revision_num,--
  REC.action,REC.vendor_name,REC.vendor_site_code,--
  REC.ship_to_location,REC.bill_to_location,REC.agent_name, REC.agent_id,
  REC.currency_code,REC.created_by,REC.creation_date,--
  REC.last_updated_by,REC.last_update_date,REC.last_update_login,--
  REC.attribute_category,REC.attribute1,REC.attribute2,--
  REC.attribute8,REC.attribute9,--
  REC.attribute3,REC.attribute14,--
  REC.message,REC.po_number,REC.po_header_id, 
  REC.shipment_header_id);
    END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_XXKHD_PO_LINE(rec XXKHD_PO_LINE%ROWTYPE) IS
 BEGIN
       
  INSERT INTO XXKHD_PO_LINE (
     interface_line_id, interface_header_id, batch_id,
     action, item_description, line_type,
     item_id, 
--     category_id, 
     item_code,
--     category, 
     unit_of_measure, quantity,
     unit_price, promised_date, ship_to_location,
     ship_to_organization_code, line_attribute_category_lines, shipment_attribute_category,
     created_by, creation_date, last_updated_by,
     last_update_date, last_update_login, line_attribute1,
     line_attribute2, line_attribute3, line_attribute4,
     line_attribute5, line_attribute6, shipment_attribute1,
     shipment_attribute2, shipment_attribute3, shipment_attribute4,
     shipment_attribute5, shipment_attribute6, message,
--     secondary_unit_of_measure,secondary_quantity,
     shipment_line_id, transaction_id,
     po_line_id, line_location_id)
  VALUES (
  REC.interface_line_id,REC.interface_header_id,REC.batch_id,--
  REC.action,REC.item_description,REC.line_type,--
  REC.item_id, 
--  REC.category_id, 
  REC.item_code,  
--  REC.category,
  REC.unit_of_measure,REC.quantity,--
  REC.unit_price,REC.promised_date,REC.ship_to_location,--
  REC.ship_to_organization_code,REC.line_attribute_category_lines,REC.shipment_attribute_category,--
  REC.created_by,REC.creation_date,REC.last_updated_by,--
  REC.last_update_date,REC.last_update_login,REC.line_attribute1,--
  REC.line_attribute2,REC.line_attribute3,REC.line_attribute4,--
  REC.line_attribute5,REC.line_attribute6,REC.shipment_attribute1,--
  REC.shipment_attribute2,REC.shipment_attribute3,REC.shipment_attribute4,--
  REC.shipment_attribute5,REC.shipment_attribute6,REC.message,--
--  REC.secondary_unit_of_measure, REC.secondary_quantity,  
   REC.shipment_line_id, REC.transaction_id,  
   REC.po_line_id,REC.line_location_id);
    END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_XXKHD_PO_DIST(rec XXKHD_PO_DIST%ROWTYPE) IS
 BEGIN
  INSERT INTO XXKHD_PO_DIST (
     interface_distribution_id, interface_header_id, interface_line_id,
     batch_id, charge_account_segment1, charge_account_segment2,
     charge_account_segment3, charge_account_segment4, charge_account_segment5,
     charge_account_segment6, charge_account_segment7, distribution_num,
     quantity_ordered, attribute_category, created_by,
     creation_date, last_updated_by, last_update_date,
     last_update_login, attribute1, attribute2,
     attribute3, attribute4, attribute5,
     attribute6, message, po_distribution_id,
     ccid)
  VALUES (
  REC.interface_distribution_id,REC.interface_header_id,REC.interface_line_id,--
  REC.batch_id,REC.charge_account_segment1,REC.charge_account_segment2,--
  REC.charge_account_segment3,REC.charge_account_segment4,REC.charge_account_segment5,--
  REC.charge_account_segment6,REC.charge_account_segment7,REC.distribution_num,--
  REC.quantity_ordered,REC.attribute_category,REC.created_by,--
  REC.creation_date,REC.last_updated_by,REC.last_update_date,--
  REC.last_update_login,REC.attribute1,REC.attribute2,--
  REC.attribute3,REC.attribute4,REC.attribute5,--
  REC.attribute6,REC.message,REC.po_distribution_id,--
  REC.ccid) ;
    END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_PO_HDR_iface(rec PO_HEADERS_INTERFACE%ROWTYPE) IS
 BEGIN
  INSERT INTO PO_HEADERS_INTERFACE (
     interface_header_id, batch_id, interface_source_code,
     process_code, action, group_code,
     org_id, document_type_code, document_subtype,
     document_num, po_header_id, release_num,
     po_release_id, release_date, currency_code,
     rate_type, rate_type_code, rate_date,
     rate, agent_name, agent_id,
     vendor_name, vendor_id, vendor_site_code,
     vendor_site_id, vendor_contact, vendor_contact_id,
     ship_to_location, ship_to_location_id, bill_to_location,
     bill_to_location_id, payment_terms, terms_id,
     freight_carrier, fob, freight_terms,
     approval_status, approved_date, revised_date,
     revision_num, note_to_vendor, note_to_receiver,
     confirming_order_flag, comments, acceptance_required_flag,
     acceptance_due_date, amount_agreed, amount_limit,
     min_release_amount, effective_date, expiration_date,
     print_count, printed_date, firm_flag,
     frozen_flag, closed_code, closed_date,
     reply_date, reply_method, rfq_close_date,
     quote_warning_delay, vendor_doc_num, approval_required_flag,
     vendor_list, vendor_list_header_id, from_header_id,
     from_type_lookup_code, ussgl_transaction_code, attribute_category,
     attribute1, attribute2, attribute3,
     attribute4, attribute5, attribute6,
     attribute7, attribute8, attribute9,
     attribute10, attribute11, attribute12,
     attribute13, attribute14, attribute15,
     creation_date, created_by, last_update_date,
     last_updated_by, last_update_login, request_id,
     program_application_id, program_id, program_update_date,
     reference_num, load_sourcing_rules_flag, vendor_num,
     from_rfq_num, wf_group_id, pcard_id,
     pay_on_code, global_agreement_flag, consume_req_demand_flag,
     shipping_control, encumbrance_required_flag, amount_to_encumber,
     change_summary, budget_account_segment1, budget_account_segment2,
     budget_account_segment3, budget_account_segment4, budget_account_segment5,
     budget_account_segment6, budget_account_segment7, budget_account_segment8,
     budget_account_segment9, budget_account_segment10, budget_account_segment11,
     budget_account_segment12, budget_account_segment13, budget_account_segment14,
     budget_account_segment15, budget_account_segment16, budget_account_segment17,
     budget_account_segment18, budget_account_segment19, budget_account_segment20,
     budget_account_segment21, budget_account_segment22, budget_account_segment23,
     budget_account_segment24, budget_account_segment25, budget_account_segment26,
     budget_account_segment27, budget_account_segment28, budget_account_segment29,
     budget_account_segment30, budget_account, budget_account_id,
     gl_encumbered_date, gl_encumbered_period_name)
  VALUES (
  REC.interface_header_id,REC.batch_id,REC.interface_source_code,--
  REC.process_code,REC.action,REC.group_code,--
  REC.org_id,REC.document_type_code,REC.document_subtype,--
  REC.document_num,REC.po_header_id,REC.release_num,--
  REC.po_release_id,REC.release_date,REC.currency_code,--
  REC.rate_type,REC.rate_type_code,REC.rate_date,--
  REC.rate,REC.agent_name,REC.agent_id,--
  REC.vendor_name,REC.vendor_id,REC.vendor_site_code,--
  REC.vendor_site_id,REC.vendor_contact,REC.vendor_contact_id,--
  REC.ship_to_location,REC.ship_to_location_id,REC.bill_to_location,--
  REC.bill_to_location_id,REC.payment_terms,REC.terms_id,--
  REC.freight_carrier,REC.fob,REC.freight_terms,--
  REC.approval_status,REC.approved_date,REC.revised_date,--
  REC.revision_num,REC.note_to_vendor,REC.note_to_receiver,--
  REC.confirming_order_flag,REC.comments,REC.acceptance_required_flag,--
  REC.acceptance_due_date,REC.amount_agreed,REC.amount_limit,--
  REC.min_release_amount,REC.effective_date,REC.expiration_date,--
  REC.print_count,REC.printed_date,REC.firm_flag,--
  REC.frozen_flag,REC.closed_code,REC.closed_date,--
  REC.reply_date,REC.reply_method,REC.rfq_close_date,--
  REC.quote_warning_delay,REC.vendor_doc_num,REC.approval_required_flag,--
  REC.vendor_list,REC.vendor_list_header_id,REC.from_header_id,--
  REC.from_type_lookup_code,REC.ussgl_transaction_code,REC.attribute_category,--
  REC.attribute1,REC.attribute2,REC.attribute3,--
  REC.attribute4,REC.attribute5,REC.attribute6,--
  REC.attribute7,REC.attribute8,REC.attribute9,--
  REC.attribute10,REC.attribute11,REC.attribute12,--
  REC.attribute13,REC.attribute14,REC.attribute15,--
  REC.creation_date,REC.created_by,REC.last_update_date,--
  REC.last_updated_by,REC.last_update_login,REC.request_id,--
  REC.program_application_id,REC.program_id,REC.program_update_date,--
  REC.reference_num,REC.load_sourcing_rules_flag,REC.vendor_num,--
  REC.from_rfq_num,REC.wf_group_id,REC.pcard_id,--
  REC.pay_on_code,REC.global_agreement_flag,REC.consume_req_demand_flag,--
  REC.shipping_control,REC.encumbrance_required_flag,REC.amount_to_encumber,--
  REC.change_summary,REC.budget_account_segment1,REC.budget_account_segment2,--
  REC.budget_account_segment3,REC.budget_account_segment4,REC.budget_account_segment5,--
  REC.budget_account_segment6,REC.budget_account_segment7,REC.budget_account_segment8,--
  REC.budget_account_segment9,REC.budget_account_segment10,REC.budget_account_segment11,--
  REC.budget_account_segment12,REC.budget_account_segment13,REC.budget_account_segment14,--
  REC.budget_account_segment15,REC.budget_account_segment16,REC.budget_account_segment17,--
  REC.budget_account_segment18,REC.budget_account_segment19,REC.budget_account_segment20,--
  REC.budget_account_segment21,REC.budget_account_segment22,REC.budget_account_segment23,--
  REC.budget_account_segment24,REC.budget_account_segment25,REC.budget_account_segment26,--
  REC.budget_account_segment27,REC.budget_account_segment28,REC.budget_account_segment29,--
  REC.budget_account_segment30,REC.budget_account,REC.budget_account_id,--
  REC.gl_encumbered_date,REC.gl_encumbered_period_name);
 END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_PO_DTL_iface(rec PO_LINES_INTERFACE%ROWTYPE) IS
 BEGIN
  INSERT INTO PO_LINES_INTERFACE (
     interface_line_id, interface_header_id, action,
     group_code, line_num, po_line_id,
     shipment_num, line_location_id, shipment_type,
     requisition_line_id, document_num, release_num,
     po_header_id, po_release_id, source_shipment_id,
     contract_num, line_type, line_type_id,
     item, item_id, item_revision,
     CATEGORY, category_id, item_description,
     vendor_product_num, uom_code, unit_of_measure,
     quantity, committed_amount, min_order_quantity,
     max_order_quantity, unit_price, list_price_per_unit,
     market_price, allow_price_override_flag, not_to_exceed_price,
     negotiated_by_preparer_flag, un_number, un_number_id,
     hazard_class, hazard_class_id, note_to_vendor,
     transaction_reason_code, taxable_flag, tax_name,
     type_1099, capital_expense_flag, inspection_required_flag,
     receipt_required_flag, payment_terms, terms_id,
     price_type, min_release_amount, price_break_lookup_code,
     ussgl_transaction_code, closed_code, closed_reason,
     closed_date, closed_by, --invoice_close_tolerance,
     receive_close_tolerance, firm_flag, days_early_receipt_allowed,
     days_late_receipt_allowed, enforce_ship_to_location_code, allow_substitute_receipts_flag,
     receiving_routing, receiving_routing_id, qty_rcv_tolerance,
     over_tolerance_error_flag, qty_rcv_exception_code, receipt_days_exception_code,
     ship_to_organization_code, ship_to_organization_id, ship_to_location,
     ship_to_location_id, need_by_date, promised_date,
     accrue_on_receipt_flag, lead_time, lead_time_unit,
     price_discount, freight_carrier, fob,
     freight_terms, effective_date, expiration_date,
     from_header_id, from_line_id, from_line_location_id,
     line_attribute_category_lines, line_attribute1, line_attribute2,
     line_attribute3, line_attribute4, line_attribute5,
     line_attribute6, line_attribute7, line_attribute8,
     line_attribute9, line_attribute10, line_attribute11,
     line_attribute12, line_attribute13, line_attribute14,
     line_attribute15, shipment_attribute_category, shipment_attribute1,
     shipment_attribute2, shipment_attribute3, shipment_attribute4,
     shipment_attribute5, shipment_attribute6, shipment_attribute7,
     shipment_attribute8, shipment_attribute9, shipment_attribute10,
     shipment_attribute11, shipment_attribute12, shipment_attribute13,
     shipment_attribute14, shipment_attribute15, last_update_date,
     last_updated_by, last_update_login, creation_date,
     created_by, request_id, program_application_id,
     program_id, program_update_date, invoice_close_tolerance,
     organization_id, item_attribute_category, item_attribute1,
     item_attribute2, item_attribute3, item_attribute4,
     item_attribute5, item_attribute6, item_attribute7,
     item_attribute8, item_attribute9, item_attribute10,
     item_attribute11, item_attribute12, item_attribute13,
     item_attribute14, item_attribute15, unit_weight,
     weight_uom_code, volume_uom_code, unit_volume,
     template_id, template_name, line_reference_num,
     sourcing_rule_name, tax_status_indicator, process_code,
     price_chg_accept_flag, price_break_flag, price_update_tolerance,
     tax_user_override_flag, tax_code_id, note_to_receiver,
     oke_contract_header_id, oke_contract_header_num, oke_contract_version_id,
     secondary_unit_of_measure, secondary_uom_code, secondary_quantity,
     preferred_grade, vmi_flag, auction_header_id,
     auction_line_number, auction_display_number, bid_number,
     bid_line_number, orig_from_req_flag, consigned_flag,
     supplier_ref_number, contract_id, job_id,
     amount, job_name, contractor_first_name,
     contractor_last_name, drop_ship_flag, base_unit_price,
     transaction_flow_header_id, job_business_group_id, job_business_group_name)
  VALUES (
  REC.interface_line_id,REC.interface_header_id,REC.action,--
  REC.group_code,REC.line_num,REC.po_line_id,--
  REC.shipment_num,REC.line_location_id,REC.shipment_type,--
  REC.requisition_line_id,REC.document_num,REC.release_num,--
  REC.po_header_id,REC.po_release_id,REC.source_shipment_id,--
  REC.contract_num,REC.line_type,REC.line_type_id,--
  REC.item,REC.item_id,REC.item_revision,--
  REC.CATEGORY,REC.category_id,REC.item_description,--
  REC.vendor_product_num,REC.uom_code,REC.unit_of_measure,--
  REC.quantity,REC.committed_amount,REC.min_order_quantity,--
  REC.max_order_quantity,REC.unit_price,REC.list_price_per_unit,--
  REC.market_price,REC.allow_price_override_flag,REC.not_to_exceed_price,--
  REC.negotiated_by_preparer_flag,REC.un_number,REC.un_number_id,--
  REC.hazard_class,REC.hazard_class_id,REC.note_to_vendor,--
  REC.transaction_reason_code,REC.taxable_flag,REC.tax_name,--
  REC.type_1099,REC.capital_expense_flag,REC.inspection_required_flag,--
  REC.receipt_required_flag,REC.payment_terms,REC.terms_id,--
  REC.price_type,REC.min_release_amount,REC.price_break_lookup_code,--
  REC.ussgl_transaction_code,REC.closed_code,REC.closed_reason,--
  REC.closed_date,REC.closed_by,--REC.invoice_close_tolerance,--
  REC.receive_close_tolerance,REC.firm_flag,REC.days_early_receipt_allowed,--
  REC.days_late_receipt_allowed,REC.enforce_ship_to_location_code,REC.allow_substitute_receipts_flag,--
  REC.receiving_routing,REC.receiving_routing_id,REC.qty_rcv_tolerance,--
  REC.over_tolerance_error_flag,REC.qty_rcv_exception_code,REC.receipt_days_exception_code,--
  REC.ship_to_organization_code,REC.ship_to_organization_id,REC.ship_to_location,--
  REC.ship_to_location_id,REC.need_by_date,REC.promised_date,--
  REC.accrue_on_receipt_flag,REC.lead_time,REC.lead_time_unit,--
  REC.price_discount,REC.freight_carrier,REC.fob,--
  REC.freight_terms,REC.effective_date,REC.expiration_date,--
  REC.from_header_id,REC.from_line_id,REC.from_line_location_id,--
  REC.line_attribute_category_lines,REC.line_attribute1,REC.line_attribute2,--
  REC.line_attribute3,REC.line_attribute4,REC.line_attribute5,--
  REC.line_attribute6,REC.line_attribute7,REC.line_attribute8,--
  REC.line_attribute9,REC.line_attribute10,REC.line_attribute11,--
  REC.line_attribute12,REC.line_attribute13,REC.line_attribute14,--
  REC.line_attribute15,REC.shipment_attribute_category,REC.shipment_attribute1,--
  REC.shipment_attribute2,REC.shipment_attribute3,REC.shipment_attribute4,--
  REC.shipment_attribute5,REC.shipment_attribute6,REC.shipment_attribute7,--
  REC.shipment_attribute8,REC.shipment_attribute9,REC.shipment_attribute10,--
  REC.shipment_attribute11,REC.shipment_attribute12,REC.shipment_attribute13,--
  REC.shipment_attribute14,REC.shipment_attribute15,REC.last_update_date,--
  REC.last_updated_by,REC.last_update_login,REC.creation_date,--
  REC.created_by,REC.request_id,REC.program_application_id,--
  REC.program_id,REC.program_update_date,REC.invoice_close_tolerance,--
  REC.organization_id,REC.item_attribute_category,REC.item_attribute1,--
  REC.item_attribute2,REC.item_attribute3,REC.item_attribute4,--
  REC.item_attribute5,REC.item_attribute6,REC.item_attribute7,--
  REC.item_attribute8,REC.item_attribute9,REC.item_attribute10,--
  REC.item_attribute11,REC.item_attribute12,REC.item_attribute13,--
  REC.item_attribute14,REC.item_attribute15,REC.unit_weight,--
  REC.weight_uom_code,REC.volume_uom_code,REC.unit_volume,--
  REC.template_id,REC.template_name,REC.line_reference_num,--
  REC.sourcing_rule_name,REC.tax_status_indicator,REC.process_code,--
  REC.price_chg_accept_flag,REC.price_break_flag,REC.price_update_tolerance,--
  REC.tax_user_override_flag,REC.tax_code_id,REC.note_to_receiver,--
  REC.oke_contract_header_id,REC.oke_contract_header_num,REC.oke_contract_version_id,--
  REC.secondary_unit_of_measure,REC.secondary_uom_code,REC.secondary_quantity,--
  REC.preferred_grade,REC.vmi_flag,REC.auction_header_id,--
  REC.auction_line_number,REC.auction_display_number,REC.bid_number,--
  REC.bid_line_number,REC.orig_from_req_flag,REC.consigned_flag,--
  REC.supplier_ref_number,REC.contract_id,REC.job_id,--
  REC.amount,REC.job_name,REC.contractor_first_name,--
  REC.contractor_last_name,REC.drop_ship_flag,REC.base_unit_price,--
  REC.transaction_flow_header_id,REC.job_business_group_id,REC.job_business_group_name);
    END;

------------------------------------------------------------------------------------------------
PROCEDURE insert_PO_DIST_iface(dist PO_DISTRIBUTIONS_INTERFACE%ROWTYPE) IS
 BEGIN
  INSERT INTO PO_DISTRIBUTIONS_INTERFACE (
  interface_header_id, interface_line_id, interface_distribution_id,
  po_header_id, po_release_id, po_line_id,
  line_location_id, po_distribution_id, distribution_num,
  source_distribution_id, org_id, quantity_ordered,
  quantity_delivered, quantity_billed, quantity_cancelled,
  rate_date, rate, deliver_to_location,
  deliver_to_location_id, deliver_to_person_full_name, deliver_to_person_id,
  destination_type, destination_type_code, destination_organization,
  destination_organization_id, destination_subinventory, destination_context,
  set_of_books, set_of_books_id, charge_account,
  charge_account_id, budget_account, budget_account_id,
  accural_account, accrual_account_id, variance_account,
  variance_account_id, amount_billed, accrue_on_receipt_flag,
  accrued_flag, prevent_encumbrance_flag, encumbered_flag,
  encumbered_amount, unencumbered_quantity, unencumbered_amount,
  failed_funds, failed_funds_lookup_code, gl_encumbered_date,
  gl_encumbered_period_name, gl_cancelled_date, gl_closed_date,
  req_header_reference_num, req_line_reference_num, req_distribution_id,
  wip_entity, wip_entity_id, wip_operation_seq_num,
  wip_resource_seq_num, wip_repetitive_schedule, wip_repetitive_schedule_id,
  wip_line_code, wip_line_id, bom_resource_code,
  bom_resource_id, ussgl_transaction_code, government_context,
  project, project_id, TASK,
  task_id, expenditure, expenditure_type,
  project_accounting_context, expenditure_organization, expenditure_organization_id,
  project_releated_flag, expenditure_item_date, attribute_category,
  attribute1, attribute2, attribute3,
  attribute4, attribute5, attribute6,
  attribute7, attribute8, attribute9,
  attribute10, attribute11, attribute12,
  attribute13, attribute14, attribute15,
  last_update_date, last_updated_by, last_update_login,
  creation_date, created_by, request_id,
  program_application_id, program_id, program_update_date,
  end_item_unit_number, recoverable_tax, nonrecoverable_tax,
  recovery_rate, tax_recovery_override_flag, award_id,
  charge_account_segment1, charge_account_segment2, charge_account_segment3,
  charge_account_segment4, charge_account_segment5, charge_account_segment6,
  charge_account_segment7, charge_account_segment8, charge_account_segment9,
  charge_account_segment10, charge_account_segment11, charge_account_segment12,
  charge_account_segment13, charge_account_segment14, charge_account_segment15,
  charge_account_segment16, charge_account_segment17, charge_account_segment18,
  charge_account_segment19, charge_account_segment20, charge_account_segment21,
  charge_account_segment22, charge_account_segment23, charge_account_segment24,
  charge_account_segment25, charge_account_segment26, charge_account_segment27,
  charge_account_segment28, charge_account_segment29, charge_account_segment30,
  oke_contract_line_id, oke_contract_line_num, oke_contract_deliverable_id,
  oke_contract_deliverable_num, award_number, amount_ordered,
  invoice_adjustment_flag, dest_charge_account_id, dest_variance_account_id)
    VALUES (
  DIST.interface_header_id,DIST.interface_line_id,DIST.interface_distribution_id,--
  DIST.po_header_id,DIST.po_release_id,DIST.po_line_id,--
  DIST.line_location_id,DIST.po_distribution_id,DIST.distribution_num,--
  DIST.source_distribution_id,DIST.org_id,DIST.quantity_ordered,--
  DIST.quantity_delivered,DIST.quantity_billed,DIST.quantity_cancelled,--
  DIST.rate_date,DIST.rate,DIST.deliver_to_location,--
  DIST.deliver_to_location_id,DIST.deliver_to_person_full_name,DIST.deliver_to_person_id,--
  DIST.destination_type,DIST.destination_type_code,DIST.destination_organization,--
  DIST.destination_organization_id,DIST.destination_subinventory,DIST.destination_context,--
  DIST.set_of_books,DIST.set_of_books_id,DIST.charge_account,--
  DIST.charge_account_id,DIST.budget_account,DIST.budget_account_id,--
  DIST.accural_account,DIST.accrual_account_id,DIST.variance_account,--
  DIST.variance_account_id,DIST.amount_billed,DIST.accrue_on_receipt_flag,--
  DIST.accrued_flag,DIST.prevent_encumbrance_flag,DIST.encumbered_flag,--
  DIST.encumbered_amount,DIST.unencumbered_quantity,DIST.unencumbered_amount,--
  DIST.failed_funds,DIST.failed_funds_lookup_code,DIST.gl_encumbered_date,--
  DIST.gl_encumbered_period_name,DIST.gl_cancelled_date,DIST.gl_closed_date,--
  DIST.req_header_reference_num,DIST.req_line_reference_num,DIST.req_distribution_id,--
  DIST.wip_entity,DIST.wip_entity_id,DIST.wip_operation_seq_num,--
  DIST.wip_resource_seq_num,DIST.wip_repetitive_schedule,DIST.wip_repetitive_schedule_id,--
  DIST.wip_line_code,DIST.wip_line_id,DIST.bom_resource_code,--
  DIST.bom_resource_id,DIST.ussgl_transaction_code,DIST.government_context,--
  DIST.project,DIST.project_id,DIST.TASK,--
  DIST.task_id,DIST.expenditure,DIST.expenditure_type,--
  DIST.project_accounting_context,DIST.expenditure_organization,DIST.expenditure_organization_id,--
  DIST.project_releated_flag,DIST.expenditure_item_date,DIST.attribute_category,--
  DIST.attribute1,DIST.attribute2,DIST.attribute3,--
  DIST.attribute4,DIST.attribute5,DIST.attribute6,--
  DIST.attribute7,DIST.attribute8,DIST.attribute9,--
  DIST.attribute10,DIST.attribute11,DIST.attribute12,--
  DIST.attribute13,DIST.attribute14,DIST.attribute15,--
  DIST.last_update_date,DIST.last_updated_by,DIST.last_update_login,--
  DIST.creation_date,DIST.created_by,DIST.request_id,--
  DIST.program_application_id,DIST.program_id,DIST.program_update_date,--
  DIST.end_item_unit_number,DIST.recoverable_tax,DIST.nonrecoverable_tax,--
  DIST.recovery_rate,DIST.tax_recovery_override_flag,DIST.award_id,--
  DIST.charge_account_segment1,DIST.charge_account_segment2,DIST.charge_account_segment3,--
  DIST.charge_account_segment4,DIST.charge_account_segment5,DIST.charge_account_segment6,--
  DIST.charge_account_segment7,DIST.charge_account_segment8,DIST.charge_account_segment9,--
  DIST.charge_account_segment10,DIST.charge_account_segment11,DIST.charge_account_segment12,--
  DIST.charge_account_segment13,DIST.charge_account_segment14,DIST.charge_account_segment15,--
  DIST.charge_account_segment16,DIST.charge_account_segment17,DIST.charge_account_segment18,--
  DIST.charge_account_segment19,DIST.charge_account_segment20,DIST.charge_account_segment21,--
  DIST.charge_account_segment22,DIST.charge_account_segment23,DIST.charge_account_segment24,--
  DIST.charge_account_segment25,DIST.charge_account_segment26,DIST.charge_account_segment27,--
  DIST.charge_account_segment28,DIST.charge_account_segment29,DIST.charge_account_segment30,--
  DIST.oke_contract_line_id,DIST.oke_contract_line_num,DIST.oke_contract_deliverable_id,--
  DIST.oke_contract_deliverable_num,DIST.award_number,DIST.amount_ordered,--
  DIST.invoice_adjustment_flag,DIST.dest_charge_account_id,DIST.dest_variance_account_id);
    END;

------------------------------------------------------------------------------------------------
   PROCEDURE populate_iface(
               p_batch_id   IN  NUMBER,
      p_count_hdr  OUT PLS_INTEGER,
      p_count_line OUT PLS_INTEGER,
      p_count_dist OUT PLS_INTEGER)  IS

  v_tot_hdr_counter  PLS_INTEGER DEFAULT 0;
  v_tot_line_counter PLS_INTEGER DEFAULT 0;
  v_tot_dist_counter PLS_INTEGER DEFAULT 0;

  iface_hdr      PO_HEADERS_INTERFACE%ROWTYPE;
  iface_line     PO_LINES_INTERFACE%ROWTYPE;
  iface_dist     PO_DISTRIBUTIONS_INTERFACE%ROWTYPE;

    CURSOR iface_hdr_cur  IS
       SELECT *
       FROM   XXKHD_PO_HDR 
    WHERE  batch_id = p_batch_id
    ORDER BY interface_header_id;

    CURSOR iface_line_cur IS
       SELECT *
       FROM   XXKHD_PO_LINE
    WHERE  batch_id = p_batch_id
    ORDER BY interface_line_id;

    CURSOR iface_dist_cur  IS
       SELECT *
       FROM   XXKHD_PO_DIST
    WHERE  batch_id = p_batch_id
    ORDER BY interface_distribution_id;


   BEGIN
        FOR HDR IN iface_hdr_cur  LOOP
   
   IFACE_HDR.interface_header_id     :=  HDR.interface_header_id;
   IFACE_HDR.org_id      := HDR.org_id  ;
   IFACE_HDR.batch_id      := HDR.batch_id  ;
   IFACE_HDR.interface_source_code  := HDR.interface_source_code ;
   IFACE_HDR.vendor_name     := HDR.vendor_name  ;
   IFACE_HDR.vendor_site_code    := HDR.vendor_site_code  ;
   IFACE_HDR.ship_to_location    := HDR.ship_to_location  ;
   IFACE_HDR.bill_to_location    := HDR.bill_to_location  ;
   IFACE_HDR.revision_num     := HDR.revision_num  ;
   IFACE_HDR.action      := HDR.action  ;
   IFACE_HDR.currency_code    := HDR.currency_code  ;
   IFACE_HDR.agent_id      := HDR.agent_id  ;

   IFACE_HDR.created_by     := HDR.created_by  ;
   IFACE_HDR.last_updated_by    := HDR.last_updated_by  ;
   IFACE_HDR.last_update_login   := HDR.last_update_login ;
   IFACE_HDR.last_update_date    := HDR.last_update_date  ;
   IFACE_HDR.creation_date    := HDR.creation_date  ;

   IFACE_HDR.attribute_category  := HDR.attribute_category ;
   IFACE_HDR.attribute1     := HDR.attribute1  ;
   IFACE_HDR.attribute2     := HDR.attribute2  ;
   IFACE_HDR.attribute8     := HDR.attribute8  ;
   IFACE_HDR.attribute9     := HDR.attribute9  ;   
   IFACE_HDR.attribute3     := HDR.attribute3  ;    --add info SJ dan no POL, 29-NOV-2012
   IFACE_HDR.attribute14     := HDR.attribute14  ;  --add info SJ dan no POL, 29-NOV-2012 


   insert_PO_HDR_iface(IFACE_HDR);

   v_tot_hdr_counter := v_tot_hdr_counter + 1;

     END LOOP;

        FOR LINE IN iface_line_cur  LOOP

   IFACE_LINE.interface_line_id           := LINE.interface_line_id ;
   IFACE_LINE.interface_header_id      := LINE.interface_header_id ;
   IFACE_LINE.action         := LINE.action ;
   IFACE_LINE.line_type        := LINE.line_type ;
   IFACE_LINE.category_id        := LINE.category_id ;

   IFACE_LINE.item_id            := LINE.item_id ;
   IFACE_LINE.item                := LINE.item_code ;
   IFACE_LINE.item_description       := LINE.item_description ;
   IFACE_LINE.unit_of_measure       := LINE.unit_of_measure ;
   IFACE_LINE.quantity         := LINE.quantity ;   
   IFACE_LINE.unit_price        := LINE.unit_price ;
   IFACE_LINE.promised_date       := LINE.promised_date ;
   IFACE_LINE.need_by_date            :=   LINE.promised_date ;
   IFACE_LINE.ship_to_location       := LINE.ship_to_location ;
   IFACE_LINE.ship_to_organization_code    := LINE.ship_to_organization_code ;

   IFACE_LINE.created_by        := LINE.created_by ;
   IFACE_LINE.creation_date       := LINE.creation_date ;
   IFACE_LINE.last_updated_by       := LINE.last_updated_by ;
   IFACE_LINE.last_update_date       := LINE.last_update_date ;
   IFACE_LINE.last_update_login      := LINE.last_update_login ;

   IFACE_LINE.line_attribute_category_lines   := LINE.line_attribute_category_lines ;
   IFACE_LINE.line_attribute1       := LINE.line_attribute1 ;
   IFACE_LINE.line_attribute2       := LINE.line_attribute2 ;
   IFACE_LINE.line_attribute3       := LINE.line_attribute3 ;
   IFACE_LINE.line_attribute4       := LINE.line_attribute4 ;
   IFACE_LINE.line_attribute5       := LINE.line_attribute5 ;
   IFACE_LINE.line_attribute6       := LINE.line_attribute6 ;

   IFACE_LINE.shipment_attribute_category    := LINE.shipment_attribute_category ;
   IFACE_LINE.shipment_attribute1      := LINE.shipment_attribute1 ;
   IFACE_LINE.shipment_attribute2      := LINE.shipment_attribute2 ;
   IFACE_LINE.shipment_attribute3      := LINE.shipment_attribute3 ;
   IFACE_LINE.shipment_attribute4      := LINE.shipment_attribute4 ;
   IFACE_LINE.shipment_attribute5      := LINE.shipment_attribute5 ;
   IFACE_LINE.shipment_attribute6      := LINE.shipment_attribute6 ;

   insert_PO_DTL_iface(IFACE_LINE);

   v_tot_line_counter := v_tot_line_counter + 1;

     END LOOP;

        FOR DIST IN iface_dist_cur LOOP

   IFACE_DIST.interface_distribution_id := DIST.interface_distribution_id ;
   IFACE_DIST.interface_header_id   := DIST.interface_header_id ;
   IFACE_DIST.interface_line_id   := DIST.interface_line_id ;

   IFACE_DIST.distribution_num    := DIST.distribution_num ;
   IFACE_DIST.quantity_ordered    := DIST.quantity_ordered ;

   IFACE_DIST.charge_account_segment1  := DIST.charge_account_segment1 ;
   IFACE_DIST.charge_account_segment2  := DIST.charge_account_segment2 ;
   IFACE_DIST.charge_account_segment3  := DIST.charge_account_segment3 ;
   IFACE_DIST.charge_account_segment4  := DIST.charge_account_segment4 ;
   IFACE_DIST.charge_account_segment5  := DIST.charge_account_segment5 ;
   IFACE_DIST.charge_account_segment6  := DIST.charge_account_segment6 ;
   IFACE_DIST.charge_account_segment7  := DIST.charge_account_segment7 ;

   IFACE_DIST.created_by     := DIST.created_by ;
   IFACE_DIST.creation_date    := DIST.creation_date ;
   IFACE_DIST.last_updated_by    := DIST.last_updated_by ;
   IFACE_DIST.last_update_date    := DIST.last_update_date ;
   IFACE_DIST.last_update_login   := DIST.last_update_login ;

   IFACE_DIST.attribute_category   := DIST.attribute_category ;
   IFACE_DIST.attribute1     := DIST.attribute1 ;
   IFACE_DIST.attribute2     := DIST.attribute2 ;
   IFACE_DIST.attribute3     := DIST.attribute3 ;
   IFACE_DIST.attribute4     := DIST.attribute4 ;
   IFACE_DIST.attribute5     := DIST.attribute5 ;
   IFACE_DIST.attribute6     := DIST.attribute6 ;

   insert_PO_DIST_iface(IFACE_DIST);

   v_tot_dist_counter := v_tot_dist_counter + 1;

     END LOOP;

  UPDATE XXKHD_po_batch
  SET    batch_status  = 'POPULATED'
  WHERE  batch_id = p_batch_id;

  UPDATE XXKHD_po_hdr
  SET    po_status = 'POPULATED'
  WHERE  batch_id  = p_batch_id;

     p_count_hdr  := v_tot_hdr_counter;
     p_count_line := v_tot_line_counter;
     p_count_dist := v_tot_dist_counter;
  
   IF g_debug = 'Y' THEN
       logF('v_batch_id         '||p_batch_id);
       logF('v_tot_hdr_counter  '||v_tot_hdr_counter);
   logF('v_tot_line_counter '||v_tot_line_counter);
   logF('v_tot_dist_counter '||v_tot_dist_counter);
  END IF;  

   END;
   
------------------------------------------------------------------------------------------------
   PROCEDURE populate_XXKHD_temp(p_batch_id OUT PLS_INTEGER) IS

  v_hdr_counter      PLS_INTEGER  DEFAULT 0;
  v_line_counter     PLS_INTEGER  DEFAULT 0;
  v_tot_line_counter PLS_INTEGER  DEFAULT 0;
  v_hierarchy_level  VARCHAR2(30) DEFAULT NULL;
  
  rcv_hdr            RCV_VRC_HDS_V%ROWTYPE;

  XXKHD_batch         XXKHD_PO_BATCH%ROWTYPE;
  XXKHD_hdr           XXKHD_PO_HDR%ROWTYPE;
  XXKHD_line          XXKHD_PO_LINE%ROWTYPE;
  XXKHD_dist          XXKHD_PO_DIST%ROWTYPE;

  VEND      vendor_rec_type;
  ITEM      item_rec_type;

 BEGIN
 
  IF g_debug = 'Y' THEN
      logF('Inside XXKHD_temp');
  END IF;
  
     FOR rec IN source_hdr_cur LOOP

   XXKHD_HDR := NULL;
   VEND  := NULL;
   
   IF v_hdr_counter = 0 THEN
  
       SELECT group_sequence_id_s.NEXTVAL
    INTO   XXKHD_BATCH.batch_id
    FROM   dual;

    XXKHD_BATCH.batch_status   := 'OPEN';
    XXKHD_BATCH.start_date    := g_start_date;
    XXKHD_BATCH.end_date    := g_end_date;
    XXKHD_BATCH.org_id     := Fnd_Global.org_id;
    XXKHD_BATCH.import_request_id  := Fnd_Global.conc_request_id;
    XXKHD_BATCH.created_by    := Fnd_Global.user_id;
    XXKHD_BATCH.last_updated_by   := Fnd_Global.user_id;
    XXKHD_BATCH.last_update_login    := Fnd_Global.login_id;
    XXKHD_BATCH.last_update_date  := SYSDATE;
    XXKHD_BATCH.creation_date   := SYSDATE;

    insert_XXKHD_PO_BATCH(XXKHD_BATCH);
   END IF;
   
   SELECT *
   INTO   RCV_HDR
   FROM   RCV_VRC_HDS_V
   WHERE  shipment_header_id = REC.shipment_header_id;

   IF g_debug = 'Y' THEN
       logF(' ');
       logF('----------');
    logF('Receipt No '||RCV_HDR.receipt_num||': '||RCV_HDR.receipt_date);
       logF('----------');    
    logF('XXKHD_BATCH.batch_id '||XXKHD_BATCH.batch_id);    
   END IF;   
      
        SELECT po_headers_interface_s.NEXTVAL
     INTO   XXKHD_HDR.interface_header_id
     FROM   dual;

   SELECT USR.employee_id, 
       EMP.full_name 
   INTO   XXKHD_HDR.agent_id, 
       XXKHD_HDR.agent_name
   FROM   fnd_user          USR,
       per_all_people_f  EMP
   WHERE  
       USR.user_id     = Fnd_Global.user_id
   AND    USR.employee_id = EMP.person_id       
   AND    TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date;
   
--   XXKHD_HDR.agent_id   := 135;
--   XXKHD_HDR.agent_name := 'BUY01';   
   
   IF g_debug = 'Y' THEN
    logF('XXKHD_HDR.agent_name '||XXKHD_HDR.agent_name);    
   END IF;     
        
            -- VENDOR ------------------------------------------------------- 
            -----------------------------------------------------------------  
   
   IF g_debug = 'Y' THEN
    logF('RCV_HDR.organization_id '||RCV_HDR.organization_id);    
   END IF;  
   
   BEGIN
    SELECT TO_NUMBER(attribute2) vendor_id,   --name,
        TO_NUMBER(attribute3) vendor_site_id,
        attribute4    segment_trading_partner 
          INTO   VEND.vendor_id,
        VEND.vendor_site_id,
        VEND.segment4   
    FROM   HR_ALL_ORGANIZATION_UNITS
    WHERE  attribute_category = 'Organization Type'
    AND    attribute1    = 'O'
    AND    organization_id   = RCV_HDR.organization_id;
   EXCEPTION 
       WHEN OTHERS THEN
        logF(cust_mesg(33).mesg);
     logF('Receipt No              '||RCV_HDR.receipt_num);
     logF('RCV_HDR.organization_id '||RCV_HDR.organization_id);            
     RAISE e_bohong;      
   END;
   
   IF g_debug = 'Y' THEN
    logF('REC.organization_id '||REC.organization_id);    
   END IF;    
   
   BEGIN
    SELECT attribute5 ship_to_organization_id 
          INTO   VEND.ship_to_organization_id           
    FROM   HR_ALL_ORGANIZATION_UNITS
    WHERE  organization_id   = REC.organization_id;
   EXCEPTION 
       WHEN OTHERS THEN
        logF(cust_mesg(33).mesg);
     logF('Receipt No          '||RCV_HDR.receipt_num);
     logF('REC.organization_id '||REC.organization_id);           
     RAISE e_bohong;      
   END; 
   
   IF VEND.vendor_id IS NULL OR VEND.vendor_site_id IS NULL OR VEND.ship_to_organization_id IS NULL THEN
        logF(cust_mesg(33).mesg);
     logF('Receipt No             '||RCV_HDR.receipt_num); 
     logF('REC.organization_id    '||REC.organization_id); 
     RAISE e_bohong;
   END IF;

   BEGIN                      
    SELECT LOC.location_code
    INTO   VEND.ship_to_location
    FROM   HR_ALL_ORGANIZATION_UNITS org,
        HR_LOCATIONS_ALL    loc
    WHERE  ORG.organization_id = VEND.ship_to_organization_id
    AND    ORG.location_id     = LOC.location_id;
   EXCEPTION
      WHEN OTHERS THEN 
     logF(cust_mesg(48).mesg);
     logF('Receipt No                   '||RCV_HDR.receipt_num); 
     logF('VEND.ship_to_organization_id '||VEND.ship_to_organization_id);
     RAISE e_bohong;         
         END; 
       
   BEGIN   
       SELECT VENDOR.vendor_name,
        SITE.vendor_site_code 
    INTO   
        VEND.vendor_name,
        VEND.vendor_site_code
    FROM   
        PO_VENDORS           vendor,
        PO_VENDOR_SITES_ALL  site
    WHERE  
        VENDOR.vendor_id       = SITE.vendor_id
    AND    SITE.vendor_site_id    = VEND.vendor_site_id --6915--
    AND    VENDOR.vendor_id       = VEND.vendor_id;
      
   EXCEPTION 
       WHEN OTHERS THEN
     logF(cust_mesg(34).mesg);
     logF('Receipt No '||RCV_HDR.receipt_num); 
     RAISE e_bohong;       
   END; 
   
   IF g_debug = 'Y' THEN
       logF('VEND.vendor_name '||VEND.vendor_name);
   END IF;     
       
            -----------------------------------------------------------------         
 
   XXKHD_HDR.po_status          := 'OPEN';
   XXKHD_HDR.batch_id          := XXKHD_BATCH.batch_id;
   XXKHD_HDR.org_id       := XXKHD_BATCH.org_id;
   XXKHD_HDR.interface_source_code := XXKHD_BATCH.batch_id ||'-'|| TO_CHAR(g_start_date,'DDMONRR') || '/' || TO_CHAR(g_end_date,'DDMONRR');

   XXKHD_HDR.vendor_name      := VEND.vendor_name;
   XXKHD_HDR.vendor_site_code     := VEND.vendor_site_code;

   XXKHD_HDR.shipment_header_id    := REC.shipment_header_id;   
   XXKHD_HDR.ship_to_location     := VEND.ship_to_location;
   XXKHD_HDR.bill_to_location     := VEND.ship_to_location;
   XXKHD_HDR.attribute1      := RCV_HDR.receipt_num;
   XXKHD_HDR.attribute2      := RCV_HDR.shipment_num;   

   XXKHD_HDR.revision_num      := g_hdr_revision_num;
   XXKHD_HDR.action       := g_hdr_action;
   XXKHD_HDR.currency_code      := g_currency_code;
   XXKHD_HDR.attribute_category    := g_hdr_attribute_category;
   XXKHD_HDR.created_by      := Fnd_Global.user_id;
   XXKHD_HDR.last_updated_by     := Fnd_Global.user_id;
   XXKHD_HDR.last_update_login     := Fnd_Global.login_id;
   XXKHD_HDR.last_update_date     := SYSDATE;
   XXKHD_HDR.creation_date      := SYSDATE;
   
   XXKHD_HDR.attribute8      := XXKHD_BATCH.batch_id;
   XXKHD_HDR.attribute9      := XXKHD_HDR.interface_header_id;
   XXKHD_HDR.attribute3      := REC.packing_slip;
   XXKHD_HDR.attribute14     := REC.comments;

   insert_XXKHD_PO_HDR(XXKHD_HDR);
   
   IF g_debug = 'Y' THEN
       logF('RCV_HDR.shipment_header_id '||RCV_HDR.shipment_header_id);    
   END IF;  
      
   v_line_counter := 0;

   FOR dtl IN source_trx_cur(RCV_HDR.shipment_header_id) LOOP
       
    XXKHD_LINE := NULL;
    XXKHD_DIST := NULL;
    ITEM   := NULL;    

                -- ITEM --------------------------------------------------------- 
             -----------------------------------------------------------------    
          
    BEGIN
     SELECT attribute1
     INTO   v_hierarchy_level
     FROM   WSH_NEW_DELIVERIES
     WHERE  organization_id     = DTL.from_organization_id
     AND    attribute_category  = g_hazard_class
     AND    NAME IN (SELECT shipment_num
                  FROM   rcv_shipment_headers
            WHERE  shipment_header_id = RCV_HDR.shipment_header_id);
    EXCEPTION
       WHEN OTHERS THEN 
      logF(cust_mesg(41).mesg);
      logF('Receipt No '||RCV_HDR.receipt_num); 
      RAISE e_bohong;         
          END;
    
    IF g_debug = 'Y' THEN
        logF(' ');
        logF('v_hierarchy_level '||v_hierarchy_level);
    END IF;
           
    BEGIN      
     SELECT flex_value  
     INTO   ITEM.item_code 
     FROM   fnd_flex_values_vl VL
     WHERE  flex_value_set_id IN (
           SELECT flex_value_set_id 
        FROM   fnd_flex_value_sets 
        WHERE  flex_value_set_name = 'SHP-MAPPING-ITEM-SERVICE')     
     AND    TRUNC(SYSDATE) BETWEEN NVL(START_DATE_ACTIVE,TO_DATE('01-JAN-1950')) AND NVL(END_DATE_ACTIVE,TO_DATE('01-JAN-3004'))
     AND    enabled_flag    = 'Y'
     AND    description     = DTL.item_code
     AND    hierarchy_level = v_hierarchy_level;
    EXCEPTION
       WHEN OTHERS THEN    
      logF(cust_mesg(42).mesg);
      logF('Receipt No    '||RCV_HDR.receipt_num); 
      logF('DTL.item_code '||DTL.item_code);
      RAISE e_bohong;        
          END;             
    
    IF g_debug = 'Y' THEN
        logF('ITEM.item_code '||ITEM.item_code);
        logF('VEND.ship_to_organization_id '||VEND.ship_to_organization_id);          
    END IF;
               
    BEGIN     
     SELECT MTL.inventory_item_id, MTL.description, MTL.primary_unit_of_measure,
--         MTL.secondary_uom_code,
         GL.segment1, GL.segment2, GL.segment3, GL.segment5, GL.segment6, GL.segment7
     INTO   
         ITEM.item_id,  ITEM.item_description, ITEM.primary_unit_of_measure,
--         ITEM.secondary_uom_code,
         ITEM.segment1, ITEM.segment2, ITEM.segment3,
         ITEM.segment5, ITEM.segment6, ITEM.segment7
     FROM   
         MTL_SYSTEM_ITEMS_B   MTL,
         GL_CODE_COMBINATIONS GL
     WHERE  
         MTL.organization_id = VEND.ship_to_organization_id
     AND    MTL.segment1     = ITEM.item_code
     AND    MTL.expense_account = GL.code_combination_id;
     
--      select unit_of_measure 
--      into   ITEM.secondary_unit_of_measure
--      from   MTL_UNITS_OF_MEASURE_TL 
--      where  uom_code = ITEM.secondary_uom_code;  
        
    EXCEPTION
       WHEN OTHERS THEN 
      logF(cust_mesg(43).mesg);
      logF('Receipt No     '||RCV_HDR.receipt_num); 
      logF('ITEM.item_code '||ITEM.item_code);
      RAISE e_bohong;         
          END;                    

            
    IF g_debug = 'Y' THEN      
        logF('ITEM.unit_price       '||ITEM.unit_price);
     logF('ITEM.item_id    '||ITEM.item_id);       
     logF('ITEM.item_code   '||ITEM.item_code);    
     logF('ITEM.item_description '||ITEM.item_description );
     logF('ITEM.category_id   '||ITEM.category_id );       
     logF('ITEM.primary_uom_code '||ITEM.primary_uom_code );  
     logF('ITEM.primary_unit_of_measure   '|| ITEM.primary_unit_of_measure );    
--      logF('ITEM.secondary_uom_code     '|| ITEM.secondary_uom_code);   
--      logF('ITEM.secondary_unit_of_measure '|| ITEM.secondary_unit_of_measure);
--      logF('ITEM.secondary_quantity   '|| ITEM.secondary_quantity);
--      logF('ITEM.secondary_conversion    '|| ITEM.secondary_conversion);   
    END IF;  
        
    BEGIN          
     SELECT DTL.unit_price,
         DTL.unit_meas_lookup_code, 
         Po_Uom_S.po_uom_convert_p(ITEM.primary_unit_of_measure, DTL.unit_meas_lookup_code, ITEM.item_id)
     INTO   ITEM.unit_price,
         ITEM.unit_meas_lookup_code,         
         ITEM.conversion
     FROM   PO_LINES_ALL dtl
     WHERE  DTL.item_id = ITEM.item_id
     AND    DTL.po_header_id IN (
       SELECT po_header_id
       FROM   PO_HEADERS_ALL
       WHERE  type_lookup_code   = 'QUOTATION'
       AND    status_lookup_code = 'A'
       AND    vendor_site_id   =  VEND.vendor_site_id
       AND    vendor_id    =  VEND.vendor_id
       AND    TRUNC(SYSDATE) BETWEEN NVL(start_date, TO_DATE('01-JAN-1950')) AND NVL(end_date, TO_DATE('01-JAN-3004') )
       );
       
                 IF ITEM.conversion <= 0 THEN
       logF(cust_mesg(46).mesg);
       logF('Receipt No                '||RCV_HDR.receipt_num); 
       logF('ITEM.item_code       '||ITEM.item_code);
       logF('ITEM.conversion           '||ITEM.conversion);      
       logF('ITEM.primary_uom_code  '||ITEM.primary_uom_code);
       logF('DTL.unit_meas_lookup_code '||ITEM.unit_meas_lookup_code);      
       RAISE e_bohong;  
     ELSE
       ITEM.unit_price                := ITEM.unit_price * ITEM.conversion;               
     END IF;
     
--         ITEM.secondary_conversion := po_uom_s.po_uom_convert_p(ITEM.unit_meas_lookup_code, ITEM.secondary_unit_of_measure, ITEM.item_id);
--      ITEM.secondary_quantity   := ITEM.secondary_conversion * DTL.quantity;
--      
--      if ITEM.secondary_conversion <= 0 then
--       logF(cust_mesg(49).mesg); 
--       logF('Receipt No                     '|| RCV_HDR.receipt_num); 
--       logF('ITEM.item_code      '|| ITEM.item_code);
--       logF('ITEM.secondary_unit_of_measure '|| ITEM.secondary_unit_of_measure);
--       logF('ITEM.secondary_conversion    '|| ITEM.secondary_conversion);      
--       raise e_bohong;           
--      end if;            
--        
    EXCEPTION
       WHEN OTHERS THEN  
      logF(cust_mesg(44).mesg);       
      logF('Receipt No    '||RCV_HDR.receipt_num); 
      logF('DTL.item_code '||DTL.item_code);
      RAISE e_bohong;         
          END;                   
      
    IF g_debug = 'Y' THEN      
        logF('ITEM.unit_price       '||ITEM.unit_price);     
    END IF;    
    
                -----------------------------------------------------------------    
    
    -- DISTRIBUTIONS --

    SELECT PO_LINES_INTERFACE_S.NEXTVAL
    INTO   XXKHD_LINE.interface_line_id
    FROM   dual;

--     if g_debug = 'Y' then      
--         logF('DTL.ship_to_location_id           '||DTL.ship_to_location_id);     
--     end if;      
    
    XXKHD_LINE.ship_to_location := VEND.ship_to_location;
--     begin    
--      SELECT location_code
--      INTO   XXKHD_LINE.ship_to_location
--      FROM   hr_locations_all
--      WHERE  location_id = DTL.ship_to_location_id;
--     exception
--        when others then 
--       logF(cust_mesg(48).mesg);
--       logF('Receipt No              '||RCV_HDR.receipt_num); 
--       logF('DTL.ship_to_location_id '||ITEM.item_code);
--       raise e_bohong;         
--           end; 
        
    IF g_debug = 'Y' THEN      
        logF('XXKHD_LINE.ship_to_location       '||XXKHD_LINE.ship_to_location);     
    END IF;  
    
    SELECT organization_code
    INTO   XXKHD_LINE.ship_to_organization_code
    FROM   mtl_parameters
    WHERE  organization_id = VEND.ship_to_organization_id;
    
    IF g_debug = 'Y' THEN      
        logF('XXKHD_LINE.ship_to_organization_code       '||XXKHD_LINE.ship_to_organization_code);     
    END IF;     
    
    v_line_counter := v_line_counter + 1;

    XXKHD_LINE.interface_header_id      := XXKHD_HDR.interface_header_id;
    XXKHD_LINE.batch_id           := XXKHD_BATCH.batch_id;
    XXKHD_LINE.action           := g_dtl_action;
    XXKHD_LINE.line_type          := g_dtl_line_type;

    XXKHD_LINE.category_id         := ITEM.category_id;
    XXKHD_LINE.item_id           := ITEM.item_id;  
    XXKHD_LINE.item_code           := ITEM.item_code;  
    XXKHD_LINE.item_description         := ITEM.item_description;        
    XXKHD_LINE.unit_of_measure         := DTL.unit_of_measure;        
    XXKHD_LINE.quantity           := DTL.quantity;    
    XXKHD_LINE.unit_price          := ITEM.unit_price;
    XXKHD_LINE.promised_date         := SYSDATE;     

--    XXKHD_LINE.shipment_line_id         := DTL.shipment_line_id;
--    XXKHD_LINE.transaction_id         := DTL.transaction_id;
            
    XXKHD_LINE.created_by       := Fnd_Global.user_id;
    XXKHD_LINE.last_updated_by      := Fnd_Global.user_id;
    XXKHD_LINE.last_update_login     := Fnd_Global.login_id;
    XXKHD_LINE.last_update_date      := SYSDATE;
    XXKHD_LINE.creation_date      := SYSDATE;

    XXKHD_LINE.line_attribute_category_lines  := g_dtl_line_attribute_category;    
    XXKHD_LINE.line_attribute1      := DTL.item_code;
    XXKHD_LINE.line_attribute2      := XXKHD_LINE.quantity;
    XXKHD_LINE.line_attribute3      := XXKHD_BATCH.batch_id;
    XXKHD_LINE.line_attribute4      := XXKHD_LINE.interface_line_id;
    XXKHD_LINE.line_attribute5      := DTL.item_id;
    XXKHD_LINE.line_attribute6      := NULL;

    XXKHD_LINE.shipment_attribute_category   := g_dtl_shipment_attr_category;
    XXKHD_LINE.shipment_attribute1     := DTL.item_code;
    XXKHD_LINE.shipment_attribute2     := XXKHD_LINE.quantity;
    XXKHD_LINE.shipment_attribute3     := XXKHD_BATCH.batch_id;
    XXKHD_LINE.shipment_attribute4     := XXKHD_LINE.interface_line_id;
    XXKHD_LINE.shipment_attribute5     := DTL.item_id;
    XXKHD_LINE.shipment_attribute6     := NULL;

    -- DISTRIBUTIONS --

    SELECT PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL
    INTO   XXKHD_DIST.interface_distribution_id
    FROM   dual;

    XXKHD_DIST.interface_header_id    := XXKHD_HDR.interface_header_id;
    XXKHD_DIST.interface_line_id     := XXKHD_LINE.interface_line_id;
    XXKHD_DIST.batch_id       := XXKHD_BATCH.batch_id;

    XXKHD_DIST.charge_account_segment1   := ITEM.segment1;
    XXKHD_DIST.charge_account_segment2   := ITEM.segment2;
    XXKHD_DIST.charge_account_segment3   := ITEM.segment3;
    XXKHD_DIST.charge_account_segment5   := ITEM.segment5;
    XXKHD_DIST.charge_account_segment6   := ITEM.segment6;
    XXKHD_DIST.charge_account_segment7   := ITEM.segment7;
    XXKHD_DIST.charge_account_segment4   := VEND.segment4;

    SELECT MAX(code_combination_id)
    INTO   XXKHD_DIST.ccid
    FROM   gl_code_combinations
    WHERE  segment1 = XXKHD_DIST.charge_account_segment1
    AND    segment2 = XXKHD_DIST.charge_account_segment2
    AND    segment3 = XXKHD_DIST.charge_account_segment3
    AND    segment4 = XXKHD_DIST.charge_account_segment4
    AND    segment5 = XXKHD_DIST.charge_account_segment5
    AND    segment6 = XXKHD_DIST.charge_account_segment6
    AND    segment7 = XXKHD_DIST.charge_account_segment7;
    
    IF g_debug = 'Y' THEN      
        logF('XXKHD_DIST.ccid       '||XXKHD_DIST.ccid);     
    END IF;  
        
    XXKHD_DIST.distribution_num     := 1;
    XXKHD_DIST.quantity_ordered     := XXKHD_LINE.quantity;

    XXKHD_DIST.created_by       := Fnd_Global.user_id;
    XXKHD_DIST.last_updated_by      := Fnd_Global.user_id;
    XXKHD_DIST.last_update_login     := Fnd_Global.login_id;
    XXKHD_DIST.last_update_date      := SYSDATE;
    XXKHD_DIST.creation_date      := SYSDATE;

    XXKHD_DIST.attribute_category    := g_dist_attribute_category;
    XXKHD_DIST.attribute1      := NULL;
    XXKHD_DIST.attribute2      := NULL;
    XXKHD_DIST.attribute3      := XXKHD_BATCH.batch_id;
    XXKHD_DIST.attribute4      := XXKHD_DIST.interface_distribution_id;
    XXKHD_DIST.attribute5      := XXKHD_DIST.ccid;
    XXKHD_DIST.attribute6      := NULL;

       insert_XXKHD_PO_LINE(XXKHD_LINE);
       insert_XXKHD_PO_DIST(XXKHD_DIST);   

   END LOOP;  

   v_hdr_counter      := v_hdr_counter      + 1;
   v_tot_line_counter := v_tot_line_counter + v_line_counter; 

  END LOOP;
  
  p_batch_id := XXKHD_BATCH.batch_id;
 END;

------------------------------------------------------------------------------------------------
   PROCEDURE generate_po_service(
             p_errbuf          OUT VARCHAR2,
             p_retcode         OUT NUMBER,
             p_start_date         VARCHAR2,
             p_end_date         VARCHAR2,
             p_validate         VARCHAR2,
             p_debug          VARCHAR2) IS

  x_phase             VARCHAR2(20);   x_status            VARCHAR2(20);
  x_dev_phase         VARCHAR2(20);   x_dev_status        VARCHAR2(20);
  x_message         VARCHAR2(240);  v_wait_result    BOOLEAN;

  v_tot_hdr_counter      PLS_INTEGER DEFAULT 0;
  v_tot_line_counter     PLS_INTEGER DEFAULT 0;
  v_tot_dist_counter     PLS_INTEGER DEFAULT 0;
  v_tot_ship_counter     PLS_INTEGER DEFAULT 0;

  v_tot_hdr_err_counter  PLS_INTEGER DEFAULT 0;
  v_batch_status     XXKHD_po_batch.batch_status%TYPE;
  v_error_message     XXKHD_po_batch.message%TYPE;
  v_emp_name      per_all_people_f.full_name%TYPE;

  v_batch_id      PLS_INTEGER DEFAULT 0;
  v_std_rpt_request_id   PLS_INTEGER DEFAULT 0;
  v_iface_request_id     PLS_INTEGER DEFAULT 0;

 BEGIN
    logF('-----------------');
    logF('Request started');
    logF('-----------------');
    logF(' ');   

    g_debug      := p_debug;
    g_start_date := TO_DATE(p_start_date, 'RRRR/MM/DD HH24:MI:SS') ;
    g_end_date := TO_DATE(p_end_date,   'RRRR/MM/DD HH24:MI:SS') ;
    
    BEGIN
   SELECT EMP.full_name 
   INTO   v_emp_name
   FROM   fnd_user          USR,
       per_all_people_f  EMP
   WHERE  USR.user_id     = Fnd_Global.user_id
   AND    USR.employee_id = EMP.person_id       
   AND    TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date;
    EXCEPTION
         WHEN OTHERS THEN
     logF(cust_mesg(47).mesg);    
     RAISE e_exception;
    END;       
    
  --POPULATE and VALIDATE ONLY ------------------------------------------------------------------------------------------------------------------------------------------------

  populate_XXKHD_temp(v_batch_id);  
  populate_iface(v_batch_id, v_tot_hdr_counter, v_tot_line_counter, v_tot_dist_counter);
      
     IF v_tot_dist_counter = 0 THEN  
       logF(cust_mesg(4).mesg);
    
       RAISE e_exception;
    
        ELSIF NVL(p_validate,'N') = 'Y' THEN  
    IF g_debug = 'Y' THEN
      logF('Print Output');
       END IF;
       print_output(v_batch_id);
    
    IF g_debug = 'Y' THEN 
       ROLLBACK;logF(cust_mesg(2).mesg);
    END IF;
    
    logF(cust_mesg(3).mesg);        
    RAISE e_exception;
  END IF;  
    
  IF g_debug = 'Y' THEN
       logF('Batch status : POPULATED');
  END IF;
      
  --SUBMISSION ------------------------------------------------------------------------------------------------------------------------------------------------

  v_iface_request_id := Fnd_Request.SUBMIT_REQUEST(
            g_std_iface_appl,
            g_std_iface,
            'XXKHD '||v_batch_id ||'-'|| TO_CHAR(g_start_date,'DD-MON-RRRR') || '/' || TO_CHAR(g_end_date,'DD-MON-RRRR'),
            SYSDATE + 2/24/60/60,
            FALSE,
         -------
          NULL,           --source
         'STANDARD',         --doc type
          NULL,           --doc subtype
         'N',          --Update item
          NULL,           --Create Sourcing Rules
         'INCOMPLETE',           --Approval Status
          NULL,           --Release Generation Method
          v_batch_id,
          NULL,           --doc subtype
          NULL);  
  
     IF v_iface_request_id = 0 THEN
       logF(cust_mesg(5).mesg);
    ROLLBACK; logF(cust_mesg(2).mesg);
       RAISE e_exception;
        END IF;

  UPDATE XXKHD_po_batch
  SET    batch_status    = 'IN PROCESS',
      iface_request_id   = v_iface_request_id,
      iface_header_count = v_tot_hdr_counter,
      iface_line_count   = v_tot_line_counter,
      iface_dist_count   = v_tot_dist_counter
  WHERE  batch_id = v_batch_id;

  UPDATE XXKHD_po_hdr
  SET    po_status = 'IN PROCESS'
  WHERE  batch_id  = v_batch_id;
    
  IF g_debug = 'Y' THEN
       logF('Request ID '||v_iface_request_id);  
       logF('Batch status : IN PROCESS');
  END IF;
  
  COMMIT; logF(cust_mesg(1).mesg);
  logF(cust_mesg(6).mesg);

  --REQUEST------------------------------------------------------------------------------------------------------------------------------------------------
  v_wait_result := Fnd_Concurrent.WAIT_FOR_REQUEST(
        v_iface_request_id, g_intval_time,   g_max_time,
        x_phase,         x_status,        x_dev_phase,
        x_dev_status,    x_message);

     IF NOT (x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL') THEN
       logF(cust_mesg(7).mesg);
    logF(cust_mesg(20).mesg); RAISE e_exception;
        END IF;

  --SYNCHRONIZED RESULTS ------------------------------------------------------------------------------------------------------------------------------------------------
  v_tot_hdr_err_counter := v_tot_hdr_counter;
  v_tot_hdr_counter     := 0;       
  logF(' '); logF(' ');
   
  FOR ora IN trx_hdr_cur(v_batch_id) LOOP 

    IF g_debug = 'Y' THEN
         logF('Interface_header_id '||ORA.interface_header_id);
      logF('New PO '||ORA.po_number);
      logF(' ');    
    END IF;
    
    UPDATE XXKHD_PO_HDR
    SET    po_status     = 'SUCCESS',
        po_number  = ORA.po_number,
        po_header_id  = ORA.po_header_id
    WHERE  interface_header_id = ORA.interface_header_id;
    
    IF g_debug = 'Y' THEN
         logF(SQL%rowcount || ' record in XXKHD_PO_HDR updated');
    END IF;
         
    UPDATE RCV_SHIPMENT_HEADERS
    SET    attribute3 = 'PROCCESSED',
        attribute4 = v_batch_id
    WHERE  shipment_header_id IN ( 
             SELECT shipment_header_id
       FROM XXKHD_PO_HDR
       WHERE interface_header_id = ORA.interface_header_id);       
    
    IF g_debug = 'Y' THEN
         logF(SQL%rowcount || ' record in RCV_SHIPMENT_HEADERS updated');
    END IF;
    
    UPDATE RCV_SHIPMENT_LINES
    SET    attribute3 = 'PROCCESSED',
        attribute4 = v_batch_id
    WHERE  shipment_header_id IN ( 
             SELECT shipment_header_id
       FROM XXKHD_PO_HDR
       WHERE interface_header_id = ORA.interface_header_id);          
    
    IF g_debug = 'Y' THEN
         logF(SQL%rowcount || ' record in RCV_SHIPMENT_LINES updated');
    END IF;
    
    UPDATE RCV_TRANSACTIONS
    SET    attribute3 = 'PROCCESSED',
        attribute4 = v_batch_id
    WHERE  transaction_id IN (
             SELECT transaction_id
       FROM XXKHD_PO_LINE 
       WHERE interface_header_id = ORA.interface_header_id);  
    
    IF g_debug = 'Y' THEN
         logF(SQL%rowcount || ' record in RCV_TRANSACTIONS updated');
    END IF;
                        
       v_tot_hdr_counter := v_tot_hdr_counter + 1;
  END LOOP;

  IF v_tot_hdr_counter = 0 THEN
      logF(cust_mesg(9).mesg);
   logF(cust_mesg(20).mesg);
  ELSE

      v_tot_hdr_err_counter := 0;
   FOR PO_HDR IN hdr_status_cur(v_batch_id) LOOP

         IF PO_HDR.po_status <> 'SUCCESS' THEN
        v_error_message := 'ERROR';

      UPDATE XXKHD_PO_HDR
      SET    po_status     = 'ERROR',
           message      = v_error_message
      WHERE  interface_header_id = PO_HDR.interface_header_id;

            v_tot_hdr_err_counter := v_tot_hdr_err_counter + 1;
      END IF;

   END LOOP;

   v_tot_line_counter := 0;
   FOR ora IN trx_line_cur(v_batch_id) LOOP
      UPDATE XXKHD_PO_LINE
      SET  po_line_id  = ORA.po_line_id
      WHERE  interface_line_id = ORA.interface_line_id;

      v_tot_line_counter := v_tot_line_counter + 1;
   END LOOP;

   v_tot_ship_counter := 0;
   FOR ora IN trx_ship_cur(v_batch_id) LOOP
      UPDATE XXKHD_PO_LINE
      SET  line_location_id  = ORA.line_location_id
      WHERE  interface_line_id = ORA.interface_line_id;

      v_tot_ship_counter := v_tot_ship_counter + 1;
   END LOOP;

   v_tot_dist_counter := 0;
   FOR ora IN trx_dist_cur(v_batch_id) LOOP
      UPDATE XXKHD_PO_DIST
      SET    po_distribution_id  = ORA.po_distribution_id
      WHERE  interface_distribution_id = ORA.interface_distribution_id;

      v_tot_dist_counter := v_tot_dist_counter + 1;
   END LOOP;

  END IF;

  --SYNCHRONIZED BATCH ------------------------------------------------------------------------------------------------------------------------------------------------

     v_std_rpt_request_id := Fnd_Request.SUBMIT_REQUEST(
                g_std_rpt_appl,
          g_std_rpt,
          'XXKHD '||v_batch_id,
          SYSDATE,
          FALSE,
          -------------
          'PO_DOCS_OPEN_INTERFACE',
           'Y');  
          
  IF v_std_rpt_request_id > 0 THEN
   logF(cust_mesg(11).mesg);
   logF('Request ID '||v_std_rpt_request_id);
  END IF;

  UPDATE XXKHD_po_batch
  SET    batch_status      = DECODE(v_tot_hdr_err_counter,
                                       0, 'SUCCESS',
                                          DECODE(v_tot_hdr_counter,
                   0, 'ERROR',
                'PARTIAL SUCCESS')
           ),
      std_rpt_request_id = v_std_rpt_request_id,
      iface_request_id  = v_iface_request_id,      
      success_header_count = v_tot_hdr_counter,
      success_line_count   = v_tot_line_counter,
      success_dist_count   = v_tot_dist_counter
  WHERE  batch_id = v_batch_id;
  
  IF g_debug = 'Y' THEN
       IF v_tot_hdr_err_counter = 0 THEN 
            logF('Batch status : SUCCESS');
    ELSE
       IF v_tot_hdr_counter = 0 THEN
        logF('Batch status : ERROR');
    ELSE
        logF('Batch status : PARTIAL SUCCESS');
    END IF;
    END IF;    
  END IF;
    
  COMMIT; logF(cust_mesg(1).mesg);
  logF(cust_mesg(8).mesg);
  
  print_output(v_batch_id);

  logF(' ');
  logF('-----------------');
  logF('Request completed');
  logF('-----------------');

 EXCEPTION
     WHEN e_exception THEN
  
       logF(' ');
    logF('-----------------');
    logF('Request completed');
    logF('-----------------');
   
     WHEN OTHERS THEN
    
    logF(' ');
    logF('-----------------');
    logF('Request failed');
    logF('-----------------');
    
    logF(SQLCODE||'-'||SQLERRM);
  
          ROLLBACK; logF(cust_mesg(2).mesg);

--     UPDATE RCV_SHIPMENT_HEADERS
--     SET    attribute3 = 'FAILED'
--     WHERE  attribute4 = v_batch_id;       
--     
--     if g_debug = 'Y' then
--          logF(sql%rowcount || ' failed record in RCV_SHIPMENT_HEADERS updated');
--     end if;
--     
--     UPDATE RCV_SHIPMENT_LINES
--     SET    attribute3 = 'FAILED'
--     WHERE  attribute4 = v_batch_id;           
--     
--     if g_debug = 'Y' then
--          logF(sql%rowcount || ' failed record in RCV_SHIPMENT_LINES updated');
--     end if;
--     
--     UPDATE RCV_TRANSACTIONS
--     SET    attribute3 = 'FAILED'
--     WHERE  attribute4 = v_batch_id;  
--     
--     if g_debug = 'Y' then
--          logF(sql%rowcount || ' failed record in RCV_TRANSACTIONS updated');
--     end if;
    
    UPDATE XXKHD_PO_BATCH
    SET    batch_status = 'ERROR'
    WHERE  batch_id  = v_batch_id;
        
    IF g_debug = 'Y' THEN
         logF(SQL%rowcount || ' failed batch in XXKHD_PO_BATCH updated');
    END IF;
        
    COMMIT; logF(cust_mesg(1).mesg);  
    
          RAISE e_exception;
 END;

------------------------------------------------------------------------------------------------

BEGIN

      SELECT hazard_class_id
      INTO   g_hazard_class_id
      FROM   PO_HAZARD_CLASSES_TL
      WHERE  hazard_class = g_hazard_class
      AND    LANGUAGE     = USERENV('LANG');
   
   SELECT currency_code
   INTO   g_currency_code
   FROM   GL_SETS_OF_BOOKS
   WHERE  set_of_books_id = g_set_of_books_id;

   cust_mesg(1).mesg  := 'COMMIT EXECUTED';
   cust_mesg(2).mesg  := 'ROLLBACK EXECUTED';
   cust_mesg(3).mesg  := 'VALIDATION COMPLETED';
   cust_mesg(4).mesg  := 'NO RECEIVING TRANSACTIONS FOUND';

   cust_mesg(5).mesg  := 'IMPORT CONCURRENT SUBMISSION FAILED';
   cust_mesg(6).mesg  := 'IMPORT PO REQUEST SUBMITTED';
   cust_mesg(7).mesg  := 'IMPORT PO REQUEST FAILED';
   cust_mesg(8).mesg  := 'IMPORT PO PROCESS COMPLETED';
   cust_mesg(9).mesg  := 'NO PO SUCCESSFULLY IMPORTED';

   cust_mesg(11).mesg := 'STANDARD PO INTERFACE ERROR REPORT SUBMITTED';
   cust_mesg(12).mesg := 'PO SERVICE REGISTER REPORT SUBMITTED';

   cust_mesg(20).mesg := 'PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR';
   
   cust_mesg(33).mesg := 'MAPPING ORGANIZATION TO VENDOR NOT FOUND';
   cust_mesg(34).mesg := 'INVALID VENDOR';            
   
   cust_mesg(41).mesg := 'TOLL FEE HIERARCHY TYPE NOT EXISTS';
   cust_mesg(42).mesg := 'ITEM CODE MAPPING NOT EXISTS';
   cust_mesg(43).mesg := 'NO VALID ITEM FOUND FOR MAPPED ITEM CODE';
   cust_mesg(44).mesg := 'NO VALID UNIT PRICE FOUND';
   cust_mesg(45).mesg := 'NO VALID PURCHASING ITEM CATEGORY FOUND';
   cust_mesg(46).mesg := 'NO VALID PURCHASING ITEM CONVERSION FOUND';
   cust_mesg(47).mesg := 'NO EMPLOYEE FOUND FOR CURRENT USER';
   cust_mesg(48).mesg := 'NO VALID ORGANIZATION LOCATION FOUND';
   cust_mesg(49).mesg := 'NO VALID SECONDARY UOM CONVERSION FOUND';                        

END; 
/

