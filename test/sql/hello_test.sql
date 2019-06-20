BEGIN;
SELECT plan(1);
SELECT ok( true , 'Hello test!');
SELECT * FROM finish();
ROLLBACK;