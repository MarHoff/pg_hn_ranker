--TODO Check that array conversion keep order
SELECT to_jsonb(hn_ranker.rankings('topstories'))=wget_url('https://hacker-news.firebaseio.com/v0/topstories.json')::jsonb