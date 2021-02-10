/* Formatted on 10/5/2020 4:23:55 PM (QP5 v5.256.13226.35538) */
DROP VIEW APPS.XXVMT_RFP_INVOICE_V;


CREATE OR REPLACE FORCE VIEW APPS.XXVMT_RFP_INVOICE_V
(
   INVOICE_ID,
   RFP_NO,
   CURRENCY_CODE,
   AMOUNT_DR,
   AMOUNT_CR,
   ACCOUNTED_DR,
   ACCOUNTED_CR,
   GL_ACCOUNT,
   GL_ACCOUNT_DESCRIPTION,
   APPROVAL_STATUS_GL
)
   BEQUEATH DEFINER
AS
   SELECT INVOICE_ID,
          RFP_NO,
          CURRENCY_CODE,
          AMOUNT_DR,
          AMOUNT_CR,
          ACCOUNTED_DR,
          ACCOUNTED_CR,
          GL_ACCOUNT,
          GL_ACCOUNT_DESCRIPTION,
          APPROVAL_STATUS_GL
     FROM (  SELECT AI.INVOICE_ID,
                    AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
                    NULL PROJECT_CODE,
                    AB.ATTRIBUTE1 RFP_NO,
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
                    XXVMT_INTF_INVOICE_PKG.gl_code_descr (
                       GLCC.CODE_COMBINATION_ID)
                       GL_ACCOUNT_DESCRIPTION,
                    GLCC.SEGMENT2 SEGMENT2,
                    GLCC.SEGMENT3 SEGMENT3,
                    GLCC.SEGMENT5 SEGMENT5,
                    GLCC.SEGMENT6 SEGMENT6,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS_GL
               FROM AP.AP_INVOICES_ALL AI,
                    GL.GL_CODE_COMBINATIONS GLCC,
                    AP.AP_BATCHES_ALL AB
              WHERE     GLCC.CODE_COMBINATION_ID =
                           AI.ACCTS_PAY_CODE_COMBINATION_ID
                    AND AI.BATCH_ID = AB.BATCH_ID
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
           GROUP BY AI.INVOICE_ID,
                    AI.INVOICE_CURRENCY_CODE,
                    AI.ATTRIBUTE8,
                    AB.ATTRIBUTE1,
                    GLCC.SEGMENT1,
                    GLCC.SEGMENT2,
                    GLCC.SEGMENT3,
                    GLCC.SEGMENT4,
                    GLCC.SEGMENT5,
                    GLCC.SEGMENT6,
                    GLCC.SEGMENT7,
                    GLCC.CODE_COMBINATION_ID,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
           UNION
             SELECT DISTINCT
                    AID.INVOICE_ID,
                    AI.INVOICE_CURRENCY_CODE CURRENCY_CODE,
                    AILA.ATTRIBUTE8 PROJECT_CODE,
                    AB.ATTRIBUTE1 RFP_NO,
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
                    XXVMT_INTF_INVOICE_PKG.gl_code_descr (
                       GLCC.CODE_COMBINATION_ID)
                       GL_ACCOUNT_DESCRIPTION,
                    GLCC.SEGMENT2 SEGMENT2,
                    GLCC.SEGMENT3 SEGMENT3,
                    GLCC.SEGMENT5 SEGMENT5,
                    GLCC.SEGMENT6 SEGMENT6,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE)
                       APPROVAL_STATUS_GL
               FROM AP.AP_INVOICES_ALL AI,
                    AP.AP_INVOICE_DISTRIBUTIONS_ALL AID,
                    AP.AP_INVOICE_LINES_ALL AILA,
                    GL.GL_CODE_COMBINATIONS GLCC,
                    AP.AP_BATCHES_ALL AB
              WHERE     GLCC.CODE_COMBINATION_ID = AID.DIST_CODE_COMBINATION_ID
                    AND AID.INVOICE_ID = AI.INVOICE_ID
                    AND AI.INVOICE_ID = AILA.INVOICE_ID
                    AND AID.INVOICE_LINE_NUMBER = AILA.LINE_NUMBER
                    AND AI.BATCH_ID = AB.BATCH_ID
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
           GROUP BY AID.INVOICE_ID,
                    AI.INVOICE_CURRENCY_CODE,
                    AILA.ATTRIBUTE8,
                    AB.ATTRIBUTE1,
                    GLCC.SEGMENT1,
                    GLCC.SEGMENT2,
                    GLCC.SEGMENT3,
                    GLCC.SEGMENT4,
                    GLCC.SEGMENT5,
                    GLCC.SEGMENT6,
                    GLCC.SEGMENT7,
                    GLCC.CODE_COMBINATION_ID,
                    AP_INVOICES_PKG.GET_APPROVAL_STATUS (
                       AI.INVOICE_ID,
                       AI.INVOICE_AMOUNT,
                       AI.PAYMENT_STATUS_FLAG,
                       AI.INVOICE_TYPE_LOOKUP_CODE))
    WHERE     APPROVAL_STATUS_GL NOT IN ('CANCELLED') --AND (AMOUNT_DR >= 0 OR AMOUNT_CR >= 0 OR ACCOUNTED_DR >= 0 OR ACCOUNTED_CR >= 0)
          AND (NVL (ACCOUNTED_DR, 0) <> 0 OR NVL (ACCOUNTED_CR, 0) <> 0);