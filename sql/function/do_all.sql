-- PROCEDURE: hn_ranker.do_all(text)

-- DROP PROCEDURE hn_ranker.do_all(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_all(
	hnr_config text DEFAULT 'production'::text)
LANGUAGE 'sql'

AS $BODY$
BEGIN;
CALL hn_ranker.do_run(hnr_config);
SAVEPOINT run_done;
CALL hn_ranker.do_run_story(hnr_config);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT run_done;
COMMIT;
$BODY$;

