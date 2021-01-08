-- PROCEDURE: hn_ranker.do_run_story(text)

-- DROP PROCEDURE hn_ranker.do_run_story(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_run_story(
	hnr_ruleset text DEFAULT 'production'::text)
LANGUAGE 'plpgsql'

AS $BODY$
DECLARE
param jsonb;
BEGIN
RAISE NOTICE 'hnr_ruleset: %', hnr_ruleset;
SELECT val INTO STRICT param FROM hn_ranker.rule WHERE ruleset_id=hnr_ruleset;
RAISE NOTICE 'param: %', param;

WITH
  classify_fetch_now AS (SELECT * FROM  hn_ranker.build_stories_classify(now()::timestamptz, hnr_ruleset) WHERE fetch_now),
  get_items AS (SELECT * FROM hn_ranker.wget_items((SELECT array_agg(story_id) FROM classify_fetch_now))),
  insert_run_story AS (
    INSERT INTO hn_ranker.run_story(
      ts_run,
      story_id,
      status,
      score,
      descendants,
      ts_payload
      )
    SELECT 
    classify_fetch_now.ts_run,
    classify_fetch_now.story_id,
    CASE
      WHEN (get_items.payload ->> 'deleted') = 'true' THEN 'deleted'
      WHEN get_items.payload = '"json_null"' THEN 'missing'
      WHEN get_items.payload IS NULL THEN 'failed'
      ELSE classify_fetch_now.new_status END::hn_ranker.story_status status,
    (get_items.payload ->> 'score')::integer score,
    (get_items.payload ->> 'descendants')::integer descendants,
    /*CASE
    WHEN items.payload IS NULL THEN NULL
    WHEN items.payload - '{"descendants","score"}'::text[] = classify_fetch_now.last_payload THEN NULL
    ELSE items.payload - '{"descendants","score"}'::text[] 
    END::jsonb*/
    get_items.ts_end ts_payload
    FROM classify_fetch_now LEFT JOIN get_items
    ON classify_fetch_now.story_id=get_items.id
    RETURNING *
    )
INSERT INTO hn_ranker.error(ts_run, object, object_id, report)
SELECT
ts_run, 'run_story' as object, story_id::text object_id, row_to_json(get_items)::jsonb
FROM insert_run_story LEFT JOIN get_items ON story_id=get_items.id
WHERE insert_run_story.status >= 'deleted' OR NOT(get_items.retries = 0);
END;
$BODY$;

