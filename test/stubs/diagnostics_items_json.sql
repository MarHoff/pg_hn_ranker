WITH
tsel AS (
  SELECT array_agg(id)
  FROM (
    SELECT generate_series(1,100)::bigint id
  )foo
)

--SELECT * FROM hn_ranker.items_json((SELECt * FROM tsel)
--ORDER BY passes desc, ts_end asc;

SELECT
passes,
EXTRACT(EPOCH FROM (max(ts_end)-transaction_timestamp())) total_duration,
avg(duration) avg_duration,
max(duration) max_duration,
min(duration) min_duration,
count(*)
FROM hn_ranker.items_json((SELECt * FROM tsel))
GROUP BY passes
ORDER BY passes desc
