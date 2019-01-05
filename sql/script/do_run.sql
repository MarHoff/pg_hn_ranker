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
      (status = 'tepid' AND last_run_story_age >= '5 second'::interval) OR --'59 min'::interval) OR
      (status = 'cooling' AND last_run_story_age >= '10 second'::interval) OR --'1 days'::interval) OR
      (status = 'cold' AND last_run_story_age >= '15 seconds'::interval) OR --'7 days'::interval) OR
      (status = 'frozen' AND last_run_story_age >= '30 seconds'::interval) --'1 month'::interval)    
  )
  
  
--SELECT * FROM classify_run_story ORDER BY newstories_rank
INSERT INTO hn_ranker.run_story(
  run_id,
  story_id,
  topstories_rank,
  beststories_rank,
  newstories_rank,
  status
  )
  SELECT
  run_id,
  story_id,
  topstories_rank,
  beststories_rank,
  newstories_rank,
  status
  FROM filter_run_story;

SELECT * FROM hn_ranker.run_story WHERE run_id=(SELECT last_value FROM hn_ranker.run_id_seq) ORDER BY status ,topstories_rank,beststories_rank,newstories_rank;
  
                                                              
                                                              
/*INSERT INTO hn_ranker.story(id, status)
  WITH
    current_run AS (SELECT * FROM hn_ranker.run_story WHERE run_id=currval('hn_ranker.run_id_seq'::regclass))
  SELECT
    COALESCE(story.id, current_run.story_id) as id,
    CASE
      WHEN story.id IS NULL THEN 'new'
      WHEN current_run.topstories_rank <= 200 OR current_run.newstories_rank <= 500 OR current_run.beststories_rank <= 0 THEN 'hot'
      WHEN current_run.topstories_rank <= 500 OR current_run.newstories_rank <= 500 OR current_run.beststories_rank <= 50 THEN 'tepid'
      WHEN current_run.topstories_rank IS NOT NULL OR current_run.newstories_rank IS NOT NULL OR current_run.beststories_rank IS NOT NULL THEN 'cold'
      ELSE 'frozen'
    END::hn_ranker.story_status as status
  FROM hn_ranker.story FULL OUTER JOIN current_run
    ON current_run.story_id=story.id
ON CONFLICT (id)
  DO UPDATE SET status=EXCLUDED.status
;

SELECT status, count(*) FROM hn_ranker.story
GROUP BY status
ORDER BY status;*/