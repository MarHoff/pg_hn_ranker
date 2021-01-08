-- FUNCTION: hn_ranker.build_stories_status(text)

-- DROP FUNCTION hn_ranker.build_stories_status(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_status(v_ts_run timestamptz DEFAULT NULL )
RETURNS TABLE (
  ts_run timestamptz,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer,
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
    run_story.ts_run,
    run_story.story_id,
    run_story.status,
    run_story.score,
    max(run_story.ts_run) OVER (
      PARTITION BY run_story.story_id
      ) max_ts_run,
    row_number() OVER (
      PARTITION BY run_story.story_id,run_story.status
      ORDER BY run_story.story_id,run_story.ts_run,run_story.status
      ) status_repeat
  FROM hn_ranker.run_story
  WHERE v_ts_run IS NULL OR run_story.ts_run <= v_ts_run
)
SELECT
    sel_run_story.ts_run,
    sel_run_story.story_id,
    array_position(run.topstories, sel_run_story.story_id) topstories_rank,
    array_position(run.beststories, sel_run_story.story_id) beststories_rank,
    array_position(run.newstories, sel_run_story.story_id) newstories_rank,
    sel_run_story.status status,
    sel_run_story.score score,
    --payload,
    run.ts_run ts_run,
    sel_run_story.status_repeat::integer status_repeat
  FROM sel_run_story
    JOIN hn_ranker.run ON sel_run_story.ts_run=run.ts_run
  WHERE sel_run_story.ts_run=max_ts_run;
END;
$BODY$;

