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
  current_run_story AS (SELECT * FROM hn_ranker.build_stories_ranks(currval('hn_ranker.run_id_seq'::regclass))),
  last_run_story AS (
  --Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
    SELECT
      run_id,
      story_id,
      topstories_rank,
      beststories_rank,
      newstories_rank,
      status,
      --payload,
      ts_payload,
      run.ts_run,
      status_repeat
    FROM (
      SELECT
        *,
        max(run_id) OVER (PARTITION BY story_id) max_run_id,
        row_number() OVER (PARTITION BY story_id,status ORDER BY story_id,run_id,status ) status_repeat
      FROM hn_ranker.run_story
      ) run_story
      JOIN hn_ranker.run ON run_id=run.id
      WHERE run_id=max_run_id
   ),
  classify_run_story AS (
  --Joining currents ranking vs last run and classifying candidates for fetching additional data
    SELECT
    currval('hn_ranker.run_id_seq'::regclass) run_id,
    COALESCE(current_run_story.story_id,last_run_story.story_id) story_id,
    current_run_story.topstories_rank,
    current_run_story.beststories_rank,
    current_run_story.newstories_rank,
    CASE
      WHEN
        last_run_story.status IS NULL OR
        last_run_story.status='new' AND last_run_story.status_repeat < (param ->> 'new_repeat')::bigint
        THEN 'new'
      WHEN
        last_run_story.status='new' OR
        last_run_story.topstories_rank <= (param ->> 'hot_rank')::bigint OR
        last_run_story.beststories_rank <= (param ->> 'hot_rank')::bigint OR
        (last_run_story.topstories_rank - current_run_story.topstories_rank) > (param ->> 'hot_rankbump')::bigint OR
        (last_run_story.beststories_rank - current_run_story.beststories_rank) > (param ->> 'hot_rankbump')::bigint OR
        (last_run_story.status='hot' AND last_run_story.status_repeat < (param ->> 'hot_repeat')::bigint)
        THEN 'hot'
      WHEN
        last_run_story.topstories_rank <= (param ->> 'tepid_rank')::bigint OR
        last_run_story.beststories_rank <= (param ->> 'tepid_rank')::bigint OR
        last_run_story.newstories_rank <= (param ->> 'tepid_rank')::bigint
        THEN 'tepid'
      WHEN
        last_run_story.status < 'cooling' OR
        (last_run_story.status='cooling' AND last_run_story.status_repeat < (param ->> 'cooling_repeat')::bigint)
        THEN 'cooling'
      WHEN
        last_run_story.status < 'cold' OR
        (last_run_story.status='cold' AND last_run_story.status_repeat < (param ->> 'cold_repeat')::bigint) OR
        last_run_story.status='missing'
        THEN 'cold'                                                     
      ELSE 'frozen'
    END::hn_ranker.story_status status,
    current_run_story.ts_run-last_run_story.ts_run as last_run_story_age
    --,last_run_story.payload as last_run_story_payload                                                           
  FROM current_run_story FULL JOIN last_run_story ON current_run_story.story_id=last_run_story.story_id 
  ),
  filter_run_story AS (
    SELECT *
    FROM classify_run_story
    WHERE
      status <= 'hot' OR
      (status = 'tepid' AND last_run_story_age >= (param ->> 'tepid_age')::interval) OR --'59 min'::interval) OR
      (status = 'cooling' AND last_run_story_age >= (param ->> 'cooling_age')::interval) OR --'1 days'::interval) OR
      (status = 'cold' AND last_run_story_age >= (param ->> 'cold_age')::interval) OR --'7 days'::interval) OR
      (status = 'frozen' AND last_run_story_age >= (param ->> 'frozen_age')::interval) --'1 month'::interval)
  ),
  get_items AS (SELECT * FROM hn_ranker.items((SELECT array_agg(story_id) FROM filter_run_story))),

  insert_run_story AS (
    INSERT INTO hn_ranker.run_story(
      run_id,
      story_id,
      topstories_rank,
      beststories_rank,
      newstories_rank,
      status,
      score,
      descendants,
      ts_payload
      )
    SELECT 
    filter_run_story.run_id,
    filter_run_story.story_id,
    filter_run_story.topstories_rank,
    filter_run_story.beststories_rank,
    filter_run_story.newstories_rank,
    CASE
      WHEN (get_items.payload ->> 'deleted') = 'true' THEN 'deleted'
      WHEN get_items.payload = '"json_null"' THEN 'missing'
      WHEN get_items.payload IS NULL THEN 'failed'
      ELSE filter_run_story.status END::hn_ranker.story_status status,
    (get_items.payload ->> 'score')::integer score,
    (get_items.payload ->> 'descendants')::integer descendants,
    /*CASE
    WHEN items.payload IS NULL THEN NULL
    WHEN items.payload - '{"descendants","score"}'::text[] = filter_run_story.last_run_story_payload THEN NULL
    ELSE items.payload - '{"descendants","score"}'::text[] 
    END::jsonb*/
    get_items.ts_end ts_payload
    FROM filter_run_story LEFT JOIN get_items
    ON filter_run_story.story_id=get_items.id
    RETURNING *
    )
INSERT INTO hn_ranker.error(run_id, object, object_id, report)
SELECT
run_id, 'run_story' as object, story_id::text object_id, row_to_json(get_items)::jsonb
FROM insert_run_story LEFT JOIN get_items ON story_id=get_items.id
WHERE insert_run_story.status >= 'deleted' OR NOT(get_items.retries = 0);
END;
$BODY$;

