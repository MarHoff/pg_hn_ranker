-- View: hn_ranker.diagnose_errors

CREATE VIEW hn_ranker.diagnose_errors AS
WITH run AS (SELECT max(ts_run) FROM hn_ranker.run)
SELECT
e.ts_run,
e.error_source,
e.source_id,
rs.status,
format('%1$s/%2$s/%3$s',
	coalesce(array_position(run.topstories, rs.story_id::bigint)::text,'*'),
	coalesce(array_position(run.beststories, rs.story_id::bigint)::text,'*'),
	coalesce(array_position(run.newstories, rs.story_id::bigint)::text,'*')
) rankings,
rs.score,
(e.report ->> 'ts_end')::timestamptz ts_end,
(e.report ->> 'duration')::numeric duration,
(e.report ->> 'retries')::integer retries,
(e.report ->> 'batch_failrate')::numeric batch_failrate,
(e.report ->> 'url') url,
jsonb_pretty(e.report -> 'payload')
FROM hn_ranker.error e
LEFT JOIN hn_ranker.run_story rs
	ON e.error_source='run_story' AND e.ts_run=rs.ts_run AND e.source_id::text=rs.story_id::text
JOIN hn_ranker.run ON e.ts_run=run.ts_run
--WHERE error_source='run_story' --AND retries = 0
ORDER BY error_source, ts_run, source_id
