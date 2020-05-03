BEGIN;
CALL hn_ranker.do_all('production');
/*
SELECT * FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq'::regclass)::bigint

SELECT * FROM hn_ranker.build_stories_ranks(ARRAY[currval('hn_ranker.run_id_seq'::regclass)::bigint])

SELECT * FROM hn_ranker.build_stories_status(currval('hn_ranker.run_id_seq'::regclass)-1);

SELECT fetch_now, (topstories_rank IS NULL AND beststories_rank IS NULL AND newstories_rank IS NULL) allranksnull,
last_status, new_status, count(*)
FROM hn_ranker.build_stories_classify(currval('hn_ranker.run_id_seq'::regclass),'production')
GROUP BY fetch_now, (topstories_rank IS NULL AND beststories_rank IS NULL AND newstories_rank IS NULL), last_status, new_status
ORDER BY fetch_now, (topstories_rank IS NULL AND beststories_rank IS NULL AND newstories_rank IS NULL), last_status, new_status;
SELECT * FROM  hn_ranker.build_stories_classify(currval('hn_ranker.run_id_seq'::regclass),'production') LIMIT 10;

*/

--ROLLBACK;