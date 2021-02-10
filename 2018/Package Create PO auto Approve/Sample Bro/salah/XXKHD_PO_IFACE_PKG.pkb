CREATE OR REPLACE PACKAGE BODY APPS.XXKHD_PO_IFACE_PKG
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

   PROCEDURE insert_po_headers (rec IN po_headers_interface%ROWTYPE)
   IS
   BEGIN
      INSERT INTO po_headers_interface
                  (interface_header_id, batch_id, interface_source_code, process_code, action, group_code, org_id,
                   document_type_code, document_subtype, document_num, po_header_id, release_num, po_release_id,
                   release_date, currency_code, rate_type, rate_type_code, rate_date, rate, agent_name, agent_id,
                   vendor_name, vendor_id, vendor_site_code, vendor_site_id, vendor_contact, vendor_contact_id,
                   ship_to_location, ship_to_location_id, bill_to_location, bill_to_location_id, payment_terms, terms_id,
                   freight_carrier, fob, freight_terms, approval_status, approved_date, revised_date, revision_num,
                   note_to_vendor, note_to_receiver, confirming_order_flag, comments, acceptance_required_flag,
                   acceptance_due_date, amount_agreed, amount_limit, min_release_amount, effective_date, expiration_date,
                   print_count, printed_date, firm_flag, frozen_flag, closed_code, closed_date, reply_date,
                   reply_method, rfq_close_date, quote_warning_delay, vendor_doc_num, approval_required_flag, vendor_list,
                   vendor_list_header_id, from_header_id, from_type_lookup_code, ussgl_transaction_code, attribute_category,
                   attribute1, attribute2, attribute3, attribute4, attribute5, attribute6, attribute7, attribute8,
                   attribute9, attribute10, attribute11, attribute12, attribute13, attribute14, attribute15,
                   creation_date, created_by, last_update_date, last_updated_by, last_update_login, request_id,
                   program_application_id, program_id, program_update_date, reference_num, load_sourcing_rules_flag,
                   vendor_num, from_rfq_num, wf_group_id, pcard_id, pay_on_code, global_agreement_flag,
                   consume_req_demand_flag, shipping_control, encumbrance_required_flag, amount_to_encumber, change_summary,
                   budget_account_segment1, budget_account_segment2, budget_account_segment3, budget_account_segment4,
                   budget_account_segment5, budget_account_segment6, budget_account_segment7, budget_account_segment8,
                   budget_account_segment9, budget_account_segment10, budget_account_segment11, budget_account_segment12,
                   budget_account_segment13, budget_account_segment14, budget_account_segment15, budget_account_segment16,
                   budget_account_segment17, budget_account_segment18, budget_account_segment19, budget_account_segment20,
                   budget_account_segment21, budget_account_segment22, budget_account_segment23, budget_account_segment24,
                   budget_account_segment25, budget_account_segment26, budget_account_segment27, budget_account_segment28,
                   budget_account_segment29, budget_account_segment30, budget_account, budget_account_id, gl_encumbered_date,
                   gl_encumbered_period_name, created_language, cpa_reference, draft_id, processing_id,
                   processing_round_num, original_po_header_id, style_id, style_display_name, clm_standard_form,
                   clm_document_format, clm_award_type, clm_source_document_id, clm_effective_date, clm_vendor_offer_number,
                   clm_award_administrator, clm_no_signed_copies_to_return, clm_min_guarantee_award_amt,
                   clm_min_guar_award_amt_percent, clm_min_order_amount, clm_max_order_amount, clm_amount_released,
                   clm_external_idv, umbrella_program_id, fon_ref_id, clm_award_type_disp, clm_award_administrator_disp,
                   clm_contract_officer_disp, clm_contract_officer, clm_source_document_disp, clm_contract_finance_code,
                   clm_payment_instr_code, clm_special_contract_type, document_creation_method, supply_agreement_flag
                  )
           VALUES (rec.interface_header_id, rec.batch_id, rec.interface_source_code, rec.process_code, rec.action, rec.group_code, rec.org_id,
                   rec.document_type_code, rec.document_subtype, rec.document_num, rec.po_header_id, rec.release_num, rec.po_release_id,
                   rec.release_date, rec.currency_code, rec.rate_type, rec.rate_type_code, rec.rate_date, rec.rate, rec.agent_name, rec.agent_id,
                   rec.vendor_name, rec.vendor_id, rec.vendor_site_code, rec.vendor_site_id, rec.vendor_contact, rec.vendor_contact_id,
                   rec.ship_to_location, rec.ship_to_location_id, rec.bill_to_location, rec.bill_to_location_id, rec.payment_terms, rec.terms_id,
                   rec.freight_carrier, rec.fob, rec.freight_terms, rec.approval_status, rec.approved_date, rec.revised_date, rec.revision_num,
                   rec.note_to_vendor, rec.note_to_receiver, rec.confirming_order_flag, rec.comments, rec.acceptance_required_flag,
                   rec.acceptance_due_date, rec.amount_agreed, rec.amount_limit, rec.min_release_amount, rec.effective_date, rec.expiration_date,
                   rec.print_count, rec.printed_date, rec.firm_flag, rec.frozen_flag, rec.closed_code, rec.closed_date, rec.reply_date,
                   rec.reply_method, rec.rfq_close_date, rec.quote_warning_delay, rec.vendor_doc_num, rec.approval_required_flag, rec.vendor_list,
                   rec.vendor_list_header_id, rec.from_header_id, rec.from_type_lookup_code, rec.ussgl_transaction_code, rec.attribute_category,
                   rec.attribute1, rec.attribute2, rec.attribute3, rec.attribute4, rec.attribute5, rec.attribute6, rec.attribute7, rec.attribute8,
                   rec.attribute9, rec.attribute10, rec.attribute11, rec.attribute12, rec.attribute13, rec.attribute14, rec.attribute15,
                   rec.creation_date, rec.created_by, rec.last_update_date, rec.last_updated_by, rec.last_update_login, rec.request_id,
                   rec.program_application_id, rec.program_id, rec.program_update_date, rec.reference_num, rec.load_sourcing_rules_flag,
                   rec.vendor_num, rec.from_rfq_num, rec.wf_group_id, rec.pcard_id, rec.pay_on_code, rec.global_agreement_flag,
                   rec.consume_req_demand_flag, rec.shipping_control, rec.encumbrance_required_flag, rec.amount_to_encumber, rec.change_summary,
                   rec.budget_account_segment1, rec.budget_account_segment2, rec.budget_account_segment3, rec.budget_account_segment4,
                   rec.budget_account_segment5, rec.budget_account_segment6, rec.budget_account_segment7, rec.budget_account_segment8,
                   rec.budget_account_segment9, rec.budget_account_segment10, rec.budget_account_segment11, rec.budget_account_segment12,
                   rec.budget_account_segment13, rec.budget_account_segment14, rec.budget_account_segment15, rec.budget_account_segment16,
                   rec.budget_account_segment17, rec.budget_account_segment18, rec.budget_account_segment19, rec.budget_account_segment20,
                   rec.budget_account_segment21, rec.budget_account_segment22, rec.budget_account_segment23, rec.budget_account_segment24,
                   rec.budget_account_segment25, rec.budget_account_segment26, rec.budget_account_segment27, rec.budget_account_segment28,
                   rec.budget_account_segment29, rec.budget_account_segment30, rec.budget_account, rec.budget_account_id, rec.gl_encumbered_date,
                   rec.gl_encumbered_period_name, rec.created_language, rec.cpa_reference, rec.draft_id, rec.processing_id,
                   rec.processing_round_num, rec.original_po_header_id, rec.style_id, rec.style_display_name, rec.clm_standard_form,
                   rec.clm_document_format, rec.clm_award_type, rec.clm_source_document_id, rec.clm_effective_date, rec.clm_vendor_offer_number,
                   rec.clm_award_administrator, rec.clm_no_signed_copies_to_return, rec.clm_min_guarantee_award_amt,
                   rec.clm_min_guar_award_amt_percent, rec.clm_min_order_amount, rec.clm_max_order_amount, rec.clm_amount_released,
                   rec.clm_external_idv, rec.umbrella_program_id, rec.fon_ref_id, rec.clm_award_type_disp, rec.clm_award_administrator_disp,
                   rec.clm_contract_officer_disp, rec.clm_contract_officer, rec.clm_source_document_disp, rec.clm_contract_finance_code,
                   rec.clm_payment_instr_code, rec.clm_special_contract_type, rec.document_creation_method, rec.supply_agreement_flag
                  );
   END insert_po_headers;

   PROCEDURE insert_po_lines (rec IN po_lines_interface%ROWTYPE)
   IS
   BEGIN
      INSERT INTO po_lines_interface
                  (interface_line_id, interface_header_id, action, group_code, line_num, po_line_id, shipment_num,
                   line_location_id, shipment_type, requisition_line_id, document_num, release_num, po_header_id,
                   po_release_id, source_shipment_id, contract_num, line_type, line_type_id, item, item_id,
                   item_revision, CATEGORY, category_id, item_description, vendor_product_num, uom_code,
                   unit_of_measure, quantity, committed_amount, min_order_quantity, max_order_quantity, unit_price,
                   list_price_per_unit, market_price, allow_price_override_flag, not_to_exceed_price,
                   negotiated_by_preparer_flag, un_number, un_number_id, hazard_class, hazard_class_id, note_to_vendor,
                   transaction_reason_code, taxable_flag, tax_name, type_1099, capital_expense_flag,
                   inspection_required_flag, receipt_required_flag, payment_terms, terms_id, price_type, min_release_amount,
                   price_break_lookup_code, ussgl_transaction_code, closed_code, closed_reason, closed_date, closed_by,
                   invoice_close_tolerance, receive_close_tolerance, firm_flag, days_early_receipt_allowed,
                   days_late_receipt_allowed, enforce_ship_to_location_code, allow_substitute_receipts_flag, receiving_routing,
                   receiving_routing_id, qty_rcv_tolerance, over_tolerance_error_flag, qty_rcv_exception_code,
                   receipt_days_exception_code, ship_to_organization_code, ship_to_organization_id, ship_to_location,
                   ship_to_location_id, need_by_date, promised_date, accrue_on_receipt_flag, lead_time, lead_time_unit,
                   price_discount, freight_carrier, fob, freight_terms, effective_date, expiration_date, from_header_id,
                   from_line_id, from_line_location_id, line_attribute_category_lines, line_attribute1, line_attribute2,
                   line_attribute3, line_attribute4, line_attribute5, line_attribute6, line_attribute7, line_attribute8,
                   line_attribute9, line_attribute10, line_attribute11, line_attribute12, line_attribute13,
                   line_attribute14, line_attribute15, shipment_attribute_category, shipment_attribute1, shipment_attribute2,
                   shipment_attribute3, shipment_attribute4, shipment_attribute5, shipment_attribute6, shipment_attribute7,
                   shipment_attribute8, shipment_attribute9, shipment_attribute10, shipment_attribute11, shipment_attribute12,
                   shipment_attribute13, shipment_attribute14, shipment_attribute15, last_update_date, last_updated_by,
                   last_update_login, creation_date, created_by, request_id, program_application_id, program_id,
                   program_update_date, organization_id, item_attribute_category, item_attribute1, item_attribute2,
                   item_attribute3, item_attribute4, item_attribute5, item_attribute6, item_attribute7, item_attribute8,
                   item_attribute9, item_attribute10, item_attribute11, item_attribute12, item_attribute13,
                   item_attribute14, item_attribute15, unit_weight, weight_uom_code, volume_uom_code, unit_volume,
                   template_id, template_name, line_reference_num, sourcing_rule_name, tax_status_indicator, process_code,
                   price_chg_accept_flag, price_break_flag, price_update_tolerance, tax_user_override_flag, tax_code_id,
                   note_to_receiver, oke_contract_header_id, oke_contract_header_num, oke_contract_version_id,
                   secondary_unit_of_measure, secondary_uom_code, secondary_quantity, preferred_grade, vmi_flag,
                   auction_header_id, auction_line_number, auction_display_number, bid_number, bid_line_number,
                   orig_from_req_flag, consigned_flag, supplier_ref_number, contract_id, job_id, amount, job_name,
                   contractor_first_name, contractor_last_name, drop_ship_flag, base_unit_price, transaction_flow_header_id,
                   job_business_group_id, job_business_group_name, catalog_name, supplier_part_auxid, ip_category_id,
                   tracking_quantity_ind, secondary_default_ind, dual_uom_deviation_high, dual_uom_deviation_low, processing_id,
                   line_loc_populated_flag, ip_category_name, retainage_rate, max_retainage_amount, progress_payment_rate,
                   recoupment_rate, advance_amount, file_line_number, parent_interface_line_id, file_line_language,
                   group_line_id, line_num_display, clm_info_flag, clm_option_indicator, clm_base_line_num, clm_option_num,
                   clm_option_from_date, clm_option_to_date, clm_funded_flag, contract_type, cost_constraint, clm_idc_type,
                   user_document_status, clm_exercised_flag, clm_exercised_date, clm_min_total_amount, clm_max_total_amount,
                   clm_min_total_quantity, clm_max_total_quantity, clm_min_order_amount, clm_max_order_amount,
                   clm_min_order_quantity, clm_max_order_quantity, clm_total_amount_ordered, clm_total_quantity_ordered,
                   clm_period_perf_end_date, clm_period_perf_start_date, contract_type_display, cost_constraint_display,
                   clm_idc_type_display, clm_base_line_num_disp, from_header_disp, from_line_disp, clm_approved_undef_amount,
                   clm_delivery_event_code, clm_delivery_period, clm_delivery_period_uom, clm_exhibit_name,
                   clm_payment_instr_code, clm_pop_duration, clm_pop_duration_uom, clm_pop_exception_reason, clm_promise_period,
                   clm_promise_period_uom, clm_uda_pricing_total, clm_undef_action_code, clm_undef_flag, schedules_required_flag
                  )
           VALUES (rec.interface_line_id, rec.interface_header_id, rec.action, rec.group_code, rec.line_num, rec.po_line_id, rec.shipment_num,
                   rec.line_location_id, rec.shipment_type, rec.requisition_line_id, rec.document_num, rec.release_num, rec.po_header_id,
                   rec.po_release_id, rec.source_shipment_id, rec.contract_num, rec.line_type, rec.line_type_id, rec.item, rec.item_id,
                   rec.item_revision, rec.CATEGORY, rec.category_id, rec.item_description, rec.vendor_product_num, rec.uom_code,
                   rec.unit_of_measure, rec.quantity, rec.committed_amount, rec.min_order_quantity, rec.max_order_quantity, rec.unit_price,
                   rec.list_price_per_unit, rec.market_price, rec.allow_price_override_flag, rec.not_to_exceed_price,
                   rec.negotiated_by_preparer_flag, rec.un_number, rec.un_number_id, rec.hazard_class, rec.hazard_class_id, rec.note_to_vendor,
                   rec.transaction_reason_code, rec.taxable_flag, rec.tax_name, rec.type_1099, rec.capital_expense_flag,
                   rec.inspection_required_flag, rec.receipt_required_flag, rec.payment_terms, rec.terms_id, rec.price_type, rec.min_release_amount,
                   rec.price_break_lookup_code, rec.ussgl_transaction_code, rec.closed_code, rec.closed_reason, rec.closed_date, rec.closed_by,
                   rec.invoice_close_tolerance, rec.receive_close_tolerance, rec.firm_flag, rec.days_early_receipt_allowed,
                   rec.days_late_receipt_allowed, rec.enforce_ship_to_location_code, rec.allow_substitute_receipts_flag, rec.receiving_routing,
                   rec.receiving_routing_id, rec.qty_rcv_tolerance, rec.over_tolerance_error_flag, rec.qty_rcv_exception_code,
                   rec.receipt_days_exception_code, rec.ship_to_organization_code, rec.ship_to_organization_id, rec.ship_to_location,
                   rec.ship_to_location_id, rec.need_by_date, rec.promised_date, rec.accrue_on_receipt_flag, rec.lead_time, rec.lead_time_unit,
                   rec.price_discount, rec.freight_carrier, rec.fob, rec.freight_terms, rec.effective_date, rec.expiration_date, rec.from_header_id,
                   rec.from_line_id, rec.from_line_location_id, rec.line_attribute_category_lines, rec.line_attribute1, rec.line_attribute2,
                   rec.line_attribute3, rec.line_attribute4, rec.line_attribute5, rec.line_attribute6, rec.line_attribute7, rec.line_attribute8,
                   rec.line_attribute9, rec.line_attribute10, rec.line_attribute11, rec.line_attribute12, rec.line_attribute13,
                   rec.line_attribute14, rec.line_attribute15, rec.shipment_attribute_category, rec.shipment_attribute1, rec.shipment_attribute2,
                   rec.shipment_attribute3, rec.shipment_attribute4, rec.shipment_attribute5, rec.shipment_attribute6, rec.shipment_attribute7,
                   rec.shipment_attribute8, rec.shipment_attribute9, rec.shipment_attribute10, rec.shipment_attribute11, rec.shipment_attribute12,
                   rec.shipment_attribute13, rec.shipment_attribute14, rec.shipment_attribute15, rec.last_update_date, rec.last_updated_by,
                   rec.last_update_login, rec.creation_date, rec.created_by, rec.request_id, rec.program_application_id, rec.program_id,
                   rec.program_update_date, rec.organization_id, rec.item_attribute_category, rec.item_attribute1, rec.item_attribute2,
                   rec.item_attribute3, rec.item_attribute4, rec.item_attribute5, rec.item_attribute6, rec.item_attribute7, rec.item_attribute8,
                   rec.item_attribute9, rec.item_attribute10, rec.item_attribute11, rec.item_attribute12, rec.item_attribute13,
                   rec.item_attribute14, rec.item_attribute15, rec.unit_weight, rec.weight_uom_code, rec.volume_uom_code, rec.unit_volume,
                   rec.template_id, rec.template_name, rec.line_reference_num, rec.sourcing_rule_name, rec.tax_status_indicator, rec.process_code,
                   rec.price_chg_accept_flag, rec.price_break_flag, rec.price_update_tolerance, rec.tax_user_override_flag, rec.tax_code_id,
                   rec.note_to_receiver, rec.oke_contract_header_id, rec.oke_contract_header_num, rec.oke_contract_version_id,
                   rec.secondary_unit_of_measure, rec.secondary_uom_code, rec.secondary_quantity, rec.preferred_grade, rec.vmi_flag,
                   rec.auction_header_id, rec.auction_line_number, rec.auction_display_number, rec.bid_number, rec.bid_line_number,
                   rec.orig_from_req_flag, rec.consigned_flag, rec.supplier_ref_number, rec.contract_id, rec.job_id, rec.amount, rec.job_name,
                   rec.contractor_first_name, rec.contractor_last_name, rec.drop_ship_flag, rec.base_unit_price, rec.transaction_flow_header_id,
                   rec.job_business_group_id, rec.job_business_group_name, rec.catalog_name, rec.supplier_part_auxid, rec.ip_category_id,
                   rec.tracking_quantity_ind, rec.secondary_default_ind, rec.dual_uom_deviation_high, rec.dual_uom_deviation_low, rec.processing_id,
                   rec.line_loc_populated_flag, rec.ip_category_name, rec.retainage_rate, rec.max_retainage_amount, rec.progress_payment_rate,
                   rec.recoupment_rate, rec.advance_amount, rec.file_line_number, rec.parent_interface_line_id, rec.file_line_language,
                   rec.group_line_id, rec.line_num_display, rec.clm_info_flag, rec.clm_option_indicator, rec.clm_base_line_num, rec.clm_option_num,
                   rec.clm_option_from_date, rec.clm_option_to_date, rec.clm_funded_flag, rec.contract_type, rec.cost_constraint, rec.clm_idc_type,
                   rec.user_document_status, rec.clm_exercised_flag, rec.clm_exercised_date, rec.clm_min_total_amount, rec.clm_max_total_amount,
                   rec.clm_min_total_quantity, rec.clm_max_total_quantity, rec.clm_min_order_amount, rec.clm_max_order_amount,
                   rec.clm_min_order_quantity, rec.clm_max_order_quantity, rec.clm_total_amount_ordered, rec.clm_total_quantity_ordered,
                   rec.clm_period_perf_end_date, rec.clm_period_perf_start_date, rec.contract_type_display, rec.cost_constraint_display,
                   rec.clm_idc_type_display, rec.clm_base_line_num_disp, rec.from_header_disp, rec.from_line_disp, rec.clm_approved_undef_amount,
                   rec.clm_delivery_event_code, rec.clm_delivery_period, rec.clm_delivery_period_uom, rec.clm_exhibit_name,
                   rec.clm_payment_instr_code, rec.clm_pop_duration, rec.clm_pop_duration_uom, rec.clm_pop_exception_reason, rec.clm_promise_period,
                   rec.clm_promise_period_uom, rec.clm_uda_pricing_total, rec.clm_undef_action_code, rec.clm_undef_flag, rec.schedules_required_flag
                  );
   END insert_po_lines;

   PROCEDURE insert_po_dist (rec IN po_distributions_interface%ROWTYPE)
   IS
   BEGIN
      INSERT INTO po_distributions_interface
                  (interface_header_id, interface_line_id, interface_distribution_id, po_header_id, po_release_id,
                   po_line_id, line_location_id, po_distribution_id, distribution_num, source_distribution_id, org_id,
                   quantity_ordered, quantity_delivered, quantity_billed, quantity_cancelled, rate_date, rate,
                   deliver_to_location, deliver_to_location_id, deliver_to_person_full_name, deliver_to_person_id,
                   destination_type, destination_type_code, destination_organization, destination_organization_id,
                   destination_subinventory, destination_context, set_of_books, set_of_books_id, charge_account,
                   charge_account_id, budget_account, budget_account_id, accural_account, accrual_account_id,
                   variance_account, variance_account_id, amount_billed, accrue_on_receipt_flag, accrued_flag,
                   prevent_encumbrance_flag, encumbered_flag, encumbered_amount, unencumbered_quantity, unencumbered_amount,
                   failed_funds, failed_funds_lookup_code, gl_encumbered_date, gl_encumbered_period_name, gl_cancelled_date,
                   gl_closed_date, req_header_reference_num, req_line_reference_num, req_distribution_id, wip_entity,
                   wip_entity_id, wip_operation_seq_num, wip_resource_seq_num, wip_repetitive_schedule,
                   wip_repetitive_schedule_id, wip_line_code, wip_line_id, bom_resource_code, bom_resource_id,
                   ussgl_transaction_code, government_context, project, project_id, task, task_id, end_item_unit_number,
                   expenditure, expenditure_type, project_accounting_context, expenditure_organization,
                   expenditure_organization_id, project_releated_flag, expenditure_item_date, attribute_category, attribute1,
                   attribute2, attribute3, attribute4, attribute5, attribute6, attribute7, attribute8, attribute9,
                   attribute10, attribute11, attribute12, attribute13, attribute14, attribute15, last_update_date,
                   last_updated_by, last_update_login, creation_date, created_by, request_id, program_application_id,
                   program_id, program_update_date, recoverable_tax, nonrecoverable_tax, recovery_rate,
                   tax_recovery_override_flag, award_id, charge_account_segment1, charge_account_segment2,
                   charge_account_segment3, charge_account_segment4, charge_account_segment5, charge_account_segment6,
                   charge_account_segment7, charge_account_segment8, charge_account_segment9, charge_account_segment10,
                   charge_account_segment11, charge_account_segment12, charge_account_segment13, charge_account_segment14,
                   charge_account_segment15, charge_account_segment16, charge_account_segment17, charge_account_segment18,
                   charge_account_segment19, charge_account_segment20, charge_account_segment21, charge_account_segment22,
                   charge_account_segment23, charge_account_segment24, charge_account_segment25, charge_account_segment26,
                   charge_account_segment27, charge_account_segment28, charge_account_segment29, charge_account_segment30,
                   oke_contract_line_id, oke_contract_line_num, oke_contract_deliverable_id, oke_contract_deliverable_num,
                   award_number, amount_ordered, invoice_adjustment_flag, dest_charge_account_id, dest_variance_account_id,
                   interface_line_location_id, processing_id, process_code, interface_distribution_ref, group_line_id,
                   funded_value, partial_funded_flag, quantity_funded, amount_funded, clm_misc_loa, clm_defence_funding,
                   clm_fms_case_number, clm_agency_acct_identifier, acrn, clm_payment_sequence_num, global_attribute_category,
                   global_attribute1, global_attribute2, global_attribute3, global_attribute4, global_attribute5,
                   global_attribute6, global_attribute7, global_attribute8, global_attribute9, global_attribute10,
                   global_attribute11, global_attribute12, global_attribute13, global_attribute14, global_attribute15,
                   global_attribute16, global_attribute17, global_attribute18, global_attribute19, global_attribute20
                  )
           VALUES (rec.interface_header_id, rec.interface_line_id, rec.interface_distribution_id, rec.po_header_id, rec.po_release_id,
                   rec.po_line_id, rec.line_location_id, rec.po_distribution_id, rec.distribution_num, rec.source_distribution_id, rec.org_id,
                   rec.quantity_ordered, rec.quantity_delivered, rec.quantity_billed, rec.quantity_cancelled, rec.rate_date, rec.rate,
                   rec.deliver_to_location, rec.deliver_to_location_id, rec.deliver_to_person_full_name, rec.deliver_to_person_id,
                   rec.destination_type, rec.destination_type_code, rec.destination_organization, rec.destination_organization_id,
                   rec.destination_subinventory, rec.destination_context, rec.set_of_books, rec.set_of_books_id, rec.charge_account,
                   rec.charge_account_id, rec.budget_account, rec.budget_account_id, rec.accural_account, rec.accrual_account_id,
                   rec.variance_account, rec.variance_account_id, rec.amount_billed, rec.accrue_on_receipt_flag, rec.accrued_flag,
                   rec.prevent_encumbrance_flag, rec.encumbered_flag, rec.encumbered_amount, rec.unencumbered_quantity, rec.unencumbered_amount,
                   rec.failed_funds, rec.failed_funds_lookup_code, rec.gl_encumbered_date, rec.gl_encumbered_period_name, rec.gl_cancelled_date,
                   rec.gl_closed_date, rec.req_header_reference_num, rec.req_line_reference_num, rec.req_distribution_id, rec.wip_entity,
                   rec.wip_entity_id, rec.wip_operation_seq_num, rec.wip_resource_seq_num, rec.wip_repetitive_schedule,
                   rec.wip_repetitive_schedule_id, rec.wip_line_code, rec.wip_line_id, rec.bom_resource_code, rec.bom_resource_id,
                   rec.ussgl_transaction_code, rec.government_context, rec.project, rec.project_id, rec.task, rec.task_id, rec.end_item_unit_number,
                   rec.expenditure, rec.expenditure_type, rec.project_accounting_context, rec.expenditure_organization,
                   rec.expenditure_organization_id, rec.project_releated_flag, rec.expenditure_item_date, rec.attribute_category, rec.attribute1,
                   rec.attribute2, rec.attribute3, rec.attribute4, rec.attribute5, rec.attribute6, rec.attribute7, rec.attribute8, rec.attribute9,
                   rec.attribute10, rec.attribute11, rec.attribute12, rec.attribute13, rec.attribute14, rec.attribute15, rec.last_update_date,
                   rec.last_updated_by, rec.last_update_login, rec.creation_date, rec.created_by, rec.request_id, rec.program_application_id,
                   rec.program_id, rec.program_update_date, rec.recoverable_tax, rec.nonrecoverable_tax, rec.recovery_rate,
                   rec.tax_recovery_override_flag, rec.award_id, rec.charge_account_segment1, rec.charge_account_segment2,
                   rec.charge_account_segment3, rec.charge_account_segment4, rec.charge_account_segment5, rec.charge_account_segment6,
                   rec.charge_account_segment7, rec.charge_account_segment8, rec.charge_account_segment9, rec.charge_account_segment10,
                   rec.charge_account_segment11, rec.charge_account_segment12, rec.charge_account_segment13, rec.charge_account_segment14,
                   rec.charge_account_segment15, rec.charge_account_segment16, rec.charge_account_segment17, rec.charge_account_segment18,
                   rec.charge_account_segment19, rec.charge_account_segment20, rec.charge_account_segment21, rec.charge_account_segment22,
                   rec.charge_account_segment23, rec.charge_account_segment24, rec.charge_account_segment25, rec.charge_account_segment26,
                   rec.charge_account_segment27, rec.charge_account_segment28, rec.charge_account_segment29, rec.charge_account_segment30,
                   rec.oke_contract_line_id, rec.oke_contract_line_num, rec.oke_contract_deliverable_id, rec.oke_contract_deliverable_num,
                   rec.award_number, rec.amount_ordered, rec.invoice_adjustment_flag, rec.dest_charge_account_id, rec.dest_variance_account_id,
                   rec.interface_line_location_id, rec.processing_id, rec.process_code, rec.interface_distribution_ref, rec.group_line_id,
                   rec.funded_value, rec.partial_funded_flag, rec.quantity_funded, rec.amount_funded, rec.clm_misc_loa, rec.clm_defence_funding,
                   rec.clm_fms_case_number, rec.clm_agency_acct_identifier, rec.acrn, rec.clm_payment_sequence_num, rec.global_attribute_category,
                   rec.global_attribute1, rec.global_attribute2, rec.global_attribute3, rec.global_attribute4, rec.global_attribute5,
                   rec.global_attribute6, rec.global_attribute7, rec.global_attribute8, rec.global_attribute9, rec.global_attribute10,
                   rec.global_attribute11, rec.global_attribute12, rec.global_attribute13, rec.global_attribute14, rec.global_attribute15,
                   rec.global_attribute16, rec.global_attribute17, rec.global_attribute18, rec.global_attribute19, rec.global_attribute20
                  );
   END insert_po_dist;
   
   procedure process_receipt(
                                errbuf          out varchar2,
                                retcode         out varchar2,
                                p_po_header_id  in  number,
                                p_file_id       in  number
                            )
                         
   is
   
   l_phase                        VARCHAR2(50);
   l_out_status                   VARCHAR2(50);
   l_devphase                     VARCHAR2(50);
   l_devstatus                    VARCHAR2(50);
   l_errormessage                 VARCHAR2(250);
   l_result                       BOOLEAN;   
   l_request_id                   NUMBER   default 0;
   
   v_group_id                     NUMBER;
   v_header_iface_id              NUMBER;
   v_rcv_trx_iface_id             NUMBER;
   v_org_id                       NUMBER;
   
   v_receipt_req_id               NUMBER;   
   v_shipment_header_id           NUMBER;
   v_shipment_line_id             NUMBER;
   v_receipt_num                  VARCHAR2(30);
   
   
   
    cursor data_po
    is 
        select 
              pla.org_id
            , poh.po_header_id
            , pla.po_line_id
            , pll.line_location_id
            , pda.deliver_to_location_id
            , pla.line_num      
            , pll.shipment_num
            , poh.segment1    
            , poh.vendor_id
            , poh.vendor_site_id
            , pll.ship_to_organization_id
            , mp.organization_code
            , pda.destination_type_code    
            , pda.deliver_to_person_id    
            , pla.item_description
            , pla.quantity
            , pla.unit_meas_lookup_code
        from po_headers_all         poh
            , po_lines_all          pla
            , po_line_locations_all pll
            , mtl_parameters        mp
            , po_distributions_all  pda    
        where 1=1
            and pla.po_header_id            = poh.po_header_id
            and pla.po_line_id              = pll.po_line_id    
            and pll.po_header_id            = poh.po_header_id
            and pll.line_location_id        = pda.line_location_id    
            and pll.ship_to_organization_id = mp.organization_id   
            and nvl(pll.cancel_flag, 'N')   = 'N'
            and pda.destination_type_code   = 'EXPENSE'
            and pll.closed_code             = 'OPEN' 
            and poh.po_header_id            = p_po_header_id;
   
   
   Begin
        logf('');
        logf('    /* Start Create GRN */');
        logf('');
    
        retcode := 0;
        v_group_id          := 0;
        v_header_iface_id   := 0;
        v_rcv_trx_iface_id  := 0;
        
        For rec in data_po
        Loop        

             logf('    PO_Header_ID  : '||rec.po_header_id);

             v_group_id         := rcv_interface_groups_s.NEXTVAL;
             v_header_iface_id  := rcv_headers_interface_s.NEXTVAL;
             
             v_rcv_trx_iface_id := rcv_transactions_interface_s.NEXTVAL;

             v_org_id           := rec.org_id;

             logf ('');
             logf ('    ***************************************');
             logf ('    Org ID              :' || v_org_id);
             logf ('    Group ID            :' || v_group_id);
             logf ('    Header Interface ID :' || v_header_iface_id);
             logf ('    ***************************************');
             logf ('');

             INSERT INTO rcv_headers_interface (header_interface_id,
                                                GROUP_ID,
                                                processing_status_code,
                                                receipt_source_code,
                                                transaction_type,
                                                auto_transact_code,
                                                last_update_date,
                                                last_updated_by,
                                                last_update_login,
                                                creation_date,
                                                created_by,
                                                vendor_id,
                                                vendor_site_id,
                                                ship_to_organization_id,
                                                expected_receipt_date,
                                                org_id,
                                                validation_flag,
                                                shipment_num,
                                                location_id,
                                                shipped_date)
                  VALUES (v_header_iface_id,
                          v_group_id,
                          'PENDING',
                          'VENDOR',
                          'NEW',
                          'DELIVER',
                          SYSDATE,
                          g_user_id,
                          g_login_id,
                          SYSDATE,
                          g_user_id,
                          rec.vendor_id,
                          rec.vendor_site_id,
                          rec.ship_to_organization_id,
                          SYSDATE,
                          v_org_id,
                          'Y',
                          NULL,         
                          NULL,
                          SYSDATE);
                          
                          
            logf ('    UOM      : ' || rec.unit_meas_lookup_code);
            logf ('    Quantity : ' || LTRIM(RTRIM(TO_CHAR(rec.quantity,'999G999G999D99'))));

            IF (NVL (rec.quantity, 0) <= 0)
            THEN
                logf ('    Please check Quantity, should be greater than zero ');
               retcode := 2;
            END IF;


            INSERT INTO rcv_transactions_interface (interface_transaction_id,
                                                    GROUP_ID,
                                                    last_update_date,
                                                    last_updated_by,
                                                    creation_date,
                                                    created_by,
                                                    last_update_login,
                                                    transaction_type,
                                                    transaction_date,
                                                    processing_status_code,
                                                    processing_mode_code,
                                                    transaction_status_code,
                                                    po_header_id,
                                                    po_line_id,
                                                    quantity,
                                                    unit_of_measure,
                                                    po_line_location_id,
                                                    auto_transact_code,
                                                    receipt_source_code,
                                                    to_organization_id,
                                                    ship_to_location_id,
                                                    source_document_code,
                                                    document_num,
                                                    destination_type_code,
                                                    deliver_to_person_id,
                                                    deliver_to_location_id,
                                                    header_interface_id,
                                                    validation_flag,
                                                    interface_source_code,
                                                    org_id)
                 VALUES (rcv_transactions_interface_s.NEXTVAL,
                         v_group_id,
                         SYSDATE,
                         g_user_id,
                         SYSDATE,
                         g_user_id,
                         g_login_id,
                         'RECEIVE',
                         SYSDATE,
                         'PENDING',
                         'BATCH',
                         'PENDING',
                         rec.po_header_id,
                         rec.po_line_id,
                         rec.quantity,
                         rec.unit_meas_lookup_code,
                         rec.line_location_id,
                         'DELIVER',
                         'VENDOR',
                         rec.ship_to_organization_id, 
                         NULL,
                         'PO',                        
                         NULL,
                         rec.destination_type_code,
                         rec.deliver_to_person_id,
                         rec.deliver_to_location_id,
                         v_header_iface_id,
                         'Y',
                         'RCV',
                         v_org_id);
            
            IF (NVL (retcode, 0) <> 2)
            THEN
                 IF v_group_id > 0
                 THEN
                    v_receipt_req_id :=fnd_request.submit_request 
                        (
                          application   => 'PO',
                          program       => 'RVCTP',
                          description   => 'MIRACLE AutoReceive PO Stockist #' || g_request_id,
                          start_time    => NULL,
                          sub_request   => FALSE,
                          argument1     => 'BATCH',
                          argument2     => v_group_id,
                          argument3     => v_org_id
                        );
                        
                    COMMIT;
                    
                 END IF;


                 IF NVL (v_receipt_req_id, 0) = 0
                 THEN   
                                     
                    logf ('    Receiving Transaction Processor Concurrent failed');
                    logf (SQLCODE || '-' || SQLERRM);
                    retcode := 2;
                    
                 ELSE
                    
                    logf('');                                
                    logf ('    Request ID ' || v_receipt_req_id || ' has been submitted !');
                    
                    l_result := fnd_concurrent.wait_for_request (v_receipt_req_id, g_interval
                                                                 ,              0, l_phase, l_out_status
                                                                 , l_devphase    , l_devstatus
                                                                 , l_errormessage
                                                                );
                                                                
                    logf ('    Phase    : ' || l_devphase);
                    logf ('    Status   : ' || l_devstatus);                                                                

                    IF l_devphase = 'COMPLETE' AND l_devstatus = 'NORMAL' 
                    THEN                    

                       FOR cek_rtp IN (
                                        SELECT error_message, interface_line_id
                                        FROM po_interface_errors
                                        WHERE batch_id = v_group_id
                                      )
                       LOOP

                          logf ('    Interface_line_id : ' || cek_rtp.interface_line_id);
                          logf ('    error             : ' || cek_rtp.error_message);
                          retcode := 2;

                       END LOOP;
                    
                       -- update Staging          
                       
                       SELECT rsh.receipt_num, rsh.shipment_header_id, rsl.shipment_line_id
                       INTO   v_receipt_num  , v_shipment_header_id  , v_shipment_line_id     
                       FROM rcv_transactions        rt,
                            rcv_shipment_headers    rsh,
                            rcv_shipment_lines      rsl,
                            po_headers_all          poh,
                            po_lines_all            pla,
                            po_line_locations_all   plla
                       WHERE 1=1
                          AND rsh.shipment_header_id  = rt.shipment_header_id
                          AND rt.transaction_type     = 'DELIVER'
                          AND rsh.receipt_source_code = 'VENDOR'
                          AND rsl.shipment_line_id    = rt.shipment_line_id
                          AND rsl.po_header_id        = poh.po_header_id
                          AND rsl.po_line_id          = pla.po_line_id
                          AND rsl.po_line_location_id = plla.line_location_id   
                          AND poh.po_header_id        = rec.po_header_id;                             
                    
                       logf('');                     
                       logf('    :-------------------------');
                       logf('    :*/*****  SUMMARY  *****/*');
                       logf('    :-------------------------');
                       logf('    : PO NO  : '||rec.segment1);
                       logf('    : RCV NO : '||v_receipt_num);
                       logf('    :-------------------------');                                                                     
                       logf(''); logf('');
                       
                        UPDATE xxkhd_po_iface_stg 
                        SET 
                           process_status       = 'S',
                           shipment_request_id  = v_receipt_req_id,
                           shipment_header_id   = v_shipment_header_id,
                           shipment_line_id     = v_shipment_line_id              
                        WHERE 1=1
                           AND NVL(process_flag, 'N')   = 'Y'   
                           AND vendor_site_id           = rec.vendor_site_id           
                           AND file_id                  = p_file_id;
                       
                       logf('    **/ MIRACLE Receiving Transaction Processor succeed..!!');
                       logf('');
                    
                    ELSE

                       retcode := 2;
                       logf ('   MIRACLE concurrent autoReceive PO Stockist failed,  '
                          || SQLCODE
                          || ' - '
                          || SQLERRM
                          || ' - '
                          || l_errormessage);

                       FOR cek_rtp IN (
                                        SELECT error_message, interface_line_id
                                        FROM po_interface_errors
                                        WHERE batch_id = v_group_id
                                      )
                       LOOP

                          logf ('    Interface_line_id : ' || cek_rtp.interface_line_id);

                          IF TRIM (cek_rtp.error_message) IS NULL
                          THEN
                             logf ('    No Errors');
                          ELSE
                             logf ('    Error : ' || cek_rtp.error_message);
                          END IF;

                       END LOOP;
                    
                    END IF;

                 END IF;
                    
            END IF;                          
                                          
        End loop;
                      
   End process_receipt;   

   procedure process_data(
                            errbuf          out varchar2,
                            retcode         out varchar2,
                            p_po_header_id  out varchar2,
                            p_file_id       in  number
                         )
                         
   is
 

   po_headers_iface               po_headers_interface%rowtype;
   po_lines_iface                 po_lines_interface%rowtype;
   po_dist_iface                  po_distributions_interface%rowtype;
   

   v_vendor_id                    NUMBER;
   v_vendor_site_id               NUMBER;
   v_vendor_name                  VARCHAR2(240);
   v_operating_unit               NUMBER;

   v_hdr_id                       NUMBER;
   v_org_location                 NUMBER;
   v_header_exists                NUMBER:=0;
   v_lns_id                       NUMBER;
   v_dist_id                      NUMBER;
   v_line_exists                  NUMBER:=0;
   l_process_notvalid             NUMBER:=0;
   v_uom_code                     VARCHAR2(25);
   v_unit_price                   NUMBER;
   v_sched_ship_date              DATE;
   
   v_buyer_id                     NUMBER;
   v_loc_id                       NUMBER;
   v_loc_id2                      NUMBER;
   v_document_type                VARCHAR2 (10);
   v_document_subtype             VARCHAR2 (25);
   v_create_items                 VARCHAR2 (25);
   v_create_sourcing_rules_flag   VARCHAR2 (25);
   v_approved_status              VARCHAR2 (20);
   v_rel_gen_metho                VARCHAR2 (70);
   v_selected_batch_id            NUMBER;
   v_org_id                       NUMBER;
   v_ga_flag                      VARCHAR2 (25);
   v_enable_sourcing_level        VARCHAR2 (10);
   v_sourcing_level               VARCHAR2 (30);
   v_inv_org_enable               VARCHAR2 (3);
   v_sourcing_inv_org_id          VARCHAR2 (38);
   v_group_lines                  VARCHAR2 (25);
   v_clm_flag                     VARCHAR2 (25);
   v_batch_size                   NUMBER;
   v_gather_stats                 VARCHAR2 (25);

   l_header_id                    VARCHAR2 (50);
   l_line_id                      VARCHAR2 (50);
   v_asl_id                       NUMBER;  

   v_process_flag                 VARCHAR2(10);
   v_error_msg                    VARCHAR2(100);
   v_tot_err_msg                  VARCHAR2(1000);
    
   v_iface_run_id                 NUMBER:=0;
    
   v_phase                        VARCHAR2(50);
   v_out_status                   VARCHAR2(50);
   v_devphase                     VARCHAR2(50);
   v_devstatus                    VARCHAR2(50);
   v_errormessage                 VARCHAR2(250);
   v_result                       BOOLEAN;   
   v_request_id                   NUMBER   default 0;
       
   l_first                        BOOLEAN;
   l_location_code                VARCHAR2(50):= 'KHD HEAD OFFICE';
   
   v_agent_id                     NUMBER;
   v_coa_id                       NUMBER;
   v_set_of_books_id              NUMBER;
   v_ledger_id                    NUMBER;
   v_chart_of_accounts_id         NUMBER;
   v_coa_combination_code         VARCHAR(80);
   v_agent_name                   VARCHAR(240)  := 'Agnes Yunita,';
   v_category_id                  NUMBER        := 2287; --**>> CATEGORY : INDIRECT - POS - OTHERS - ALL
   
   v_po_number                    VARCHAR(30);  
   l_po_line_id                   NUMBER;
   l_line_location_id             NUMBER;
   
    
    cursor data_grp_po_stg 
    is 
    select 
          file_id
        , vendor_site_id
        , vendor_site_code
    from xxkhd_po_iface_stg 
    where 1=1
        and nvl(process_status,'N') = 'P1'
        and nvl(process_flag,'N')   = 'Y'
        and file_id                 = p_file_id
    group by
          file_id
        , vendor_site_id
        , vendor_site_code;
    
    cursor data_po_stg (p_vendor_site_id number)
    is 
    select 
          file_id
        , vendor_site_id
        , vendor_site_code
        , description
        , coa_khdex
        , sum(dpp) nilai_dpp
    from xxkhd_po_iface_stg 
    where 1=1
        and nvl(process_status,'N') = 'P1'
        and nvl(process_flag,'N')   = 'Y'
        and vendor_site_id          = p_vendor_site_id
        and file_id                 = p_file_id
    group by
          file_id
        , vendor_site_id
        , vendor_site_code 
        , coa_khdex
        , description;
    
    Begin
    
        logf('    /* Start Create PO */');
        logf('');
    
        retcode           := 0;
        v_org_id          := null;
        v_operating_unit  := null;
        
        -- /* Get set_of_books_id */
        begin
           select set_of_books_id
           into v_set_of_books_id
           from gl_sets_of_books
           where 1=1
               and upper(name) ='KHD_LEDGER_OPERATION';
               
        exception
            when others
            then
                l_process_notvalid  := l_process_notvalid + 1;                
                logf ('Invalid set_of_books_id, '|| SQLERRM);
        end;        
        
        -- /* Get chart_of_accounts_id */
        begin
        
           select ledger_id, chart_of_accounts_id
           into v_ledger_id, v_chart_of_accounts_id
           from gl_ledgers
           where 1=1
               and upper(ledger_category_code)='PRIMARY';   
               
        exception
            when others
            then
                l_process_notvalid  := l_process_notvalid + 1;                
                logf ('Invalid chart_of_accounts_id, '|| SQLERRM);
        end;        
        
        -- /* Get Operating unit */
        
        begin
         
             select organization_id
             into v_operating_unit
             from hr_all_organization_units      
             where 1=1
                and upper(name) like '%OPERATING UNIT';
                        
        exception
             when others then
                l_process_notvalid  := l_process_notvalid + 1;                
                logf ('Invalid Operation Unit, '|| SQLERRM);
        end;    
        
        --/* Get Organization_id *//
                          
        begin
         
             select organization_id, organization_id
             into v_org_id         , v_org_location
             from mtl_parameters      
             where 1=1
                and upper(organization_code) = g_org_code;
                        
        exception
             when others then
                l_process_notvalid  := l_process_notvalid + 1;                
                logf ('Invalid Organization code : '||g_org_code);                      
        end;    
        
       logf('    Operating unit         : '||v_operating_unit);
       logf('    Organization code      : '||g_org_code);
       logf('');
       
       begin              
            select location_id
            into v_loc_id
            from hr_locations
            where  1=1
                --and inventory_organization_id is not null
                --and inventory_organization_id = v_org_location
              and ship_to_site_flag = 'Y'
              and location_code     = l_location_code;
       exception
            when others
            then
                logf ('Error get location info : '||l_location_code||', '||sqlerrm);
                l_process_notvalid := l_process_notvalid + 1;
       end;
          
       begin
            
            select bill_to_location_id 
            into v_loc_id2 
            from financials_system_params_all
            where 1=1;
            
       exception
            when others
            then
                logf ('Error get bill_to_location_id, ' || sqlerrm);
                l_process_notvalid := l_process_notvalid + 1;
       end;
          
       begin
            
            select agent_id
            into v_agent_id 
            from po_agents_v pav
            where 1=1
                and upper(agent_name)   = upper(v_agent_name);
            
       exception
            when others
            then
                logf ('Error get agent_id, ' || sqlerrm);
                l_process_notvalid := l_process_notvalid + 1;
       end;       


       for grp in data_grp_po_stg
       loop
       
           select po_headers_interface_s.nextval 
           into v_hdr_id 
           from dual;      
           
           l_first              := True;    
           l_process_notvalid   := 0;
           v_header_exists      := 0;
               
           if l_first 
           then    
               
               begin
                        
                   select pv.vendor_id, pvs.vendor_site_id, pv.vendor_name
                   into v_vendor_id   , v_vendor_site_id  , v_vendor_name
                   from 
                        po_vendors pv
                      , po_vendor_sites_all pvs
                   where 1=1 
                      and pv.vendor_id         = pvs.vendor_id
                      and pvs.vendor_site_code = grp.vendor_site_code;
                           
               exception
                    when others
                    then
                         logf ('Error get vendor_site_code : ' ||grp.vendor_site_code||', '||sqlerrm);
                         l_process_notvalid := l_process_notvalid + 1;   
               end;
                   
               l_first := False;
                   
           end if;
               
               /* INSERT DATA HEADER */
           logf('');
           logf('**/  STEP-02. Create PO Interface  **/');
           logf('');
           logf('    PO interface header_id : '||v_hdr_id);  
           logf('    Vendor_site_code       : '||grp.vendor_site_code);  
           logf('    Vendor_name            : '||v_vendor_name);  
               
           po_headers_iface.interface_header_id  := v_hdr_id;
           po_headers_iface.batch_id             := v_hdr_id;
           po_headers_iface.document_type_code   := 'STANDARD';
           po_headers_iface.action               := 'ORIGINAL';
           po_headers_iface.org_id               := v_operating_unit;
           po_headers_iface.document_num         := NULL;
           po_headers_iface.vendor_id            := v_vendor_id;   
           po_headers_iface.vendor_name          := v_vendor_name; 
           po_headers_iface.vendor_site_id       := v_vendor_site_id;    
           po_headers_iface.vendor_site_code     := grp.vendor_site_code;
           po_headers_iface.ship_to_location_id  := v_loc_id;        
           po_headers_iface.bill_to_location_id  := v_loc_id2;       
           po_headers_iface.agent_id             := v_agent_id;  
           po_headers_iface.currency_code        := 'IDR';
           po_headers_iface.creation_date        := SYSDATE;
           po_headers_iface.created_by           := g_user_id;
               
           insert_po_headers (po_headers_iface);
               
           v_header_exists  := v_header_exists + 1;   
                                                    
           v_line_exists    := 0;
                            
           for rec in data_po_stg (v_vendor_site_id)
           loop                                 
               
               select po_lines_interface_s.nextval 
               into v_lns_id 
               from dual;
                                            
               v_sched_ship_date                        := trunc(sysdate);
                    
               po_lines_iface.interface_line_id         := v_lns_id;        
               po_lines_iface.interface_header_id       := v_hdr_id;       
               po_lines_iface.ship_to_organization_id   := v_org_location; 
               po_lines_iface.ship_to_location_id       := v_loc_id;       
               po_lines_iface.category_id               := v_category_id;
               po_lines_iface.line_num                  := nvl(po_lines_iface.line_num, 0) + 1;
               po_lines_iface.line_type                 := 'Services'; 
               po_lines_iface.ship_to_organization_code := g_org_code;
               po_lines_iface.item_description          := rec.description;
               po_lines_iface.quantity                  := rec.nilai_dpp;         
               po_lines_iface.unit_price                := 1 ;
               po_lines_iface.uom_code                  := 'IDR';
               po_lines_iface.promised_date             := v_sched_ship_date; 
               po_lines_iface.need_by_date              := v_sched_ship_date; 
               
               insert_po_lines (po_lines_iface);
               
               v_line_exists := v_line_exists + 1;
                         
               logf('');
               logf('    PO interface line_id   : '||v_lns_id);
               logf('    Description            : '||rec.description);
               logf('    Amount                 : '||LTRIM(RTRIM(TO_CHAR(rec.nilai_dpp,'999G999G999D99'))));
               logf('');
               

               -- distribution
               select po_distributions_interface_s.nextval 
               into v_dist_id 
               from dual;
               
               logf('    PO interface dist_id   : '||v_dist_id);
               logf('    COA KHDex              : '||rec.coa_khdex);
               logf('');
               -- Get COA Inventory KHDex
               
               select code_combination_id
               into v_coa_id
               from gl_code_combinations_kfv
               where 1=1
                  and chart_of_accounts_id    = v_chart_of_accounts_id
                  and concatenated_segments   = rec.coa_khdex;


               po_dist_iface.interface_header_id            := v_hdr_id;
               po_dist_iface.interface_line_id              := v_lns_id;
               po_dist_iface.interface_distribution_id      := v_dist_id;
               po_dist_iface.distribution_num               := 1;
               po_dist_iface.quantity_ordered               := rec.nilai_dpp;
               po_dist_iface.org_id                         := v_operating_unit;
               po_dist_iface.deliver_to_location_id         := v_loc_id;
               po_dist_iface.destination_organization_id    := v_org_id; 
               po_dist_iface.set_of_books_id                := v_set_of_books_id;
               po_dist_iface.charge_account_id              := v_coa_id;                     
               
               insert_po_dist (po_dist_iface);                              

                IF (v_header_exists > 0 AND (v_line_exists <= 0)) OR l_process_notvalid > 0 
                THEN
                      logf('***');
                      logf('step delete header interface table ');
            
                      v_header_exists := v_header_exists - 1;
                      
                      begin
                         
                         delete po_lines_interface
                         where 1=1
                            and interface_header_id = v_hdr_id;
                            
                      exception
                         when others
                         then
                            logf ('Error when delete po_lines_interface ' || sqlerrm);
                      end;
                      
                      begin
                         
                         delete po_distributions_interface
                         where 1=1
                            and interface_header_id = v_hdr_id;
                            
                      exception
                         when others
                         then
                            logf ('Error when delete po_distributions_interface ' || sqlerrm);
                      end;

                      begin
                         
                         delete po_headers_interface
                         where 1=1
                            and interface_header_id = v_hdr_id;
                            
                      exception
                         when others
                         then
                            logf ('Error when delete po_distributions_interface ' || sqlerrm);
                      end;        
                
                END IF;
                                                    
            
                -- logf (v_header_exists ||'-'||v_line_exists||'-'||l_process_notvalid);            
            
                IF v_header_exists > 0 AND v_line_exists > 0 AND l_process_notvalid = 0                 
                THEN
                                                      
                      v_buyer_id                    := v_agent_id;
                      v_document_type               := 'STANDARD';
                      v_document_subtype            := NULL;
                      v_create_items                := 'N';
                      v_create_sourcing_rules_flag  := NULL;
                      v_approved_status             := 'APPROVED'; --'INCOMPLETE';                 --INITIATE APPROVAL'; 5Juli2017
                      v_rel_gen_metho               := NULL;
                      v_selected_batch_id           := v_hdr_id;
                      v_org_id                      := NULL;
                      v_ga_flag                     := NULL;
                      v_enable_sourcing_level       := NULL;
                      v_sourcing_level              := NULL;
                      v_inv_org_enable              := NULL;
                      v_sourcing_inv_org_id         := NULL;
                      v_group_lines                 := NULL;
                      v_clm_flag                    := NULL;
                      v_batch_size                  := NULL;
                      v_gather_stats                := NULL;
                                            
                      v_request_id := fnd_request.submit_request 
                            (                         
                                application   => 'PO',
                                program       => 'POXPOPDOI',
                                description   => 'MIRACLE - Import Standard Purchase Orders',
                                start_time    => NULL,
                                sub_request   => FALSE,
                                argument1     => v_buyer_id,
                                argument2     => v_document_type,
                                argument3     => v_document_subtype,
                                argument4     => v_create_items,
                                argument5     => v_create_sourcing_rules_flag,
                                argument6     => v_approved_status,
                                argument7     => v_rel_gen_metho,
                                argument8     => v_selected_batch_id,
                                argument9     => v_org_id,
                                argument10    => v_ga_flag,
                                argument11    => v_enable_sourcing_level,
                                argument12    => v_sourcing_level,
                                argument13    => v_inv_org_enable,
                                argument14    => v_sourcing_inv_org_id,
                                argument15    => v_group_lines,
                                argument16    => v_clm_flag,
                                argument17    => v_batch_size,
                                argument18    => v_gather_stats
                            );                        
                        
                    commit;
                    
                    logf('');            
                    logf('    **/ Final PO -> submit request standard PO, #Request_ID : ' || v_request_id);
                                        
                    v_result := fnd_concurrent.wait_for_request (v_request_id, g_interval
                                                                 , 0, v_phase, v_out_status
                                                                 , v_devphase, v_devstatus
                                                                 , v_errormessage
                                                                );

                    if v_devphase = 'COMPLETE' and v_devstatus = 'NORMAL' then
                        
                        logf('    **/ Vendor_site_code : '||grp.vendor_site_code ||', Import Standard Purchase Orders succeed..!!');
                        logf('');
                        
                        SELECT pha.po_header_id, pla.po_line_id, plla.line_location_id, pha.segment1
                        INTO   p_po_header_id , l_po_line_id   , l_line_location_id   , v_po_number                         
                        FROM po_headers_interface       phi,
                            po_headers_all              pha,
                            po_lines_all                pla,
                            po_line_locations_all       plla,
                            apps.po_document_types_all  pdt
                        WHERE 1=1
                            AND phi.po_header_id        = pha.po_header_id
                            AND pla.po_header_id        = pha.po_header_id
                            AND plla.po_line_id         = pla.po_line_id
                            AND plla.po_header_id       = pla.po_header_id
                            AND pha.type_lookup_code    = pdt.document_subtype
                            AND pha.org_id              = pdt.org_id
                            AND pdt.document_type_code  = 'PO'
                            AND phi.interface_header_id = v_hdr_id;

                        UPDATE xxkhd_po_iface_stg 
                        SET 
                           process_status       = 'P2',
                           po_request_id        = v_request_id,
                           po_header_id         = p_po_header_id,
                           po_line_id           = l_po_line_id,  
                           po_line_location_id  = l_line_location_id          
                        WHERE 1=1
                           AND NVL(process_flag, 'N')  = 'Y'   
                           AND vendor_site_code        = grp.vendor_site_code           
                           AND file_id                 = p_file_id;
                            
                       logf('     #PO Number : '||v_po_number);
                           
                       logf('');logf('');                       
                       logf('**/  STEP-03. Create GRN Interface  **/');
                            
                        
                    else

                         retcode        := 2;
                         v_errormessage := '';

                         FOR i IN (
                                     SELECT error_message
                                     FROM po_interface_errors
                                     WHERE 1=1
                                        AND request_id = v_request_id
                                  )
                         LOOP
                            
                            v_errormessage := v_errormessage||','||i.error_message;
                            logf ('PO Interface Error Msg : ' || i.error_message);
                            
                         END LOOP;

                        logf('');

                        -- all data set status = Error 
                        
                        update xxkhd_po_iface_stg 
                        set 
                            process_status      = 'E',
                            po_request_id       = v_request_id,         
                            error_message       = substr(v_errormessage,1,500)                          
                        where 1=1
                            and nvl(process_flag, 'N')  = 'Y'        
                            and vendor_site_code        = grp.vendor_site_code        
                            and file_id                 = p_file_id;  
                                                                     
                    end if;  
                    
                    commit;
                    
                ELSE
                 
                    retcode := 2;                    
                    
                END IF;                
                                                                                                                                          
           end loop;                        
              
       end loop;
       
                
    exception
        when others then
            logf (SQLCODE || ' Error :' || SQLERRM);
            logf('exception occured at main loop');
            logf(DBMS_UTILITY.FORMAT_ERROR_STACK);
            logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                        
    end process_data;
    
   procedure print_result (p_file_id NUMBER)
   is
   
   l_user_created_by    VARCHAR(50);
   l_creation_date      VARCHAR(50);
   l_file_name          VARCHAR(100);
   
   l_error              PLS_INTEGER:=0;
   l_count              PLS_INTEGER:=0;
   l_conc_status        BOOLEAN;
   
   cursor c_data
   is            
         select 
              xou.period_name         
            , xou.user_je_category_name category_name
            , substr(xou.reference1, 1, 20) journal_name
            , substr(xou.reference2, 1, 50) journal_desc 
            , xou.segment1||'-'||xou.segment2||'-'||xou.segment3||'-'||xou.segment4||'-'||xou.segment5||'-'||xou.segment6||'-'||xou.segment7 coa
            , xou.process_status
            , substr(xou.error_message, 1, 200) error_message           
         from xxkhd_gl_iface_stg xou         
         where 1=1      
            and nvl(process_status,'E') = 'E' 
            and nvl(process_flag,  'N') = 'Y'   
            and error_message           is not null
            and file_id                 = p_file_id
         group by 
              xou.period_name         
            , xou.user_je_category_name
            , substr(xou.reference1, 1, 20)
            , substr(xou.reference2, 1, 50)
            , xou.segment1||'-'||xou.segment2||'-'||xou.segment3||'-'||xou.segment4||'-'||xou.segment5||'-'||xou.segment6||'-'||xou.segment7
            , xou.process_status
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
                 from xxkhd_gl_iface_stg xou         
                 where 1=1                 
                    and nvl(process_status,'E') = 'E' 
                    and nvl(process_flag,  'N') = 'Y'   
                    and file_id                 = p_file_id
            )
         where 1=1
            and rownum<=1
         group by file_name, user_created_by, creation_date;
               
      outf('/* START */');                          
      outf(' '); outf(' ');  outf(' ');
      outf('      '||'Upload PO - GRN status report');
      outf(' ');
      outf('      '||'Proceed By      : '||l_user_created_by );
      outf('      '||'Proceed Date on : '||l_creation_date );
      outF('      '||'------- --------------------- ------------- --------------------------------------------------- ----------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------');  
      outF('      '||'PERIOD  JE CATEGORY           JE NAME       JE DESCRIPTION                                      COA COMBINATION                           STATUS ERROR MESSAGE                                                                                                     ');       
      outF('      '||'------- --------------------- ------------- --------------------------------------------------- ----------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------');         

      FOR i IN c_data LOOP
      
                outF ('      '||
                        RPAD(i.period_name,      6,' ')||'  ' ||
                        RPAD(i.category_name,   20,' ')||'  ' ||
                        RPAD(i.journal_name,    12,' ')||'  ' ||
                        RPAD(i.journal_desc,    50,' ')||'  ' ||
                        RPAD(i.coa,             40,' ')||'  ' ||
                        RPAD(i.process_status,   5,' ')||'  ' ||
                        RPAD(i.error_message,  200,' ')
                     );              
           
      END LOOP;
      outF('      '||'------- --------------------- ------------- --------------------------------------------------- ----------------------------------------- ------ ------------------------------------------------------------------------------------------------------------------');         
      outf(' '); outf(' '); outf(' '); 
      outf('/* END */');          
            
   END print_result;     
   
   
   procedure validasi_trx_value (
                                    p_file_id       NUMBER
                                )
   is
      
   cursor c_data_stg
   is         
        select 
              stg.vendor_site_id
            , stg.vendor_site_code
            , stg.trx_no
            , sum(stg.dpp)      nilai_stg
            , sum(total_amount) nilai_mrc
        from 
              xxkhd_po_iface_stg    stg
            , xxkhd_mrc_po_stg      mrc
        where 1=1
            and stg.vendor_site_code        = mrc.supplier_site_code
            and stg.trx_no                  = mrc.pick_list_number
            and nvl(stg.process_status,'N') ='N'
            and nvl(stg.process_flag,'N')   ='N'
            and mrc.receipt_number          is null
            and stg.file_id                 = p_file_id
        group by 
              vendor_site_id
            , vendor_site_code
            , trx_no
        having (sum(stg.dpp) - sum(total_amount)) > 0;             
         
   
   begin
   
        for rec in c_data_stg 
        loop
            
            exit when c_data_stg%notfound;
                  
            begin                                      
                update xxkhd_po_iface_stg
                set error_message   = error_message ||', no match amount value',
                    process_status  ='E' 
                where 1=1
                    and vendor_site_code    = rec.vendor_site_code
                    and trx_no              = rec.trx_no
                    and file_id             = p_file_id;                                      
            end;                        
                                      
        end loop;       
                    
   end validasi_trx_value;          
    
   procedure final_validation (p_file_id number)
   is
   
   l_conc_status    boolean;
   l_nextproceed    boolean    :=false;

   l_error          pls_integer:=0;
   l_jml_data       number     :=0;

   
   cursor c_DataNotValid
   is         
         select 
              file_id      
            , process_status
         from xxkhd_po_iface_stg xou         
         where 1=1
            and nvl(process_status,'E') ='E'
            and nvl(process_flag,  'N') ='N'
            and file_id                 = p_file_id
         group by   
               file_id      
             , process_status;
   
   BEGIN
   
        l_jml_data :=0;
        
        for i in c_DataNotValid loop
            
            exit when c_DataNotValid%notfound;
            
            l_jml_data := l_jml_data + 1;
          
            exit when l_jml_data > 0; 
                            
        end loop;
        
        if l_jml_data > 0 then
        
           l_nextproceed := true;
         
        end if;
      
        if l_nextproceed then

            update xxkhd_po_iface_stg
                set process_status='E', process_flag='Y'
            where 1=1
                and nvl(process_flag,'N')   ='N'
                and file_id  = p_file_id;
                
        else                

            update xxkhd_po_iface_stg
                set process_status='P1', process_flag = 'Y'
            where 1=1
                and nvl(process_flag,'N')   ='N'
                and file_id  = p_file_id;                
        
        end if;
                                                 
        commit;                
                
        select count(*)                       
        into l_error
        from xxkhd_po_iface_stg
        where 1=1
           and nvl(process_status,'E')  = 'E' 
            and nvl(process_flag, 'N')  = 'Y'
            and file_id                 = p_file_id;
            
        logf ('Error, Count : '||l_error);  

        logf('');
        logf('**/  STEP-01. Upload Data staging  **/');        
        logf('');
            
        if l_error > 0 then
        
            print_result (p_file_id);
                              
           l_conc_status := fnd_concurrent.set_completion_status('ERROR',2);    
           
           logf ('    Error, Upload data staging failed ..!!!');   
           
        else
           logf('    **/ Upload data staging succeed..!!');
           logf ('');
              
        end if;            
           
   END final_validation;      
    
   procedure insert_data(
                        errbuf      out varchar2,
                        retcode     out number,
                        p_file_id   number
                     )
    is
        
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
        l_ou_id                     NUMBER:= 0;
        
        l_vendor_site_id            NUMBER:= 0;
        l_no_npwp                   VARCHAR2(40);
                            
        l_vendor_site_code          VARCHAR2(40);
        l_vendor_name               VARCHAR2(240);
        l_description               VARCHAR2(240);
        l_coa_khdex                 VARCHAR2(50);
        l_tax_code                  VARCHAR2(10);
        l_trx_no                    VARCHAR2(50);
        l_sku                       VARCHAR2(30);
        l_sku_desc                  VARCHAR2(200);
        l_dpp                       NUMBER;        
        l_ppn                       NUMBER;
        l_amount                    NUMBER;
        

        l_comments                VARCHAR2(200);
        l_status                  VARCHAR2(20);
        l_error_message           VARCHAR2(200);
      
        l_err_cnt                 NUMBER;
        l_formula_cnt             NUMBER:= 0;
        l_stg_cnt                 NUMBER:= 0;
        l_cnt_err_format          NUMBER:= 0;
        l_sql                     VARCHAR2(32767);
      
        l_ledger_id               NUMBER:= 0;
        l_org_id                  NUMBER:= 0;
        l_chart_of_accounts_id    NUMBER:= 0;   
        l_code_combination_id     NUMBER:= 0;
        
        l_application_id          NUMBER:= 101; -- GL
        l_iface_run_id            NUMBER:= 0;
        l_po_header_id            NUMBER:= 0;
            
    
