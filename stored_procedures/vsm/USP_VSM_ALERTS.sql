CREATE OR REPLACE PROCEDURE USP_VSM_ALERTS()
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
        ,(ha.member_id)dashid_link
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
        "VESTA_PRODUCTION"."VESTA"."V_HEALTH_ALERTS" ha
    JOIN
        "VESTA_PRODUCTION"."VESTA"."V_PLATFORM_PATIENTS" pp
        ON ha.member_id=pp.id
    LEFT JOIN
        "VESTA_PRODUCTION"."VESTA"."V_EMPLOYEES" e ON ha.created_by = e.id
    LEFT JOIN
        "VESTA_PRODUCTION"."VESTA"."V_EMPLOYEES" emp1 ON ha.evaluated_by = emp1.id
    LEFT JOIN
        "VESTA_PRODUCTION"."VESTA"."V_EMPLOYEES" emp2 ON ha.assignee_id = emp2.id
    LEFT JOIN
    (
    SELECT 
                (hah.id)alert_id
                        ,(rv.user_name)assigned_by
                        ,(rv.user_id)assigned_by_id
                        ,to_timestamp(rv.timestamp/1000)assigned_at
                    FROM 
                        "VESTA_PRODUCTION"."VESTA"."V_REVISION_LOGS" rv
                    INNER JOIN
                        "VESTA_PRODUCTION"."VESTA"."V_HEALTH_ALERTS_HIST" hah ON rv.id = hah.rev
                    WHERE rv.id IN (
    SELECT revision_id
    FROM 
    ( 

      SELECT 
    (ha.id)alert_id
    ,(hah.rev)revision_id
    ,ROW_NUMBER() OVER (PARTITION BY ha.id ORDER BY hah.rev ASC) AS rn
    FROM 
    "VESTA_PRODUCTION"."VESTA"."V_HEALTH_ALERTS_HIST" hah
    INNER JOIN
    "VESTA_PRODUCTION"."VESTA"."V_HEALTH_ALERTS" ha ON hah.id = ha.id 
    WHERE hah.assignee_id IS NOT NULL
    )x
    WHERE x.rn = 1
                                    )
    )assign ON assign.alert_id = ha.id
  )BASE ON d.CALENDAR_DATE = CAST(BASE.alert_createdat AS DATE) order by d.calendar_date desc
;`;
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();
    return 'done';
$$