-- noinspection SqlResolve
CREATE OR REPLACE VIEW VESTA.V_HEALTH_ALERTS
AS
SELECT 
    id,
    assignee_id,
    status,
    zendesk_ticket_id,
    channel,
    created_at,
    updated_at,
    valid,
    alert_date,
    resolved_at,
    closed_at,
    evaluation_updated_at,
    evaluated_by,
    alert_date_time,
    created_by,
    urgent,
    has_time,
    is_off_hours,
    note,
    invalidated_reason,
    invalid_note,
    translated_note,
    note_language_source_code,
    program_configuration_member_id,
    patient_caregiver_id,
    channel_external_id,
    diverted_from_er,
    diverted_from,
    member_document_id,
    diverted_from_ed,
    member_id
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS"
WHERE _FIVETRAN_DELETED=false;