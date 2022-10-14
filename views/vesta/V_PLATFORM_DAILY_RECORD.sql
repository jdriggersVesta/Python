-- noinspection SqlResolve
CREATE OR REPLACE VIEW VESTA.V_PLATFORM_DAILY_RECORD
AS
SELECT 
    id,
    start_time,
    end_time,
    created_at,
    updated_at,
    status,
    created_by,
    channel,
    patient_caregiver_id
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PLATFORM_DAILY_RECORD"
WHERE _FIVETRAN_DELETED=false;