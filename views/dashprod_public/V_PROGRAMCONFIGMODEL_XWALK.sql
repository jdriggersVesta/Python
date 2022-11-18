-- noinspection SqlResolve
create or replace view PC_FIVETRAN_DB.DASHPROD_PUBLIC.V_PROGRAMCONFIGMODEL_XWALK(
	DASH_ID,
	PCM_ID,
	PROGRAM_CONFIGURATION_MEMBER_ID_XWALK,
	PCM_ID_XWALK
) as
--1+1
select pcm.member_id as dash_id, pcm.id as pcm_id,
CASE 
WHEN pcm.id IS NULL THEN 'Unk' ELSE CAST(pcm.id AS varchar) END || '-' || 
CASE
WHEN pcm.member_id IS NULL THEN 'Unk' ELSE CAST(pcm.member_id AS varchar) END
AS program_configuration_member_id_xwalk,
CASE 
WHEN pcm.id IS NULL THEN 'Unk' ELSE CAST(pcm.id AS varchar) END || '-' || 
CASE
WHEN pcm.member_id IS NULL THEN 'Unk' ELSE CAST(pcm.member_id AS varchar) END
AS pcm_id_xwalk
from "VESTA_PRODUCTION"."VESTA"."V_PROGRAM_CONFIGURATION_MEMBERS" as pcm
--0+1
UNION
select pcm.member_id as dash_id, pcm.id as pcm_id,
'Unk-' || 
CASE
WHEN pcm.member_id IS NULL THEN 'Unk' ELSE CAST(pcm.member_id AS varchar) END
AS program_configuration_member_id_xwalk,
'Unk-' || 
CASE
WHEN pcm.member_id IS NULL THEN 'Unk' ELSE CAST(pcm.member_id AS varchar) END
AS pcm_id_xwalk
from "VESTA_PRODUCTION"."VESTA"."V_PROGRAM_CONFIGURATION_MEMBERS" as pcm
--1+0
UNION 
select pcm.member_id as dash_id, pcm.id as pcm_id,
CASE 
WHEN pcm.id IS NULL THEN 'Unk' ELSE CAST(pcm.id AS varchar) END || '-Unk'
AS program_configuration_member_id_xwalk,
CASE 
WHEN pcm.id IS NULL THEN 'Unk' ELSE CAST(pcm.id AS varchar) END || '-Unk'
AS pcm_id_xwalk
from "VESTA_PRODUCTION"."VESTA"."V_PROGRAM_CONFIGURATION_MEMBERS" as pcm
UNION 
select id as dash_id, null as pcm_id, 
'Unk-' || CAST(id AS varchar) AS program_configuration_member_id_xwalk,
'Unk-' || CAST(id AS varchar) AS pcm_id_xwalk
from "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PLATFORM_PATIENTS";