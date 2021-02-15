-- FUNCTION: hn_ranker.build_stories_ranks(text)

-- DROP FUNCTION hn_ranker.build_stories_ranks(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_ranks( v_ts_run timestamptz[] DEFAULT NULL )
RETURNS TABLE (
  ts_run timestamptz,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer
)
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
WITH
  selected_run AS (
    SELECT * FROM hn_ranker.run WHERE v_ts_run IS NULL OR run.ts_run = ANY(v_ts_run)
  ),
  unnest_rankings AS (
  --Unesting data from selected_run
    SELECT selected_run.ts_run, 'topstories' ranking, a.story_id, a.hn_rank
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.topstories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.ts_run, 'beststories' ranking, a.story_id, a.hn_rank
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.beststories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.ts_run, 'newstories' ranking, a.story_id, a.hn_rank
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  )
--Grouping information by unique story_id for current run
SELECT
      unnest_rankings.ts_run ts_run,
      unnest_rankings.story_id story_id,
      min(hn_rank) FILTER (WHERE ranking='topstories')::integer topstories_rank,
      min(hn_rank) FILTER (WHERE ranking='beststories')::integer beststories_rank,
      min(hn_rank) FILTER (WHERE ranking='newstories')::integer newstories_rank
    FROM unnest_rankings
      GROUP BY unnest_rankings.ts_run, unnest_rankings.story_id;
END;
$BODY$;

