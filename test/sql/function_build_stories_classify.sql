BEGIN;
SELECT plan(1);
SELECT lives_ok( 'SELECT * FROM hn_ranker.build_stories_classify();' , 'Call without parameter should work on most recent run');
SELECT * FROM finish();
ROLLBACK;