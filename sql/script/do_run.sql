/*
INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	max_id)
	SELECT
	now() ts_run,
	hn_ranker.rankings('topstories') topstories,
	hn_ranker.rankings('beststories') beststories,
	hn_ranker.rankings('newstories') newstories,
	hn_ranker.max_id() max_id
;
*/
SELECT run_id, story_id, row_number() OVER () as topstories_rank
FROM (
  SELECT id run_id, unnest(topstories) story_id
  FROM hn_ranker.run
  WHERE id=currval('hn_ranker.run_id_seq'::regclass)
) foo