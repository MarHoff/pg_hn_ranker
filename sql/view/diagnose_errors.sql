-- View: @extschema@.diagnose_errors

CREATE VIEW @extschema@.diagnose_errors AS
WITH run AS (SELECT max(ts_run) FROM hn_ranker.run)
SELECT
e.ts_run,
e.object,
e.object_id,
rs.status,
format('%1$s/%2$s/%3$s',
	coalesce(array_position(run.topstories, e.object_id::bigint)::text,'*'),
	coalesce(array_position(run.beststories, e.object_id::bigint)::text,'*'),
	coalesce(array_position(run.newstories, e.object_id::bigint)::text,'*')
) rankings,
rs.score,
(e.report ->> 'ts_end')::timestamptz ts_end,
(e.report ->> 'duration')::numeric duration,
(e.report ->> 'retries')::integer retries,
(e.report ->> 'batch_failrate')::numeric batch_failrate,
(e.report ->> 'url') url,
jsonb_pretty(e.report -> 'payload')
FROM hn_ranker.error e
LEFT JOIN hn_ranker.run_story rs ON e.object='run_story' AND e.ts_run=rs.ts_run AND e.object_id::text=rs.story_id::text
JOIN hn_ranker.run ON e.ts_run=run.ts_run
--WHERE object='run_story' --AND retries = 0
ORDER BY object, ts_run, object_id