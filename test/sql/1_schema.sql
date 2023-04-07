BEGIN;
SELECT plan(10);

SELECT tables_are( 'hn_ranker', ARRAY['run', 'story', 'run_story', 'error', 'ruleset', 'rules']);

SELECT views_are( 'hn_ranker', ARRAY['diagnose_errors', 'stats_run' , 'stats_run_story']);

SELECT types_are( 'hn_ranker', ARRAY['object','ranking','story_status'] );

SELECT functions_are( 'hn_ranker', ARRAY['build_stories_classify','build_stories_status','build_stories_ranks','check_time_window','do_all','do_run','do_run_story','wget_items','wget_rankings'] );

SELECT columns_are( 'hn_ranker', 'run', ARRAY['ts_run','ts_run','topstories','beststories','newstories','ts_end','extversion','ruleset_id']);
SELECT columns_are( 'hn_ranker', 'story', ARRAY['id','status']);
SELECT columns_are( 'hn_ranker', 'run_story', ARRAY['ts_run','story_id','status','score','descendants','ts_payload']);
SELECT columns_are( 'hn_ranker', 'error', ARRAY['ts_run','object','object_id','report']);
SELECT columns_are( 'hn_ranker', 'ruleset', ARRAY['id']);
SELECT columns_are( 'hn_ranker', 'rules', ARRAY['ruleset_id','id','type_val','val']);



SELECT * FROM finish();
ROLLBACK;