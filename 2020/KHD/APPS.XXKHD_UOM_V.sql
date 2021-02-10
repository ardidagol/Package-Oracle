DROP VIEW APPS.XXKHD_UOM_V;

/* Formatted on 7/28/2020 2:10:59 PM (QP5 v5.256.13226.35538) */
CREATE OR REPLACE FORCE VIEW APPS.XXKHD_UOM_V
(
   UOM_CODE,
   UOM_DESCRIPTION
)
   BEQUEATH DEFINER
AS
   SELECT muo.uom_code, muo.unit_of_measure uom
     FROM mtl_units_of_measure_vl muo
    WHERE 1 = 1 AND UPPER (uom_class) = 'COUNT';
