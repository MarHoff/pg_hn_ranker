--Create type used in rankings()

CREATE TYPE hn_ranker.ranking AS ENUM ('topstories','beststories','newstories');--Type used in story & run_story

CREATE TYPE hn_ranker.story_status AS ENUM ('new','hot','tepid','cooling','cold','frozen','missing');--Create type used in object()

CREATE TYPE hn_ranker.object AS ENUM ('run','run_story');-- Table: @extschema@.run

CREATE SEQUENCE IF NOT EXISTS @extschema@.run_id_seq AS bigint;
CREATE TABLE @extschema@.run
(
    id bigint NOT NULL DEFAULT nextval('@extschema@.run_id_seq'::regclass),
    ts_run timestamp with time zone,
    topstories bigint[],
    beststories bigint[],
    newstories bigint[],
    ts_end timestamp with time zone,
    CONSTRAINT run_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
;
-- Table: @extschema@.story

CREATE TABLE @extschema@.story
(
    id bigint NOT NULL,
    status @extschema@.story_status,
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);
-- Table: @extschema@.run_story

CREATE TABLE @extschema@.run_story
(
    run_id bigint NOT NULL,
    story_id bigint NOT NULL,
    topstories_rank integer,
    beststories_rank integer,
    newstories_rank integer,
    status hn_ranker.story_status,
    score integer,
    descendants bigint,
    ts_payload timestamp with time zone,
    success boolean,
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id),
    CONSTRAINT run_story_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES @extschema@.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
);
-- Table: @extschema@.error

CREATE TABLE @extschema@.error
(
    run_id bigint NOT NULL,
    object hn_ranker.object,
    object_id text,
    report jsonb,
    CONSTRAINT error_pkey PRIMARY KEY (run_id, object, object_id),
    CONSTRAINT error_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES @extschema@.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
    DEFERRABLE INITIALLY DEFERRED
)
WITH (
    OIDS = FALSE
);
-- Name: ruleset; Type: TABLE; Schema: hn_ranker; Owner: -
--

CREATE TABLE ruleset (
    id text NOT NULL,
    CONSTRAINT ruleset_pkey PRIMARY KEY (id)

);


INSERT INTO ruleset (id) (VALUES
('debug'),
('production')
);-- Name: rules; Type: TABLE; Schema: hn_ranker; Owner: -
--

