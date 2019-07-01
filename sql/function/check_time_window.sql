-- FUNCTION: hn_ranker.time_window(timestamp with time zone, timestamp with time zone, integer)

CREATE OR REPLACE FUNCTION hn_ranker.check_time_window(
	t_new timestamp with time zone,
	t_old timestamp with time zone,
	t_window integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
BEGIN
IF t_window > 86399 OR t_window < 0 THEN
	RAISE EXCEPTION 'Time windows can''t be negative or larger than max seconds past midnight (86399)!';
--ELSE RAISE DEBUG 't_window: %', t_window;
END IF;

--RAISE DEBUG 'age: %', age(t_new,t_old);
--RAISE DEBUG 'second to midnight: %', to_char(age(t_new,t_old),'SSSS');

IF t_window = 0 THEN
	RETURN true;
ELSE
	IF to_char(age(t_new,t_old),'SSSS')::integer < t_window THEN RETURN true;
	ELSE RETURN false;
	END IF;
END IF;

END;
$BODY$;
