CREATE OR REPLACE PROCEDURE USP_VSM_CENSUS_RESTORE()
  RETURNS VARCHAR(10)
  LANGUAGE javascript
  AS
  $$
var cmd=`TRUNCATE VESTA.VESTA_MEMBERCENSUS;`;
  var sql=snowflake.createStatement({sqlText: cmd});
  sql.execute();

    var cmd=`CREATE OR REPLACE TEMPORARY TABLE censushist
              AS
              SELECT
                           y.dash_id
                          ,y.status
                          ,y.dischargerollup
                          ,y.datechange
                          ,y.dateanchor
                          ,ROW_NUMBER() OVER (PARTITION BY dash_id ORDER BY y.datechange ASC) AS ff
                        FROM
              (
              SELECT
                x.Dash_ID
                ,x.status
                ,CASE WHEN x.status IN ('INSTITUTION','DISQUALIFIED', 'DISCHARGED', 'DISENROLLED', 'DECEASED', 'DECLINED') THEN 'DISCHARGED'
                      WHEN x.status IN ('ACTIVE','HOSPICE') THEN 'ACTIVE'
                      ELSE x.status END AS DischargeRollup
                ,(x.time_stamp)DateChange
                ,x.dateanchor
                ,(ROW_NUMBER() OVER (PARTITION BY x.Dash_ID, x.dateanchor ORDER BY x.time_stamp DESC))RN
                ,(ROW_NUMBER() OVER (PARTITION BY x.Dash_ID, x.dateanchor, x.STATUS = 'PASSIVE' ORDER BY x.time_stamp ASC))PASSIVECATCH --important when member created and changed status on same day
              FROM
                (  
                  SELECT 
                  (to_timestamp(r.timestamp/1000))Time_Stamp 
                  ,CAST((to_timestamp(r.timestamp/1000)) AS DATE)dateanchor 
                  ,(h.id)Dash_ID 
                  ,h.status 
                  FROM PC_FIVETRAN_DB.DASHPROD_PUBLIC.PLATFORM_PATIENTS_HIST h 
                  INNER JOIN 
                  PC_FIVETRAN_DB.DASHPROD_PUBLIC.REVISION_LOGS r ON h.rev = r.id 
                  WHERE h.status is not null AND h.TEST = FALSE AND DASH_ID != 3453 --THIS DASH HAS HISTORIC TEST = FALSE. MUST BE CHANGED IN SOURCE OR EXPLICITLY EXCLUDED
                  UNION ALL 
                  --NECESSARY FOR FIRST IMPORT PASSIVE STATUS  
                  SELECT 
                    (to_timestamp(p.created_at))Time_Stamp 
                    ,CAST(p.created_at AS DATE)dateanchor 
                    ,(p.id)Dash_ID 
                    ,('PASSIVE')status 
                  FROM PC_FIVETRAN_DB.DASHPROD_PUBLIC.PLATFORM_PATIENTS p 
                  WHERE p.status IS NOT NULL AND p.TEST = FALSE AND DASH_ID != 3453 --THIS DASH HAS HISTORIC TEST = FALSE. MUST BE CHANGED IN SOURCE OR EXPLICITLY EXCLUDED
                )x 
              )y WHERE RN = 1 OR PASSIVECATCH = 1;`;
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();              
                
    var cmd=`CREATE OR REPLACE TEMPORARY TABLE penultimate AS
                SELECT
                         PREP.dash_id
                        ,PREP.status
                        ,PREP.dischargerollup
                        ,PREP.datechange
                        ,PREP.dateanchor
                        ,ROW_NUMBER() OVER (PARTITION BY PREP.dash_id ORDER BY PREP.datechange DESC) AS rn
                      FROM
                (
                SELECT
                       a.dash_id
                      ,a.status
                      ,a.dischargerollup
                      ,a.datechange
                      ,a.dateanchor
                      ,CASE WHEN a.ff = 1 OR a.dischargerollup != b.dischargerollup THEN 1 END AS changeflag
                FROM censushist a
                LEFT JOIN
                censushist b ON a.dash_id = b.dash_id
                             AND a.ff = b.ff+1
                )PREP WHERE changeflag = 1;`;
                  
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();
                  
    /*********************
         VESTA TABLE         
    *********************/
                  
    var cmd=`INSERT INTO VESTA.VESTA_MEMBERCENSUS
                SELECT
                (p.id)dash_id
                ,(p.first_name)member_firstname
                ,(p.last_name)member_lastname
                ,(p.birth_date)member_birthdate
                ,(p.gender)member_gender
                ,(p.language)member_language
                ,(p.phone_number)member_phonenumber
                ,(p.address_1)member_address1
                ,(p.address_2)member_address2
                ,(p.city)member_city
                ,(p.state)member_state
                ,(p.zip_code)member_zipcode
                ,(p.self_directing)member_selfdirecting
                ,(p.residence_type)member_residencetype
                ,(p.residence_type_other)member_residencetypeother
                ,(p.living_arrangement)member_livingarrangement
                ,(p.living_arrangement_other)member_livingarrangementother
                ,(p.care_team_info)member_careteaminfo
                ,CASE WHEN x.member_censusstatus IS NULL THEN p.status ELSE x.member_censusstatus END AS member_censusstatus
                ,CASE WHEN x.member_statusrollup IS NULL AND p.status = 'PASSIVE' THEN 'PASSIVE' ELSE x.member_statusrollup END AS member_statusrollup
                ,CASE WHEN x.member_censusdatechange IS NULL THEN p.created_at ELSE x.member_censusdatechange END AS member_censusdatechange
                ,CASE WHEN x.member_statusstartdate IS NULL THEN CAST(p.created_at + INTERVAL '1 day' AS DATE) ELSE x.member_statusstartdate END AS member_statusstartdate
                ,CASE WHEN x.member_statusenddate IS NULL THEN '1899-12-31' ELSE x.member_statusenddate END AS member_statusenddate
                ,emp.member_empowner
                ,np.member_npowner
                ,CASE WHEN x.member_statushistory IS NULL THEN 1 ELSE x.member_statushistory END AS member_statushistory
                ,x.member_currentlyactive
                ,(p.external_id)member_externalID
                ,(p.created_at)member_createdat
                ,o.client_name
                ,o.client_abbr
                ,o.program_name
                ,o.program_abbr
                ,o.program_configid
                ,GETDATE() AS RUNTIME
                FROM PC_FIVETRAN_DB.DASHPROD_PUBLIC.PLATFORM_PATIENTS p
                LEFT JOIN
                (
                SELECT
                   (CENSUS.dash_id)dashmatches
                  ,(CENSUS.status)member_censusstatus
                  ,(CENSUS.dischargerollup)member_statusrollup
                  ,(CENSUS.datechange)member_censusdatechange
                  ,(CENSUS.status_startdate)member_statusstartdate
                  ,(CENSUS.status_enddate)member_statusenddate
                  --,(NULL)member_EmpOwner
                  ,(CENSUS.statushistory)member_statushistory
                  ,CASE WHEN statushistory = 1 AND dischargerollup = 'ACTIVE' THEN 1 END AS member_currentlyactive
                FROM
                (
                SELECT
                    a.dash_id
                    ,a.status
                    ,a.dischargerollup
                    ,a.datechange
                    ,CASE WHEN a.status NOT IN ('PASSIVE') then CAST(a.datechange + INTERVAL '1 day' AS DATE)
                                ELSE CAST(a.datechange AS DATE) END AS Status_StartDate
                    ,CASE WHEN b.datechange is null then '1899-12-31'
                                WHEN a.datechange = b.datechange THEN CAST(a.datechange + INTERVAL '1 day' AS DATE)
                                ELSE CAST(b.datechange AS DATE) END AS Status_EndDate
                    ,(a.rn)statushistory
                  FROM
                penultimate a
                LEFT JOIN
                penultimate b
                ON a.dash_id = b.dash_id AND a.rn = b.rn+1
                )CENSUS
                )x ON p.id = x.dashmatches AND p.TEST = FALSE
                LEFT JOIN
                (
                  SELECT
                      (pcm.member_id)dash_id
                      ,o.client_name
                      ,o.client_abbr
                      ,o.program_name
                      ,o.program_abbr
                      ,o.program_configid
                  FROM 
                      VESTA.V_PROGRAM_CONFIGURATION_MEMBERS pcm
                  LEFT JOIN
                      VESTA.V_VESTACLIENTS o ON pcm.program_configuration_id = o.program_configid
               )o ON o.dash_id = p.id
                LEFT JOIN
                (
                  SELECT id,CONCAT(first_name,' ',last_name)member_empowner
                  FROM PC_FIVETRAN_DB.DASHPROD_PUBLIC.EMPLOYEES e
                )emp ON p.owner_id = emp.id
                 LEFT JOIN
                (
                  SELECT id,CONCAT(first_name,' ',last_name)member_npowner
                  FROM PC_FIVETRAN_DB.DASHPROD_PUBLIC.EMPLOYEES e
                )np ON p.np_owner_id = np.id;`;
    var sql=snowflake.createStatement({sqlText: cmd});
    sql.execute();

   var cmd=`TRUNCATE VSM.CENSUS;`;
   var sql=snowflake.createStatement({sqlText: cmd});
   sql.execute();

   var cmd=`INSERT INTO VSM.CENSUS
      SELECT DISTINCT 
          dates.CALENDAR_ID,
          dates.CALENDAR_DATE,
          dates.CALENDAR_YEAR,
          dates.CALENDAR_QUARTER,
          dates.CALENDAR_MONTH,
          dates.CALENDAR_MONTHNAME,
          dates.CALENDAR_WEEK,
          dates.CALENDAR_YEARWEEK,
          dates.CALENDAR_DAY,
          dates.CALENDAR_WEEKDAY,
          dates.CALENDAR_WEEKDAYNAME,
          dates.CALENDAR_DAYOFYEAR,
          clients.CLIENT_NAME,        
          clients.CLIENT_ABBR,
          clients.PROGRAM_NAME,
          clients.PROGRAM_ABBR,
          clients.PROGRAM_CONFIGID,
          census.DASH_ID,
          census.MEMBER_FIRSTNAME,
          census.MEMBER_LASTNAME,
          census.MEMBER_BIRTHDATE,
          census.MEMBER_GENDER,
          census.MEMBER_LANGUAGE,
          census.MEMBER_PHONENUMBER,
          census.MEMBER_ADDRESS1,
          census.MEMBER_ADDRESS2,
          census.MEMBER_CITY,
          census.MEMBER_STATE,
          census.MEMBER_ZIPCODE,
          census.MEMBER_SELFDIRECTING,
          census.MEMBER_RESIDENCETYPE,
          census.MEMBER_RESIDENCETYPEOTHER,
          census.MEMBER_LIVINGARRANGEMENT,
          census.MEMBER_LIVINGARRANGEMENTOTHER,
          census.MEMBER_CARETEAMINFO,
          census.MEMBER_CENSUSSTATUS,
          census.MEMBER_STATUSROLLUP,
          census.MEMBER_CENSUSDATECHANGE,
          census.MEMBER_STATUSSTARTDATE,
          census.MEMBER_STATUSENDDATE,
          census.MEMBER_EMPOWNER,
          census.MEMBER_NPOWNER,
          census.MEMBER_STATUSHISTORY,
          census.MEMBER_CURRENTLYACTIVE,
          census.MEMBER_EXTERNALID,
          census.MEMBER_CREATEDAT,
          cg.CAREGIVER_ID,
          cg.CAREGIVER_ENABLED,
          cg.CAREGIVER_ACTIVE,
          cg.CAREGIVER_FIRSTNAME,
          cg.CAREGIVER_LASTNAME,
          cg.CAREGIVER_FIRSTNAMETHREE,
          cg.CAREGIVER_LASTNAMETHREE,
          cg.CAREGIVER_FULLNAME,
          cg.CAREGIVER_RELATIONSHIP,
          cg.CAREGIVER_PHONENUMBER,
          cg.CAREGIVER_OTHERRELATIONSHIP,
          cg.CAREGIVER_TYPE,
          cg.CAREGIVER_PREFERREDLANGUAGE,
          cg.CAREGIVER_LIVESWITH,
          cg.CAREGIVER_SERVICELEVELS,
          cg.CAREGIVER_INACTIVEREASON,
          cg.CAREGIVER_INACTIVEDTTM,
          cg.CAREGIVER_DISABLEDAT,
          cg.CAREGIVER_AGENCY,
          cg.CAREGIVER_AGENCYNAME,
          cg.CAREGIVER_OTHERAGENCY,
          cg.CAREGIVER_CREATEDAT,
          cg.CAREGIVER_CREATIONSOURCE,
          GETDATE() AS RUNTIME
      FROM
      DIM.DATES dates
      CROSS JOIN
      VESTA.V_VESTACLIENTS clients
      LEFT JOIN
      (
        SELECT 
          *,
          CASE WHEN DATE_PART(YEAR,c.member_statusenddate) = 1899 THEN CAST(GETDATE() AS DATE) ELSE c.member_statusenddate END AS FIXDATE 
        FROM VESTA.VESTA_MEMBERCENSUS c
      )census ON dates.CALENDAR_DATE BETWEEN census.member_statusstartdate AND census.FIXDATE 
              AND census.program_configid = clients.program_configid
      LEFT JOIN
      VESTA.VESTA_CAREGIVERS cg ON cg.DASHID_LINK = census.dash_id
      WHERE dates.CALENDAR_DATE >= '2018-11-01' AND dates.CALENDAR_DATE < DATEADD(day,7,CAST(GETDATE() AS DATE));`;
        
var sql=snowflake.createStatement({sqlText: cmd});
sql.execute();
return 'done';
$$