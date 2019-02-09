-- PROCEDURE: hn_ranker.do_run(text)

-- DROP PROCEDURE hn_ranker.do_run(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_run(
	hnr_config text DEFAULT 'default'::text)
LANGUAGE 'sql'

AS $BODY$
WITH
get_rankings AS (SELECT * FROM hn_ranker.rankings('{topstories,beststories,newstories}')),
insert_run AS (
INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	ts_end)
SELECT
  now() ts_run,
  max(payload) FILTER (WHERE id ='topstories') as topstories,
  max(payload) FILTER (WHERE id ='beststories') as beststories,
  max(payload) FILTER (WHERE id ='newstories') as newstories,
  max(ts_end) as ts_end
  FROM get_rankings
RETURNING *)
INSERT INTO hn_ranker.error(
run_id, object, object_id, report)
SELECT insert_run.id run_id, 'run' as object, get_rankings.id::text object_id, row_to_json(get_rankings)::jsonb
FROM insert_run, get_rankings
WHERE get_rankings.payload IS NULL OR NOT(get_rankings.retries = 0);
$BODY$;

