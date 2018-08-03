-- FUNCTION: hn_ranker.items_json(bigint[])

CREATE OR REPLACE FUNCTION hn_ranker.items_json(
  id_array bigint[],
    wait numeric DEFAULT 0,
    timeout numeric DEFAULT 5,
    tries integer DEFAULT 1,
    workers integer DEFAULT 100,
    delimiter text DEFAULT '@wget_token@',
  nbpasses integer DEFAULT 3)
    RETURNS TABLE (id bigint, url url, payload jsonb, ts_end timestamptz, duration double precision, passes integer)
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
WITH RECURSIVE
tunnest AS (SELECT DISTINCT tid FROM unnest(wget_id) tid ORDER BY tid),
tsel AS (SELECT tid, format(wget_query,tid) url FROM tunnest),
tget AS (
  SELECT wget_urls.url, wget_urls.payload, wget_urls.ts_end, wget_urls.duration, 1 as passes
    FROM wget_urls((SELECT array_agg(tsel.url)::url_array FROM tsel),
      wait := wait , timeout := timeout, tries := tries, workers := workers, delimiter := delimiter)
  UNION ALL
  SELECT tget.url, wget_url(tget.url, wait := wait , timeout := timeout, tries := tries) payload, clock_timestamp()::timestamptz ts_end, NULL duration,tget.passes+1 as passes
  FROM tget WHERE tget.payload IS NULL AND tget.passes < nbpasses
  )
SELECT tid id, tsel.url::url, tget.payload::jsonb, tget.ts_end, COALESCE(tget.duration,EXTRACT(EPOCH FROM (tget.ts_end-(lag(tget.ts_end) OVER (ORDER BY tget.ts_end asc))))), tget.passes
FROM tsel LEFT JOIN tget ON tsel.url=tget.url
AND tget.payload is NOT NULL;

END

$BODY$;


