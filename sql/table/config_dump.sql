--Table utilisateur à sauvegarder
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.error', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run_story', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.ruleset', $$WHERE id NOT IN ('debug','producton','production_default')$$);
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.rules', $$WHERE ruleset_id NOT IN ('debug','producton','production_default')$$);
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.story', '');
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.items', '');

