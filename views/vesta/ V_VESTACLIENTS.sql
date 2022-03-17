CREATE OR REPLACE VIEW V_VESTACLIENTS
AS
(
 SELECT DISTINCT 
    pco.ORGANIZATION_ID AS CLIENT_ID,
    o.NAME AS CLIENT_NAME,
    o.ABBR AS CLIENT_ABBR,
    pcm.PROGRAM_CONFIGURATION_ID AS program_configid,
    --TYPE,
    p.NAME AS PROGRAM_NAME,
    p.ABBR AS PROGRAM_ABBR
    FROM 
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_MEMBERS" pcm
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATION_ORGANIZATIONS" pco ON pcm.program_configuration_id = pco.program_configuration_id 
                                                AND pco.role = 'CLIENT'
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAM_CONFIGURATIONS" pc ON pc.id = pcm.program_configuration_id
    LEFT JOIN
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."ORGANIZATIONS" o ON o.id = pco.organization_id
    LEFT JOIN 
        "PC_FIVETRAN_DB"."DASHPROD_PUBLIC"."PROGRAMS" p ON p.ID = pc.program_id
        WHERE pcm.status = 'ACTIVE' 
);