-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

-- DROP FUNCTION hn_ranker.item_json(text, integer, boolean, numeric, numeric, text, text, text);

CREATE OR REPLACE FUNCTION hn_ranker.item_json(
    id integer
)
  RETURNS jsonb AS
$BODY$
DECLARE
frapi_query text;
frapi_wait numeric DEFAULT 0.1;
frapi_timeout numeric DEFAULT 10;
frapi_result jsonb;

frapi_q text DEFAULT '';
BEGIN


frapi_q := "id"::text;

frapi_query :='https://hacker-news.firebaseio.com/v0/item/'||frapi_q||'.json';
RAISE DEBUG 'frapi_query : %', frapi_query;


frapi_result := hn_ranker.get_url(frapi_query,frapi_wait,frapi_timeout)::jsonb;

RAISE DEBUG 'by : %', (SELECT frapi_result -> 'by');
RAISE DEBUG 'id : %', (SELECT frapi_result -> 'id');
RAISE DEBUG 'kids : %', (SELECT frapi_result -> 'kids');
RAISE DEBUG 'text : %', (SELECT frapi_result -> 'text');
RAISE DEBUG 'time : %', (SELECT frapi_result -> 'time');
RAISE DEBUG 'type : %', (SELECT frapi_result -> 'type');
RAISE DEBUG 'parent : %', (SELECT frapi_result -> 'parent');


RETURN frapi_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
