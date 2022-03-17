CREATE OR REPLACE VIEW VESTA_PRODUCTION.VESTA.V_PROGRAMCONFIGMODEL
AS
select pcm.member_id as dash_id, pcm.id as pcm_id,
      pcm.program_configuration_id, pcm.effective_date as pcm_effective_date,
      pcm.discontinue_date as pcm_discontinue_date, pcm.status as pcm_status,
      pc.type, pc.updated_at, p.name as program_name, p.effective_date as program_effective_date,
      p.discontinue_date as program_discontinue_date, pco.id as pco_id, pco.role,
      o.id as org_id, o.name as org_name, o.abbr as org_abbr
from "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_MEMBERS" as pcm
   left join "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATIONS" as pc on pcm.program_configuration_id = pc.id
   left join "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAMS" as p on pc.program_id = p.id
   left join "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_ORGANIZATIONS" as pco on pcm.program_configuration_id = pco.program_configuration_id and pco.role = 'CLIENT'
   left join "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."ORGANIZATIONS" as o on o.id = pco.organization_id
        --order by o.id, pco.id;