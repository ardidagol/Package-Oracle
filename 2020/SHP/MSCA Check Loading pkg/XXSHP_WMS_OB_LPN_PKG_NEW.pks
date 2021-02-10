CREATE OR REPLACE PACKAGE APPS.XXSHP_WMS_OB_LPN_PKG_NEW
   AUTHID CURRENT_USER
AS
   /* $HEADER: XXSHP_WMS_OB_LPN_PKG_NEW.PK 122.5.1.8 2017/01/01 17:27:00 Iqbal Dwi Prawira $ */

   /******************************************************************************
       NAME: XXSHP_WMS_OB_LPN_PKG_NEW
       PURPOSE:

       REVISIONS:
       Ver         Date            Author                        Description
       ---------   ----------      ---------------               ------------------------------------
       1.0         17-Jan-2017    Iqbal DwiPrawira,             1. Created this package.
       1.1         21 Juni 2017   Farid Bachtiar                2. Mengubah LOV Untuk LPN Outbound
       2.0         05 Sep 2017   Iqbal dwi Prawira              3. tambahin parameter pada insertTemp
       3.0         13 May 2019   Michael Leonard              1. tambah procesuder get_spm_load_lov
                                                              2. tambah procedure get_lpn_ob_load_lov
                                                              3. tambah procedure get_lot_ob_load_lov
                                                              4. tambah procedure get_remarks_load_lov
                                                             5. tambah procedure get_checking_lpn
                                                             6. tambah procedure get_load_notes
                                                             7. tambah procedure GET_LOAD_ITEM_ID
                                                             8. tambah procedure get_prim_qty_load
                                                             9. tambah procedure get_load_remaining_lot
                                                             10. tambah procedure get_load_remaining_lpn
                                                             11. tambah procedure insert_load_temp
      ******************************************************************************/
   TYPE t_ref_csr IS REF CURSOR;

   g_user_id   NUMBER := fnd_profile.VALUE ('USER_ID');
   g_item_id   NUMBER;

   PROCEDURE get_spm_lov (x_spm         OUT NOCOPY t_ref_csr,
                          p_spm      IN            VARCHAR2,
                          p_org_id   IN            NUMBER);
                          
   PROCEDURE get_spm_load_lov (x_spm         OUT NOCOPY t_ref_csr,
                               p_spm      IN            VARCHAR2,
                               p_org_id   IN            NUMBER);

   PROCEDURE commit_transaction (p_source IN VARCHAR2);

   PROCEDURE get_lpn_ob_lov (x_lpn       OUT NOCOPY t_ref_csr,
                             p_spm    IN            VARCHAR2,
                             p_lpn    IN            VARCHAR2,
                             p_item   IN            VARCHAR2);
   
   PROCEDURE get_lpn_ob_load_lov (x_lpn       OUT NOCOPY t_ref_csr,
                                  p_spm    IN            VARCHAR2,
                                  p_lpn    IN            VARCHAR2,
                                  p_item   IN            VARCHAR2);

   PROCEDURE get_lot_ob_lov (x_lpn       OUT NOCOPY t_ref_csr,
                             p_spm    IN            VARCHAR2,
                             p_lpn    IN            VARCHAR2,
                             p_item   IN            VARCHAR2,
                             p_lot    IN            VARCHAR2);
                             
   PROCEDURE get_lot_ob_load_lov (x_lpn       OUT NOCOPY t_ref_csr,
                                  p_spm    IN            VARCHAR2,
                                  p_lpn    IN            VARCHAR2,
                                  p_item   IN            VARCHAR2,
                                  p_lot    IN            VARCHAR2);

   PROCEDURE get_remarks_lov (x_remarks OUT NOCOPY t_ref_csr);
   
   PROCEDURE get_remarks_load_lov (x_remarks OUT NOCOPY t_ref_csr);

   FUNCTION convertion_qty (p_inv_item_id   IN NUMBER,
                            p_from_qty      IN NUMBER,
                            p_from_name     IN VARCHAR2,
                            p_to_name       IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_remaining_lot (p_lpn IN VARCHAR2)
      RETURN NUMBER;
      
   FUNCTION get_load_remaining_lot (p_lpn IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_remaining_lpn (p_source_doc IN VARCHAR2)
      RETURN NUMBER;
      
   FUNCTION get_load_remaining_lpn (p_source_doc IN VARCHAR2)
      RETURN NUMBER;
      
   FUNCTION get_load_remaining_lpn_v2 (p_source_doc IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_checking_lpn (p_lpn        VARCHAR2,
                              p_lot        VARCHAR2,
                              p_item_id    NUMBER)
      RETURN NUMBER;
      
   FUNCTION get_checking_load_lpn (p_lpn        VARCHAR2,
                                   p_lot        VARCHAR2,
                                   p_item_id    NUMBER)
      RETURN NUMBER;

   FUNCTION get_prim_qty_stg (p_lpn VARCHAR2, p_lot VARCHAR2)
      RETURN VARCHAR2;
      
   FUNCTION get_prim_qty_load (p_lpn VARCHAR2, p_lot VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION GET_ITEM_ID (p_lpn IN VARCHAR2, P_LOT IN VARCHAR2)
      RETURN NUMBER;
      
   FUNCTION GET_LOAD_ITEM_ID (p_lpn IN VARCHAR2, P_LOT IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_remarks (p_lpn VARCHAR2, p_lot VARCHAR2, p_item_id NUMBER)
      RETURN VARCHAR2;

   FUNCTION get_notes (p_lpn VARCHAR2, p_lot VARCHAR2, p_item_id NUMBER)
      RETURN VARCHAR2;
      
   FUNCTION get_load_notes (p_lpn VARCHAR2, p_lot VARCHAR2, p_item_id NUMBER)
      RETURN VARCHAR2;

   PROCEDURE insert_temp (p_spm                  IN     VARCHAR2,
                          p_item_id              IN     NUMBER,
                          p_lpn                  IN     VARCHAR2,
                          p_lot                  IN     VARCHAR2,
                          p_uom                  IN     VARCHAR2,
                          p_primary_qty          IN     NUMBER,
                          p_secondary_uom_code   IN     VARCHAR2,
                          p_primary_stg_qty      IN     NUMBER,
                          p_secondary_stg_qty    IN     NUMBER,
                          p_remarks_stg          IN     VARCHAR2,
                          p_notes_stg            IN     VARCHAR2,
                          p_orgid                IN     NUMBER,
                          p_start_date_stg       IN     VARCHAR2,
                          p_end_date_stg         IN     VARCHAR2,
                          p_delivery_detail_id   IN     NUMBER,
                          P_USER_ID_STG          IN     NUMBER, --update by iqbal 05-09-2017
                          p_result                  OUT VARCHAR2);
                          
   PROCEDURE insert_temp_load (p_spm                  IN     VARCHAR2,
                               p_item_id              IN     NUMBER,
                               p_lpn                  IN     VARCHAR2,
                               p_lot                  IN     VARCHAR2,
                               p_uom                  IN     VARCHAR2,
                               p_primary_qty          IN     NUMBER,
                               p_secondary_uom_code   IN     VARCHAR2,
                               p_primary_load_qty     IN     NUMBER,
                               p_secondary_load_qty   IN     NUMBER,
                               p_remarks_load         IN     VARCHAR2,
                               p_notes_load           IN     VARCHAR2,
                               p_orgid                IN     NUMBER,
                               p_start_date_load      IN     VARCHAR2,
                               p_end_date_load        IN     VARCHAR2,
                               p_delivery_detail_id   IN     NUMBER,
                               P_USER_ID_LOAD         IN     NUMBER, --update by iqbal 05-09-2017
                               p_dock_id              IN     NUMBER,
                               p_dock_door            IN     VARCHAR2,
                               p_result                  OUT VARCHAR2);

   PROCEDURE update_outbound (p_source_no       IN     VARCHAR2,
                              p_inv_item_id     IN     NUMBER,
                              p_lpn             IN     VARCHAR2,
                              p_lot             IN     VARCHAR2,
                              p_prim_uom        IN     VARCHAR2,
                              p_sec_uom         IN     VARCHAR2,
                              p_prim_qty        IN     NUMBER,
                              p_update_by       IN     NUMBER,
                              p_prim_conf_qty   IN     NUMBER,
                              p_sec_conf_qty    IN     NUMBER,
                              p_remark          IN     VARCHAR2,
                              p_notes           IN     VARCHAR2,
                              p_start           IN     VARCHAR2,
                              p_end             IN     VARCHAR2,
                              p_result             OUT VARCHAR2);
END XXSHP_WMS_OB_LPN_PKG_NEW;
/