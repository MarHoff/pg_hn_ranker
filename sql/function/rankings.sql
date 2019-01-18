-- FUNCTION: hn_ranker.rankings(extschema@.ranking[])

CREATE OR REPLACE FUNCTION @extschema@.rankings(
  ranking_array @extschema@.ranking[]
)
RETURNS TABLE (
  ranking @extschema@.ranking,
  url url,
  ids bigint[],
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
wget_ranking @extschema@.ranking[];
wget_query text;
BEGIN

wget_ranking := "ranking_array";

wget_query :='https://hacker-news.firebaseio.com/v0/%s.json';
RAISE DEBUG 'wget_query : %', wget_query;
RAISE DEBUG 'wget_ranking : %', wget_ranking;


RETURN QUERY
WITH
tunnest AS (SELECT DISTINCT tid FROM unnest(wget_ranking) tid ORDER BY tid),
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
SELECT tid id, tsel.url::url, conv.ids::bigint[], tget.ts_end, tget.duration, tget.batch, tget.retries, tget.batch_failrate
FROM tsel
LEFT JOIN tget ON tsel.url=tget.url
LEFT JOIN LATERAL (SELECT array_agg(id::bigint) ids FROM jsonb_array_elements_text(tget.payload::jsonb) WITH ORDINALITY AS a(id, hn_rank)) conv ON true;

END

$BODY$;


