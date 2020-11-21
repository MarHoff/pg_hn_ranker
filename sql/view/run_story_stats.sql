-- View: @extschema@.run_story_stats

CREATE VIEW @extschema@.run_story_stats AS
SELECT run.id run_id,
    /* Broken since columns were removed from run story - Need fix!
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.topstories_rank IS NOT NULL), COALESCE(array_length(run.topstories,1)::text,'error')) AS topstories,
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.beststories_rank IS NOT NULL), COALESCE(array_length(run.beststories,1)::text,'error')) AS beststories,
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.newstories_rank IS NOT NULL), COALESCE(array_length(run.newstories,1)::text,'error')) AS newstories,
	*/ 
	--Theses stand as Placeholder until then
	NULL::text AS topstories,
	NULL::text AS beststories,
	NULL::text AS newstories,
	count(*) FILTER (WHERE run_story.status='new') AS new,
	count(*) FILTER (WHERE run_story.status='hot') AS hot,
	count(*) FILTER (WHERE run_story.status='tepid') AS tepid,
	count(*) FILTER (WHERE run_story.status='cooling') AS cooling,
	count(*) FILTER (WHERE run_story.status='cold') AS cold,
	count(*) FILTER (WHERE run_story.status='frozen') AS frozen,
	count(*) FILTER (WHERE run_story.status='deleted') AS deleted,
	count(*) FILTER (WHERE run_story.status='missing') AS missing,
	count(*) FILTER (WHERE run_story.status='failed') AS failed,
	(count(*) FILTER (WHERE (error.report ->> 'retries')::integer > 0)) AS retried_count,
	count(*) AS total_count,
	ts_run,
	max(ts_payload)-min(ts_run) as fetch_duration
FROM @extschema@.run
LEFT JOIN @extschema@.run_story ON run.id=run_story.run_id
LEFT JOIN @extschema@.error ON run_story.run_id=error.run_id AND error.object='run_story' AND run_story.story_id=error.object_id::bigint
GROUP BY run.id
ORDER BY run.id desc;
