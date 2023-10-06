--Unregistering migrated elements
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.story;
ALTER EXTENSION pg_hn_ranker DROP TABLE hn_ranker.run_story;
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

--Casting colums using extension specific type to standard type
ALTER TABLE error_old ALTER COLUMN "object" TYPE text; 
ALTER TABLE run_story_old ALTER COLUMN status TYPE text; 
ALTER TABLE story_old ALTER COLUMN status TYPE text; 

--Dropping unmigrated objects
DROP TABLE diagnose_errors;
DROP TABLE run_story_stats;

DROP PROCEDURE do_all;
DROP FUNCTION do_run_story;
DROP FUNCTION do_run;
DROP FUNCTION build_stories_classify;
DROP FUNCTION build_stories_status;
DROP FUNCTION build_stories_ranks;
DROP FUNCTION wget_items;
DROP FUNCTION wget_rankings;
DROP FUNCTION max_id;
DROP FUNCTION check_time_window;

DROP TYPE object;
DROP TYPE story_status;
DROP TYPE ranking;




