SELECT count(*) FROM hn_ranker.build_stories_classify(200,'debug')
UNION ALL
SELECT count(distinct story_id) FROM hn_ranker.run_story WHERE run_id<=200;