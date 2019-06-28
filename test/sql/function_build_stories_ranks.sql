--TODO Check that array conversion keep order
BEGIN;
SELECT plan(1);

SELECT pg_sleep(1);
CALL hn_ranker.do_run();

PREPARE revert_build_stories_ranks(bigint) AS 
SELECT
array_agg(story_id ORDER BY topstories_rank) FILTER (WHERE topstories_rank IS NOT NULL) topstories,
array_agg(story_id ORDER BY beststories_rank) FILTER (WHERE beststories_rank IS NOT NULL) beststories,
array_agg(story_id ORDER BY newstories_rank) FILTER (WHERE newstories_rank IS NOT NULL) newstories
FROM hn_ranker.build_stories_ranks(ARRAY[$1]);

PREPARE run_ranks(bigint) AS 
SELECT topstories, beststories, newstories FROM hn_ranker.run WHERE id=$1;

SELECT results_eq(
    $$EXECUTE revert_build_stories_ranks(1);$$,
    $$EXECUTE run_ranks(1);$$,
    'By aggregating result of build_stories_ranks for a given run we should be able to recreate run arrays'
);

SELECT * FROM finish();
ROLLBACK;