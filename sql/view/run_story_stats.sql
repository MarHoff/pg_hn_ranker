-- View: @extschema@.run_story_stats

CREATE VIEW @extschema@.run_story_stats AS
SELECT run.id run_id,
	array_length(run.topstories,1) topstories_count,
	count(*) FILTER (WHERE run_story.topstories_rank IS NOT NULL) topstories_recorded,
	array_length(run.beststories,1) beststories_count,
	count(*) FILTER (WHERE run_story.beststories_rank IS NOT NULL) beststories_recorded,
	array_length(run.newstories,1) newstories_count,
	count(*) FILTER (WHERE run_story.newstories_rank IS NOT NULL) newstories_recorded,
	count(*) FILTER (WHERE run_story.status='new') new_count,
	count(*) FILTER (WHERE run_story.status='hot') hot_count,
	count(*) FILTER (WHERE run_story.status='tepid') tepid_count,
	count(*) FILTER (WHERE run_story.status='cooling') cooling_count,
	count(*) FILTER (WHERE run_story.status='cold') cold_count,
	count(*) FILTER (WHERE run_story.status='frozen') frozen_count,
	(count(*) FILTER (WHERE NOT run_story.success))-(count(*) FILTER (WHERE score IS NULL)) retried_count,
	count(*) FILTER (WHERE score IS NULL) fail_count,
	count(*) total_count,
	ts_run,
	max(ts_payload)-min(ts_run) as fetch_duration
FROM @extschema@.run LEFT JOIN @extschema@.run_story ON run.id=run_story.run_id
	GROUP BY run.id
	ORDER BY run.id desc;
