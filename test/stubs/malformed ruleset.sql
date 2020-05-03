DELETE FROM hn_ranker.rule WHERE ruleset_id='broken';
DELETE FROM hn_ranker.ruleset WHERE id='broken';

INSERT INTO hn_ranker.ruleset (id) (VALUES('broken'));

INSERT INTO hn_ranker.rule (ruleset_id, rule, type_val, val) (VALUES
('broken'::text, 'run_story_param', 'jsonb',
/*$${
"new_repeat":1,
"hot_repeat":1,
"hot_rank":30,
"tepid_rank":60,
"tepid_age":"1 minute",
"cooling_repeat":1,
"cooling_age":"1 minute",
"cold_repeat":1,
"cold_age":"1 minute",
"frozen_age":"1 minute"
}$$*/NULL::jsonb));

SELECT hn_ranker.build_stories_fetch(hnr_ruleset => 'broken');