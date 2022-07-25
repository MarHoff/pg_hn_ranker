-- PROCEDURE: hn_ranker.do_all(text)

-- DROP PROCEDURE hn_ranker.do_all(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_all(
	hnr_config text DEFAULT 'production_default'::text)
LANGUAGE 'plpgsql'

AS $BODY$
DECLARE
	ts_run timestamptz ;
BEGIN
ts_run := (SELECT hn_ranker.do_run(hnr_config));
CALL hn_ranker.do_run_story(ts_run, hnr_config);
END
$BODY$;

