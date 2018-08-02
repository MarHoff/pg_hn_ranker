WITH
tsel AS (
  SELECT string_agg(url,' ')
  FROM (
    SELECT 'https://hacker-news.firebaseio.com/v0/item/'||generate_series(1,100)||'.json' url
  )foo
),
tapi AS (SELECT hn_ranker.get_urls_raw((SELECT * FROM tsel),0.1,10,3,100)),
tapitable AS (SELECT regexp_split_to_array(regexp_split_to_table((SELECT * FROM tapi) ,'@frapi_token@@frapi_token@\n'),'@frapi_token@') r)
SELECT substring(r[1]  from '(\d*)\.json$') num, r[1] url, r[2] payload FROM tapitable order by substring(r[1]  from '(\d*)\.json$')::integer

--SELECT * FROM tapi