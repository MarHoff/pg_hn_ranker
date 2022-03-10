BEGIN;
SELECT plan(1);
SELECT lives_ok( 'CALL hn_ranker.do_all();' , 'Try an iteration with defaults parameters');
SELECT * FROM finish();
ROLLBACK;