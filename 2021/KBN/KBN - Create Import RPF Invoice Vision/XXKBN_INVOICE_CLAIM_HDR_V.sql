DROP VIEW APPS.XXKBN_INVOICE_CLAIM_HDR_V;

/* Formatted on 2/9/2021 4:15:02 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXKBN_INVOICE_CLAIM_HDR_V
(
   INVOICE_ID,
   INVOICE_TYPE_LOOKUP_CODE,
   INVOICE_NUM,
   INVOICE_CURRENCY_CODE,
   INVOICE_AMOUNT,
   INVOICE_DATE,
   EXCHANGE_RATE,
   EXCHANGE_DATE,
   GL_DATE,
   VENDOR_NAME,
   VENDOR_SITE_CODE,
   DESCRIPTION,
   TOP,
   BANK_ACCOUNT_NUM,
   BANK_ACCOUNT_NAME,
   LIABILITY_ACCOUNT,
   INV_STATUS,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15
)
   BEQUEATH DEFINER
AS
   SELECT ai.invoice_id,
          ai.INVOICE_TYPE_LOOKUP_CODE,
          ai.invoice_num,
          ai.invoice_currency_code,
          ai.INVOICE_AMOUNT,
          ai.invoice_date,
          ai.EXCHANGE_RATE,
          ai.exchange_date,
          ai.GL_DATE,
          asu.VENDOR_NAME,
          assa.VENDOR_SITE_CODE,
          ai.description,
          at.NAME TOP,
          ieba.BANK_ACCOUNT_NUM,
          ieba.BANK_ACCOUNT_NAME,
          gcc.CONCATENATED_SEGMENTS LIABILITY_ACCOUNT,
          AP_INVOICES_PKG.GET_APPROVAL_STATUS (ai.invoice_id,
                                               ai.invoice_amount,
                                               ai.payment_status_flag,
                                               ai.invoice_type_lookup_code)
             inv_status,
          ai.ATTRIBUTE1,
          ai.ATTRIBUTE2,
          ai.ATTRIBUTE3,
          ai.ATTRIBUTE5,
          ai.ATTRIBUTE6,
          ai.ATTRIBUTE7,
          ai.ATTRIBUTE8,
          ai.ATTRIBUTE9,
          ai.ATTRIBUTE10,
          ai.ATTRIBUTE11,
          ai.ATTRIBUTE12,
          ai.ATTRIBUTE13,
          ai.ATTRIBUTE14,
          ai.ATTRIBUTE15
     FROM ap_invoices_all ai,
          ap_suppliers asu,
          ap_supplier_sites_all assa,
          ap_terms at,
          iby_ext_bank_accounts ieba,
          gl_code_combinations_kfv gcc
    WHERE     1 = 1
          AND at.TERM_ID = ai.TERMS_ID
          AND ai.source = 'VISION'
          AND asu.vendor_id = ai.vendor_id
          AND assa.vendor_site_id = ai.vendor_site_id
          AND ai.EXTERNAL_BANK_ACCOUNT_ID = ieba.EXT_BANK_ACCOUNT_ID
          AND ai.ACCTS_PAY_CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID;


CREATE OR REPLACE SYNONYM XXKBN.XXKBN_INVOICE_CLAIM_HDR_V FOR APPS.XXKBN_INVOICE_CLAIM_HDR_V;


GRANT SELECT ON APPS.XXKBN_INVOICE_CLAIM_HDR_V TO XXKBN;
