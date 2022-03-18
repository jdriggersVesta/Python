CREATE OR REPLACE VIEW VESTA.V_EMPLOYEES
AS
SELECT 
    id,
    role,
    timezone,
    created_at,
    updated_at,
    enabled,
    phone_number,
    email,
    title,
    "GROUP",
    home_phone,
    home_email,
    quote,
    first_name,
    last_name,
    picture,
    cats_one_id_for_care_manager,
    salesforce_user_id,
    "PASSWORD",
    zoom_meeting_id,
    phi_access,
    account_id,
    dash_permission_id,
    system_account
FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES"
WHERE _FIVETRAN_DELETED=false;