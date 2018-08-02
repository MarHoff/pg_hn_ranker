-- FUNCTION: hn_ranker.items_json(bigint[])

CREATE OR REPLACE FUNCTION hn_ranker.items_json(
	id_array bigint[],
    wait numeric DEFAULT 0,
    timeout numeric DEFAULT 5,
    tries integer DEFAULT 3,
    workers integer DEFAULT 100,
    delimiter text DEFAULT '@wget_token@')
    RETURNS TABLE (id bigint, url url, payload jsonb)
    LANGUAGE 'plpgsql'
    VOLATILE
AS $BODY$

DECLARE
wget_id bigint[];
wget_query text;
BEGIN

wget_id := "id_array";

wget_query :='https://hacker-news.firebaseio.com/v0/item/%s.json';
RAISE DEBUG 'wget_query : %', wget_query;
RAISE DEBUG 'wget_id : %', wget_id;


RETURN QUERY
WITH
tunnest AS (SELECT DISTINCT tid FROM unnest(wget_id) tid ORDER BY tid),
tsel AS (SELECT tid, format(wget_query,tid) url FROM tunnest),
tget AS (SELECT * FROM wget_urls((SELECT array_agg(tsel.url)::url_array FROM tsel),wait := wait , timeout := timeout, tries := tries, workers := workers, delimiter := delimiter))
SELECT tid id, tsel.url::url, tget.payload::jsonb FROM tsel LEFT JOIN tget ON tsel.url=tget.url;

END

$BODY$;


