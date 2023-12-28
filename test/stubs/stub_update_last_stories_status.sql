WITH selected_run AS (
    SELECT * FROM hn_ranker.run WHERE id = (SELECT last_value FROM hn_ranker.run_id_seq)
  ),
  unnest_rankings AS (
  --Unesting data from selected_run
    SELECT selected_run.id, 'topstories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.topstories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.id, 'beststories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.beststories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.id, 'newstories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  ),
--Grouping information by unique story_id for current run
live AS (
	SELECT unnest_rankings.story_id story_id
	FROM unnest_rankings
	GROUP BY unnest_rankings.id, unnest_rankings.story_id),
live_max AS (
  SELECT run_story.*, live.story_id IS NOT NULL keepers,
    max(run_story.run_id) OVER (
      PARTITION BY run_story.story_id
      ) max_run_id
  FROM hn_ranker.run_story LEFT JOIN live ON run_story.story_id=live.story_id
),
notkeepers AS (SELECt run_id, story_id FROM live_max WHERE run_id=max_run_id AND NOT keepers
ORDER BY run_id desc)

UPDATE hn_ranker.run_story
SET status='unknown'
FROM notkeepers
WHERE run_story.run_id=notkeepers.run_id AND run_story.story_id=notkeepers.story_id

