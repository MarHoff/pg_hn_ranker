--Placeholder for temp_migrate

-------------------------------------------------------------- Change!
INSERT INTO run
(
  ts_run, topstories, beststories, newstories, ts_end, extversion, ruleset_id
)
SELECT
  ts_run, topstories, beststories, newstories, ts_end, '0.1.5'::text , 'unknown'::text
FROM
  run_old
;

--------------------------------------------------------------
INSERT INTO run_story
(
  ts_run, story_id, status, score, descendants, ts_payload
)
SELECT
  ts_run, story_id, status::hn_ranker.story_status, score, descendants, ts_payload
FROM
  run_story_old
;

--------------------------------------------------------------
INSERT INTO hn_ranker.story
(
  id, status
)
SELECT
  id, status::hn_ranker.story_status
FROM
  story_old
;

-------------------------------------------------------------- Change!
INSERT INTO hn_ranker.error
(
  ts_run, error_source, source_id, report
)
SELECT
  ts_run, "object"::hn_ranker.error_source, object_id, report
FROM
  error_old
;

--------------------------------------------------------------
INSERT INTO hn_ranker.ruleset
(
  id
)
SELECT
  id
FROM
  ruleset_old
WHERE
  id NOT IN ('debug','production','production_default')
;

-------------------------------------------------------------- Change!
INSERT INTO hn_ranker.rules
(
  ruleset_id, id, type_val, val
)
SELECT
  ruleset_id, "rule", type_val, val
FROM
  "rules_old"
WHERE
  ruleset_id NOT IN ('debug','production','production_default')
;

