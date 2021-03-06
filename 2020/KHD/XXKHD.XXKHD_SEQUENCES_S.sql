--DROP SEQUENCE XXKHD.XXKHD_SEQUENCES_S;

CREATE SEQUENCE XXKHD.XXKHD_SEQUENCES_S
  START WITH 1
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER
  NOKEEP
  GLOBAL;


CREATE OR REPLACE SYNONYM APPS.XXKHD_SEQUENCES_S FOR XXKHD.XXKHD_SEQUENCES_S;


GRANT ALTER, SELECT ON XXKHD.XXKHD_SEQUENCES_S TO APPS;
