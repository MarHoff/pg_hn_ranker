-- FUNCTION: hn_ranker.items(bigint[])

CREATE OR REPLACE FUNCTION hn_ranker.items(
  id_array bigint[]
)
RETURNS TABLE (
  id bigint,
  url url,
  payload jsonb,
  ts_end timestamptz,
  duration double precision,
  batch bigint,
  retries integer,
  batch_failrate double precision
)
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
tget AS (
  SELECT * FROM
    wget_urls(
      url_array := (SELECT array_agg(tsel.url)::url_array FROM tsel),
      i_min_latency := 0,
      i_timeout := 5,
      i_tries := 1,
      i_waitretry := 0,
      i_parallel_jobs := 75,
      i_delimiter := '@wget_token@'::text,
      i_delay := 0,
      r_min_latency := 0,
      r_timeout := 5,
      r_tries := 1,
      r_waitretry := 0,
      r_parallel_jobs := 20,
      r_delimiter := '@wget_token@'::text,
      r_delay := 5,
      batch_size := 2000,
      batch_retries := 2,
      batch_retries_failrate := 0.05
    )
)
SELECT
tid id,
  tsel.url::url,
  --API might return 'null' json value so we need to diferentiate that from SQL NULL returned by wget failure
  CASE WHEN tget.payload='null' THEN to_jsonb('json_null'::text) ELSE tget.payload::jsonb END payload,
  tget.ts_end,
  tget.duration,
  tget.batch,
  tget.retries,
  tget.batch_failrate
FROM tsel LEFT JOIN tget ON tsel.url=tget.url;

END

$BODY$;


