--TODO Check that array conversion keep order
BEGIN;
SELECT plan(2);

SELECT lives_ok( 'SELECT * FROM hn_ranker.stats_run;' , 'Calling global stats function');
SELECT lives_ok( 'SELECT * FROM hn_ranker.stats_run_story;' , 'Calling stats for each run');

SELECT * FROM finish();

ROLLBACK;