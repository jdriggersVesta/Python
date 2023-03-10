-- noinspection SqlResolve
CREATE OR REPLACE VIEW VESTA.V_PATIENT_CAREGIVERS
AS
SELECT 
    id,
    caregiver_id,
    service_days,
    service_levels,
    active,
    type,
    agency,
    relationship,
    lives_with,
    inactive_reason,
    other_reason,
    marked_inactive,
    last_updated_by,
    created_at,
    updated_at,
    other_relationship,
    other_agency,
    program_configuration_member_id,
    enabled,
    disabled_at,
    program_configuration_organization_id,
    agency_search_term,
    creation_source,
    phi_delegation,
    last_login_at,
    last_login_consumer_id,
    last_login_device_id,
    reporter,
    member_id,
    engagement_owner,
    caregiver_status
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PATIENT_CAREGIVERS"
WHERE _FIVETRAN_DELETED=false;