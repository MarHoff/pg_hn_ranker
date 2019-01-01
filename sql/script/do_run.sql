INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	max_id
  )
	SELECT
  	now() ts_run,
  	hn_ranker.rankings('topstories') topstories,
  	hn_ranker.rankings('beststories') beststories,
  	hn_ranker.rankings('newstories') newstories,
  	hn_ranker.max_id() max_id
;

INSERT INTO hn_ranker.run_story(
	run_id,
  story_id,
  topstories_rank,
  beststories_rank,
  newstories_rank
  )
  WITH
    last_run AS (SELECT * FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq'::regclass)),
    unnest_rankings AS (
      SELECT id, 'topstories' ranking, story_id, hn_rank
      FROM last_run, unnest(topstories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
      SELECT id, 'beststories' ranking, story_id, hn_rank
      FROM last_run, unnest(beststories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
      SELECT id, 'newstories' ranking, story_id, hn_rank
      FROM last_run, unnest(newstories) WITH ORDINALITY AS a(story_id, hn_rank)
    )
  SELECT
    id run_id,
    story_id,
    min(hn_rank) FILTER (WHERE ranking='topstories') topstories_rank,
    min(hn_rank) FILTER (WHERE ranking='beststories') beststories_rank,
    min(hn_rank) FILTER (WHERE ranking='newstories') newstories_rank
  FROM unnest_rankings
    GROUP BY run_id, story_id
    ORDER BY topstories_rank, newstories_rank, beststories_rank
;

INSERT INTO hn_ranker.story(id, status)
  WITH
    last_run AS (SELECT * FROM hn_ranker.run_story WHERE run_id=currval('hn_ranker.run_id_seq'::regclass))
  SELECT
    COALESCE(story.id, last_run.story_id) as id,
    CASE
      WHEN story.id IS NULL THEN 'new'
      WHEN last_run.topstories_rank <= 200 OR last_run.newstories_rank <= 500 OR last_run.beststories_rank <= 0 THEN 'hot'
      WHEN last_run.topstories_rank <= 500 OR last_run.newstories_rank <= 500 OR last_run.beststories_rank <= 50 THEN 'tepid'
      WHEN last_run.topstories_rank IS NOT NULL OR last_run.newstories_rank IS NOT NULL OR last_run.beststories_rank IS NOT NULL THEN 'cold'
      ELSE 'frozen'
    END::hn_ranker.story_status as status
  FROM hn_ranker.story FULL OUTER JOIN last_run
    ON last_run.story_id=story.id
ON CONFLICT (id)
  DO UPDATE SET status=EXCLUDED.status
;

SELECT status, count(*) FROM hn_ranker.story
GROUP BY status
ORDER BY status;