--Un registering first-off

ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run_story;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.story;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.error;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.ruleset;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.rule;


--Rename all object to be migrate before droping other extension objects
ALTER TABLE run RENAME TO run_old;
ALTER TABLE run_story RENAME TO run_story_old;
ALTER TABLE story RENAME TO story_old;
ALTER TABLE error RENAME TO error_old;
ALTER TABLE ruleset RENAME TO ruleset_old;
ALTER TABLE rule RENAME TO rule_old;