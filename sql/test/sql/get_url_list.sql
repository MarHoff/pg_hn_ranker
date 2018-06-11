WITH tquery AS (
  SELECT string_agg(url,' ')
  FROM (
    SELECT 'https://hacker-news.firebaseio.com/v0/item/'||generate_series(1,10)||'.json' url
  )foo
)
SELECT hn_ranker.get_url_list((SELECT * FROM tquery),0.1,10,3,100)