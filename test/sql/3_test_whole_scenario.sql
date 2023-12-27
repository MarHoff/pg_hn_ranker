BEGIN;
SELECT plan(3);
SELECT lives_ok( $$CALL hn_ranker.do_all();$$ , 'Try an iteration without parameters (should default to production_default)');
SELECT pg_sleep(5); --Cautionary delay to avoid being kicked by HN firebase API for abuse 
SELECT lives_ok( $$CALL hn_ranker.do_all('production_default');$$ , 'Try an iteration with defaults parameters explicitely called');
SELECT pg_sleep(5); --Cautionary delay to avoid being kicked by HN firebase API for abuse 
SELECT lives_ok( $$CALL hn_ranker.do_all('debug');$$ , 'Try an iteration with debug parameters');
SELECT * FROM finish();
ROLLBACK;