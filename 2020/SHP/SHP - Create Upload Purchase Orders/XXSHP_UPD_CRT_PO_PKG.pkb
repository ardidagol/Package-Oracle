CREATE OR REPLACE PACKAGE BODY APPS.xxshp_upd_crt_po_pkg
AS
   /*
      REM +=========================================================================================================+
      REM |                                    Copyright (C) 2017  KNITERS                                          |
      REM |                                        All rights Reserved                                              |
      REM +=========================================================================================================+
      REM |                                                                                                         |
      REM |     Program Name: XXSHP_UPD_CRT_PO.pks                                                                  |
      REM |     Concurrent  : SHP - Uploader Create Purchase Orders                                                 |
      REM |     Parameters  :                                                                                       |
      REM |     Description : Planning Parameter New all in this Package                                            |
      REM |     History     : 1 OCT 2020  --Ardianto--                                                              |
      REM |     Proposed    :                                                                                       |
      REM |     Updated     :                                                                                       |
      REM +---------------------------------------------------------------------------------------------------------+
      */
   PROCEDURE logf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END logf;

   PROCEDURE outf (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
      DBMS_OUTPUT.put_line (p_msg);
   END outf;

   FUNCTION hex_to_decimal (p_hex_str IN VARCHAR2)
      --this function is based on one by Connor McDonald
      --http://www.jlcomp.demon.co.uk/faq/base_convert.html

      RETURN NUMBER
   IS
      v_dec   NUMBER;
      v_hex   VARCHAR2 (16) := '0123456789ABCDEF';
   BEGIN
      v_dec := 0;

      FOR indx IN 1 .. LENGTH (p_hex_str)
      LOOP
         v_dec :=
              v_dec * 16
            + INSTR (v_hex, UPPER (SUBSTR (p_hex_str, indx, 1)))
            - 1;
      END LOOP;

      RETURN v_dec;
   END hex_to_decimal;

   PROCEDURE delimstring_to_table (
      p_delimstring   IN     VARCHAR2,
      p_table            OUT varchar2_table,
      p_nfields          OUT INTEGER,
      p_a                OUT NUMBER,
      p_delim         IN     VARCHAR2 DEFAULT ';')
   IS
      v_string     VARCHAR2 (32767) := p_delimstring;
      v_nfields    PLS_INTEGER := 1;
      v_table      varchar2_table;
      v_delimpos   PLS_INTEGER := INSTR (p_delimstring, p_delim);
      v_delimlen   PLS_INTEGER := LENGTH (p_delim);
   BEGIN
      IF v_delimpos = 0
      THEN
         logf ('Delimiter '';'' not Found');
      END IF;

      WHILE v_delimpos > 0
      LOOP
         v_table (v_nfields) := SUBSTR (v_string, 1, v_delimpos - 1);
         v_string := SUBSTR (v_string, v_delimpos + v_delimlen);
         v_nfields := v_nfields + 1;
         v_delimpos := INSTR (v_string, p_delim);
      END LOOP;

      v_table (v_nfields) := v_string;
      p_table := v_table;
      p_nfields := v_nfields;
   END delimstring_to_table;

   PROCEDURE waitforrequest (in_requestid       IN     NUMBER,
                             out_status            OUT VARCHAR2,
                             out_errormessage      OUT VARCHAR2)
   IS
      v_result      BOOLEAN;
      v_phase       VARCHAR2 (20);
      v_devphase    VARCHAR2 (20);
      v_devstatus   VARCHAR2 (20);
   BEGIN
      v_result :=
         fnd_concurrent.wait_for_request (in_requestid,
                                          5,
                                          0,
                                          v_phase,
                                          out_status,
                                          v_devphase,
                                          v_devstatus,
                                          out_errormessage);
   END waitforrequest;



   PROCEDURE print_error (errbuf         OUT VARCHAR2,
                          retcode        OUT NUMBER,
                          p_file_id   IN     NUMBER)
   IS
      v_requester   VARCHAR2 (200);

      CURSOR c_data
      IS
         SELECT DISTINCT pie.column_name,
                         pie.error_message,
                         xups.item_code,
                         xups.line_number,
                         xups.batch_group,
                         pie.table_name
           FROM po_interface_errors pie, xxshp_upd_po_stg xups
          WHERE     xups.interface_header_id = pie.interface_header_id
                AND xups.file_id = p_file_id;
   BEGIN
      BEGIN
         SELECT user_name
           INTO v_requester
           FROM fnd_user
          WHERE 1 = 1 AND user_id = g_user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_requester := 'N/A';
      END;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Create PO status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || v_requester);
      outf ('      ' || 'Proceed Date on : ' || SYSDATE);
      outF (
            '      '
         || '--------------- ------------- ------------- ------- --------------------------------------------------------');
      outF (
            '      '
         || 'COLUMN_NAME     ITEM_CODE     BATCH_GROUP   LINE_NO ERROR_MESSAGE                                           ');
      outF (
            '      '
         || '--------------- ------------- ------------- ------- --------------------------------------------------------');

      outf (' ');

      FOR i IN c_data
      LOOP
         outf (
               '      '
            || RPAD (i.column_name, 14, ' ')
            || '  '
            || RPAD (i.item_code, 12, ' ')
            || '  '
            || RPAD (i.batch_group, 12, ' ')
            || '  '
            || RPAD (i.line_number, 6, ' ')
            || '  '
            || RPAD (i.error_message || '/' || i.table_name, 45, ' '));
      END LOOP;

      outF (
            '      '
         || '--------------- ------------- ------------- ------- --------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_error;

   PROCEDURE print_success (errbuf         OUT VARCHAR2,
                            retcode        OUT NUMBER,
                            p_file_id   IN     NUMBER)
   IS
      v_requester   VARCHAR2 (200);

      CURSOR c_data
      IS
         SELECT DISTINCT xups.po_number,
                         xups.item_code,
                         xups.item_description
           FROM xxshp_upd_po_stg xups
          WHERE 1 = 1 AND xups.file_id = p_file_id;
   BEGIN
      BEGIN
         SELECT user_name
           INTO v_requester
           FROM fnd_user
          WHERE 1 = 1 AND user_id = g_user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_requester := 'N/A';
      END;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Create PO status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || v_requester);
      outf ('      ' || 'Proceed Date on : ' || SYSDATE);
      outF (
            '      '
         || '--------------- ------------- --------------------------------------------------------');
      outF (
            '      '
         || 'PO_NUMBER       ITEM_CODE     ITEM_DESCRIPTION                                        ');
      outF (
            '      '
         || '--------------- ------------- --------------------------------------------------------');

      outf (' ');

      FOR i IN c_data
      LOOP
         outf (
               '      '
            || RPAD (i.po_number, 14, ' ')
            || '  '
            || RPAD (i.item_code, 12, ' ')
            || '  '
            || RPAD (i.item_description, 100, ' '));
      END LOOP;

      outF (
            '      '
         || '--------------- ------------- --------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_success;

   PROCEDURE print_result (errbuf         OUT VARCHAR2,
                           retcode        OUT NUMBER,
                           p_file_id   IN     NUMBER)
   IS
      v_requester   VARCHAR2 (200);

      CURSOR c_data
      IS
         SELECT batch_group,
                vendor_name,
                agent_name,
                bpa_number,
                line_type,
                item_code,
                quantity,
                status,
                error_message
           FROM xxshp_upd_po_stg stg
          WHERE     1 = 1
                AND NVL (status, 'E') = 'E'
                AND error_message IS NOT NULL
                AND NVL (flag, 'N') = 'N'
                AND file_id = p_file_id;
   BEGIN
      BEGIN
         SELECT user_name
           INTO v_requester
           FROM fnd_user
          WHERE 1 = 1 AND user_id = g_user_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_requester := 'N/A';
      END;

      outf ('/* START */');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('      ' || 'Upload Create PO status report');
      outf (' ');
      outf ('      ' || 'Proceed By      : ' || v_requester);
      outf ('      ' || 'Proceed Date on : ' || SYSDATE);
      outF (
            '      '
         || '--------------- ------------------------------------------ ---------------------------- ------------- ------------- ------------ ------- --------------------------------------------------------');
      outF (
            '      '
         || 'BATCH_GROUP     VENDOR_NAME                                AGENT_NAME                   BPA_NUMBER    ITEM_CODE     QUANTITY     STATUS  ERROR_MESSAGE                                           ');
      outF (
            '      '
         || '--------------- ------------------------------------------ ---------------------------- ------------- ------------- ------------ ------- --------------------------------------------------------');

      outf (' ');

      FOR i IN c_data
      LOOP
         outf (
               '      '
            || RPAD (i.batch_group, 14, ' ')
            || '  '
            || RPAD (i.vendor_name, 41, ' ')
            || '  '
            || RPAD (i.agent_name, 27, ' ')
            || '  '
            || RPAD (i.bpa_number, 12, ' ')
            || '  '
            || RPAD (i.item_code, 12, ' ')
            || '  '
            || RPAD (i.quantity, 11, ' ')
            || '  '
            || RPAD (i.status, 6, ' ')
            || '  '
            || RPAD (i.error_message, 45, ' '));
      END LOOP;

      outF (
            '      '
         || '--------------- ------------------------------------------ ---------------------------- ------------- ------------- ------------ ------- --------------------------------------------------------');
      outf (' ');
      outf (' ');
      outf (' ');
      outf ('/* END */');
   END print_result;

   PROCEDURE po_auto_approve (po_number VARCHAR2)
   IS
      v_item_key   VARCHAR2 (100);
      var_pathid   NUMBER;
      var_fromid   NUMBER;
      var_toid     NUMBER;

      CURSOR c_po_details
      IS
         SELECT pha.po_header_id,
                pha.org_id,
                pha.segment1,
                pha.agent_id,
                pdt.document_subtype,
                pdt.document_type_code,
                pha.authorization_status
           FROM apps.po_headers_all pha, apps.po_document_types_all pdt
          WHERE     pha.type_lookup_code = pdt.document_subtype
                AND pha.org_id = pdt.org_id
                AND pdt.document_type_code = 'PO'
                AND authorization_status IN ('INCOMPLETE',
                                             'REQUIRES REAPPROVAL',
                                             'REJECTED')
                AND segment1 = po_number;   -- Enter the Purchase Order Number
   BEGIN
      fnd_global.apps_initialize (user_id        => g_user_id,
                                  resp_id        => g_resp_id,
                                  resp_appl_id   => g_resp_appl_id);

      FOR p_rec IN c_po_details
      LOOP
         mo_global.init (p_rec.document_type_code);
         mo_global.set_policy_context ('S', p_rec.org_id);

         SELECT    p_rec.po_header_id
                || '-'
                || TO_CHAR (po_wf_itemkey_s.NEXTVAL)
           INTO v_item_key
           FROM DUAL;

         SELECT position_structure_id, person_id, superior_person_id
           INTO var_pathid, var_fromid, var_toid
           FROM xxshp_hr_pos_hierarchy_v
          WHERE person_id = p_rec.agent_id;

         logf (
               'Calling po_reqapproval_init1.start_wf_process for po_id=> '
            || p_rec.segment1);

         po_reqapproval_init1.start_wf_process (
            itemtype                 => 'POAPPRV',
            itemkey                  => v_item_key,
            workflowprocess          => 'POAPPRV_TOP',
            actionoriginatedfrom     => 'PO_FORM',
            documentid               => p_rec.po_header_id,    -- po_header_id
            documentnumber           => p_rec.segment1, -- Purchase Order Number
            preparerid               => p_rec.agent_id,   -- Buyer/Preparer_id
            documenttypecode         => p_rec.document_type_code,       --'PO'
            documentsubtype          => p_rec.document_subtype,   --'STANDARD'
            submitteraction          => 'APPROVE',
            forwardtoid              => NULL,
            forwardfromid            => NULL,
            defaultapprovalpathid    => var_pathid,
            note                     => NULL,
            printflag                => 'N',
            faxflag                  => 'N',
            faxnumber                => NULL,
            emailflag                => 'N',
            emailaddress             => NULL,
            createsourcingrule       => 'N',
            releasegenmethod         => 'N',
            updatesourcingrule       => 'N',
            massupdatereleases       => 'N',
            retroactivepricechange   => 'N',
            orgassignchange          => 'N',
            communicatepricechange   => 'N',
            p_background_flag        => 'N',
            p_initiator              => NULL,
            p_xml_flag               => NULL,
            fpdsngflag               => 'N',
            p_source_type_code       => NULL);

         COMMIT;
         logf ('The PO which is Approved Now =>' || p_rec.segment1);
      END LOOP;
   END po_auto_approve;

   PROCEDURE populate_iface (errbuf            OUT VARCHAR2,
                             retcode           OUT NUMBER,
                             p_file_id      IN     NUMBER,
                             p_count_hdr       OUT PLS_INTEGER,
                             p_count_line      OUT PLS_INTEGER,
                             p_count_dist      OUT PLS_INTEGER)
   IS
      v_tot_hdr_counter             PLS_INTEGER DEFAULT 0;
      v_tot_line_counter            PLS_INTEGER DEFAULT 0;
      v_tot_dist_counter            PLS_INTEGER DEFAULT 0;

      iface_hdr                     PO_HEADERS_INTERFACE%ROWTYPE;
      iface_line                    PO_LINES_INTERFACE%ROWTYPE;
      iface_dist                    PO_DISTRIBUTIONS_INTERFACE%ROWTYPE;

      v_org_id                      NUMBER;
      v_agent_id                    NUMBER;
      v_agent_name                  VARCHAR2 (250);
      v_interface_header_id         NUMBER;
      v_interface_line_id           NUMBER;
      v_interface_distribution_id   NUMBER;
      v_category_id                 NUMBER;
      v_segment1                    VARCHAR2 (50);
      v_segment2                    VARCHAR2 (50);
      v_segment3                    VARCHAR2 (50);
      v_segment4                    VARCHAR2 (50);
      v_segment5                    VARCHAR2 (50);
      v_segment6                    VARCHAR2 (50);
      v_segment7                    VARCHAR2 (50);

      v_org_location                NUMBER;
      v_mfg_id                      NUMBER;
      v_vendor_id                   NUMBER;
      v_vendor_site_id              NUMBER;
      v_asl_id                      NUMBER;
      v_fr_header_id                NUMBER;
      v_fr_line_id                  NUMBER;

      v_rate_type                   VARCHAR2 (50);
      v_rate_type_code              VARCHAR2 (50);
      v_rate_date                   DATE;
      v_rate                        VARCHAR2 (50);
      v_conversion_rate             VARCHAR2 (50);

      CURSOR iface_hdr_cur
      IS
           SELECT organization_code,
                  vendor_name,
                  vendor_site_code,
                  ship_to_location,
                  currency_code,
                  batch_group,
                  ship_to_org_code,
                  old_po_number,
                  agent_name
             FROM xxshp_upd_po_stg
            WHERE file_id = p_file_id
         GROUP BY organization_code,
                  vendor_name,
                  vendor_site_code,
                  ship_to_location,
                  currency_code,
                  batch_group,
                  old_po_number,
                  ship_to_org_code,
                  agent_name;

      CURSOR iface_line_cur (
      p_batch_group         VARCHAR2,
      p_vendor_name         VARCHAR2,
      p_vendor_site_code    VARCHAR2)
   IS
        SELECT organization_code,
               vendor_name,
               vendor_site_code,
               ship_to_location,
               bill_to_location,
               agent_name,
               ship_to_org_code,
               currency_code,
               old_po_number,
               bpa_number,
               line_number,
               line_type,
               inventory_item_id,
               item_code,
               item_description,
               quantity,
               unit_price,
               unit_of_measure,
               promise_date,
               need_by_date,
               shipment_number,
               req_header_ref_num,
               req_line_ref_num,
               deliver_to_location,
               deliver_to_person
          FROM xxshp_upd_po_stg
         WHERE     file_id = p_file_id
               AND batch_group = p_batch_group
               AND vendor_name = p_vendor_name
               AND vendor_site_code = p_vendor_site_code
      ORDER BY line_number;
   BEGIN
      logf ('Run interface validation.');

      FOR HDR IN iface_hdr_cur
      LOOP
         BEGIN
            SELECT organization_id
              INTO v_org_location
              FROM mtl_parameters
             WHERE organization_code = hdr.ship_to_org_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Organization id not found' || SQLERRM);
               RAISE e_exception;
         END;

         -- get data buyer.
         BEGIN
            SELECT person_id, last_name
              INTO v_agent_id, v_agent_name
              FROM per_people_v7
             WHERE 1 = 1 AND last_name = hdr.agent_name AND ROWNUM <= 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Error get agent id' || SQLERRM);
               RAISE e_exception;
         END;

         BEGIN
            SELECT pv.vendor_id, pvs.vendor_site_id
              INTO v_vendor_id, v_vendor_site_id
              FROM po_vendors pv, po_vendor_sites_all pvs
             WHERE     1 = 1
                   AND pv.vendor_id = pvs.vendor_id
                   AND pv.vendor_name = hdr.vendor_name
                   AND pvs.vendor_site_code = hdr.vendor_site_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Not found manufacture name ' || SQLERRM);
               RAISE e_exception;
         END;

         --Get Rate
         BEGIN
            SELECT CONVERSION_TYPE
              INTO v_conversion_rate
              FROM GL_DAILY_CONVERSION_TYPES
             WHERE 1 = 1 AND CONVERSION_TYPE = g_conversion_rate_type;

            IF hdr.currency_code <> 'IDR'
            THEN
               SELECT conversion_type,
                      status_code,
                      conversion_date,
                      conversion_rate
                 INTO v_rate_type,
                      v_rate_type_code,
                      v_rate_date,
                      v_rate
                 FROM GL_DAILY_RATES
                WHERE     1 = 1
                      AND FROM_CURRENCY = hdr.currency_code
                      AND TO_CURRENCY = 'IDR'
                      AND CONVERSION_TYPE = v_conversion_rate
                      AND TRUNC (CONVERSION_DATE) = TRUNC (SYSDATE);
            ELSE
               v_rate_type := NULL;
               v_rate_type_code := NULL;
               v_rate_date := NULL;
               v_rate := NULL;
            END IF;
         END;

         logf ('Insert Header.');

         SELECT po_headers_interface_s.NEXTVAL
           INTO v_interface_header_id
           FROM DUAL;

         iface_hdr.interface_header_id := v_interface_header_id;
         iface_hdr.org_id := g_org_id;
         iface_hdr.batch_id := v_interface_header_id;
         iface_hdr.vendor_name := hdr.vendor_name;
         iface_hdr.document_type_code := 'STANDARD';
         iface_hdr.vendor_site_code := hdr.vendor_site_code;
         iface_hdr.ship_to_location := hdr.ship_to_location;
         iface_hdr.bill_to_location := hdr.ship_to_location;
         iface_hdr.revision_num := g_hdr_revision_num;
         iface_hdr.action := g_hdr_action;
         iface_hdr.currency_code := hdr.currency_code;
         iface_hdr.rate_type := v_rate_type;
         --iface_hdr.rate_type_code := v_rate_type_code;
         iface_hdr.rate_date := v_rate_date;
         iface_hdr.rate := v_rate;
         iface_hdr.attribute1 := hdr.old_po_number;
         iface_hdr.agent_id := v_agent_id;

         iface_hdr.created_by := g_user_id;
         iface_hdr.last_updated_by := g_user_id;
         iface_hdr.last_update_login := g_login_id;
         iface_hdr.last_update_date := SYSDATE;
         iface_hdr.creation_date := SYSDATE;

         xxshp_po_interfaces_pkg.ins_hdr (iface_hdr);
         logf ('Header inserted ' || v_interface_header_id);

         v_tot_hdr_counter := v_tot_hdr_counter + 1;

         BEGIN
            UPDATE xxshp_upd_po_stg
               SET interface_header_id = v_interface_header_id
             WHERE file_id = p_file_id AND batch_group = hdr.batch_group;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Update interface header id error ' || SQLERRM);
         END;

         logf ('Insert to line. ');

         FOR LINE
         IN iface_line_cur (hdr.batch_group,
                            hdr.vendor_name,
                            hdr.vendor_site_code)
         LOOP
            /* validasi ASL */
            BEGIN
               SELECT DISTINCT asl_id
                 INTO v_asl_id
                 FROM po_approved_supplier_list
                WHERE     1 = 1
                      AND vendor_id = v_vendor_id
                      AND vendor_site_id = v_vendor_site_id
                      AND item_id = line.inventory_item_id
                      AND NVL (disable_flag, 'N') <> 'Y';
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  logf (
                        'More than 1 ASL active for item :'
                     || line.item_code
                     || ' - '
                     || SQLERRM);
                  RAISE e_exception;
               WHEN OTHERS
               THEN
                  logf (
                        'Error get ASL for item :'
                     || line.item_code
                     || ' - '
                     || SQLERRM);
                  RAISE e_exception;
            END;

            BEGIN
               SELECT DISTINCT poh.po_header_id, pll.po_line_id
                 INTO v_fr_header_id, v_fr_line_id
                 FROM po_headers_all poh,
                      po_lines_all pll,
                      mtl_uom_conversions muc
                WHERE     poh.type_lookup_code = 'BLANKET'
                      AND NVL (poh.global_agreement_flag, 'N') = 'Y'
                      AND poh.authorization_status = 'APPROVED'
                      AND po_headers_sv3.get_po_status (poh.po_header_id) =
                             'Approved'
                      AND poh.po_header_id = pll.po_header_id
                      AND pll.item_id = line.inventory_item_id
                      AND poh.vendor_id = v_vendor_id
                      AND NVL (pll.cancel_flag, 'N') = 'N'
                      AND NVL (pll.closed_code, 'X') <> 'CLOSED'
                      AND pll.UNIT_MEAS_LOOKUP_CODE = muc.unit_of_measure
                      AND poh.org_id = g_org_id
                      AND poh.segment1 = line.bpa_number;
            EXCEPTION
               WHEN TOO_MANY_ROWS
               THEN
                  logf (
                     'More than 1 BPA active for item :' || line.item_code);
                  RAISE e_exception;
               WHEN OTHERS
               THEN
                  logf ('Invalid Number, ');
                  RAISE e_exception;
            END;

            SELECT PO_LINES_INTERFACE_S.NEXTVAL
              INTO v_interface_line_id
              FROM DUAL;

            iface_line.interface_line_id := v_interface_line_id;
            iface_line.interface_header_id := v_interface_header_id;
            iface_line.action := g_dtl_action;
            iface_line.line_type := g_dtl_line_type;
            iface_line.from_header_id := v_fr_header_id;
            iface_line.from_line_id := v_fr_line_id;

            iface_line.item_id := line.inventory_item_id;
            iface_line.item := line.item_code;
            iface_line.item_description := line.item_description;
            iface_line.unit_of_measure := line.unit_of_measure;
            iface_line.quantity := line.quantity;
            --iface_line.unit_price := line.unit_price;
            iface_line.promised_date := line.promise_date;
            iface_line.need_by_date := line.promise_date;
            iface_line.ship_to_location := line.ship_to_location;
            iface_line.ship_to_organization_code := line.ship_to_org_code;
            iface_line.shipment_num := line.shipment_number;
            iface_line.line_num := line.line_number;


            iface_line.created_by := g_user_id;
            iface_line.creation_date := SYSDATE;
            iface_line.last_updated_by := g_user_id;
            iface_line.last_update_date := SYSDATE;
            iface_line.last_update_login := g_login_id;

            xxshp_po_interfaces_pkg.ins_lns (iface_line);

            v_tot_line_counter := v_tot_line_counter + 1;

            SELECT PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL
              INTO v_interface_distribution_id
              FROM DUAL;

            iface_dist.interface_distribution_id :=
               v_interface_distribution_id;
            iface_dist.interface_header_id := v_interface_header_id;
            iface_dist.interface_line_id := v_interface_line_id;

            iface_dist.distribution_num := 1;
            iface_dist.quantity_ordered := line.quantity;
            iface_dist.req_header_reference_num := line.req_header_ref_num;
            iface_dist.req_line_reference_num := line.req_header_ref_num;
            iface_dist.deliver_to_location := line.deliver_to_location;
            --iface_dist.deliver_to_person_full_name := line.deliver_to_person;

            iface_dist.created_by := g_user_id;
            iface_dist.creation_date := SYSDATE;
            iface_dist.last_updated_by := g_user_id;
            iface_dist.last_update_date := SYSDATE;
            iface_dist.last_update_login := g_login_id;

            xxshp_po_interfaces_pkg.ins_dist (iface_dist);

            v_tot_dist_counter := v_tot_dist_counter + 1;
         END LOOP;
      END LOOP;

      p_count_hdr := v_tot_hdr_counter;
      p_count_line := v_tot_line_counter;
      p_count_dist := v_tot_dist_counter;

      COMMIT;

      IF g_debug = 'Y'
      THEN
         logF ('v_file_id         ' || p_file_id);
         logF ('v_tot_hdr_counter  ' || v_tot_hdr_counter);
         logF ('v_tot_line_counter ' || v_tot_line_counter);
         logF ('v_tot_dist_counter ' || v_tot_dist_counter);
      END IF;
   EXCEPTION
      WHEN e_bohong
      THEN
         ROLLBACK;
         logf ('Error insert to interface ROLLBACK.');
      WHEN e_exception
      THEN
         ROLLBACK;
         logf ('Error insert to interface ROLLBACK.');
      WHEN OTHERS
      THEN
         ROLLBACK;
         logf ('Error insert to interface ROLLBACK.');
   END populate_iface;

   PROCEDURE final_validation (errbuf         OUT VARCHAR2,
                               retcode        OUT NUMBER,
                               p_file_id   IN     NUMBER)
   IS
      l_conc_status   BOOLEAN;
      l_nextproceed   BOOLEAN := FALSE;

      l_error         PLS_INTEGER := 0;
      l_jml_data      NUMBER := 0;


      CURSOR c_notvalid_items
      IS
           SELECT file_id, status
             FROM xxshp_upd_po_stg xups
            WHERE     1 = 1
                  AND NVL (status, 'E') = 'E'
                  AND NVL (flag, 'Y') = 'Y'
                  AND file_id = p_file_id
         GROUP BY file_id, status;
   BEGIN
      l_jml_data := 0;

      FOR i IN c_notvalid_items
      LOOP
         EXIT WHEN c_notvalid_items%NOTFOUND;

         l_jml_data := l_jml_data + 1;

         EXIT WHEN l_jml_data > 0;
      END LOOP;

      IF l_jml_data > 0
      THEN
         l_nextproceed := TRUE;
      END IF;

      IF l_nextproceed
      THEN
         UPDATE xxshp_upd_po_stg
            SET status = 'E', flag = 'N'
          WHERE 1 = 1 AND NVL (flag, 'Y') = 'Y' AND file_id = p_file_id;

         COMMIT;
      END IF;

      SELECT COUNT (*)
        INTO l_error
        FROM xxshp_upd_po_stg
       WHERE     1 = 1
             AND NVL (status, 'E') = 'E'
             AND NVL (flag, 'N') = 'N'
             AND file_id = p_file_id;

      logf ('Error validation count : ' || l_error);

      IF l_error > 0
      THEN
         l_conc_status := fnd_concurrent.set_completion_status ('ERROR', 2);

         print_result (errbuf, retcode, p_file_id);
         retcode := 2;

         logf ('Error, Create PO for data all ..!!!');
      ELSE
         logf ('Successfully, Create PO for data all ..!!!');
      END IF;
   END final_validation;

   PROCEDURE generate_po_service (errbuf         OUT VARCHAR2,
                                  retcode        OUT NUMBER,
                                  p_file_id   IN     NUMBER)
   IS
      x_phase                 VARCHAR2 (20);
      x_status                VARCHAR2 (20);
      x_dev_phase             VARCHAR2 (20);
      x_dev_status            VARCHAR2 (20);
      x_message               VARCHAR2 (240);
      v_wait_result           BOOLEAN;

      v_tot_hdr_counter       PLS_INTEGER DEFAULT 0;
      v_tot_line_counter      PLS_INTEGER DEFAULT 0;
      v_tot_dist_counter      PLS_INTEGER DEFAULT 0;
      v_tot_ship_counter      PLS_INTEGER DEFAULT 0;

      v_tot_hdr_err_counter   PLS_INTEGER DEFAULT 0;
      v_batch_status          xxshp_pr_po_batch.batch_status%TYPE;
      v_error_message         xxshp_pr_po_batch.MESSAGE%TYPE;
      v_emp_name              per_all_people_f.full_name%TYPE;

      v_batch_id              PLS_INTEGER DEFAULT 0;
      l_po_number             NUMBER;
      g_intval_time           PLS_INTEGER DEFAULT 0;
      v_std_rpt_request_id    PLS_INTEGER DEFAULT 0;
      v_iface_request_id      PLS_INTEGER DEFAULT 0;
      b                       NUMBER;

      v_iface_source_code     po_headers_all.interface_source_code%TYPE;

      CURSOR c_po_header (p_iface_req_id NUMBER)
      IS
         SELECT segment1 po_number
           FROM po_headers_all
          WHERE request_id = p_iface_req_id;

      CURSOR c_generate_po
      IS
           SELECT interface_header_id
             FROM xxshp_upd_po_stg
            WHERE file_id = p_file_id
         GROUP BY batch_group, interface_header_id;
   BEGIN
      logF ('-----------------');
      logF ('Request started');
      logF ('-----------------');
      logF (' ');


      --g_start_date := TO_DATE (sysdate, 'RRRR/MM/DD HH24:MI:SS');
      g_end_date := TO_DATE (SYSDATE, 'RRRR/MM/DD HH24:MI:SS');

      BEGIN
         SELECT EMP.full_name
           INTO v_emp_name
           FROM fnd_user USR, per_all_people_f EMP
          WHERE     USR.user_id = g_user_id
                AND USR.employee_id = EMP.person_id
                AND TRUNC (SYSDATE) BETWEEN effective_start_date
                                        AND effective_end_date;
      EXCEPTION
         WHEN OTHERS
         THEN
            logF (cust_mesg (47).mesg);
            RAISE e_exception;
      END;

      --POPULATE and VALIDATE ONLY ------------------------------------------------------------------------------------------------------------------------------------------------

      --logf ('INSERTING INTO STG TABLE');

      --insert_data (errbuf, retcode, p_file_id);

      logf ('INSERTING INTO INTERFACE');
      logF (p_file_id);
      XXSHP_UPD_CRT_PO_PKG.populate_iface (
         errbuf         => errbuf,
         retcode        => retcode,
         p_file_id      => p_file_id,
         p_count_hdr    => v_tot_hdr_counter,
         p_count_line   => v_tot_line_counter,
         p_count_dist   => v_tot_dist_counter);

      logF ('total header ' || v_tot_hdr_counter);
      logF ('total line ' || v_tot_line_counter);
      logF ('total dist ' || v_tot_dist_counter);

      logF ('data di interface ' || b);

      --SUBMISSION ------------------------------------------------------------------------------------------------------------------------------------------------

      mo_global.init ('PO');
      mo_global.set_policy_context ('S', '82');
      apps.fnd_global.apps_initialize (user_id        => g_user_id,
                                       resp_id        => g_resp_id,
                                       resp_appl_id   => g_resp_appl_id);

      FOR i IN c_generate_po
      LOOP
         v_iface_request_id :=
            fnd_request.submit_request (
               application   => 'PO',
               program       => 'POXPOPDOI',
               description   => 'Import Standard Purchase Orders',
               start_time    => SYSDATE + 2 / 24 / 60 / 60,
               sub_request   => FALSE,
               argument1     => NULL,                         -- Default Buyer
               argument2     => 'STANDARD',                   -- Document Type
               argument3     => NULL,                      -- Document SubType
               argument4     => 'N',                 -- Create or Update Items
               argument5     => 'N',                  -- Create Sourcing Rules
               argument6     => 'APPROVED', --'INCOMPLETE', -- Approval Status
               argument7     => NULL,                    -- Release Generation
               argument8     => i.interface_header_id,             -- Batch Id
               argument9     => NULL,                        -- Operating Unit
               argument10    => NULL,                      -- Global Agreement
               argument11    => NULL,                 -- Enable Sourcing Level
               argument12    => NULL,                        -- Sourcing Level
               argument13    => NULL,                        -- Inv Org Enable
               argument14    => NULL                 -- Inventory Organization
                                    );

         logF ('req iface ' || v_iface_request_id);

         IF v_iface_request_id = 0
         THEN
            logF (cust_mesg (5).mesg);
            ROLLBACK;
            logF (cust_mesg (2).mesg);
            RAISE e_exception;
         END IF;

         COMMIT;

         --REQUEST------------------------------------------------------------------------------------------------------------------------------------------------
         v_wait_result :=
            Fnd_Concurrent.WAIT_FOR_REQUEST (v_iface_request_id,
                                             g_intval_time,
                                             g_max_time,
                                             x_phase,
                                             x_status,
                                             x_dev_phase,
                                             x_dev_status,
                                             x_message);

         IF NOT (x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL')
         THEN
            logF (cust_mesg (7).mesg);
            logF (cust_mesg (20).mesg);
            RAISE e_exception;
         END IF;

         COMMIT;
         logF (cust_mesg (1).mesg);
         logF (cust_mesg (8).mesg);
      --RUN AUTO APPROVE--------------------------------------------------------------------------------------------------------------------------------------
      /*logf (v_iface_request_id || ',' || v_iface_source_code);

      BEGIN
         SELECT DISTINCT segment1
           INTO l_po_number
           FROM po_headers_all
          WHERE request_id = v_iface_request_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('error bro');
      END;


      FOR rec IN c_po_header (v_iface_request_id)
      LOOP
         po_auto_approve (rec.po_number);
         DBMS_OUTPUT.PUT_LINE ('PO_APPROVE OK');
         logf ('Po Number : ' || l_po_number);
      END LOOP;*/
      END LOOP;

      -- update untuk memasukan po number ke stg
      FOR i IN valid_pr_po_hdr (p_file_id)
      LOOP
         UPDATE xxshp_upd_po_stg
            SET po_number = i.po_number
          WHERE interface_header_id = i.interface_header_id;

         COMMIT;
      END LOOP;

      logF (' ');
      logF ('-----------------');
      logF ('Request completed');
      logF ('-----------------');
   EXCEPTION
      WHEN e_exception
      THEN
         logF (' ');
         logF ('-----------------');
         logF ('Request completed exc ' || SQLERRM);
         logF ('-----------------');
      WHEN e_bohong
      THEN
         logF (' ');
         logF ('-----------------');
         logF ('Request completed exc bohong' || SQLERRM);
         logF ('-----------------');
      WHEN OTHERS
      THEN
         logF (' ');
         logF ('-----------------');
         logF ('Request failed');
         logF ('-----------------');

         logF (SQLCODE || '-' || SQLERRM);

         ROLLBACK;
         logF (cust_mesg (2).mesg);


         IF g_debug = 'Y'
         THEN
            logF (SQL%ROWCOUNT || ' failed in updated');
         END IF;

         COMMIT;
         logF (cust_mesg (1).mesg);
         RAISE e_exception;
   END generate_po_service;

   PROCEDURE insert_data (errbuf      OUT VARCHAR2,
                          retcode     OUT NUMBER,
                          p_file_id       NUMBER)
   IS
      v_filename              VARCHAR2 (50);
      v_plan_name             VARCHAR2 (50);
      v_blob_data             BLOB;
      v_blob_len              NUMBER;
      v_position              NUMBER;
      v_loop                  NUMBER;
      v_raw_chunk             RAW (10000);
      c_chunk_len             NUMBER := 1;
      v_char                  CHAR (1);
      v_line                  VARCHAR2 (32767) := NULL;
      v_tab                   varchar2_table;
      v_tablen                NUMBER;
      x                       NUMBER;
      l_err                   NUMBER := 0;

      l_batch_group           VARCHAR2 (250);
      l_organization          VARCHAR2 (10);
      l_vendor_name           VARCHAR2 (250);
      l_vendor_site_code      VARCHAR2 (250);
      l_ship_to_location      VARCHAR2 (250);
      l_bill_to_location      VARCHAR2 (250);
      l_agent_name            VARCHAR2 (100);
      l_currency_code         VARCHAR2 (10);
      l_old_po_number         VARCHAR2 (100);
      l_bpa_number            VARCHAR2 (100);
      l_line_number           VARCHAR2 (100);
      l_line_type             VARCHAR2 (100);
      l_item_code             VARCHAR2 (100);
      l_quantity              VARCHAR2 (100);
      l_unit_price            VARCHAR2 (100);
      l_unit_of_measure       VARCHAR2 (100);
      l_promise_date          VARCHAR2 (100);
      l_need_by_date          VARCHAR2 (100);
      l_shipment_number       VARCHAR2 (100);
      l_ship_to_org_code      VARCHAR2 (100);
      l_req_header_ref_num    VARCHAR2 (100);
      l_req_line_ref_num      VARCHAR2 (100);
      l_deliver_to_location   VARCHAR2 (100);
      l_deliver_to_person     VARCHAR2 (100);

      v_inventory_item_id     NUMBER;
      v_item_description      VARCHAR2 (100);
      v_line_action           VARCHAR2 (100);
      v_vendor_id             NUMBER;
      v_vendor_site_id        NUMBER;
      v_bpa_num               VARCHAR2 (50);
      v_org_location          NUMBER;
      v_loc_id                NUMBER;

      l_comments              VARCHAR2 (200);
      l_status                VARCHAR2 (20);
      l_error_message         VARCHAR2 (200);


      l_err_cnt               NUMBER;
      l_stg_cnt               NUMBER := 0;
      l_item_cnt              NUMBER := 0;
      l_cnt_err_format        NUMBER := 0;
      l_sql                   VARCHAR2 (32767);
      l_cnt_err               NUMBER;
      l_conc_status           BOOLEAN;

      l_org_id                NUMBER := 0;
      l_sub_inv_code          VARCHAR2 (10);
      l_status_code           VARCHAR2 (20);

      l_category_set_id       NUMBER;
      l_category_id           NUMBER;
   BEGIN
      BEGIN
         SELECT file_data, file_name
           INTO v_blob_data, v_filename
           FROM fnd_lobs
          WHERE 1 = 1 AND file_id = p_file_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            logf ('File Not Found');
            RAISE NO_DATA_FOUND;
      END;

      v_blob_len := DBMS_LOB.getlength (v_blob_data);
      v_position := 1;
      v_loop := 1;

      WHILE (v_position <= v_blob_len)
      LOOP
         v_raw_chunk := DBMS_LOB.SUBSTR (v_blob_data, c_chunk_len, v_position);
         v_char := CHR (hex_to_decimal (RAWTOHEX (v_raw_chunk)));
         v_line := v_line || v_char;
         v_position := v_position + c_chunk_len;

         IF v_char = CHR (10)
         THEN
            IF v_position <> v_blob_len
            THEN
               v_line :=
                  REPLACE (
                     REPLACE (
                        SUBSTR (TRIM (v_line), 1, LENGTH (TRIM (v_line)) - 1),
                        CHR (13),
                        ''),
                     CHR (10),
                     '');
            END IF;

            delimstring_to_table (v_line,
                                  v_tab,
                                  x,
                                  v_tablen);

            --logf ('x : ' || x);
            IF x = 24
            THEN
               IF v_loop >= 2
               THEN
                  FOR i IN 1 .. x
                  LOOP
                     IF i = 1
                     THEN
                        l_batch_group := TRIM (v_tab (1));
                     ELSIF i = 2
                     THEN
                        l_organization := TRIM (v_tab (2));
                     ELSIF i = 3
                     THEN
                        l_vendor_name := TRIM (v_tab (3));
                     ELSIF i = 4
                     THEN
                        l_vendor_site_code := TRIM (v_tab (4));
                     ELSIF i = 5
                     THEN
                        l_ship_to_location := TRIM (v_tab (5));
                     ELSIF i = 6
                     THEN
                        l_bill_to_location := TRIM (v_tab (6));
                     ELSIF i = 7
                     THEN
                        l_agent_name := TRIM (v_tab (7));
                     ELSIF i = 8
                     THEN
                        l_currency_code := TRIM (v_tab (8));
                     ELSIF i = 9
                     THEN
                        l_old_po_number := TRIM (v_tab (9));
                     ELSIF i = 10
                     THEN
                        l_bpa_number := TRIM (v_tab (10));
                     ELSIF i = 11
                     THEN
                        l_line_number := TRIM (v_tab (11));
                     ELSIF i = 12
                     THEN
                        l_line_type := TRIM (v_tab (12));
                     ELSIF i = 13
                     THEN
                        l_item_code := TRIM (v_tab (13));
                     ELSIF i = 14
                     THEN
                        l_quantity := TRIM (v_tab (14));
                     ELSIF i = 15
                     THEN
                        l_unit_price := TRIM (v_tab (15));
                     ELSIF i = 16
                     THEN
                        l_unit_of_measure := TRIM (v_tab (16));
                     ELSIF i = 17
                     THEN
                        l_promise_date := TRIM (v_tab (17));
                     ELSIF i = 18
                     THEN
                        l_need_by_date := TRIM (v_tab (18));
                     ELSIF i = 19
                     THEN
                        l_shipment_number := TRIM (v_tab (19));
                     ELSIF i = 20
                     THEN
                        l_ship_to_org_code := TRIM (v_tab (20));
                     ELSIF i = 21
                     THEN
                        l_req_header_ref_num := TRIM (v_tab (21));
                     ELSIF i = 22
                     THEN
                        l_req_line_ref_num := TRIM (v_tab (22));
                     ELSIF i = 23
                     THEN
                        l_deliver_to_location := TRIM (v_tab (23));
                     ELSIF i = 24
                     THEN
                        l_deliver_to_person := TRIM (v_tab (24));
                     END IF;
                  END LOOP;


                  l_err_cnt := 0;
                  l_error_message := NULL;


                  IF l_batch_group = NULL
                  THEN
                     l_error_message := l_error_message || 'Invalid batch, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  --validasi org_code
                  IF l_org_id = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid organization, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  --/*
                  BEGIN
                     v_vendor_id := NULL;

                     SELECT pv.vendor_id
                       INTO v_vendor_id
                       FROM po_vendors pv
                      WHERE 1 = 1 AND pv.vendor_name = l_vendor_name;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid vendor name, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  BEGIN
                     v_vendor_site_id := NULL;

                     SELECT pv.vendor_id, pvs.vendor_site_id
                       INTO v_vendor_id, v_vendor_site_id
                       FROM po_vendors pv, po_vendor_sites_all pvs
                      WHERE     1 = 1
                            AND pv.vendor_id = pvs.vendor_id
                            AND pv.vendor_name = l_vendor_name
                            AND pvs.vendor_site_code = l_vendor_site_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid vendor site, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  IF l_ship_to_location = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid ship to loc, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  BEGIN
                     v_org_location := NULL;

                     SELECT organization_id
                       INTO v_org_location
                       FROM mtl_parameters
                      WHERE ORGANIZATION_CODE = l_ship_to_org_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid ship to org, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  BEGIN
                     v_loc_id := NULL;

                     SELECT location_id
                       INTO v_loc_id
                       FROM hr_locations
                      WHERE     1 = 1
                            AND inventory_organization_id IS NOT NULL
                            AND inventory_organization_id = v_org_location
                            AND ship_to_site_flag = 'Y'
                            AND location_code = l_ship_to_location
                            AND ROWNUM = 1;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid ship to loc, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  IF l_bill_to_location = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid bill to loc, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_agent_name = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid agent name, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_currency_code = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid currency, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_bpa_number = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid bpa number, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_line_number = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid line number, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_line_type = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid line type, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  --validasi item

                  BEGIN
                     v_inventory_item_id := NULL;

                     SELECT DISTINCT msi.inventory_item_id, description
                       INTO v_inventory_item_id, v_item_description
                       FROM mtl_system_items msi
                      WHERE 1 = 1 AND msi.segment1 = l_item_code;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || ', Item code : ' || l_item_code;
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  -- Cek BPA Number
                  BEGIN
                     SELECT DISTINCT poh.segment1
                       INTO v_bpa_num
                       FROM po_headers_all poh,
                            po_lines_all pll,
                            mtl_uom_conversions muc
                      WHERE     poh.type_lookup_code = 'BLANKET'
                            AND NVL (poh.global_agreement_flag, 'N') = 'Y'
                            AND poh.authorization_status = 'APPROVED'
                            AND po_headers_sv3.get_po_status (
                                   poh.po_header_id) = 'Approved'
                            AND poh.po_header_id = pll.po_header_id
                            AND pll.item_id = v_inventory_item_id
                            AND poh.vendor_id = v_vendor_id
                            AND NVL (pll.cancel_flag, 'N') = 'N'
                            AND NVL (pll.closed_code, 'X') <> 'CLOSED'
                            AND pll.UNIT_MEAS_LOOKUP_CODE =
                                   muc.unit_of_measure
                            AND poh.org_id = g_org_id
                            AND poh.segment1 = l_bpa_number;
                  EXCEPTION
                     WHEN TOO_MANY_ROWS
                     THEN
                        l_error_message :=
                              l_error_message
                           || ', More than 1 BPA active for item :'
                           || l_item_code;
                        l_err_cnt := l_err_cnt + 1;
                     WHEN OTHERS
                     THEN
                        l_error_message :=
                           l_error_message || 'Invalid Number, ';
                        l_err_cnt := l_err_cnt + 1;
                  END;

                  IF l_quantity = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid Quantity, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_unit_price = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid Unitprice, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_unit_of_measure = NULL
                  THEN
                     l_error_message := l_error_message || 'Invalid uom, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_promise_date = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid promise date, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_need_by_date = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid need by date, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_shipment_number = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid shipment num, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_req_header_ref_num = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid req hdr num, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_req_line_ref_num = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid req line num, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_deliver_to_location = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid deliver to location, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  IF l_deliver_to_person = NULL
                  THEN
                     l_error_message :=
                        l_error_message || 'Invalid deliver to person, ';
                     l_err_cnt := l_err_cnt + 1;
                  END IF;

                  SELECT DECODE (l_err_cnt, 0, 'N', 'E')
                    INTO l_status
                    FROM DUAL;

                  --insert to staging

                  BEGIN
                     EXECUTE IMMEDIATE
                        'insert into xxshp_upd_po_stg (
                            file_id                     ,
                            file_name                   ,
                            batch_group                 ,
                            organization_code           ,
                            vendor_name                 ,
                            vendor_site_code            ,
                            ship_to_location            ,
                            bill_to_location            ,
                            agent_name                  ,
                            ship_to_org_code            ,
                            currency_code               ,
                            old_po_number               ,
                            bpa_number                  ,
                            line_number                 ,
                            line_type                   ,
                            inventory_item_id           ,
                            item_code                   ,
                            item_description            ,
                            quantity                    ,
                            unit_price                  ,
                            unit_of_measure             ,
                            promise_date                ,
                            need_by_date                ,
                            shipment_number             ,
                            req_header_ref_num          ,
                            req_line_ref_num            ,
                            deliver_to_location         ,
                            deliver_to_person           ,
                            status                      ,
                            error_message               ,
                            created_by                  ,
                            creation_date               ,
                            last_updated_by             ,
                            last_update_date            ,
                            last_update_login           )
                         VALUES(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13,:14,:15,:16,:17,:18,:19,:20,:21,:22,:23,:24,:25,:26,:27,:28,:29,:30,:31,:32,:33,:34,:35)'
                        USING p_file_id,
                              v_filename,
                              l_batch_group,
                              l_organization,
                              l_vendor_name,
                              l_vendor_site_code,
                              l_ship_to_location,
                              l_bill_to_location,
                              l_agent_name,
                              l_ship_to_org_code,
                              l_currency_code,
                              l_old_po_number,
                              l_bpa_number,
                              l_line_number,
                              l_line_type,
                              v_inventory_item_id,
                              l_item_code,
                              v_item_description,
                              l_quantity,
                              l_unit_price,
                              l_unit_of_measure,
                              TO_DATE (l_promise_date,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              TO_DATE (l_need_by_date,
                                       'DD/MM/YYYY hh24:mi:ss'),
                              l_shipment_number,
                              l_req_header_ref_num,
                              l_req_line_ref_num,
                              l_deliver_to_location,
                              l_deliver_to_person,
                              l_status,
                              l_error_message,
                              g_user_id,
                              SYSDATE,
                              g_user_id,
                              SYSDATE,
                              g_login_id;
                  --COMMIT;

                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        logf (SQLERRM);
                        l_err := l_err + 1;
                  END;
               END IF;

               v_loop := v_loop + 1;
               v_line := NULL;
            ELSE
               IF v_position > v_blob_len
               THEN
                  logf ('Upload File Finished');
               ELSE
                  logf (
                        'Wrong file,please check the pipeline delimiter has '
                     || x
                     || ' column');
                  l_cnt_err_format := l_cnt_err_format + 1;
                  l_err := l_err + 1;
                  v_line := NULL;
               END IF;
            END IF;
         END IF;
      END LOOP;

      logf ('v_err : ' || l_err);

      IF l_err > 0
      THEN
         ROLLBACK;
         logf (
               'File: '
            || v_filename
            || ' has 0 rows inserting to staging table, ROLLBACK');

         retcode := 2;
      ELSE
         COMMIT;
         logf (
               'File: '
            || v_filename
            || ' succesfully inserting to staging table,COMMIT');
         -- final data checking
         -- 1 error 1 batch lsg di errorkan

         final_validation (errbuf, retcode, p_file_id);

         --/*
         BEGIN
            SELECT COUNT (*)
              INTO l_stg_cnt
              FROM xxshp_upd_po_stg
             WHERE 1 = 1 AND NVL (status, 'N') = 'N' AND file_id = p_file_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               logf ('Staging error');
         END;

         IF NVL (l_stg_cnt, 0) > 0
         THEN
            logf ('Call Procedure generate PO.');
            XXSHP_UPD_CRT_PO_PKG.generate_po_service (
               errbuf      => errbuf,
               retcode     => retcode,
               p_file_id   => p_file_id);
         END IF;


         BEGIN
            SELECT COUNT (1)
              INTO l_cnt_err
              FROM po_interface_errors pie, xxshp_upd_po_stg xups
             WHERE     xups.interface_header_id = pie.interface_header_id
                   AND xups.file_id = p_file_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         IF l_cnt_err > 0
         THEN
            l_conc_status :=
               fnd_concurrent.set_completion_status ('WARNING', 1);
            print_error (errbuf, retcode, p_file_id);
            retcode := 1;
         ELSE
            print_success (errbuf, retcode, p_file_id);
         END IF;

         UPDATE fnd_lobs
            SET expiration_date = SYSDATE, upload_date = SYSDATE
          WHERE 1 = 1 AND file_id = p_file_id;
      --*/

      END IF;
   --print_result(p_file_id);

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         logf ('error no data found6');
         logf (DBMS_UTILITY.format_error_backtrace);
         ROLLBACK;
      WHEN OTHERS
      THEN
         logf ('Error others : ' || SQLERRM);
         logf (DBMS_UTILITY.format_error_stack);
         logf (DBMS_UTILITY.format_error_backtrace);
         ROLLBACK;
   END insert_data;
BEGIN
   cust_mesg (1).mesg := 'COMMIT EXECUTED';
   cust_mesg (2).mesg := 'ROLLBACK EXECUTED';
   cust_mesg (3).mesg := 'VALIDATION COMPLETED';
   cust_mesg (4).mesg := 'NO RECEIVING TRANSACTIONS FOUND';

   cust_mesg (5).mesg := 'IMPORT CONCURRENT SUBMISSION FAILED';
   cust_mesg (6).mesg := 'IMPORT PO REQUEST SUBMITTED';
   cust_mesg (7).mesg := 'IMPORT PO REQUEST FAILED';
   cust_mesg (8).mesg := 'IMPORT PO PROCESS COMPLETED';
   cust_mesg (9).mesg := 'NO PO SUCCESSFULLY IMPORTED';

   cust_mesg (11).mesg := 'STANDARD PO INTERFACE ERROR REPORT SUBMITTED';
   cust_mesg (12).mesg := 'PO SERVICE REGISTER REPORT SUBMITTED';

   cust_mesg (20).mesg := 'PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR';

   cust_mesg (33).mesg := 'MAPPING ORGANIZATION TO VENDOR NOT FOUND';
   cust_mesg (34).mesg := 'INVALID VENDOR';

   cust_mesg (41).mesg := 'TOLL FEE HIERARCHY TYPE NOT EXISTS';
   cust_mesg (42).mesg := 'ITEM CODE MAPPING NOT EXISTS';
   cust_mesg (43).mesg := 'NO VALID ITEM FOUND FOR MAPPED ITEM CODE';
   cust_mesg (44).mesg := 'NO VALID UNIT PRICE FOUND';
   cust_mesg (45).mesg := 'NO VALID PURCHASING ITEM CATEGORY FOUND';
   cust_mesg (46).mesg := 'NO VALID PURCHASING ITEM CONVERSION FOUND';
   cust_mesg (47).mesg := 'NO EMPLOYEE FOUND FOR CURRENT USER';
   cust_mesg (48).mesg := 'NO VALID ORGANIZATION LOCATION FOUND';
   cust_mesg (49).mesg := 'NO VALID SECONDARY UOM CONVERSION FOUND';
   cust_mesg (50).mesg := 'NO VALID BILL TO LOCATION';

   cust_mesg (51).mesg := 'PLEASE MAKE SURE PR NUMBER IS APPROVED';
   cust_mesg (52).mesg :=
      'PR NUMBER HAS BEEN GENERATED BEFORE, PLEASE USE ANOTHER PR NUMBER';
END xxshp_upd_crt_po_pkg;
/
