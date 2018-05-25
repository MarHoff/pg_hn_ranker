-- Function: top_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.max_id(
)
  RETURNS bigint AS
$BODY$
DECLARE
frapi_query text;
frapi_wait numeric DEFAULT 0.01;
frapi_timeout numeric DEFAULT 5;
frapi_result bigint;
BEGIN

frapi_query :='https://hacker-news.firebaseio.com/v0/maxitem.json';
RAISE DEBUG 'frapi_query : %', frapi_query;


frapi_result := @extschema@.get_url(frapi_query,frapi_wait,frapi_timeout)::jsonb;

RAISE DEBUG 'max_id : %', (SELECT frapi_result);

RETURN frapi_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
