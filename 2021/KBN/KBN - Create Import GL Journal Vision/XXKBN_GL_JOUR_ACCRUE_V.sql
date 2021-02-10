DROP VIEW APPS.XXKBN_GL_JOUR_ACCRUE_V;

/* Formatted on 2/9/2021 4:19:22 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXKBN_GL_JOUR_ACCRUE_V
(
   JE_BATCH_ID,
   BATCH_DESC,
   JE_HEADER_ID,
   "Journal_Name",
   HEADER_DESC,
   JE_SOURCE,
   JE_CATEGORY,
   JE_REFERENCE,
   COA,
   DATETIME_POSTED,
   ACCOUNTING_PERIOD,
   CREATED_BY_USER,
   LAST_UPDATE_BY,
   LINE_NUM,
   CURRENCY_CODE,
   CURRENCY_CONVERSION_DATE,
   CURRENCY_CONVERSION_RATE,
   ENTRY_DR,
   ENTRY_CR,
   ACCOUNTED_DR,
   ACCOUNTED_CR,
   LINE_DESC,
   REFERENCE_1,
   REFERENCE_4,
   REFERENCE_10,
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
     SELECT GLB.JE_BATCH_ID,
            GLB.description "BATCH_DESC",
            GLH.JE_HEADER_ID,
            glh.name "Journal_Name",
            glh.description "HEADER_DESC",
            glh.JE_SOURCE,
            glh.JE_CATEGORY,
            glh.JE_HEADER_ID || gll.JE_LINE_NUM "JE_REFERENCE",
            gcc.CONCATENATED_SEGMENTS "COA",
            glh.posted_date "DATETIME_POSTED",
            gll.period_name "ACCOUNTING_PERIOD",
            fu2.USER_NAME "CREATED_BY_USER",
            fu1.USER_NAME "LAST_UPDATE_BY",
            GLL.JE_LINE_NUM "LINE_NUM",
            GLH.CURRENCY_CODE,
            GLH.CURRENCY_CONVERSION_DATE,
            GLH.CURRENCY_CONVERSION_RATE,
            (NVL (GLL.ENTERED_DR, 0)) ENTRY_DR,
            (NVL (GLL.ENTERED_CR, 0)) ENTRY_CR,
            (NVL (gll.ACCOUNTED_DR, 0)) ACCOUNTED_DR,
            (NVL (gll.ACCOUNTED_CR, 0)) ACCOUNTED_CR,
            gll.description "LINE_DESC",
            gll.REFERENCE_1,
            gll.REFERENCE_4,
            gll.REFERENCE_10,
            gll.ATTRIBUTE1,
            gll.ATTRIBUTE2,
            gll.ATTRIBUTE3,
            gll.ATTRIBUTE5,
            gll.ATTRIBUTE6,
            gll.ATTRIBUTE7,
            gll.ATTRIBUTE8,
            gll.ATTRIBUTE9,
            gll.ATTRIBUTE10,
            gll.ATTRIBUTE11,
            gll.ATTRIBUTE12,
            gll.ATTRIBUTE13,
            gll.ATTRIBUTE14,
            gll.ATTRIBUTE15
       FROM apps.GL_JE_LINES gll,
            apps.GL_JE_HEADERS glh,
            apps.GL_CODE_COMBINATIONS_KFV gcc,
            apps.gl_je_batches GLB,
            apps.FND_USER fu1,
            apps.FND_USER fu2,
            apps.GL_JE_SOURCES gjs
      WHERE     gll.last_updated_by = fu1.user_id
            AND gll.created_by = fu2.user_id
            AND glh.je_batch_id = GLB.je_batch_id
            AND gll.je_header_id = glh.je_header_id
            AND gll.LEDGER_ID = 2021
            AND gll.code_combination_id = gcc.code_combination_id
            AND gjs.JE_SOURCE_NAME = glh.JE_SOURCE
            AND gjs.USER_JE_SOURCE_NAME = 'KBN-Vision'
   ORDER BY 1, 2;


CREATE OR REPLACE SYNONYM XXKBN.XXKBN_GL_JOUR_ACCRUE_V FOR APPS.XXKBN_GL_JOUR_ACCRUE_V;


GRANT SELECT ON APPS.XXKBN_GL_JOUR_ACCRUE_V TO XXKBN;
