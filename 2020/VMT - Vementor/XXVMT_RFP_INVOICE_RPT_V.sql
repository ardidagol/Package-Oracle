/* Formatted on 10/5/2020 1:26:59 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE VIEW XXVMT_RFP_INVOICE_RPT_V
AS
   SELECT RFP_NO,
          SUPPLIER_NAME,
          BATCH_ID,
          ORG_ID,
          INVOICE_BATCH_NAME,
          INVOICE_DUE,
          TOTAL_PAYMENT,
          PAID_TO,
          REQUESTOR,
          CREATOR,
          INVOICE_AMOUNT,
          VAT_REGISTRATION_NUM,
          BANK_NAME,
          BENEFICIARY_NAME,
          ACCOUNT_NUMBER,
          INVOICE_ID,
          INVOICE_NUM,
          INVOICE_DATE,
          GL_DATE,
          EXCHANGE_RATE,
          EXCHANGE_DATE,
          EXCHANGE_RATE_TYPE,
          INVOICE_CURRENCY_CODE,
          NPWP,
          TGL_FAKTUR,
          ATTRIBUTE_CATEGORY,
          DESCRIPTION,
          TERMS_DUE_DAYS,
          BP_NUMBER,
          PPN_BASE_AMOUNT,
          PPN_AMOUNT,
          SUPPLIER_SITE,
          PO_NUM,
          PO_DATE,
          RCV_NUM,
          RCV_DATE,
          APPROVAL_STATUS,
          PROJECT_CODE,
          AMOUNT_DR,
          AMOUNT_CR,
          ACCOUNTED_DR,
          ACCOUNTED_CR,
          GL_ACCOUNT,
          SEGMENT2,
          SEGMENT3,
          SEGMENT5,
          SEGMENT6,
          PAYMENT_STATUS_FLAG,
          APPROVAL_STATUS_GL
     FROM (  SELECT AB.ATTRIBUTE1 RFP_NO,
                    HP.PARTY_NAME SUPPLIER_NAME,
                    AB.BATCH_ID,
                    AI.ORG_ID,
                    AB.BATCH_NAME INVOICE_BATCH_NAME,
                    APSA.DUE_DATE INVOICE_DUE,
                    SUM (AI.INVOICE_AMOUNT) TOTAL_PAYMENT,
                    DECODE (AB.ATTRIBUTE2,
                            NULL, HP.PARTY_NAME,
                            AB.ATTRIBUTE2, AB.ATTRIBUTE2)
                       PAID_TO,
                    AB.ATTRIBUTE3 REQUESTOR,
                    FU.USER_NAME CREATOR,
                    APS.VAT_REGISTRATION_NUM,
                    IEB.BANK_NAME Bank_Name,
                    IEBA.BANK_ACCOUNT_NAME Beneficiary_Name,
                    IEBA.BANK_ACCOUNT_NUM Account_Number,
                    AI.INVOICE_ID,
                    AI.INVOICE_NUM,
                    AI.INVOICE_DATE,
                    AI.INVOICE_AMOUNT,
                    AI.GL_DATE,
                    AI.EXCHANGE_RATE,
                    AI.EXCHANGE_DATE,
                    AI.EXCHANGE_RATE_TYPE,
                    AI.INVOICE_CURRENCY_CODE,
                    AI.SUPPLIER_TAX_INVOICE_NUMBER NPWP,
                    AI.SUPPLIER_TAX_INVOICE_DATE TGL_FAKTUR,
                    AI.ATTRIBUTE_CATEGORY,
                    AI.DESCRIPTION,
                    ATL.DUE_DAYS TERMS_DUE_DAYS,
                    ACA.ATTRIBUTE3 BP_NUMBER,
                    TO_CHAR (AI.ATTRIBUTE3, '9,999,999,999,999.9999')
                       PPN_BASE_AMOUNT,
                    TO_CHAR (AI.ATTRIBUTE4, '999,999,999,999.9999') PPN_AMOUNT,
                    POV.VENDOR_SITE_CODE SUPPLIER_SITE,
                    PHA.SEGMENT1 PO_NUM,
                    PHA.CREATION_DATE PO_DATE,
                    RSH.RECEIPT_NUM RCV_NUM,
                    RT.TRANSACTION_DATE RCV_DATE,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS,
                    NULL PROJECT_CODE,
                    NULL AMOUNT_DR,
                    SUM (NVL (AI.INVOICE_AMOUNT, 0)) AMOUNT_CR,
                    NULL ACCOUNTED_DR,
                    DECODE (AI.INVOICE_CURRENCY_CODE,
                            'IDR', SUM (NVL (AI.INVOICE_AMOUNT, 0)),
                            SUM (NVL (AI.BASE_AMOUNT, 0)))
                       ACCOUNTED_CR,
                       GLCC.SEGMENT1
                    || '-'
                    || GLCC.SEGMENT2
                    || '-'
                    || GLCC.SEGMENT3
                    || '-'
                    || GLCC.SEGMENT4
                    || '-'
                    || GLCC.SEGMENT5
                    || '-'
                    || GLCC.SEGMENT6
                    || '-'
                    || GLCC.SEGMENT7
                       GL_ACCOUNT,
                    GLCC.SEGMENT2 SEGMENT2,
                    GLCC.SEGMENT3 SEGMENT3,
                    GLCC.SEGMENT5 SEGMENT5,
                    GLCC.SEGMENT6 SEGMENT6,
                    AI.PAYMENT_STATUS_FLAG,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS_GL
               FROM AP.AP_INVOICES_ALL AI,
                    AP.AP_BATCHES_ALL AB,
                    AP.AP_PAYMENT_SCHEDULES_ALL APSA,
                    AR.HZ_PARTIES HP,
                    AP.AP_TERMS_LINES ATL,
                    AP.AP_INVOICE_PAYMENTS_ALL AIPA,
                    AP.AP_CHECKS_ALL ACA,
                    FND_USER FU,
                    AP_SUPPLIERS APS,
                    IBY_EXT_BANK_ACCOUNTS IEBA,
                    IBY_EXT_BANKS_V IEB,
                    APPS.PO_VENDOR_SITES_ALL POV,
                    AP_INVOICE_LINES_ALL AILA,
                    PO_HEADERS_ALL PHA,
                    RCV_TRANSACTIONS RT,
                    RCV_SHIPMENT_HEADERS RSH,
                    GL.GL_CODE_COMBINATIONS GLCC
              WHERE     AI.BATCH_ID = AB.BATCH_ID
                    AND AI.PARTY_ID = HP.PARTY_ID
                    AND AB.CREATED_BY = FU.USER_ID
                    AND AI.VENDOR_ID = APS.VENDOR_ID
                    AND APSA.INVOICE_ID = AI.INVOICE_ID
                    AND POV.VENDOR_ID = AI.VENDOR_ID
                    AND POV.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
                    AND AI.TERMS_ID = ATL.TERM_ID
                    AND AI.INVOICE_ID = AIPA.INVOICE_ID(+)
                    AND AIPA.CHECK_ID = ACA.CHECK_ID(+)
                    AND AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                           AI.INVOICE_ID,
                           AI.INVOICE_AMOUNT,
                           AI.PAYMENT_STATUS_FLAG,
                           AI.INVOICE_TYPE_LOOKUP_CODE) NOT IN ('CANCELLED')
                    AND AP_INVOICES_UTILITY_PKG.GET_APPROVAL_STATUS (
                           AI.INVOICE_ID,
                           AI.INVOICE_AMOUNT,
                           AI.PAYMENT_STATUS_FLAG,
                           AI.INVOICE_TYPE_LOOKUP_CODE) NOT IN ('CANCELLED')
                    AND AI.ACCTS_PAY_CODE_COMBINATION_ID =
                           GLCC.CODE_COMBINATION_ID
                    AND IEBA.EXT_BANK_ACCOUNT_ID(+) =
                           AI.EXTERNAL_BANK_ACCOUNT_ID
                    AND IEBA.BANK_ID = IEB.BANK_PARTY_ID(+)
                    AND AI.INVOICE_ID = AILA.INVOICE_ID(+)
                    AND AILA.PO_HEADER_ID = PHA.PO_HEADER_ID(+)
                    AND AILA.RCV_TRANSACTION_ID = RT.TRANSACTION_ID(+)
                    AND RT.SHIPMENT_HEADER_ID = RSH.SHIPMENT_HEADER_ID(+)
           GROUP BY AB.ATTRIBUTE1,
                    HP.PARTY_NAME,
                    AB.BATCH_ID,
                    AI.ORG_ID,
                    AB.BATCH_NAME,
                    APSA.DUE_DATE,
                    AI.INVOICE_CURRENCY_CODE,
                    DECODE (AB.ATTRIBUTE2,
                            NULL, HP.PARTY_NAME,
                            AB.ATTRIBUTE2, AB.ATTRIBUTE2),
                    AB.ATTRIBUTE3,
                    FU.USER_NAME,
                    AI.INVOICE_AMOUNT,
                    APS.VAT_REGISTRATION_NUM,
                    IEB.BANK_NAME,
                    IEBA.BANK_ACCOUNT_NAME,
                    IEBA.BANK_ACCOUNT_NUM,
                    AI.INVOICE_ID,
                    AI.INVOICE_NUM,
                    AI.INVOICE_DATE,
                    AI.GL_DATE,
                    AI.EXCHANGE_RATE,
                    AI.EXCHANGE_DATE,
                    AI.EXCHANGE_RATE_TYPE,
                    AI.INVOICE_CURRENCY_CODE,
                    AI.SUPPLIER_TAX_INVOICE_NUMBER,
                    AI.SUPPLIER_TAX_INVOICE_DATE,
                    AI.ATTRIBUTE_CATEGORY,
                    ACA.ATTRIBUTE3,
                    TO_CHAR (AI.ATTRIBUTE3, '9,999,999,999,999.9999'),
                    TO_CHAR (AI.ATTRIBUTE4, '999,999,999,999.9999'),
                    POV.VENDOR_SITE_CODE,
                    PHA.SEGMENT1,
                    PHA.CREATION_DATE,
                    RSH.RECEIPT_NUM,
                    RT.TRANSACTION_DATE,
                    AI.DESCRIPTION,
                    ATL.DUE_DAYS,
                    GLCC.SEGMENT1,
                    GLCC.SEGMENT2,
                    GLCC.SEGMENT3,
                    GLCC.SEGMENT4,
                    GLCC.SEGMENT5,
                    GLCC.SEGMENT6,
                    GLCC.SEGMENT7,
                    AI.PAYMENT_STATUS_FLAG,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
           UNION
             SELECT AB.ATTRIBUTE1 RFP_NO,
                    HP.PARTY_NAME SUPPLIER_NAME,
                    AB.BATCH_ID,
                    AI.ORG_ID,
                    AB.BATCH_NAME INVOICE_BATCH_NAME,
                    APSA.DUE_DATE INVOICE_DUE,
                    SUM (AI.INVOICE_AMOUNT) TOTAL_PAYMENT,
                    DECODE (AB.ATTRIBUTE2,
                            NULL, HP.PARTY_NAME,
                            AB.ATTRIBUTE2, AB.ATTRIBUTE2)
                       PAID_TO,
                    AB.ATTRIBUTE3 REQUESTOR,
                    FU.USER_NAME CREATOR,
                    APS.VAT_REGISTRATION_NUM,
                    IEB.BANK_NAME Bank_Name,
                    IEBA.BANK_ACCOUNT_NAME Beneficiary_Name,
                    IEBA.BANK_ACCOUNT_NUM Account_Number,
                    AI.INVOICE_ID,
                    AI.INVOICE_NUM,
                    AI.INVOICE_DATE,
                    AI.INVOICE_AMOUNT,
                    AI.GL_DATE,
                    AI.EXCHANGE_RATE,
                    AI.EXCHANGE_DATE,
                    AI.EXCHANGE_RATE_TYPE,
                    AI.INVOICE_CURRENCY_CODE,
                    AI.SUPPLIER_TAX_INVOICE_NUMBER NPWP,
                    AI.SUPPLIER_TAX_INVOICE_DATE TGL_FAKTUR,
                    AI.ATTRIBUTE_CATEGORY,
                    AI.DESCRIPTION,
                    ATL.DUE_DAYS TERMS_DUE_DAYS,
                    ACA.ATTRIBUTE3 BP_NUMBER,
                    TO_CHAR (AI.ATTRIBUTE3, '9,999,999,999,999.9999')
                       PPN_BASE_AMOUNT,
                    TO_CHAR (AI.ATTRIBUTE4, '999,999,999,999.9999') PPN_AMOUNT,
                    POV.VENDOR_SITE_CODE SUPPLIER_SITE,
                    PHA.SEGMENT1 PO_NUM,
                    PHA.CREATION_DATE PO_DATE,
                    RSH.RECEIPT_NUM RCV_NUM,
                    RT.TRANSACTION_DATE RCV_DATE,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS,
                    AILA.ATTRIBUTE8 PROJECT_CODE,
                    SUM (NVL (AID.AMOUNT, 0)) AMOUNT_DR,
                    NULL AMOUNT_CR,
                    DECODE (AI.INVOICE_CURRENCY_CODE,
                            'IDR', SUM (NVL (AID.AMOUNT, 0)),
                            SUM (NVL (AID.BASE_AMOUNT, 0)))
                       ACCOUNTED_DR,
                    NULL ACCOUNTED_CR,
                       GLCC.SEGMENT1
                    || '-'
                    || GLCC.SEGMENT2
                    || '-'
                    || GLCC.SEGMENT3
                    || '-'
                    || GLCC.SEGMENT4
                    || '-'
                    || GLCC.SEGMENT5
                    || '-'
                    || GLCC.SEGMENT6
                    || '-'
                    || GLCC.SEGMENT7
                       GL_ACCOUNT,
                    GLCC.SEGMENT2 SEGMENT2,
                    GLCC.SEGMENT3 SEGMENT3,
                    GLCC.SEGMENT5 SEGMENT5,
                    GLCC.SEGMENT6 SEGMENT6,
                    AI.PAYMENT_STATUS_FLAG,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS_GL
               FROM AP.AP_INVOICES_ALL AI,
                    AP.AP_BATCHES_ALL AB,
                    AP.AP_PAYMENT_SCHEDULES_ALL APSA,
                    AR.HZ_PARTIES HP,
                    AP.AP_TERMS_LINES ATL,
                    AP.AP_INVOICE_PAYMENTS_ALL AIPA,
                    AP.AP_CHECKS_ALL ACA,
                    FND_USER FU,
                    AP_SUPPLIERS APS,
                    IBY_EXT_BANK_ACCOUNTS IEBA,
                    IBY_EXT_BANKS_V IEB,
                    APPS.PO_VENDOR_SITES_ALL POV,
                    AP.AP_INVOICE_LINES_ALL AILA,
                    PO_HEADERS_ALL PHA,
                    RCV_TRANSACTIONS RT,
                    RCV_SHIPMENT_HEADERS RSH,
                    AP.AP_INVOICE_DISTRIBUTIONS_ALL AID,
                    GL.GL_CODE_COMBINATIONS GLCC
              --          DR_CR
              WHERE     AI.BATCH_ID = AB.BATCH_ID
                    AND AI.PARTY_ID = HP.PARTY_ID
                    AND AB.CREATED_BY = FU.USER_ID
                    AND AI.VENDOR_ID = APS.VENDOR_ID
                    AND APSA.INVOICE_ID = AI.INVOICE_ID
                    AND POV.VENDOR_ID = AI.VENDOR_ID
                    AND POV.VENDOR_SITE_ID = AI.VENDOR_SITE_ID
                    AND AI.TERMS_ID = ATL.TERM_ID
                    AND AI.INVOICE_ID = AIPA.INVOICE_ID(+)
                    AND AIPA.CHECK_ID = ACA.CHECK_ID(+)
                    AND AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                           AI.INVOICE_ID,
                           AI.INVOICE_AMOUNT,
                           AI.PAYMENT_STATUS_FLAG,
                           AI.INVOICE_TYPE_LOOKUP_CODE) NOT IN ('CANCELLED')
                    AND AP_INVOICES_UTILITY_PKG.GET_APPROVAL_STATUS (
                           AI.INVOICE_ID,
                           AI.INVOICE_AMOUNT,
                           AI.PAYMENT_STATUS_FLAG,
                           AI.INVOICE_TYPE_LOOKUP_CODE) NOT IN ('CANCELLED')
                    AND AI.INVOICE_ID = AID.INVOICE_ID
                    AND AI.INVOICE_ID = AILA.INVOICE_ID(+)
                    AND GLCC.CODE_COMBINATION_ID = AID.DIST_CODE_COMBINATION_ID
                    AND AID.INVOICE_LINE_NUMBER = AILA.LINE_NUMBER
                    AND IEBA.EXT_BANK_ACCOUNT_ID(+) =
                           AI.EXTERNAL_BANK_ACCOUNT_ID
                    AND IEBA.BANK_ID = IEB.BANK_PARTY_ID(+)
                    AND AI.INVOICE_ID = AILA.INVOICE_ID(+)
                    AND AILA.PO_HEADER_ID = PHA.PO_HEADER_ID(+)
                    AND AILA.RCV_TRANSACTION_ID = RT.TRANSACTION_ID(+)
                    AND RT.SHIPMENT_HEADER_ID = RSH.SHIPMENT_HEADER_ID(+)
           GROUP BY AB.ATTRIBUTE1,
                    HP.PARTY_NAME,
                    AB.BATCH_ID,
                    AI.ORG_ID,
                    AB.BATCH_NAME,
                    APSA.DUE_DATE,
                    AI.INVOICE_CURRENCY_CODE,
                    DECODE (AB.ATTRIBUTE2,
                            NULL, HP.PARTY_NAME,
                            AB.ATTRIBUTE2, AB.ATTRIBUTE2),
                    AB.ATTRIBUTE3,
                    FU.USER_NAME,
                    APS.VAT_REGISTRATION_NUM,
                    IEB.BANK_NAME,
                    AI.INVOICE_AMOUNT,
                    IEBA.BANK_ACCOUNT_NAME,
                    IEBA.BANK_ACCOUNT_NUM,
                    AI.INVOICE_ID,
                    AI.INVOICE_NUM,
                    AI.INVOICE_DATE,
                    AI.GL_DATE,
                    AI.EXCHANGE_RATE,
                    AI.EXCHANGE_DATE,
                    AI.EXCHANGE_RATE_TYPE,
                    AI.INVOICE_CURRENCY_CODE,
                    AI.SUPPLIER_TAX_INVOICE_NUMBER,
                    AI.SUPPLIER_TAX_INVOICE_DATE,
                    AI.ATTRIBUTE_CATEGORY,
                    ACA.ATTRIBUTE3,
                    TO_CHAR (AI.ATTRIBUTE3, '9,999,999,999,999.9999'),
                    TO_CHAR (AI.ATTRIBUTE4, '999,999,999,999.9999'),
                    POV.VENDOR_SITE_CODE,
                    PHA.SEGMENT1,
                    PHA.CREATION_DATE,
                    RSH.RECEIPT_NUM,
                    RT.TRANSACTION_DATE,
                    AI.DESCRIPTION,
                    ATL.DUE_DAYS,
                    GLCC.SEGMENT1,
                    GLCC.SEGMENT2,
                    GLCC.SEGMENT3,
                    GLCC.SEGMENT4,
                    GLCC.SEGMENT5,
                    GLCC.SEGMENT6,
                    GLCC.SEGMENT7,
                    AILA.ATTRIBUTE8,
                    AI.PAYMENT_STATUS_FLAG,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE))
    WHERE     APPROVAL_STATUS_GL NOT IN ('CANCELLED')
          AND (NVL (ACCOUNTED_DR, 0) <> 0 OR NVL (ACCOUNTED_CR, 0) <> 0)
          AND ORG_ID = 82
          AND RFP_NO = 'RFP/CRM/20/09/000008'