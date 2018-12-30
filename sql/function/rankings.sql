-- Function: ranking(text, integer, boolean, numeric, numeric, text, text, text)
CREATE TYPE hn_ranker.ranking AS ENUM ('beststories','newstories','topstories');
CREATE OR REPLACE FUNCTION @extschema@.rankings(
	ranking hn_ranker.ranking
)
  RETURNS bigint[] AS
$BODY$
DECLARE
wget_query text;
wget_result jsonb;
BEGIN

wget_query := format('https://hacker-news.firebaseio.com/v0/%s.json',ranking);
RAISE DEBUG 'wget_query : %', wget_query;

wget_result := wget_url(
	url := wget_query,
  min_latency := 0,
  timeout := 5,
  tries := 5,
  waitretry := 1
  )::jsonb;

RAISE DEBUG 'Best : %', (SELECT wget_result);

RETURN (SELECT array_agg(ids::bigint) FROM jsonb_array_elements_text(wget_result) ids);

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
