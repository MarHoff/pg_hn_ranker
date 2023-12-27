--Unregistering migrated elements
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.story;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run_story;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.error;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.ruleset;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.rule;

--Rename all object to be migrate before droping other extension objects
ALTER TABLE run RENAME TO run_old;
ALTER TABLE story RENAME TO story_old;
ALTER TABLE run_story RENAME TO run_story_old;
ALTER TABLE error RENAME TO error_old;
ALTER TABLE ruleset RENAME TO ruleset_old;
ALTER TABLE rule RENAME TO rules_old;

--Dropping unmigrated objects
DROP VIEW diagnose_errors;
DROP VIEW run_story_stats;

DROP ROUTINE do_all;
DROP ROUTINE do_run_story;
DROP ROUTINE do_run;
DROP ROUTINE build_stories_classify;
DROP ROUTINE build_stories_status;
DROP ROUTINE build_stories_ranks;
DROP ROUTINE wget_items;
DROP ROUTINE wget_rankings;
DROP ROUTINE max_id;
DROP ROUTINE check_time_window;

--Casting kept colums using extension specific type to standard base type before dropping type
ALTER TABLE error_old ALTER COLUMN "object" TYPE text; 
ALTER TABLE run_story_old ALTER COLUMN status TYPE text; 
ALTER TABLE story_old ALTER COLUMN status TYPE text; 

DROP TYPE object;
DROP TYPE story_status;
DROP TYPE ranking;

--Dropping constraint on kept table to release constaint name
ALTER TABLE hn_ranker.run_old DROP CONSTRAINT run_pkey;
ALTER TABLE hn_ranker.story_old DROP CONSTRAINT story_pkey;
ALTER TABLE hn_ranker.run_story_old DROP CONSTRAINT run_story_pkey;
ALTER TABLE hn_ranker.error_old DROP CONSTRAINT error_pkey;
ALTER TABLE hn_ranker.rules_old DROP CONSTRAINT rule_ruleset_id_fkey;
ALTER TABLE hn_ranker.rules_old DROP CONSTRAINT rule_pkey;
ALTER TABLE hn_ranker.ruleset_old DROP CONSTRAINT ruleset_pkey;