BEGIN
    
      begin
      
         select file_data, file_name
         into v_blob_data, v_filename
         from fnd_lobs
         where 1=1
            and file_id = p_file_id;
      exception
         when others
         then
            logf ('File Not Found');
            raise no_data_found;
      end;
      
      begin
           select ledger_id,chart_of_accounts_id
           into l_ledger_id, l_chart_of_accounts_id
           from gl_ledgers
           where 1=1
               and upper(ledger_category_code)='PRIMARY';   
      exception
         when others
         then
            logf ('File Not Found');
            raise no_data_found;      
      end;
      
      begin
         select organization_id
         into l_ou_id
         from hr_all_organization_units      
         where 1=1
            and upper(name) like '%OPERATING UNIT';            
      exception
         when others then
            logf ('Operation Unit');
            raise no_data_found;
      
      end;
            
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
                    IF x = 11 THEN
                       
                       IF v_loop >= 2 THEN
                       
                          FOR i IN 1 .. x  LOOP

                             IF i = 1 THEN                     
                                l_vendor_site_code      := TRIM (v_tab (1));                                                
                             ELSIF i = 2 THEN
                                l_vendor_name           := TRIM ( v_tab(2));
                             ELSIF i = 3 THEN
                                l_coa_khdex             := TRIM ( v_tab(3));
                             ELSIF i = 4 THEN
                                l_description           := TRIM ( v_tab(4));
                             ELSIF i = 5 THEN
                                l_tax_code              := TRIM ( v_tab(5));
                             ELSIF i = 6 THEN
                                l_trx_no                := TRIM (v_tab (6));
                             ELSIF i = 7 THEN
                                l_sku                   := TRIM (v_tab (7));
                             ELSIF i = 8 THEN
                                l_sku_desc              := TRIM (v_tab (8));
                             ELSIF i = 9 THEN
                                l_dpp                   := TRIM (v_tab (9));
                            ELSIF  i = 10 THEN
                                l_ppn                   := TRIM (v_tab (10));
                             ELSIF i = 11 THEN
                                l_amount                := TRIM (v_tab (11));
                             END IF;
                             
                          END LOOP;

                          l_err_cnt         := 0;
                          l_error_message   := NULL;                                                    

                         --validasi supplier_site_code
                          begin
                          
                              l_vendor_site_id  := NULL;
                              l_no_npwp         := NULL;
                              
                              select vendor_site_id, vat_registration_num
                              into l_vendor_site_id, l_no_npwp
                              from xxkhd_supplier_site_v
                              where 1=1 
                                 and vendor_site_code = l_vendor_site_code;                              
                                                        
                          exception
                             when others then
                                l_error_message := 'Invalid supplier site code : '||l_vendor_site_code;
                                l_err_cnt       := l_err_cnt + 1;
                                
                          end;    
                                 
                         --validasi coa KHDex
                          begin
                          
                              l_code_combination_id  := NULL;
                              
                              select code_combination_id
                              into l_code_combination_id
                              from gl_code_combinations_kfv
                              where 1=1
                                 and chart_of_accounts_id    = l_chart_of_accounts_id
                                 and concatenated_segments   = l_coa_khdex;
                                                                                      
                          exception
                             when others then
                                l_error_message := 'Invalid KHDex code combinations  : '||l_coa_khdex;
                                l_err_cnt       := l_err_cnt + 1;
                                
                          end;    
                          
                          begin
                          
                              if l_tax_code = 'PKP'
                              then
                                  
                                  if l_no_npwp is null
                                  then
                                        l_error_message := l_error_message || ', Invalid NPWP Number';
                                        l_err_cnt       := l_err_cnt + 1;
                                  end if;
                                  
                              else
                                  
                                  l_error_message := l_error_message || ', tax code should be : PKP';
                                  l_err_cnt       := l_err_cnt + 1;
                                                              
                              End if;
                          
                          
                          end;
                                                                       

                          SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                          INTO l_status
                          FROM DUAL;

                          --insert to staging
                          
                          l_sql :=
                                'insert into xxkhd_po_iface_stg(
                                    file_id                         ,
                                    file_name                       ,
                                    vendor_site_id                  ,
                                    vendor_site_code                ,
                                    vendor_name                     ,
                                    coa_khdex                       ,
                                    description                     ,
                                    tax_code                        ,
                                    trx_no                          ,
                                    sku                             ,
                                    sku_desc                        ,
                                    dpp                             ,
                                    ppn                             ,
                                    amount                          ,
                                    process_status                  ,
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
                             || l_vendor_site_id
                             || ''','''
                             || l_vendor_site_code
                             || ''','''
                             || l_vendor_name
                             || ''','''
                             || l_coa_khdex
                             || ''','''
                             || l_description
                             || ''','''
                             || l_tax_code
                             || ''','''
                             || l_trx_no
                             || ''','''
                             || l_sku
                             || ''','''
                             || l_sku_desc
                             || ''','''
                             || l_dpp
                             || ''','''
                             || l_ppn
                             || ''','''
                             || l_amount
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

                          --logf ('l_sql : ' || l_sql);
                          BEGIN
                             EXECUTE IMMEDIATE l_sql;
                          EXCEPTION
                             WHEN OTHERS THEN
                                logf (SQLERRM);
                                DBMS_OUTPUT.put_line (SQLERRM);
                                l_err := l_err + 1;
                          END;
                       END IF;

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
        
            update fnd_lobs
            set expiration_date = sysdate,
                upload_date = sysdate
            where 1=1
                and file_id = p_file_id;


            COMMIT;
            logf ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');
            DBMS_OUTPUT.put_line ('File: ' || v_filename || ' succesfully inserting to staging table,COMMIT');


            --validasi_trx_value (p_file_id);                 
            
            final_validation (p_file_id);         

            select count(*)                       
            into l_stg_cnt
            from xxkhd_po_iface_stg
            where 1=1
                and nvl(process_status,'N') = 'P1' 
                and nvl(process_flag,'N')   = 'Y'
                and file_id                 = p_file_id;
                                   
            if nvl(l_stg_cnt,0) > 0 then
                 
                process_data (errbuf, retcode, l_po_header_id, p_file_id);
                
                if nvl(retcode,0) = 0 
                then
                
                    process_receipt (errbuf, retcode, l_po_header_id, p_file_id);
                
                end if; 
                             
            end if;                        
                    
        END IF;     
              
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        logf ('error no data found');
        ROLLBACK;
    WHEN OTHERS THEN
        logf ('Error others : ' || SQLERRM);
        logf(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;           
END;                        
    
END XXKHD_PO_IFACE_PKG; 
/

