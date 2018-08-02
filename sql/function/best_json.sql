-- Function: best_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.best_json(
)
  RETURNS jsonb AS
$BODY$
DECLARE
wget_query text;
wget_wait numeric DEFAULT 0.01;
wget_timeout numeric DEFAULT 5;
wget_result jsonb;
BEGIN

wget_query :='https://hacker-news.firebaseio.com/v0/beststories.json';
RAISE DEBUG 'wget_query : %', wget_query;


wget_result := wget_url(wget_query,wget_wait,wget_timeout)::jsonb;

RAISE DEBUG 'Best : %', (SELECT wget_result);

RETURN wget_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
