-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE FUNCTION hn_ranker.item_json(
    id bigint
)
  RETURNS jsonb AS
$BODY$
DECLARE
wget_query text;
wget_wait numeric DEFAULT 0.01;
wget_timeout numeric DEFAULT 5;
wget_result jsonb;

wget_id text;
BEGIN


wget_id := "id"::text;

wget_query := format('https://hacker-news.firebaseio.com/v0/item/%s.json',wget_id);
RAISE DEBUG 'wget_query : %', wget_query;


wget_result := wget_url(wget_query,wget_wait,wget_timeout)::jsonb;

RAISE DEBUG 'score : %', (SELECT wget_result -> 'score');
RAISE DEBUG 'by : %', (SELECT wget_result -> 'by');
RAISE DEBUG 'id : %', (SELECT wget_result -> 'id');
RAISE DEBUG 'url : %', (SELECT wget_result -> 'url');
RAISE DEBUG 'type : %', (SELECT wget_result -> 'type');
RAISE DEBUG 'time : %', (SELECT wget_result -> 'time');
RAISE DEBUG 'descendants : %', (SELECT wget_result -> 'descendants');
RAISE DEBUG 'title : %', (SELECT wget_result -> 'title');
RAISE DEBUG 'kids : %', (SELECT wget_result -> 'kids');
RAISE DEBUG 'text : %', (SELECT wget_result -> 'text');
RAISE DEBUG 'parent : %', (SELECT wget_result -> 'parent');



RETURN wget_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  PARALLEL SAFE
  COST 2000;
