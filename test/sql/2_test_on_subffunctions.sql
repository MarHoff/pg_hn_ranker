--TODO Check that array conversion keep order
BEGIN;
SELECT plan(4);

PREPARE wget_rankings(text[]) AS 
SELECT to_json(payload)::text as payload FROM hn_ranker.wget_rankings($1::hn_ranker.ranking[]);

SELECT pg_sleep(1);
SELECT results_eq(
    $$EXECUTE wget_rankings('{topstories}');$$,
    $$SELECT wget_url('https://hacker-news.firebaseio.com/v0/topstories.json') payload ;$$,
    'hn_ranker.wget_rankings() call for topstories should return same result as as bare pmwget call'
);
SELECT pg_sleep(1);
SELECT results_eq(
    $$EXECUTE wget_rankings('{beststories}');$$,
    $$SELECT wget_url('https://hacker-news.firebaseio.com/v0/beststories.json') payload ;$$,
    'hn_ranker.wget_rankings() call for beststories should return same result as as bare pmwget call'
);
SELECT pg_sleep(1);
SELECT results_eq(
    $$EXECUTE wget_rankings('{newstories}');$$,
    $$SELECT wget_url('https://hacker-news.firebaseio.com/v0/newstories.json') payload ;$$,
    'hn_ranker.wget_rankings() call for newstories should return same result as as bare pmwget call'
);

SELECT lives_ok( 'SELECT * FROM hn_ranker.build_stories_classify();' , 'Call without parameter should work on most recent run even before any run');

SELECT * FROM finish();
ROLLBACK;