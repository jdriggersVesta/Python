CREATE OR REPLACE PROCEDURE USP_CLAIMS_PLATFORMMEMBERS()
  RETURNS VARCHAR(10)
  LANGUAGE javascript
  AS
  $$
       var cmd=`TRUNCATE VSM.ALERTS;`;
       var sql=snowflake.createStatement({sqlText: cmd});
       sql.execute();

       var cmd=`INSERT INTO VSM.ALERTS

   /*  create or replace table vsm.alerts as */
SELECT DISTINCT
  d.CALENDAR_DATE, 
  BASE.*, 
  GETDATE() AS RUNTIME
FROM DIM.DATES d
LEFT JOIN
    (

    SELECT DISTINCT 
        (ha.id)alert_id
        ,(pat.member_id)dashid_link
      --,CASE WHEN pat.member_id IS NULL THEN pcm.dash_id ELSE pat.member_id END AS dashid_link      --Appears to be introducing Dash IDs with 'Enabled = False'
        ,CAST(ha.created_at AS TIMESTAMP_NTZ(9))alert_createdat
        ,(ha.status)alert_status
        ,(ha.urgent)alert_urgent
        ,(ha.valid)alert_valid
        ,(ha.patient_caregiver_id)alert_caregiverID
        ,(ha.channel)alert_channel
        ,CAST(ha.closed_at AS TIMESTAMP_NTZ(9))alert_closedat
        ,(ha.created_by)alert_createdby
        ,CAST(assign.assigned_at AS TIMESTAMP_NTZ(9))alert_assignedat
        ,(assign.assigned_by)alert_assignedby
        ,(assign.assigned_by_id)alert_assignedbyid
        ,(ha.assignee_id)alert_assigneeID
        ,concat(e.first_name,' ',e.last_name)alert_createdbyname
        ,(ha.evaluated_by)alert_evaluatedby
        ,concat(emp1.first_name,' ',emp1.last_name)alert_evaluatedbyname
        ,concat(emp2.first_name,' ',emp2.last_name)alert_assignedtoname
        ,CAST(ha.evaluation_updated_at AS TIMESTAMP_NTZ(9))alert_evaluationupdatedat
        ,CAST(ha.resolved_at AS TIMESTAMP_NTZ(9))alert_resolvedat 
        ,CAST(ha.updated_at AS TIMESTAMP_NTZ(9))alert_updatedat  
        ,(ha.has_time)alert_hastime
        ,(ha.invalid_note)alert_invalidnote
        ,(ha.invalidated_reason)alert_invalidatedreason
        ,(ha.is_off_hours)alert_isoffhours
        ,(ha.note)alert_note
        ,(ha.program_configuration_member_id)alert_pcmid
        ,ha.diverted_from as alert_diverted_from_er
        ,ha.diverted_from_ed as alert_diverted_from_ed
    FROM 
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS_XWALK" ha
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES" e ON ha.created_by = e.id
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES" emp1 ON ha.evaluated_by = emp1.id
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES" emp2 ON ha.assignee_id = emp2.id
    LEFT JOIN
    (
    SELECT 
                (hah.id)alert_id
                        ,(rv.user_name)assigned_by
                        ,(rv.user_id)assigned_by_id
                        ,to_timestamp(rv.timestamp/1000)assigned_at
                    FROM 
                        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."REVISION_LOGS" rv
                    INNER JOIN
                        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS_HIST" hah ON rv.id = hah.rev
                    WHERE rv.id IN (
    SELECT revision_id
    FROM 
    ( 

      SELECT 
    (ha.id)alert_id
    ,(hah.rev)revision_id
    ,ROW_NUMBER() OVER (PARTITION BY ha.id ORDER BY hah.rev ASC) AS rn
    FROM 
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS_HIST" hah
    INNER JOIN
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS" ha ON hah.id = ha.id 
    WHERE hah.assignee_id IS NOT NULL
    )x
    WHERE x.rn = 1
                                    )
    )assign ON assign.alert_id = ha.id
    LEFT JOIN
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."V_PROGRAMCONFIGMODEL_XWALK" pcm ON pcm.pcm_id_XWALK = ha.program_configuration_member_id_XWALK
    LEFT JOIN
    (
--------
      SELECT
         (pp.id)member_id
        ,pp.external_id
        ,pp.phone_number
        ,pp.first_name
        ,pp.last_name
        ,Concat(pp.first_name,' ',pp.last_name)full_name
        ,pp.zip_code
        ,pp.agency
        ,pp.status
        ,pp.gender
        ,pp.language
        ,pp.plan
        ,pp.timezone
        ,pp.birth_date
        ,pp.risk_profile_completed
        ,pp.risk_profile_completed_at
        ,pp.reporting_start_date
        ,pp.social_assessment_completed_at
        ,pp.last_pcp_visit
        ,(pp.updated_at)member_updated_DtTm
        ,(pp.created_at)member_created_DtTm
        ,pp.expected_weekly_health_reports
        ,pp.owner_id
        ,(x.created_at)HR_Created_At
    FROM "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PLATFORM_PATIENTS" pp
    LEFT JOIN
    (
    SELECT pcm.dash_id AS member_id, pdr.created_At
    FROM
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PLATFORM_DAILY_RECORD" pdr
    INNER JOIN
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PATIENT_CAREGIVERS_XWALK" pc ON pdr.patient_caregiver_id = pc.id
    INNER JOIN
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_MEMBERS_XWALK" pcm ON pc.program_configuration_member_id_XWALK = pcm.pcm_id_XWALK
    )x ON x.member_id = pp.id
    WHERE pp.test = 'false'
          AND
          pp.enabled = 'true'
        )pat ON pat.member_id = pcm.dash_id
  )BASE ON d.CALENDAR_DATE = CAST(BASE.alert_createdat AS DATE) order by d.calendar_date desc
;`;
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();
    return 'done';
$$