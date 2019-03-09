WITH run AS (SELECT max(id) FROM hn_ranker.run)
SELECT run_id, object, object_id, a.*
FROM hn_ranker.error, run
LEFT JOIN LATERAL jsonb_to_record(error.report) AS a(id text, url url, payload text, ts_end timestamp with time zone, duration double precision, batch bigint, retries integer, batch_failrate double precision) ON true
WHERE run_id=run.max