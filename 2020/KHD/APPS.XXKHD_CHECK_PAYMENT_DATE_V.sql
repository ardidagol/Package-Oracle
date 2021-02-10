DROP VIEW APPS.XXKHD_CHECK_PAYMENT_DATE_V;

/* Formatted on 7/28/2020 2:12:30 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXKHD_CHECK_PAYMENT_DATE_V
(
   BATCH_NAME,
   DOLPHINE_ADV_NUM,
   CHECK_DATE,
   BP,
   CHECK_NUMBER,
   INVOICE_NUM,
   AMOUNT,
   CREATION_DATEBP
)
   BEQUEATH DEFINER
AS
   SELECT aba.batch_name batch_name,
          aia.invoice_num dolphine_adv_num,
          aca.check_date check_date,
          NVL (aca.attribute3, ''),
          aca.check_number,
          aia.invoice_num,
          aca.amount,
          aca.creation_date creation_dateBP
     FROM ap_batches_all aba,
          ap_invoices_all aia,
          ap_invoice_payments_all aip,
          ap_checks_all aca
    WHERE     aba.batch_id = aia.batch_id
          AND aia.invoice_id = aip.invoice_id
          AND aip.check_id = aca.check_id
          AND aca.attribute3 IS NOT NULL --AND ABA.batch_name = 'RFA AD-A0101-1105001/0002';;;;;;
          -- tambahan 20140217 Wilson, tambah aca.status_lookup_code <> 'VOIDED'
          AND aca.status_lookup_code <> 'VOIDED';
