--TODO Check that array conversion keep order
BEGIN;
SELECT plan(2);

SELECT pg_sleep(1);

SELECT hn_ranker.do_run() ts INTO test_run;

PREPARE revert_build_stories_ranks(timestamptz) AS 
SELECT
array_agg(story_id ORDER BY topstories_rank) FILTER (WHERE topstories_rank IS NOT NULL) topstories,
array_agg(story_id ORDER BY beststories_rank) FILTER (WHERE beststories_rank IS NOT NULL) beststories,
array_agg(story_id ORDER BY newstories_rank) FILTER (WHERE newstories_rank IS NOT NULL) newstories
FROM hn_ranker.build_stories_ranks(ARRAY[$1]);

PREPARE run_ranks(timestamptz) AS 
SELECT topstories, beststories, newstories FROM hn_ranker.run WHERE ts_run=$1;

SELECT results_eq(
    format($$EXECUTE revert_build_stories_ranks('%1$s'::timestamptz);$$,(SELECT ts FROM test_run)),
    format($$EXECUTE run_ranks('%1$s'::timestamptz);$$,(SELECT ts FROM test_run)),
    'By aggregating result of build_stories_ranks for a given run we should be able to recreate run arrays'
);

CALL hn_ranker.do_all('production_default');
SELECT lives_ok( 'SELECT * FROM hn_ranker.build_stories_classify();' , 'Call without parameter should work on most recent run after a run');
SELECT * FROM finish();

ROLLBACK;