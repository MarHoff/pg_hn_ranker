-- Function: best_json(text, integer, boolean, numeric, numeric, text, text, text)

-- DROP FUNCTION hn_ranker.best_json(text, integer, boolean, numeric, numeric, text, text, text);

CREATE OR REPLACE FUNCTION hn_ranker.best_json(
)
  RETURNS jsonb AS
$BODY$
DECLARE
frapi_query text;
frapi_wait numeric DEFAULT 0.01;
frapi_timeout numeric DEFAULT 5;
frapi_result jsonb;
BEGIN

frapi_query :='https://hacker-news.firebaseio.com/v0/beststories.json';
RAISE DEBUG 'frapi_query : %', frapi_query;


frapi_result := hn_ranker.get_url(frapi_query,frapi_wait,frapi_timeout)::jsonb;

RAISE DEBUG 'Best : %', (SELECT frapi_result);

RETURN frapi_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