CREATE TABLE rule (
    ruleset_id text NOT NULL,
    rule text NOT NULL,
    type_val text,
    val text,
    CONSTRAINT rule_pkey PRIMARY KEY (ruleset_id, rule),
    CONSTRAINT rule_ruleset_id_fkey FOREIGN KEY (ruleset_id)
        REFERENCES ruleset (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


INSERT INTO rule (ruleset_id, rule, type_val, val) (VALUES
('debug'::text, 'run_story_param', 'jsonb',
$${
"new_repeat":1,
"hot_repeat":1,
"hot_rank":30,
"hot_rankbump":30,
"tepid_rank":60,
"tepid_age":"1 minute",
"cooling_repeat":1,
"cooling_age":"1 minute",
"cold_repeat":1,
"cold_age":"1 minute",
"frozen_age":"1 minute"
}$$::jsonb),

('production', 'run_story_param', 'jsonb',
$${
"new_repeat":12,
"hot_repeat":6,
"hot_rank":30,
"hot_rankbump":30,
"tepid_rank":60,
"tepid_age":"19 minute",
"cooling_repeat":12,
"cooling_age":"59 minute",
"cold_repeat":2,
"cold_age":"6 hour",
"frozen_age":"7 day"
}$$)
);--Table utilisateur à sauvegarder
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.error', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run_story', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.ruleset', $$WHERE id NOT IN ('debug','production')$$);
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.rule', $$WHERE ruleset_id NOT IN ('debug','production')$$);
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.story', '');
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.items', '');

-- Function: top_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.max_id(
)
  RETURNS bigint AS
$BODY$
DECLARE
wget_query text;
wget_wait numeric DEFAULT 0.01;
wget_timeout numeric DEFAULT 5;
wget_result bigint;
BEGIN

wget_query :='https://hacker-news.firebaseio.com/v0/maxitem.json';
RAISE DEBUG 'wget_query : %', wget_query;


wget_result := wget_url(wget_query,wget_wait,wget_timeout)::jsonb;

RAISE DEBUG 'max_id : %', (SELECT wget_result);

RETURN wget_result;

END
$BODY$
  LANGUAGE plpgsql VOLATILE;
-- FUNCTION: hn_ranker.rankings(extschema@.ranking[])

CREATE OR REPLACE FUNCTION @extschema@.rankings(
  ranking_array @extschema@.ranking[]
)
RETURNS TABLE (
  id @extschema@.ranking,
  url url,
  payload bigint[],
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
LEFT JOIN LATERAL (SELECT array_agg(a.id::bigint) ids FROM jsonb_array_elements_text(tget.payload::jsonb) WITH ORDINALITY AS a(id, hn_rank)) conv ON true;

END

$BODY$;


-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.item_json(
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


-- PROCEDURE: hn_ranker.do_run(text)

-- DROP PROCEDURE hn_ranker.do_run(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_run(
	hnr_config text DEFAULT 'production'::text)
LANGUAGE 'sql'

AS $BODY$
WITH
get_rankings AS (SELECT * FROM hn_ranker.rankings('{topstories,beststories,newstories}')),
insert_run AS (
INSERT INTO hn_ranker.run(
	ts_run,
	topstories,
	beststories,
	newstories,
	ts_end)
SELECT
  now() ts_run,
  max(payload) FILTER (WHERE id ='topstories') as topstories,
  max(payload) FILTER (WHERE id ='beststories') as beststories,
  max(payload) FILTER (WHERE id ='newstories') as newstories,
  max(ts_end) as ts_end
  FROM get_rankings
RETURNING *)
INSERT INTO hn_ranker.error(
run_id, object, object_id, report)
SELECT insert_run.id run_id, 'run' as object, get_rankings.id::text object_id, row_to_json(get_rankings)::jsonb
FROM insert_run, get_rankings
WHERE get_rankings.payload IS NULL OR NOT(get_rankings.retries = 0);
$BODY$;

-- PROCEDURE: hn_ranker.do_run_story(text)

-- DROP PROCEDURE hn_ranker.do_run_story(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_run_story(
	hnr_ruleset text DEFAULT 'production'::text)
LANGUAGE 'plpgsql'

AS $BODY$
DECLARE
param jsonb;
BEGIN
RAISE NOTICE 'hnr_ruleset: %', hnr_ruleset;
SELECT val INTO STRICT param FROM hn_ranker.rule WHERE ruleset_id=hnr_ruleset;
RAISE NOTICE 'param: %', param;

WITH
  current_run AS (
    SELECT * FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq'::regclass)
  ),
  unnest_rankings AS (
  --Unesting data from current_run
    SELECT id, 'topstories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(topstories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT id, 'beststories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(beststories) WITH ORDINALITY AS a(story_id, hn_rank)
    UNION ALL
    SELECT id, 'newstories' ranking, story_id, hn_rank, ts_run
    FROM current_run, unnest(newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  ),
  current_run_story AS (
  --Grouping information by unique story_id for current run
    SELECT
      id run_id,
      story_id,
      min(hn_rank) FILTER (WHERE ranking='topstories') topstories_rank,
      min(hn_rank) FILTER (WHERE ranking='beststories') beststories_rank,
      min(hn_rank) FILTER (WHERE ranking='newstories') newstories_rank,
      ts_run
    FROM unnest_rankings
      GROUP BY run_id, ts_run, story_id
      ORDER BY topstories_rank, newstories_rank, beststories_rank),
  last_run_story AS (
  --Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
    SELECT
      run_id,
      story_id,
      topstories_rank,
      beststories_rank,
      newstories_rank,
      status,
      --payload,
      ts_payload,
      run.ts_run,
      status_repeat
    FROM (
      SELECT
        *,
        max(run_id) OVER (PARTITION BY story_id) max_run_id,
        row_number() OVER (PARTITION BY story_id,status ORDER BY story_id,run_id,status ) status_repeat
      FROM hn_ranker.run_story
      ) run_story
      JOIN hn_ranker.run ON run_id=run.id
      WHERE run_id=max_run_id
   ),
  classify_run_story AS (
  --Joining currents ranking vs last run and classifying candidates for fetching additional data
    SELECT
    currval('hn_ranker.run_id_seq'::regclass) run_id,
    COALESCE(current_run_story.story_id,last_run_story.story_id) story_id,
    current_run_story.topstories_rank,
    current_run_story.beststories_rank,
    current_run_story.newstories_rank,
    CASE
      WHEN
        last_run_story.status IS NULL OR
        last_run_story.status='new' AND last_run_story.status_repeat < (param ->> 'new_repeat')::bigint
        THEN 'new'
      WHEN
        last_run_story.status='new' OR
        last_run_story.topstories_rank <= (param ->> 'hot_rank')::bigint OR
        last_run_story.beststories_rank <= (param ->> 'hot_rank')::bigint OR
        (last_run_story.topstories_rank - current_run_story.topstories_rank) > (param ->> 'hot_rankbump')::bigint OR
        (last_run_story.beststories_rank - current_run_story.beststories_rank) > (param ->> 'hot_rankbump')::bigint OR
        (last_run_story.status='hot' AND last_run_story.status_repeat < (param ->> 'hot_repeat')::bigint)
        THEN 'hot'
      WHEN
        last_run_story.topstories_rank <= (param ->> 'tepid_rank')::bigint OR
        last_run_story.beststories_rank <= (param ->> 'tepid_rank')::bigint OR
        last_run_story.newstories_rank <= (param ->> 'tepid_rank')::bigint
        THEN 'tepid'
      WHEN
        last_run_story.status < 'cooling' OR
        (last_run_story.status='cooling' AND last_run_story.status_repeat < (param ->> 'cooling_repeat')::bigint)
        THEN 'cooling'
      WHEN
        last_run_story.status < 'cold' OR
        (last_run_story.status='cold' AND last_run_story.status_repeat < (param ->> 'cold_repeat')::bigint) OR
        last_run_story.status='missing'
        THEN 'cold'                                                     
      ELSE 'frozen'
    END::hn_ranker.story_status status,
    current_run_story.ts_run-last_run_story.ts_run as last_run_story_age
    --,last_run_story.payload as last_run_story_payload                                                           
  FROM current_run_story FULL JOIN last_run_story ON current_run_story.story_id=last_run_story.story_id 
  ),
  filter_run_story AS (
    SELECT *
    FROM classify_run_story
    WHERE
      status <= 'hot' OR
      (status = 'tepid' AND last_run_story_age >= (param ->> 'tepid_age')::interval) OR --'59 min'::interval) OR
      (status = 'cooling' AND last_run_story_age >= (param ->> 'cooling_age')::interval) OR --'1 days'::interval) OR
      (status = 'cold' AND last_run_story_age >= (param ->> 'cold_age')::interval) OR --'7 days'::interval) OR
      (status = 'frozen' AND last_run_story_age >= (param ->> 'frozen_age')::interval) --'1 month'::interval)
  ),
  get_items AS (SELECT * FROM hn_ranker.items((SELECT array_agg(story_id) FROM filter_run_story))),

  insert_run_story AS (
    INSERT INTO hn_ranker.run_story(
      run_id,
      story_id,
      topstories_rank,
      beststories_rank,
      newstories_rank,
      status,
      score,
      descendants,
      ts_payload,
      success
      )
    SELECT 
    filter_run_story.run_id,
    filter_run_story.story_id,
    filter_run_story.topstories_rank,
    filter_run_story.beststories_rank,
    filter_run_story.newstories_rank,
    CASE WHEN get_items.payload = '"json_null"' THEN 'missing' ELSE filter_run_story.status END::hn_ranker.story_status status,
    (get_items.payload ->> 'score')::integer score,
    (get_items.payload ->> 'descendants')::integer descendants,
    /*CASE
    WHEN items.payload IS NULL THEN NULL
    WHEN items.payload - '{"descendants","score"}'::text[] = filter_run_story.last_run_story_payload THEN NULL
    ELSE items.payload - '{"descendants","score"}'::text[] 
    END::jsonb*/
    get_items.ts_end ts_payload,
    CASE WHEN get_items.payload IS NULL THEN false ELSE true END::boolean as success
    FROM filter_run_story LEFT JOIN get_items
    ON filter_run_story.story_id=get_items.id
    RETURNING *
    )
INSERT INTO hn_ranker.error(run_id, object, object_id, report)
SELECT
run_id, 'run_story' as object, story_id::text object_id, row_to_json(get_items)::jsonb
FROM insert_run_story LEFT JOIN get_items ON story_id=get_items.id
WHERE NOT insert_run_story.success OR NOT(get_items.retries = 0);
END;
$BODY$;

-- PROCEDURE: hn_ranker.do_all(text)

-- DROP PROCEDURE hn_ranker.do_all(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_all(
	hnr_config text DEFAULT 'production'::text)
LANGUAGE 'sql'

AS $BODY$
CALL hn_ranker.do_run(hnr_config);
CALL hn_ranker.do_run_story(hnr_config);
$BODY$;

-- View: @extschema@.run_story_stats

CREATE VIEW @extschema@.run_story_stats AS
SELECT run.id run_id,
	array_length(run.topstories,1) topstories_count,
	count(*) FILTER (WHERE run_story.topstories_rank IS NOT NULL) topstories_recorded,
	array_length(run.beststories,1) beststories_count,
	count(*) FILTER (WHERE run_story.beststories_rank IS NOT NULL) beststories_recorded,
	array_length(run.newstories,1) newstories_count,
	count(*) FILTER (WHERE run_story.newstories_rank IS NOT NULL) newstories_recorded,
	count(*) FILTER (WHERE run_story.status='new') new_count,
	count(*) FILTER (WHERE run_story.status='hot') hot_count,
	count(*) FILTER (WHERE run_story.status='tepid') tepid_count,
	count(*) FILTER (WHERE run_story.status='cooling') cooling_count,
	count(*) FILTER (WHERE run_story.status='cold') cold_count,
	count(*) FILTER (WHERE run_story.status='frozen') frozen_count,
	count(*) FILTER (WHERE run_story.status='missing') missing_count,
	(count(*) FILTER (WHERE NOT run_story.success))-(count(*) FILTER (WHERE score IS NULL)) retried_count,
	count(*) FILTER (WHERE score IS NULL) fail_count,
	count(*) total_count,
	ts_run,
	max(ts_payload)-min(ts_run) as fetch_duration
FROM @extschema@.run LEFT JOIN @extschema@.run_story ON run.id=run_story.run_id
	GROUP BY run.id
	ORDER BY run.id desc;
