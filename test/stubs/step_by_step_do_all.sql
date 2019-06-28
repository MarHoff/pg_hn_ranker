--BEGIN;
--CALL hn_ranker.do_run('debug');
--SELECT * FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq'::regclass)::bigint
--SELECT * FROM hn_ranker.build_stories_ranks(ARRAY[currval('hn_ranker.run_id_seq'::regclass)::bigint])
--SELECT * FROM hn_ranker.build_stories_last(currval('hn_ranker.run_id_seq'::regclass));
SELECT fetch_now, last_status, new_status, count(*) FROM hn_ranker.build_stories_classify(currval('hn_ranker.run_id_seq'::regclass),'debug')
GROUP BY fetch_now, last_status, new_status
ORDER BY fetch_now, last_status, new_status
;
--ROLLBACK;