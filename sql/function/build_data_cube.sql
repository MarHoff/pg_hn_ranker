WITH allranks AS (SELECT * FROM hn_ranker.build_stories_ranks(
	
))

SELECT
COALESCE(allranks.run_id,run_story.run_id) run_id,
COALESCE(allranks.story_id,run_story.story_id) story_id,
allranks.topstories_rank,
allranks.beststories_rank,
allranks.newstories_rank,
allranks.ts_run,
run_story.status,
run_story.score,
run_story.descendants,
run_story.ts_payload
FROM allranks
FULL OUTER JOIN hn_ranker.run_story
ON allranks.run_id=run_story.run_id AND allranks.story_id=run_story.story_id