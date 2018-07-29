-- FUNCTION: hn_ranker.items_json(bigint[])

CREATE OR REPLACE FUNCTION hn_ranker.items_json( id_array bigint[])
    RETURNS TABLE (id bigint, url url, payload jsonb)
    LANGUAGE 'plpgsql'
    VOLATILE PARALLEL SAFE
AS $BODY$

DECLARE
wget_query text;
wget_wait numeric DEFAULT 0.01;
wget_timeout numeric DEFAULT 5;
wget_result jsonb;

wget_id bigint[];
BEGIN

wget_id := "id_array";

wget_query :='https://hacker-news.firebaseio.com/v0/item/%s.json';
RAISE DEBUG 'wget_query : %', wget_query;
RAISE DEBUG 'wget_id : %', wget_id;


RETURN QUERY
WITH
tunnest AS (SELECT DISTINCT tid FROM unnest(wget_id) tid ORDER BY tid),
tsel AS (SELECT tid, format(wget_query,tid) url FROM tunnest),
tget AS (SELECT * FROM wget_urls((SELECT array_agg(tsel.url)::url_array FROM tsel)))
SELECT tid id, tsel.url::url, tget.payload::jsonb FROM tsel LEFT JOIN tget ON tsel.url=tget.url;

END

$BODY$;


