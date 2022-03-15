
   var cmd=`TRUNCATE "CLAIMS_REPORTING"."PLATFORM_MEMBERS";`;
   var sql=snowflake.createStatement({sqlText: cmd});
   sql.execute();

   var cmd=`INSERT INTO "CLAIMS_REPORTING"."PLATFORM_MEMBERS"
/* create or replace table claims_reporting.platform_members as */
  select
    cast(pm.plan as varchar(25)) as plan, trim(cast(pm.external_id as varchar(50)),' ') as member_id, 
    pm.reporting_start_date, cast(pm.platform_status as varchar(50)) as platform_status, ats.ae_status,
    cast(pm.full_name as varchar(100)) as full_name, pm.last_name, pm.first_name,
    cast(pm.member_id as varchar(10)) as dash_id , pm.expected_weekly_health_reports as expected_hr, 
    pm.hr_min_date_og, pm.enrolled, pm.hr_last_4_wk, pm.avg_wk_hr, pm.engaged, 
    
    case when pm.disenroll_date_p >= pm.hr_min_date_og and pm.hr_min_date_og is not null 
         then pm.disenroll_date_p end as disenroll_date_dash, 
    atm.date_onboarded as date_onboarded_ae, atd.date_disenrolled as date_disenrolled_ae,
         
    case when pm.hr_min_date_og is null or pm.hr_min_date_og >= '2021-03-01' then atm.date_onboarded 
         else pm.hr_min_date_og end as hr_min_date, 
         
    case when disenroll_date_dash is null or disenroll_date_dash >= '2021-03-01' then atd.date_disenrolled
         else disenroll_date_dash end as disenroll_date,
    do.current_program, do.cd as prog_calendar_date,
    case when substring(plan,1,3) = 'CTL' then 'CTL'
		 when substr(plan,1,6) = 'UHC NJ' then 'UHC'
         when substr(plan,1,6) = 'UHC NE' then 'UHC_NE'
         when substr(plan,1,6) = 'UHC NY' then 'UHC_NY'
	     when substr(plan,1,3) = 'CCA' then 'CCA' end as claims_clnt,
    GETDATE() AS RUNTIME
  from
    (select
        pcm.org_abbr as plan, pp.external_id, pp.reporting_start_date, pp.status as platform_status, pp.full_name, 
        pp.last_name, pp.first_name,
        pp.member_id,  pp.expected_weekly_health_reports, date(min(pp.hr_created_at)) as hr_min_date_og,
        max(case when pp.hr_created_at > '1900-01-01' then 1 else 0 end) as enrolled,
        sum(case when current_date() - date(pp.hr_created_at) <= 28 THEN 1 ELSE 0 END) as hr_last_4_wk,
        hr_last_4_wk/4 as avg_wk_hr,
        case when hr_last_4_wk >= 4 then 1 else 0 end as engaged,
        MAX(date(case when s.dash_status = 'DISENROLLED' AND pp.status <> 'ACTIVE' 
                      then s.time_stamp end)) as disenroll_date_p

    FROM
    (SELECT
         pp.id as member_id
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

    FROM pc_fivetran_db.dashprod_public.platform_patients pp
    LEFT JOIN (
      SELECT pcm.member_id, pdr.created_At 
        FROM pc_fivetran_db.dashprod_public.platform_daily_record pdr
      INNER JOIN
        pc_fivetran_db.dashprod_public.Patient_caregivers pc ON pdr.patient_caregiver_id = pc.id
      INNER JOIN
        pc_fivetran_db.dashprod_public.Program_configuration_members pcm ON pc.program_configuration_member_id = pcm.id
              )x ON x.member_id = pp.id
        WHERE pp.test = 'false' AND pp.enabled = 'true') as pp

    LEFT JOIN    
        (select pcm.member_id as dash_id, pcm.id as pcm_id,
          pcm.program_configuration_id, pcm.effective_date as pcm_effective_date,
          pcm.discontinue_date as pcm_discontinue_date, pcm.status as pcm_status,
          pc.type, pc.updated_at, p.name as program_name, p.effective_date as program_effective_date,
          p.discontinue_date as program_discontinue_date, pco.id as pco_id, pco.role,
          o.id as org_id, o.name as org_name, o.abbr as org_abbr
         from pc_fivetran_db.dashprod_public.program_configuration_members as pcm
            left join pc_fivetran_db.dashprod_public.program_configurations as pc on pcm.program_configuration_id = pc.id
            left join pc_fivetran_db.dashprod_public.programs as p on pc.program_id = p.id
            left join pc_fivetran_db.dashprod_public.program_configuration_organizations as pco 
                on pcm.program_configuration_id = pco.program_configuration_id and pco.role = 'CLIENT'
            left join pc_fivetran_db.dashprod_public.organizations as o on o.id = pco.organization_id
                order by o.id, pco.id) as PCM on pp.member_id = pcm.dash_id

    LEFT JOIN
        (select bb.* from 
            (select ba.id, ba.rv_id, ba.status, 
                case when ba.prev_dash_id = ba.id then ba.prev_status end as status_prev, ba.time_stamp, ba.dash_status, 
                case when ba.prev_dash_id = ba.id then ba.prev_dash_status end as dash_status_prev 
             from
                (select a.id, b.id as rv_id, a.status, lag(a.status,1) OVER (order by a.id, b.id) as prev_status,
                        to_timestamp(b.timestamp/1000) as Time_Stamp,
                        case when a.status in ('PASSIVE','ACTIVE','HOSPICE') 
                             then a.status else 'DISENROLLED' end as dash_status,
                        lag (case when a.status in ('PASSIVE','ACTIVE','HOSPICE') then a.status else 'DISENROLLED' end,1) 
                            OVER (order by a.id, b.id) as prev_dash_status,
                        lag(a.id) OVER (order by a.id, b.id) as prev_dash_id
         from pc_fivetran_db.dashprod_public.platform_patients_hist as a
              inner join pc_fivetran_db.dashprod_public.revision_logs as b on a.rev = b.id
                order by rv_id desc) as ba) as bb
                  where (bb.dash_status <> bb.dash_status_prev or bb.dash_status_prev is null) 
                         and bb.dash_status = 'DISENROLLED' 
                    order by bb.id, bb.rv_id desc) as s on pp.member_id = s.id
       group by  pcm.org_abbr, pp.external_id, pp.reporting_start_date, pp.status, pp.full_name, pp.last_name, pp.first_name,
                 pp.member_id,  pp.expected_weekly_health_reports) as pm
     /* 2021-08-14 airtable onboarded date */            
     LEFT JOIN ( select distinct a.dashid, b.client_abbr, min(a.atm_airtablestatus) as status,
		                min(a.atm_statusstartdate) as date_onboarded
	             from vesta_production.vsm.AIRTABLE_MEMBERS as a
		            left join vesta_production.vsm.CENSUS as b 
                            on a.dashid = b.dash_id and a.calendar_date = b.calendar_date 
                        where substr(atm_airtablestatus,1,9) = 'Onboarded' 
		                  group by a.dashid, b.client_abbr
               ) /*vesta_development.claims_reporting.atm_onboarded_min*/ as atm 
            on pm.member_id= atm.dashid and pm.plan = atm.client_abbr
            
      left join (select distinct
		         a.dashid, b.client_abbr, a.atm_airtablestatus as status, 
		         a.atm_statusstartdate as date_disenrolled
	            from vesta_production.vsm.AIRTABLE_MEMBERS as a
		            left join vesta_production.vsm.CENSUS as b 
                            on a.dashid = b.dash_id and a.calendar_date = b.calendar_date 
                        where a.atm_airtablestatus in ('Onboarded - Deceased','Onboarded - Discharged',
												       'Onboarded - Disenrolled','Onboarded - Institution')
				              and atm_airtablestatushistory = 1) as atd
             on pm.member_id= atd.dashid and pm.plan = atd.client_abbr
             
      left join (select distinct a.dashid, b.client_abbr, a.atm_airtablestatus as ae_status
                 from vesta_production.vsm.AIRTABLE_MEMBERS as a
		            left join vesta_production.vsm.CENSUS as b 
                            on a.dashid = b.dash_id and a.calendar_date = b.calendar_date 
                        where  atm_airtablestatushistory = 1) as ats      
              on pm.member_id= ats.dashid and pm.plan = ats.client_abbr
              
      left join  (select dash_id, client_abbr, max(calendar_date) as cd, 
                    row_number() over(partition by dash_id order by max(calendar_date) desc) as current_program
                  from vesta_production.vsm.CENSUS
		              group by dash_id, client_abbr) as do 
                            on pm.member_id = do.dash_id and pm.plan = do.client_abbr
                 where do.current_program = 1 and pm.last_name <> 'Duplicate' and
                            trim(cast(pm.external_id as varchar(50)),' ') <> '' and pm.member_id <> 24560
                 order by hr_min_date desc;
 `;
 
   var sql=snowflake.createStatement({sqlText: cmd});
   sql.execute();
   
return 'done';
