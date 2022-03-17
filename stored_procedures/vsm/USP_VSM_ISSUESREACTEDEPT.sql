CREATE OR REPLACE PROCEDURE USP_CLAIMS_PLATFORMMEMBERS()
  RETURNS VARCHAR(10)
  LANGUAGE javascript
  AS
  $$
var cmd=`TRUNCATE TABLE VSM.ISSUESREACTEDEPT;`;
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();

var cmd=`
INSERT INTO VSM.ISSUESREACTEDEPT
SELECT 
        CALENDAR_DATE, 
        BASE.*, 
        GETDATE() AS RUNTIME
FROM DIM.DATES d
LEFT JOIN
(
SELECT DISTINCT
    issues.issue_id
    ,issues.health_alert_id
    ,issues.issue_escalated
    ,issues.issue_type
    ,issues.issue_createdat
    ,issues.issue_updatedat
    ,issues.issue_valid
    ,issues.issue_note
    ,issues.issue_source
    ,issue_evaluatedurgency
    ,react.react_id
    ,react.react_additionalinfo
    ,react.react_createdat
    ,react.react_createdbyname
    ,react.react_outcomeresult
    ,react.react_outcomestatus
    ,react.react_outcomeupdatedbyname
    ,react.react_specialist
    ,react.react_type
    ,react.react_updatedat
    ,ed.edviz_id
    ,ed.edviz_createdat
    ,ed.edviz_date
    ,ed.edviz_otherreason
    ,ed.edviz_reasons
    ,ed.edviz_updatedat
    ,pcm.pcm_id
FROM 
    "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ALERTS" ha
LEFT JOIN
(
          SELECT  
              (a.id)issue_id
              ,a.health_alert_id
              ,(a.escalated)issue_escalated
              ,(a.type)issue_type
              ,(a.created_at)issue_createdat
              ,(a.updated_at)issue_updatedat
              ,(a.daily_care_question_id)issue_dcqid
              ,(a.valid)issue_valid
              ,(a.note)issue_note
              ,(a.source)issue_source
              ,(a.evaluated_urgency)issue_evaluatedurgency
          FROM 
              "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."HEALTH_ISSUES" a
          LEFT JOIN 
              "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."DAILY_CARE_QUESTIONS" b on a.daily_care_question_id = b.id
          )issues ON issues.health_alert_id = ha.id

LEFT JOIN
  
(
          SELECT
          (i.id)react_id
          ,(i.additional_info)react_additionalinfo
          ,(i.created_at)react_createdat
          ,concat(e1.first_name,' ',e1.last_name)react_createdbyname
          ,i.health_issue_id
          ,(i.outcome_result)react_outcomeresult
          ,(i.outcome_status)react_outcomestatus
          ,(i.outcome_updated_by)react_outcomeupdatedbyID
          ,concat(e.first_name,' ',e.last_name)react_outcomeupdatedbyname
          ,(i.specialist)react_specialist
          ,(i.type)react_type
          ,(i.updated_at)react_updatedat
          FROM 
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."INTERVENTIONS" i
          LEFT JOIN
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES" e on e.id = i.outcome_updated_by
          LEFT JOIN
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMPLOYEES" e1 on e1.id = i.created_by
          )react ON react.health_issue_id = issues.issue_id

LEFT JOIN

(
          SELECT
          (ed.id)edviz_id
          ,(ed.created_at)edviz_createdat
          ,(ed.date)edviz_date
          ,ed.health_issue_id
          ,(ed.other_reason)edviz_otherreason
          ,(ed.reasons)edviz_reasons
          ,(ed.updated_at)edviz_updatedat
          FROM 
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."EMERGENCY_ROOM_VISITS" ed
)ed ON ed.health_issue_id = issues.issue_id

LEFT JOIN

(
SELECT * FROM VESTA.V_PROGRAMCONFIGMODEL
)pcm ON pcm.pcm_id = ha.program_configuration_member_id

LEFT JOIN

(
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
          SELECT pcm.member_id, pdr.created_At
          FROM
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PLATFORM_DAILY_RECORD" pdr
          INNER JOIN
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PATIENT_CAREGIVERS" pc ON pdr.patient_caregiver_id = pc.id
          INNER JOIN
          "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_MEMBERS" pcm ON pc.program_configuration_member_id = pcm.id
          )x ON x.member_id = pp.id

          WHERE pp.test = 'false'
                AND
                pp.enabled = 'true'

)pat ON pat.member_id = pcm.dash_id
  )BASE ON d.CALENDAR_DATE = to_date(BASE.issue_createdat)
  
  `;

   var sql=snowflake.createStatement({sqlText: cmd});
   sql.execute();
   
return 'done';
$$