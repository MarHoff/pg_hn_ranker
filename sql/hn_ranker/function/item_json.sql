-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.item_json(
    id integer
)
  RETURNS jsonb AS
$BODY$
DECLARE
frapi_query text;
frapi_wait numeric DEFAULT 0.01;
frapi_timeout numeric DEFAULT 5;
frapi_result jsonb;

frapi_q text DEFAULT '';
BEGIN


frapi_q := "id"::text;

frapi_query :='https://hacker-news.firebaseio.com/v0/item/'||frapi_q||'.json';
RAISE DEBUG 'frapi_query : %', frapi_query;


frapi_result := @extschema@.get_url(frapi_query,frapi_wait,frapi_timeout)::jsonb;

RAISE DEBUG 'score : %', (SELECT frapi_result -> 'score');
RAISE DEBUG 'by : %', (SELECT frapi_result -> 'by');
RAISE DEBUG 'id : %', (SELECT frapi_result -> 'id');
RAISE DEBUG 'url : %', (SELECT frapi_result -> 'url');
RAISE DEBUG 'type : %', (SELECT frapi_result -> 'type');
RAISE DEBUG 'time : %', (SELECT frapi_result -> 'time');
RAISE DEBUG 'descendants : %', (SELECT frapi_result -> 'descendants');
RAISE DEBUG 'title : %', (SELECT frapi_result -> 'title');
RAISE DEBUG 'kids : %', (SELECT frapi_result -> 'kids');
RAISE DEBUG 'text : %', (SELECT frapi_result -> 'text');
RAISE DEBUG 'parent : %', (SELECT frapi_result -> 'parent');



RETURN frapi_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
