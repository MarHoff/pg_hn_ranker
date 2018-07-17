WITH
tsel AS (
  SELECT string_agg(url,' ')
  FROM (
    SELECT 'https://hacker-news.firebaseio.com/v0/item/'||generate_series(1,100)||'.json' url
  )foo
),
tapi AS (SELECT regexp_split_to_array(regexp_split_to_table(hn_ranker.get_urls((SELECT * FROM tsel),0.1,10,3,100),'@frapi_token@@frapi_token@\n'),'@frapi_token@') r)
SELECT r[1] url, r[2] payload FROM tapi
order by url