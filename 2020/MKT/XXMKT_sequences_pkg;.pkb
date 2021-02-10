CREATE OR REPLACE PACKAGE BODY APPS.xxmkt_sequences_pkg
/* $Header: xxmkt_sequences_pkg.pkb 122.5.1.5 2016/03/01 15:29:00  Edi Yanto $ */
AS
   /**************************************************************************************************
         NAME: xxmkt_sequences_pkg
         PURPOSE:

         REVISIONS:
         Ver         Date                 Author              Description
         ---------   ----------          ---------------     ------------------------------------
         1.0         01-Nov-2016          Edi Yanto           1. Created this package.
         1.1         27-Dec-2016          Edi Yanto           1. Add gen_ap_cmp_num procedure
         1.2         30-Dec-2016          Edi Yanto           1. Add get_last_value, gen_wms_lpn_lot_num, gen_wms_lpn_split_num procedures
         1.3         24-Jan-2017          Edi Yanto           1. Add gen_gmd_sample_num procedure, update format_trx_number function
                                                                   and get_last_value procedure
         1.4         26-Jan-2017          Edi Yanto           1. Add gen_oe_spm_num procedure
         1.5         01-Mar-2017          Edi Yanto           1. Add gen_ap_rfp_num and update format_trx_number procedures
         1.9         15-Sep-2017          Michael Leonard 1. Add gen_ap_rfa_num and gen_ap_rfs_num
         2.1         07-Jul-2018          Wilson Chandra      1. add sequence untuk E Payment SUFIN         
     **************************************************************************************************/

   --PRIVATE declaration
   PROCEDURE get_last_value (
      p_appl_sh         IN       VARCHAR2,
      p_seq_type        IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_curr_month      IN       VARCHAR2 DEFAULT NULL,
      p_curr_year       IN       NUMBER,
      p_monthly_reset   IN       VARCHAR2 DEFAULT 'N',
      p_seq_num         OUT      VARCHAR2
   );
   
   PROCEDURE get_last_value_day (
      p_appl_sh         IN       VARCHAR2,
      p_seq_type        IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_curr_day        IN       VARCHAR2,
      p_curr_month      IN       VARCHAR2,
      p_curr_year       IN       NUMBER,
      p_seq_num         OUT      VARCHAR2
   );

   PROCEDURE get_last_value (p_appl_sh IN VARCHAR2, p_seq_type IN VARCHAR2, p_organization_id IN NUMBER, p_curr_date IN DATE, p_seq_num OUT VARCHAR2);

   FUNCTION format_trx_number (
      p_seq_number   IN   VARCHAR2,
      p_seq_type     IN   VARCHAR2,
      p_org_id       IN   NUMBER,
      p_trx_date     IN   DATE,
      p_ppn          IN   VARCHAR2 DEFAULT 'N',
      p_segment1     IN   VARCHAR2 DEFAULT NULL,
      p_segment2     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2;
      
   PROCEDURE get_last_value_custom(p_appl_sh IN VARCHAR2, p_seq_type IN VARCHAR2, p_org_id IN NUMBER, p_start_seq_num IN NUMBER, p_seq_num OUT VARCHAR2);

   --End PRIVATE declaration

   --PRIVATE PROCUDURE/FUNCTION
   PROCEDURE get_last_value (
      p_appl_sh         IN       VARCHAR2,
      p_seq_type        IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_curr_month      IN       VARCHAR2 DEFAULT NULL,
      p_curr_year       IN       NUMBER,
      p_monthly_reset   IN       VARCHAR2 DEFAULT 'N',
      p_seq_num         OUT      VARCHAR2
   )
   /*
       Created by Edi Yanto on 01-Nov-2016

       History Update:
       - Edi Yanto on 24-Jan-2017
            a. Add condition for seq_type NCR


   */
   IS
      v_seq_type_id   xxmkt_sequences.seq_type_id%TYPE   := 0;
      v_last_val      xxmkt_sequences.LAST_VALUE%TYPE    := 0;
   --v_seq_number    VARCHAR2 (50);
   BEGIN
      BEGIN
         -- if p_monthly_reset = 'Y' means sequence reset monthly, otherwise yearly
         IF p_monthly_reset = 'Y'
         THEN
            SELECT     seq_type_id, LAST_VALUE
                  INTO v_seq_type_id, v_last_val
                  FROM xxmkt_sequences
                 WHERE org_id = p_org_id
                   AND enabled_flag = 'Y'
                   AND application_short_name = p_appl_sh
                   AND seq_type = p_seq_type
                   AND current_month = p_curr_month
                   AND current_year = p_curr_year
            FOR UPDATE;
         ELSE
            IF p_seq_type = g_gmd_ncr_sample
            THEN
               SELECT     seq_type_id, LAST_VALUE
                     INTO v_seq_type_id, v_last_val
                     FROM xxmkt_sequences
                    WHERE enabled_flag = 'Y' AND application_short_name = p_appl_sh AND seq_type = p_seq_type AND current_year = p_curr_year
               FOR UPDATE;
            ELSE
               SELECT     seq_type_id, LAST_VALUE
                     INTO v_seq_type_id, v_last_val
                     FROM xxmkt_sequences
                    WHERE org_id = p_org_id
                      AND enabled_flag = 'Y'
                      AND application_short_name = p_appl_sh
                      AND seq_type = p_seq_type
                      AND current_year = p_curr_year
               FOR UPDATE;
            END IF;
         END IF;

         v_last_val := v_last_val + 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- select sequence from xxmkt_sequences_s
            SELECT xxmkt_sequences_s.NEXTVAL
              INTO v_seq_type_id
              FROM DUAL;

            -- assign v_last_val = 1
            v_last_val := 1;

            -- insert ke table
            IF p_monthly_reset = 'Y'
            THEN
               INSERT INTO xxmkt_sequences
                           (seq_type_id, application_short_name, seq_type, org_id, current_month, current_year, LAST_VALUE, description, created_by,
                            last_updated_by, last_update_login
                           )
                    VALUES (v_seq_type_id, p_appl_sh, p_seq_type, p_org_id, p_curr_month, p_curr_year, v_last_val, NULL, g_user_id,
                            g_user_id, g_login_id
                           );
            ELSE
               INSERT INTO xxmkt_sequences
                           (seq_type_id, application_short_name, seq_type, org_id, current_month, current_year, LAST_VALUE, description,
                            created_by, last_updated_by, last_update_login
                           )
                    VALUES (v_seq_type_id, p_appl_sh, p_seq_type, DECODE (p_seq_type, g_gmd_ncr, -1, p_org_id), NULL, p_curr_year, v_last_val, NULL,
                            g_user_id, g_user_id, g_login_id
                           );
            END IF;
      END;

      UPDATE xxmkt_sequences
         SET LAST_VALUE = v_last_val,
             last_updated_by = g_user_id,
             last_update_date = SYSDATE,
             last_update_login = g_login_id
       WHERE seq_type_id = v_seq_type_id;

      p_seq_num := v_last_val;
   END get_last_value;
   
   PROCEDURE get_last_value_day (
      p_appl_sh         IN       VARCHAR2,
      p_seq_type        IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_curr_day        IN       VARCHAR2,
      p_curr_month      IN       VARCHAR2,
      p_curr_year       IN       NUMBER,
      p_seq_num         OUT      VARCHAR2
   )
   /*
       Created by Michael Leonard on 20-JUL-2018

   */
   IS
      v_seq_type_id   xxmkt_sequences.seq_type_id%TYPE   := 0;
      v_last_val      xxmkt_sequences.LAST_VALUE%TYPE    := 0;
   --v_seq_number    VARCHAR2 (50);
   BEGIN
      BEGIN
         SELECT     seq_type_id, LAST_VALUE
                  INTO v_seq_type_id, v_last_val
                  FROM xxmkt_sequences
                 WHERE org_id = p_org_id
                   AND enabled_flag = 'Y'
                   AND application_short_name = p_appl_sh
                   AND seq_type = p_seq_type
                   AND current_day = p_curr_day
                   AND current_month = p_curr_month
                   AND current_year = p_curr_year
            FOR UPDATE;

         v_last_val := v_last_val + 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- select sequence from xxmkt_sequences_s
            SELECT xxmkt_sequences_s.NEXTVAL
              INTO v_seq_type_id
              FROM DUAL;

            -- assign v_last_val = 1
            v_last_val := 1;

            -- insert ke table
            INSERT INTO xxmkt_sequences
                   (seq_type_id, application_short_name, seq_type, org_id,current_day, current_month, current_year, LAST_VALUE, description, created_by,
                    last_updated_by, last_update_login
                   )
            VALUES (v_seq_type_id, p_appl_sh, p_seq_type, p_org_id,p_curr_day, p_curr_month, p_curr_year, v_last_val, NULL, g_user_id,
                    g_user_id, g_login_id
                   );
      END;

      UPDATE xxmkt_sequences
         SET LAST_VALUE = v_last_val,
             last_updated_by = g_user_id,
             last_update_date = SYSDATE,
             last_update_login = g_login_id
       WHERE seq_type_id = v_seq_type_id;

      p_seq_num := v_last_val;
   END get_last_value_day;
   

   PROCEDURE get_last_value (p_appl_sh IN VARCHAR2, p_seq_type IN VARCHAR2, p_organization_id IN NUMBER, p_curr_date IN DATE, p_seq_num OUT VARCHAR2)
    /*
       Created by Edi Yanto on 30-DEC-2016

       History Update:


   */
   IS
      v_seq_type_id   xxmkt_sequences.seq_type_id%TYPE   := 0;
      v_last_val      xxmkt_sequences.LAST_VALUE%TYPE    := 0;
   BEGIN
      BEGIN
         SELECT     seq_type_id, LAST_VALUE
               INTO v_seq_type_id, v_last_val
               FROM xxmkt_sequences
              WHERE 1 = 1                                                                                                 --org_id = p_organization_id
                AND enabled_flag = 'Y'
                AND application_short_name = p_appl_sh
                AND seq_type = p_seq_type
                AND current_full_date = p_curr_date
         FOR UPDATE;

         v_last_val := v_last_val + 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            -- select sequence from xxmkt_sequences_s
            SELECT xxmkt_sequences_s.NEXTVAL
              INTO v_seq_type_id
              FROM DUAL;

            -- assign v_last_val = 1
            v_last_val := 1;

            -- insert ke table
            INSERT INTO xxmkt_sequences
                        (seq_type_id, application_short_name, seq_type, org_id, current_full_date, LAST_VALUE, description, created_by,
                         last_updated_by, last_update_login
                        )
                 VALUES (v_seq_type_id, p_appl_sh, p_seq_type, p_organization_id, p_curr_date, v_last_val, NULL, g_user_id,
                         g_user_id, g_login_id
                        );
      END;

      UPDATE xxmkt_sequences
         SET LAST_VALUE = v_last_val,
             last_updated_by = g_user_id,
             last_update_date = SYSDATE,
             last_update_login = g_login_id
       WHERE seq_type_id = v_seq_type_id;

      p_seq_num := v_last_val;
   END get_last_value;
   
   PROCEDURE get_last_value_custom(
      p_appl_sh         IN       VARCHAR2,
      p_seq_type        IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_start_seq_num   IN       NUMBER,
      p_seq_num         OUT      VARCHAR2
   )
    /*
       Created by Michael Leonard on 08-APR-2018

       
   */
   IS
      v_seq_type_id   xxmkt_sequences.seq_type_id%TYPE   := 0;
      v_last_val      xxmkt_sequences.LAST_VALUE%TYPE    := 0;
      
   BEGIN
        BEGIN
            SELECT     seq_type_id, LAST_VALUE
                   INTO v_seq_type_id, v_last_val
                   FROM xxmkt_sequences
                  WHERE 1 = 1                                                                                                 --org_id = p_organization_id
                    AND enabled_flag = 'Y'
                    AND application_short_name = p_appl_sh
                    AND org_id = p_org_id
                    AND seq_type = p_seq_type
             FOR UPDATE;
             
             v_last_val := v_last_val + 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                SELECT xxmkt_sequences_s.NEXTVAL
                INTO v_seq_type_id
                FROM DUAL;
                
                v_last_val := p_start_seq_num;
                
                -- insert ke table
                INSERT INTO xxmkt_sequences
                        (seq_type_id, application_short_name, seq_type, org_id, LAST_VALUE, description, created_by,
                         last_updated_by, last_update_login
                        )
                 VALUES (v_seq_type_id, p_appl_sh, p_seq_type, p_org_id, v_last_val, NULL, g_user_id,
                         g_user_id, g_login_id
                        );
        END;
        
        UPDATE xxmkt_sequences
         SET LAST_VALUE = v_last_val,
             last_updated_by = g_user_id,
             last_update_date = SYSDATE,
             last_update_login = g_login_id
       WHERE seq_type_id = v_seq_type_id;
       
       p_seq_num := v_last_val;
   END get_last_value_custom;

   FUNCTION format_trx_number (
      p_seq_number   IN   VARCHAR2,
      p_seq_type     IN   VARCHAR2,
      p_org_id       IN   NUMBER,
      p_trx_date     IN   DATE,
      p_ppn          IN   VARCHAR2 DEFAULT 'N',
      p_segment1     IN   VARCHAR2 DEFAULT NULL,
      p_segment2     IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   /*
       Created by Edi Yanto on 01-Nov-2016

       History Update:
       - Edi Yanto on 27-Dec-2016
            a. Add format number for seq_type CMP-PPN or CMP-NON-PPN
       - Edi Yanto on 30-Dec-2016
            a. Add format number for seq_type LPN and LOT
       - Edi Yanto on 24-Jan-2017
            a. Add format number for seq_type ICM, BL, FG, MN, NCR (NCR_OLD), SAR
       - Edi Yantp on 26-Jan-2017
            a. Add format number for seq_type SPM
       - Edi Yanto on 3-Feb-2017
            a. Add format number for seq_type LPN-INV
       - Edi Yanto on 22-Feb-2017
            a. Add format number for seq_type INC, INL, FGS, INV, NCR
       - Edi Yanto on 1-Mar-2017
            a. Add format number for seq_type RFP
       - Edi Yanto on 7-Mar-2017
            a. Add format number for seq_type GRPKN, GRPLT
       - Edi Yanto on 13-Mar-2017
            a. Add format number for seq_type like 'QA%'
       - Edi Yanto on 20-Mar-2017
            a. Add params p_segment1 and p_segment2
            b. Add format number for seq_type SALOK
       - Michael Leonard on 15-Sep-2017
            a. Add format number for seq_type RFA, RFS


   */
   IS
      v_trx_num          VARCHAR2 (100);
      v_org_short_name   hr_organization_information.org_information5%TYPE;
   BEGIN
      BEGIN                                                                                                  -- select short name for operating units
         SELECT hoiv.org_information5
           INTO v_org_short_name
           FROM hr_organization_units_v houv, hr_organization_information_v hoiv
          WHERE houv.organization_id = hoiv.organization_id
            AND hoiv.org_information_context = 'Operating Unit Information'
            AND houv.organization_id = p_org_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT organization_code
                 INTO v_org_short_name
                 FROM mtl_parameters
                WHERE organization_id = p_org_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  -- 'ERR' is for organization short name that not define yet...
                  v_org_short_name := 'ERR';
            END;
      END;

      --v_trx_num := v_org_short_name || '/' || p_seq_type || '/' || TO_CHAR (p_trx_date, 'RRRR/MM') || '/' || p_seq_number;
      IF p_seq_type = g_underlying_type
      THEN
         v_trx_num := TO_CHAR (p_trx_date, 'RRRRMM') || p_seq_number;
      ELSIF (p_seq_type = g_cmp_type || '-' || g_cmp_ppn OR p_seq_type = g_cmp_type || '-' || g_cmp_non_ppn)
      THEN
         SELECT    g_cmp_type
                || '/'
                || TO_CHAR (p_trx_date, 'RRRR')
                || '/SHP-FA/'
                || DECODE (p_ppn, 'Y', g_cmp_ppn, g_cmp_non_ppn)
                || '/'
                || TO_CHAR (p_trx_date, 'fmRM')
                || '/'
                || p_seq_number
           INTO v_trx_num
           FROM DUAL;
      ELSIF p_seq_type LIKE g_wms_lpn_type || '%'
      THEN
         v_trx_num := '/' || TO_CHAR (p_trx_date, 'RRMMDD') || '/' || p_seq_number;
      ELSIF p_seq_type = g_wms_lpn_outbound_type
      THEN
         v_trx_num := '/' || TO_CHAR (p_trx_date, 'RRMMDD') || '/' || p_seq_number;
      ELSIF p_seq_type = g_wms_lot_type
      THEN
         v_trx_num := v_org_short_name || TO_CHAR (p_trx_date, 'RRMMDD') || p_seq_number;
      ELSIF SUBSTR (p_seq_type, 1, INSTR (p_seq_type, '#') - 1) = g_gmd_incoming
      THEN
         v_trx_num := v_org_short_name || '-' || SUBSTR (p_seq_type, INSTR (p_seq_type, '#') + 1) || TO_CHAR (p_trx_date, 'MMRR') || '-'
                      || p_seq_number;
      ELSIF SUBSTR (p_seq_type, 1, INSTR (p_seq_type, '#') - 1) = g_gmd_inline
      THEN
         v_trx_num := v_org_short_name || '-' || g_gmd_inline || TO_CHAR (p_trx_date, 'MMRR') || '-' || p_seq_number;
      ELSIF SUBSTR (p_seq_type, 1, INSTR (p_seq_type, '#') - 1) = g_gmd_fg
      THEN
         v_trx_num := v_org_short_name || '-' || g_gmd_fg || TO_CHAR (p_trx_date, 'MMRR') || '-' || p_seq_number;
      ELSIF SUBSTR (p_seq_type, 1, INSTR (p_seq_type, '#') - 1) = g_gmd_monitoring
      THEN
         v_trx_num := v_org_short_name || '-' || SUBSTR (p_seq_type, INSTR (p_seq_type, '#') + 1) || TO_CHAR (p_trx_date, 'MMRR') || '-'
                      || p_seq_number;
      ELSIF SUBSTR (p_seq_type, 1, INSTR (p_seq_type, '#') - 1) = g_gmd_ncr_sample
      THEN
         v_trx_num :=
               SUBSTR (g_gmd_ncr_sample, 1, 3)
            || '-'
            || SUBSTR (p_seq_type, INSTR (p_seq_type, '#') + 1)
            || TO_CHAR (p_trx_date, 'MMRR')
            || '-'
            || p_seq_number;
      ELSIF p_seq_type = g_gmd_sample_adm_req
      THEN
         v_trx_num := v_org_short_name || '-' || TO_CHAR (p_trx_date, 'RR') || '-' || TO_CHAR (p_trx_date, 'MM') || '-' || p_seq_number;
      ELSIF p_seq_type = g_oe_spm_num
      THEN
         v_trx_num := TO_CHAR (p_trx_date, 'RRMM') || p_seq_number;
      ELSIF p_seq_type = g_wms_lpn_inv
      THEN
         v_trx_num := '/' || TO_CHAR (p_trx_date, 'RRMMDD') || '/' || p_seq_number;
      ELSIF p_seq_type IN (g_gmd_inc, g_gmd_inl, g_gmd_fgs, g_gmd_inv, g_gmd_ncr, g_gmd_grpkn, g_gmd_grplt)
      THEN
         v_trx_num := p_seq_type || TO_CHAR (p_trx_date, 'RR') || p_seq_number;
      ELSIF p_seq_type = g_ap_rfp OR p_seq_type = g_ap_rfa OR p_seq_type = g_ap_rfs
      THEN
         v_trx_num := p_seq_type || '/' || TO_CHAR (p_trx_date, 'RR') || '/' || TO_CHAR (p_trx_date, 'MM') || '/' || p_seq_number;
      ELSIF p_seq_type LIKE 'QA%'
      THEN
         v_trx_num := p_seq_type || '-' || p_org_id || '-' || TO_CHAR (p_trx_date, 'RRRR') || '-' || TO_CHAR (p_trx_date, 'MM') || '-'
                      || p_seq_number;
      /*Wilson 20180704*/
      ELSIF p_seq_type = g_ap_epay_sufin
      THEN
         v_trx_num := p_seq_type || '-' || TO_CHAR (p_trx_date, 'RRRR') || '-' || TO_CHAR (p_trx_date, 'MM') || '-'
                      || p_seq_number;
                      
      ELSIF p_seq_type = g_oe_salok_num
      THEN
         v_trx_num := p_seq_number || '/' || p_segment1 || '/' || p_segment2 || '/' || TO_CHAR (p_trx_date, 'MM') || '/'
                      || TO_CHAR (p_trx_date, 'RR');
      /* Michael Leonard v2.1 */
      ELSIF p_seq_type = g_opi_doc_num
      THEN
         v_trx_num :=  p_seq_number || '/' || p_segment1 || '/' || TO_CHAR (p_trx_date, 'RRRR');
      ELSIF p_seq_type = g_vms_sample
      THEN
         v_trx_num := 'SAMPLE/' || TO_CHAR (p_trx_date, 'RR') || TO_CHAR (p_trx_date, 'MM') || '/' || p_seq_number;
      ELSIF p_seq_type = g_vms_batch
      THEN
         v_trx_num := 'BATCH/' || TO_CHAR (p_trx_date, 'RR') || TO_CHAR (p_trx_date, 'MM') || '/' || p_seq_number;
      END IF;

      RETURN (v_trx_num);
   END format_trx_number;

   --END PRIVATE PROCEDURE/FUNCTION

   --PUBLIC PROCEDURE/FUNCTION
   PROCEDURE gen_ce_underlying_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 01-Nov-2016

       History Update:


   */
   IS
      v_month      VARCHAR2 (2);
      v_year       NUMBER;
      v_seq_num    VARCHAR2 (10);
      v_seq_type   xxmkt_sequences.seq_type%TYPE;
   BEGIN
      -- call get_lastvalue
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('CE', g_underlying_type, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      -- call format_voucher
      IF LENGTH (v_seq_num) > 2
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_underlying_type, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 2, '0'), g_underlying_type, p_org_id, p_trx_date);
      END IF;
   --commit;
   END gen_ce_underlying_num;

   PROCEDURE gen_ap_cmp_num (
      p_source          IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_trx_date        IN       DATE,
      p_ppn             IN       VARCHAR2 DEFAULT 'N',
      p_monthly_reset   IN       VARCHAR2,
      x_trx_num         OUT      VARCHAR2
   )
   /*
       Created by Edi Yanto on 27-Dec-2016

       History Update:


   */
   IS
      v_cmp_type   VARCHAR2 (20);
      v_month      VARCHAR2 (2);
      v_year       NUMBER;
      v_seq_num    VARCHAR2 (10);
   BEGIN
      SELECT g_cmp_type || '-' || DECODE (p_ppn, 'Y', g_cmp_ppn, g_cmp_non_ppn)
        INTO v_cmp_type
        FROM DUAL;

      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('SQLAP', v_cmp_type, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 4
      THEN
         x_trx_num := format_trx_number (v_seq_num, v_cmp_type, p_org_id, p_trx_date, p_ppn);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 4, '0'), v_cmp_type, p_org_id, p_trx_date, p_ppn);
      END IF;
   END gen_ap_cmp_num;

   PROCEDURE gen_wms_lpn_lot_num (p_source IN VARCHAR2, p_organization_id IN NUMBER, p_trx_date IN DATE, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 30-Dec-2016

       History Update:


   */
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      get_last_value ('WMS', p_source, p_organization_id, p_trx_date, v_seq_num);

      IF LENGTH (v_seq_num) > 4
      THEN
         x_trx_num := format_trx_number (v_seq_num, p_source, p_organization_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 4, '0'), p_source, p_organization_id, p_trx_date);
      END IF;

      COMMIT;
   END gen_wms_lpn_lot_num;

   PROCEDURE gen_wms_lpn_split_num (p_source_lpn IN VARCHAR2, p_organization_id IN NUMBER, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 30-Dec-2016

       History Update:


   */
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_seq_num      VARCHAR2 (10);
      v_last_value   NUMBER;
   BEGIN
      BEGIN
         SELECT NVL (MAX (SUBSTR (license_plate_number, INSTR (license_plate_number, '-', -1) + 1)), 0) LAST_VALUE
           INTO v_last_value
           FROM wms_license_plate_numbers
          WHERE license_plate_number LIKE p_source_lpn || '-%' AND organization_id = p_organization_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_last_value := 0;
      END;

      x_trx_num := p_source_lpn || '-' || (v_last_value + 1);
      COMMIT;
   END gen_wms_lpn_split_num;

   PROCEDURE gen_gmd_sample_num (
      p_source_code       IN       VARCHAR2,
      p_sample_type       IN       VARCHAR2,
      p_organization_id   IN       NUMBER,
      p_trx_date          IN       DATE,
      x_trx_num           OUT      VARCHAR2
   )
   /*
       Created by Edi Yanto on 24-Jan-2016

       History Update:
       1. Edi Yanto on 7-Mar-2017
            a. Add condition for g_gmd_grpkn and g_gmd_grplt
       2. Edi Yanto on 13-Mar-2017
            a. Add condition for QM (g_gmd_qa_xxx)


   */
   IS
      --PRAGMA AUTONOMOUS_TRANSACTION;
      v_seq_num   VARCHAR2 (10);
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');

      IF p_source_code = g_gmd_sample_adm_req
      THEN
         get_last_value ('GMD', p_source_code, p_organization_id, v_month, v_year, 'Y', v_seq_num);

         IF LENGTH (v_seq_num) > 3
         THEN
            x_trx_num := format_trx_number (v_seq_num, p_source_code, p_organization_id, p_trx_date);
         ELSE
            x_trx_num := format_trx_number (LPAD (v_seq_num, 3, '0'), p_source_code, p_organization_id, p_trx_date);
         END IF;
      ELSIF p_source_code LIKE 'QA%'
      THEN
         get_last_value ('GMD', p_source_code, p_organization_id, v_month, v_year, 'Y', v_seq_num);

         IF LENGTH (v_seq_num) > 4
         THEN
            x_trx_num := format_trx_number (v_seq_num, p_source_code, p_organization_id, p_trx_date);
         ELSE
            x_trx_num := format_trx_number (LPAD (v_seq_num, 4, '0'), p_source_code, p_organization_id, p_trx_date);
         END IF;
      --NEW
      ELSIF p_source_code IN (g_gmd_inc, g_gmd_inl, g_gmd_fgs, g_gmd_inv, g_gmd_ncr, g_gmd_grpkn, g_gmd_grplt)
      THEN
         get_last_value ('GMD', p_source_code, -1, 1, v_year, 'N', v_seq_num);

         IF p_source_code IN (g_gmd_grpkn, g_gmd_grplt)
         THEN
            IF LENGTH (v_seq_num) > 5
            THEN
               x_trx_num := format_trx_number (v_seq_num, p_source_code, -1, p_trx_date);
            ELSE
               x_trx_num := format_trx_number (LPAD (v_seq_num, 5, '0'), p_source_code, -1, p_trx_date);
            END IF;
         ELSE
            IF LENGTH (v_seq_num) > 10
            THEN
               x_trx_num := format_trx_number (v_seq_num, p_source_code, -1, p_trx_date);
            ELSE
               x_trx_num := format_trx_number (LPAD (v_seq_num, 10, '0'), p_source_code, -1, p_trx_date);
            END IF;
         END IF;
      ELSE
         --Sample No                                                                                                                                         --OLD
         get_last_value ('GMD', p_source_code|| '#' || p_sample_type, p_organization_id, v_month, v_year, 'Y', v_seq_num);

         IF LENGTH (v_seq_num) > 5
         THEN
            x_trx_num := format_trx_number (v_seq_num, p_source_code || '#' || p_sample_type, p_organization_id, p_trx_date);
         ELSE
            x_trx_num := format_trx_number (LPAD (v_seq_num, 5, '0'), p_source_code || '#' || p_sample_type, p_organization_id, p_trx_date);
         END IF;
      END IF;
   --COMMIT;
   END gen_gmd_sample_num;

   PROCEDURE gen_oe_spm_num (p_source_code IN VARCHAR2, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 26-Jan-2016

       History Update:


   */
   IS
      v_seq_num   VARCHAR2 (10);
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('ONT', g_oe_spm_num, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 4
      THEN
         x_trx_num := p_source_code || format_trx_number (v_seq_num, g_oe_spm_num, p_org_id, p_trx_date);
      ELSE
         x_trx_num := p_source_code || format_trx_number (LPAD (v_seq_num, 4, '0'), g_oe_spm_num, p_org_id, p_trx_date);
      END IF;
   END gen_oe_spm_num;

   PROCEDURE gen_ap_rfp_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 1-Mar-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('SQLAP', g_ap_rfp, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_ap_rfp, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_ap_rfp, p_org_id, p_trx_date);
      END IF;
   END gen_ap_rfp_num;
   
   PROCEDURE gen_ap_rfa_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 15-Sep-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('SQLAP', g_ap_rfa, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_ap_rfa, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_ap_rfa, p_org_id, p_trx_date);
      END IF;
   END gen_ap_rfa_num;
   
   PROCEDURE gen_ap_rfs_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 15-Sep-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('SQLAP', g_ap_rfs, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_ap_rfs, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_ap_rfs, p_org_id, p_trx_date);
      END IF;
   END gen_ap_rfs_num;
   
   PROCEDURE gen_ap_epay_sufin_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Wilson on 04-Jul-2018

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('SQLAP', g_ap_epay_sufin, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 3
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_ap_epay_sufin, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 3, '0'), g_ap_epay_sufin, p_org_id, p_trx_date);
      END IF;
   END gen_ap_epay_sufin_num;

   PROCEDURE gen_oe_surat_alokasi_num (
      p_source          IN       VARCHAR2,
      p_trx_date        IN       DATE,
      p_monthly_reset   IN       VARCHAR2,
      p_org_id          IN       NUMBER,
      p_segment1        IN       VARCHAR2,
      p_segment2        IN       VARCHAR2,
      x_trx_num         OUT      VARCHAR2
   )
   /*
       Created by Edi Yanto on 20-Mar-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('ONT', g_oe_salok_num, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 3
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_oe_salok_num, p_org_id, p_trx_date, NULL, p_segment1, p_segment2);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 3, '0'), g_oe_salok_num, p_org_id, p_trx_date, NULL, p_segment1, p_segment2);
      END IF;
   END gen_oe_surat_alokasi_num;
   
   PROCEDURE gen_table_b2b(p_source IN VARCHAR2, p_table_name IN VARCHAR2, p_start_seq_num IN NUMBER, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 06-JUN-2018

       History Update:


   */
   IS
        v_seq_num   VARCHAR2 (10);
   BEGIN
        get_last_value_custom(p_source, p_table_name, p_org_id, p_start_seq_num, v_seq_num);
        
        IF LENGTH (v_seq_num) > 0
        THEN
            x_trx_num := v_seq_num;
        ELSE
            x_trx_num := p_start_seq_num;
        END IF;
        
   END gen_table_b2b;
   
   PROCEDURE gen_table_custom(p_source IN VARCHAR2, p_table_name IN VARCHAR2, p_start_seq_num IN NUMBER, p_org_id IN NUMBER, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 27-MAR-2019

       History Update:


   */
   IS
        v_seq_num   VARCHAR2 (10);
   BEGIN
        get_last_value_custom(p_source, p_table_name, p_org_id, p_start_seq_num, v_seq_num);
        
        IF LENGTH (v_seq_num) > 0
        THEN
            x_trx_num := v_seq_num;
        ELSE
            x_trx_num := p_start_seq_num;
        END IF;
        
   END gen_table_custom;
   
   PROCEDURE gen_vms_sample_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 15-Sep-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('VMS', g_vms_sample, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_vms_sample, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_vms_sample, p_org_id, p_trx_date);
      END IF;
   END gen_vms_sample_num;
   
   PROCEDURE gen_vms_batch_num (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 15-Sep-2017

       History Update:


   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('VMS', g_vms_batch, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_vms_batch, p_org_id, p_trx_date);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_vms_batch, p_org_id, p_trx_date);
      END IF;
   END gen_vms_batch_num;
   
   PROCEDURE gen_opi_doc_num (p_source IN VARCHAR2, p_lob_name IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Michael Leonard on 15-Sep-2017
       History Update:
   */
   IS
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value ('OPI', p_source, p_org_id, v_month, v_year, p_monthly_reset, v_seq_num);

      IF LENGTH (v_seq_num) > 6
      THEN
         x_trx_num := format_trx_number (v_seq_num, g_opi_doc_num, p_org_id, p_trx_date, 'N', p_lob_name);
      ELSE
         x_trx_num := format_trx_number (LPAD (v_seq_num, 6, '0'), g_opi_doc_num, p_org_id, p_trx_date, 'N', p_lob_name);
      END IF;
   END gen_opi_doc_num;
   
   PROCEDURE gen_star_mo_repl (p_source IN VARCHAR2, p_org_id IN NUMBER, p_trx_date IN DATE, p_monthly_reset IN VARCHAR2, x_trx_num OUT VARCHAR2)
   /*
       Created by Edi Yanto on 1-Mar-2017

       History Update:


   */
   IS
      v_day       VARCHAR2 (2);
      v_month     VARCHAR2 (2);
      v_year      NUMBER;
      v_seq_num   VARCHAR2 (10);
   BEGIN
      v_day := TO_CHAR (p_trx_date, 'DD');
      v_month := TO_CHAR (p_trx_date, 'MM');
      v_year := TO_NUMBER (TO_CHAR (p_trx_date, 'RRRR'), '9999');
      get_last_value_day ('INV',p_source, p_org_id,v_day,v_month,v_year,v_seq_num);

      IF LENGTH (v_seq_num) > 1 
      THEN
         x_trx_num := v_day || v_month || SUBSTR(v_year,-2) || v_seq_num;
      ELSE
         x_trx_num := v_day || v_month || SUBSTR(v_year,-2) || LPAD(v_seq_num,2,0);
      END IF;
   END gen_star_mo_repl;
--END PUBLIC PROCEDURE/FUNCTION
END xxmkt_sequences_pkg;
/
