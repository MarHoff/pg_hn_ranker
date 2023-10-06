--Drop all old tables
DROP TABLE run RENAME TO run_old;
DROP TABLE run_story RENAME TO run_story_old;
DROP TABLE story RENAME TO story_old;
DROP TABLE error RENAME TO error_old;
DROP TABLE ruleset RENAME TO ruleset_old;
DROP TABLE rule RENAME TO rule_old;