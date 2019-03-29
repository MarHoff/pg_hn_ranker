-- View: @extschema@.diagnose_errors

CREATE VIEW @extschema@.diagnose_errors AS
WITH run AS (SELECT max(id) FROM hn_ranker.run)
SELECT
e.run_id,
e.object,
e.object_id,
rs.status,
format('%1$s/%2$s/%3$s',
		coalesce(topstories_rank::text,'*'),
		coalesce(beststories_rank::text,'*'),
		coalesce(newstories_rank::text,'*')
) rankings,
rs.score,
(e.report ->> 'ts_end')::timestamptz ts_end,
(e.report ->> 'duration')::numeric duration,
(e.report ->> 'retries')::integer retries,
(e.report ->> 'batch_failrate')::numeric batch_failrate,
(e.report ->> 'url') url,
jsonb_pretty(e.report -> 'payload')
FROM hn_ranker.error e
LEFT JOIN hn_ranker.run_story rs ON e.object='run_story' AND e.run_id=rs.run_id AND e.object_id::text=rs.story_id::text
--WHERE object='run_story' --AND retries = 0
ORDER BY object, run_id, object_id