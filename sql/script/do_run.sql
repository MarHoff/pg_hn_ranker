INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	ts_end,
  failed
  )
SELECT
  now() ts_run,
  max(ids) FILTER (WHERE ranking ='topstories') as topstories,
  max(ids) FILTER (WHERE ranking ='beststories') as beststories,
  max(ids) FILTER (WHERE ranking ='newstories') as newstories,
  max(ts_end) as ts_end,
  jsonb_object_agg(ranking,row_to_json(rankings.*)) FILTER (WHERE ids IS NULL) AS failed
  FROM hn_ranker.rankings('{topstories,beststories,newstories}')
;

WITH
  current_run AS (
    SELECT * FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq'::regclass)
  ),
  unnest_rankings AS (
    SELECT id, 'topstories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(topstories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT id, 'beststories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(beststories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT id, 'newstories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  ),
  from_run_story AS (
    SELECT
      id run_id,
      story_id,
      min(hn_rank) FILTER (WHERE ranking='topstories') topstories_rank,
      min(hn_rank) FILTER (WHERE ranking='beststories') beststories_rank,
      min(hn_rank) FILTER (WHERE ranking='newstories') newstories_rank,
      ts_run
    FROM unnest_rankings
      GROUP BY run_id, ts_run, story_id
      ORDER BY topstories_rank, newstories_rank, beststories_rank),
  last_run_story AS (
    SELECT
      run_id,
      story_id,
      topstories_rank,
      beststories_rank,
      newstories_rank,
      status,
      payload,
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
    SELECT
    currval('hn_ranker.run_id_seq'::regclass) run_id,
    COALESCE(from_run_story.story_id,last_run_story.story_id) story_id,
    from_run_story.topstories_rank,
    from_run_story.beststories_rank,
    from_run_story.newstories_rank,
    CASE
      WHEN
        last_run_story.status IS NULL OR
        last_run_story.status='new' AND last_run_story.status_repeat < 2
      THEN 'new'
      WHEN
        last_run_story.topstories_rank <= 2 OR
        last_run_story.beststories_rank <= 2 OR
        last_run_story.status='new' OR
        (last_run_story.status='hot' AND last_run_story.status_repeat < 2)
      THEN 'hot'
      WHEN last_run_story.topstories_rank <= 4 OR
      last_run_story.beststories_rank <= 4 OR
      last_run_story.newstories_rank <= 4
      THEN 'tepid'
      WHEN
          last_run_story.status < 'cooling' OR (last_run_story.status='cooling' AND last_run_story.status_repeat < 2)
      THEN 'cooling'
      WHEN
          last_run_story.status < 'cold' OR (last_run_story.status='cold' AND last_run_story.status_repeat < 2)
      THEN 'cold'                                                     
      ELSE 'frozen'
    END::hn_ranker.story_status status,
    from_run_story.ts_run-last_run_story.ts_run as last_run_story_age,
    last_run_story.payload as last_run_story_payload                                                           
  FROM from_run_story FULL JOIN last_run_story ON from_run_story.story_id=last_run_story.story_id 
  ),
  filter_run_story AS (
    SELECT *
    FROM classify_run_story
    WHERE
      status <= 'hot' OR
      (status = 'tepid' AND last_run_story_age >= '15 second'::interval) OR --'59 min'::interval) OR
      (status = 'cooling' AND last_run_story_age >= '30 second'::interval) OR --'1 days'::interval) OR
      (status = 'cold' AND last_run_story_age >= '60 seconds'::interval) OR --'7 days'::interval) OR
      (status = 'frozen' AND last_run_story_age >= '180 seconds'::interval) --'1 month'::interval)
  ),
  wget_run_story AS (
  SELECT 
  filter_run_story.run_id,
  filter_run_story.story_id,
  filter_run_story.topstories_rank,
  filter_run_story.beststories_rank,
  filter_run_story.newstories_rank,
  filter_run_story.status,
  (items.payload ->> 'score')::integer score,
  (items.payload ->> 'descendants')::integer descendants,
  /*CASE
  WHEN items.payload IS NULL THEN NULL
  WHEN items.payload - '{"descendants","score"}'::text[] = filter_run_story.last_run_story_payload THEN NULL
  ELSE items.payload - '{"descendants","score"}'::text[] 
  END::jsonb*/
  items.payload payload,
  items.ts_end ts_payload
  FROM filter_run_story LEFT JOIN hn_ranker.items((SELECT array_agg(story_id) FROM filter_run_story))
  ON filter_run_story.story_id=items.id
  )
  
  
--SELECT * FROM classify_run_story ORDER BY newstories_rank
INSERT INTO hn_ranker.run_story(
  run_id,
  story_id,
  topstories_rank,
  beststories_rank,
  newstories_rank,
  status,
  score,
  descendants,
  payload,
  ts_payload
)
  SELECT
  run_id,
  story_id,
  topstories_rank,
  beststories_rank,
  newstories_rank,
  status,
  score,
  descendants,
  payload,
  ts_payload
  FROM wget_run_story;

SELECT * FROM hn_ranker.run_story WHERE run_id=(SELECT last_value FROM hn_ranker.run_id_seq) ORDER BY status ,topstories_rank,beststories_rank,newstories_rank;
