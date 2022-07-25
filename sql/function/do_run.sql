-- FUNCTION: hn_ranker.do_run(text)

-- DROP FUNCTION hn_ranker.do_run(text);

CREATE OR REPLACE FUNCTION hn_ranker.do_run(
	hnr_config text DEFAULT 'production_default'::text)
RETURNS timestamptz
LANGUAGE 'plpgsql'

AS $BODY$
DECLARE
  ts_run timestamptz := clock_timestamp() ;
BEGIN

WITH
get_rankings AS (SELECT * FROM hn_ranker.wget_rankings('{topstories,beststories,newstories}')),
insert_run AS (
INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	ts_end,
  extversion,
  ruleset_id)
SELECT
  ts_run,
  max(payload) FILTER (WHERE id ='topstories') as topstories,
  max(payload) FILTER (WHERE id ='beststories') as beststories,
  max(payload) FILTER (WHERE id ='newstories') as newstories,
  max(ts_end) as ts_end,
  ( SELECT extversion FROM pg_catalog.pg_extension WHERE extname = 'pg_hn_ranker') AS extversion,
  hnr_config AS ruleset_id
  FROM get_rankings
RETURNING *)
INSERT INTO hn_ranker.error(
ts_run, object, object_id, report)
SELECT insert_run.ts_run ts_run, 'run' as object, get_rankings.id::text object_id, row_to_json(get_rankings)::jsonb
FROM insert_run, get_rankings
WHERE get_rankings.payload IS NULL OR NOT(get_rankings.retries = 0);

RETURN ts_run;

END
$BODY$;

