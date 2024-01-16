CREATE OR REPLACE FUNCTION public.pgtrigger_update_current_stage_id_faa80()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
                
                BEGIN
                    
            IF (_pgtrigger_should_ignore(TG_TABLE_NAME, TG_NAME) IS TRUE) THEN
                IF (TG_OP = 'DELETE') THEN
                    RETURN OLD;
                ELSE
                    RETURN NEW;
                END IF;
            END IF;
        
                    
UPDATE fdm_case SET
  extra_fields = y.extra_fields,
  calculated_groups = y.calculated_groups::jsonb
FROM (
  SELECT
    c.id AS id,
    CASE WHEN c.extra_fields IS NULL THEN
      ('{"current_stage_id": "' || x.stage_id || '", "current_stage_name": "' || x.stage_name || '"}')::jsonb
    ELSE
      c.extra_fields || ('{"current_stage_id": "' || x.stage_id || '", "current_stage_name": "' || x.stage_name || '"}')::jsonb
    END AS extra_fields,
    array_to_json(allowed_groups) AS calculated_groups,
    position
  FROM fdm_case c
  INNER JOIN (
    SELECT
      case_id,
      stage_id,
      stage_name,
      array(
        SELECT unnest(stage_allowed_groups)
        INTERSECT
        SELECT unnest(pt_allowed_groups)
      ) AS allowed_groups,
      position
    FROM (
      SELECT
        NEW.id AS case_id,
        s.id AS stage_id,
        cs.name AS stage_name,
        ARRAY_AGG(sp.group_id) AS stage_allowed_groups,
        ARRAY_AGG(pp.group_id) AS pt_allowed_groups,
        cs.position AS position
      FROM fdm_stage s
      INNER JOIN fdm_casestage cs ON cs.id = s.case_stage_id
      INNER JOIN fdm_processtype p on s.process_type_id = p.id
      INNER JOIN fdm_processtype_authorized_groups pp on pp.processtype_id = p.id
      INNER JOIN fdm_stage_authorized_groups sp on sp.stage_id = s.id
    WHERE
      ARRAY[s.process_type_id] <@ (
        SELECT ARRAY_AGG(e.process_type_id) process_type_ids
        FROM fdm_case c
        INNER JOIN fdm_alert a on a.case_id=c.id
        INNER JOIN fdm_event e on e.id=a.event_ptr_id
        WHERE c.id=NEW.id
      )
      AND cs.position >= NEW.current_stage
      GROUP BY case_id, s.id, cs.name, cs.position
      ORDER by cs.position
      LIMIT 1
    ) z
  ) AS x ON x.case_id = c.id
) AS y
WHERE fdm_case.id = y.id;
RETURN NULL;

                END;
            $function$
;
