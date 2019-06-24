BEGIN;
SELECT plan(6);

SELECT tables_are( 'hn_ranker', ARRAY['run', 'story', 'run_story', 'error', 'ruleset', 'rule']);

SELECT views_are( 'hn_ranker', ARRAY['diagnose_errors', 'run_story_stats']);

SELECT sequences_are( 'hn_ranker', ARRAY['run_id_seq'] );

SELECT types_are( 'hn_ranker', ARRAY['object','ranking','story_status'] );

SELECT functions_are( 'hn_ranker', ARRAY['build_stories_fetch','build_stories_last','build_stories_ranks','do_all','do_run','do_run_story','item_json','items','max_id','rankings'] );


SELECT columns_are( 'hn_ranker', 'run', ARRAY['id','ts_run','topstories','beststories','newstories','ts_end']);



SELECT * FROM finish();
ROLLBACK;