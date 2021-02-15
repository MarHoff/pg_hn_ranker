-- PROCEDURE: hn_ranker.do_all(text)

-- DROP PROCEDURE hn_ranker.do_all(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_all(
	hnr_config text DEFAULT 'production'::text)
LANGUAGE 'sql'

AS $BODY$
CALL hn_ranker.do_run(hnr_config);
CALL hn_ranker.do_run_story(hnr_config);
$BODY$;

