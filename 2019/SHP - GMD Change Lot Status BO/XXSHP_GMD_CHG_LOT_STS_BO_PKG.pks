CREATE OR REPLACE PACKAGE APPS.XXSHP_GMD_CHG_LOT_STS_BO_PKG
AS
   TYPE T_LOT_NUMBER IS RECORD
   (
      inventory_item_id              NUMBER,
      segment1                       VARCHAR2 (30),
      description                    VARCHAR2 (400),
      status_id                      NUMBER,
      old_status_id                  NUMBER,
      lot_number                     VARCHAR2 (40),
      organization_id                NUMBER,
      primary_transaction_quantity   NUMBER,
      expiration_date                DATE,
      parent_lot_number              VARCHAR2 (40),
      origination_type               NUMBER,
      availability_type              NUMBER,
      expiration_action_date         DATE
   );

   --   TYPE LISTTABLE IS TABLE OF VARCHAR2 (4000);

   TYPE TB_LOT_NUMBER IS TABLE OF T_LOT_NUMBER
      INDEX BY BINARY_INTEGER;

   g_user_name         VARCHAR2 (100) := fnd_global.user_name;
   g_user_id           NUMBER := fnd_profile.VALUE ('USER_ID');
   g_login_id          NUMBER := fnd_profile.VALUE ('LOGIN_ID');
   g_resp_id           NUMBER := fnd_profile.VALUE ('RESP_ID');
   g_resp_appl_id      NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   g_organization_id   NUMBER := 83; --fnd_profile.VALUE ('MFG_ORGANIZATION_ID');

   -- Procedure Change Lot Status BO
   PROCEDURE change_lot (errbuf          OUT VARCHAR2,
                         retcode         OUT NUMBER,
                         p_exp_date   IN     NUMBER,
                         p_email      IN     VARCHAR2
                         );

   -- Procedure Kirim E-mail
   PROCEDURE send_mail (errbuf              OUT VARCHAR2,
                        retcode             OUT VARCHAR2,
                        p_result            OUT VARCHAR2,
                        p_email          IN     VARCHAR2,
                        p_total_update   IN     VARCHAR2,
                        p_exp_date       IN     NUMBER);
END XXSHP_GMD_CHG_LOT_STS_BO_PKG;
/
