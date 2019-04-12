-- FUNCTION: hn_ranker.build_stories_last(text)

-- DROP FUNCTION hn_ranker.build_stories_last(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_last(v_run_id bigint DEFAULT NULL )
RETURNS TABLE (
  run_id bigint,
  story_id bigint,
  status hn_ranker.story_status,
  score integer,
  ts_run timestamptz,
  status_repeat integer
)
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
--Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
WITH
sel_run_story AS (
  SELECT
    run_story.run_id,
    run_story.story_id,
    run_story.status,
    run_story.score,
    max(run_story.run_id) OVER (
      PARTITION BY run_story.story_id
      ) max_run_id,
    row_number() OVER (
      PARTITION BY run_story.story_id,run_story.status
      ORDER BY run_story.story_id,run_story.run_id,run_story.status
      ) status_repeat
  FROM hn_ranker.run_story
  WHERE v_run_id IS NULL OR run_story.run_id < v_run_id
)
SELECT
    sel_run_story.run_id,
    sel_run_story.story_id,
    sel_run_story.status status,
    sel_run_story.score score,
    --payload,
    run.ts_run ts_run,
    sel_run_story.status_repeat::integer status_repeat
  FROM sel_run_story
    JOIN hn_ranker.run ON sel_run_story.run_id=run.id
  WHERE sel_run_story.run_id=max_run_id;
END;
$BODY$;

