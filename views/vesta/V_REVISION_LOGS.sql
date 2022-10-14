-- noinspection SqlResolve
CREATE OR REPLACE VIEW VESTA.V_REVISION_LOGS
AS
SELECT 
    id,
    timestamp,
    reason,
    user_id,
    user_name,
    user_type
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."REVISION_LOGS"
WHERE _FIVETRAN_DELETED=false;