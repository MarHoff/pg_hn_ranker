-- View: @extschema@.run_story_stats

CREATE VIEW @extschema@.run_story_stats AS
SELECT run.id run_id,
	format('%1%s/%2%s',count(*) FILTER (WHERE run_story.topstories_rank IS NOT NULL),array_length(run.topstories,1)) topstories,
	format('%1%s/%2%s',count(*) FILTER (WHERE run_story.beststories_rank IS NOT NULL),array_length(run.beststories,1)) beststories,
	format('%1%s/%2%s',count(*) FILTER (WHERE run_story.newstories_rank IS NOT NULL),array_length(run.newstories,1)) newstories,
	count(*) FILTER (WHERE run_story.status='new') new,
	count(*) FILTER (WHERE run_story.status='hot') hot,
	count(*) FILTER (WHERE run_story.status='tepid') tepid,
	count(*) FILTER (WHERE run_story.status='cooling') cooling,
	count(*) FILTER (WHERE run_story.status='cold') cold,
	count(*) FILTER (WHERE run_story.status='frozen') frozen,
	count(*) FILTER (WHERE run_story.status='deleted') deleted,
	count(*) FILTER (WHERE run_story.status='missing') missing,
	count(*) FILTER (WHERE run_story.status='failed') failed,
	(count(*) FILTER (WHERE (error.report ->> 'retries')::integer > 0) retried_count,
	count(*) total_count,
	ts_run,
	max(ts_payload)-min(ts_run) as fetch_duration
FROM @extschema@.run
LEFT JOIN @extschema@.run_story ON run.id=run_story.run_id
LEFT JOIN @extschema@.error ON run_story.run_id=error.run_id AND error.object='run_story' AND run_story.story_id=error.object_id
GROUP BY run.id
ORDER BY run.id desc;
