-- noinspection SqlResolve
CREATE OR REPLACE VIEW VESTA.V_PROGRAM_CONFIGURATION_MEMBERS
AS
SELECT 
    id,
    member_id,
    program_configuration_id,
    effective_date,
    discontinue_date,
    status,
    created_at,
    updated_at
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_MEMBERS"
WHERE _FIVETRAN_DELETED=false;