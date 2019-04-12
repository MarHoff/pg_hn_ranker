-- FUNCTION: hn_ranker.build_stories_ranks(text)

-- DROP FUNCTION hn_ranker.build_stories_ranks(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_ranks( v_run_id bigint)
RETURNS TABLE (
  run_id bigint,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer,
  ts_run timestamptz
)
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
WITH
  current_run AS (
    SELECT * FROM hn_ranker.run WHERE id=v_run_id
  ),
  unnest_rankings AS (
  --Unesting data from current_run
    SELECT current_run.id, 'topstories' ranking, a.story_id, a.hn_rank, current_run.ts_run
    FROM current_run, unnest(topstories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT current_run.id, 'beststories' ranking, a.story_id, a.hn_rank, current_run.ts_run
    FROM current_run, unnest(beststories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT current_run.id, 'newstories' ranking, a.story_id, a.hn_rank, current_run.ts_run
    FROM current_run, unnest(newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  )
--Grouping information by unique story_id for current run
SELECT
      unnest_rankings.id run_id,
      unnest_rankings.story_id story_id,
      min(hn_rank) FILTER (WHERE ranking='topstories')::integer topstories_rank,
      min(hn_rank) FILTER (WHERE ranking='beststories')::integer beststories_rank,
      min(hn_rank) FILTER (WHERE ranking='newstories')::integer newstories_rank,
      unnest_rankings.ts_run
    FROM unnest_rankings
      GROUP BY unnest_rankings.id, unnest_rankings.ts_run, unnest_rankings.story_id
END;
$BODY$;

