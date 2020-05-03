--Create type used in rankings()

CREATE TYPE hn_ranker.ranking AS ENUM ('topstories','beststories','newstories');--Type used in story & run_story

CREATE TYPE hn_ranker.story_status AS ENUM ('new','hot','tepid','cooling','cold','unknown','frozen','missing','failed','deleted','unexpected');--Create type used in object()

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
    topstories_rank integer,  --to be deprecated on next schema upgrade
    beststories_rank integer, --to be deprecated on next schema upgrade
    newstories_rank integer, --to be deprecated on next schema upgrade
    status hn_ranker.story_status,
    score integer,
    descendants bigint,
    ts_payload timestamp with time zone,
    success boolean, --to be deprecated on next schema upgrade
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id)
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
    CONSTRAINT error_pkey PRIMARY KEY (run_id, object, object_id)
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
"tepid_rank":60,
"tepid_age":"1 minute",
"cooling_repeat":1,
"cooling_age":"1 minute",
"cold_repeat":1,
"cold_age":"1 minute",
"failed_repeat":4,
"frozen_age":"1 minute",
"frozen_window":0
}$$::jsonb),

('production', 'run_story_param', 'jsonb',
$${
"new_repeat":12,
"hot_repeat":6,
"hot_rank":30,
"tepid_rank":60,
"tepid_age":"19 minute",
"cooling_repeat":12,
"cooling_age":"59 minute",
"cold_repeat":2,
"cold_age":"6 hour",
"failed_repeat":4,
"frozen_age":"7 day",
"frozen_window":600
}$$)
);--Table utilisateur à sauvegarder
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.error', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.run_story', '');
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.ruleset', $$WHERE id NOT IN ('debug','production')$$);
SELECT pg_catalog.pg_extension_config_dump('hn_ranker.rule', $$WHERE ruleset_id NOT IN ('debug','production')$$);
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.story', '');
--SELECT pg_catalog.pg_extension_config_dump('hn_ranker.items', '');

-- FUNCTION: hn_ranker.time_window(timestamp with time zone, timestamp with time zone, integer)

CREATE OR REPLACE FUNCTION hn_ranker.check_time_window(
	t_new timestamp with time zone,
	t_old timestamp with time zone,
	t_window integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
BEGIN
IF t_window > 86399 OR t_window < 0 THEN
	RAISE EXCEPTION 'Time windows can''t be negative or larger than max seconds past midnight (86399)!';
--ELSE RAISE DEBUG 't_window: %', t_window;
END IF;

--RAISE DEBUG 'age: %', age(t_new,t_old);
--RAISE DEBUG 'second to midnight: %', to_char(age(t_new,t_old),'SSSS');

IF t_window = 0 THEN
	RETURN true;
ELSE
	IF to_char(age(t_new,t_old),'SSSS')::integer < t_window THEN RETURN true;
	ELSE RETURN false;
	END IF;
END IF;

END;
$BODY$;
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
-- FUNCTION: hn_ranker.wget_rankings(extschema@.ranking[])

CREATE OR REPLACE FUNCTION @extschema@.wget_rankings(
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
      r_timeout := 10,
      r_tries := 1,
      r_waitretry := 0,
      r_parallel_jobs := 20,
      r_delimiter := '@wget_token@'::text,
      r_delay := 5,
      batch_size := 2000,
      batch_retries := 2,
      batch_retries_failrate := 1
    )
)
SELECT tid id, tsel.url::url, conv.ids::bigint[], tget.ts_end, tget.duration, tget.batch, tget.retries, tget.batch_failrate
FROM tsel
LEFT JOIN tget ON tsel.url=tget.url
CROSS JOIN LATERAL (SELECT array_agg(a.id::bigint) ids FROM jsonb_array_elements_text(tget.payload::jsonb) WITH ORDINALITY AS a(id, hn_rank)) conv;

END

$BODY$;


-- FUNCTION: hn_ranker.wget_items(bigint[])

CREATE OR REPLACE FUNCTION hn_ranker.wget_items(
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


-- FUNCTION: hn_ranker.build_stories_ranks(text)

-- DROP FUNCTION hn_ranker.build_stories_ranks(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_ranks( v_run_id bigint[] DEFAULT NULL )
RETURNS TABLE (
  run_id bigint,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer,
  ts_run timestamptz
)
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
WITH
  selected_run AS (
    SELECT * FROM hn_ranker.run WHERE v_run_id IS NULL OR id = ANY(v_run_id)
  ),
  unnest_rankings AS (
  --Unesting data from selected_run
    SELECT selected_run.id, 'topstories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.topstories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.id, 'beststories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.beststories) WITH ORDINALITY AS a(story_id, hn_rank)
  UNION ALL
    SELECT selected_run.id, 'newstories' ranking, a.story_id, a.hn_rank, selected_run.ts_run
    FROM selected_run
    CROSS JOIN LATERAL unnest(selected_run.newstories) WITH ORDINALITY AS a(story_id, hn_rank)
  )
--Grouping information by unique story_id for current run
SELECT
      unnest_rankings.id run_id,
      unnest_rankings.story_id story_id,
      min(hn_rank) FILTER (WHERE ranking='topstories')::integer topstories_rank,
      min(hn_rank) FILTER (WHERE ranking='beststories')::integer beststories_rank,
      min(hn_rank) FILTER (WHERE ranking='newstories')::integer newstories_rank,
      unnest_rankings.ts_run
    FROM unnest_rankings
      GROUP BY unnest_rankings.id, unnest_rankings.ts_run, unnest_rankings.story_id;
END;
$BODY$;

-- FUNCTION: hn_ranker.build_stories_status(text)

-- DROP FUNCTION hn_ranker.build_stories_status(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_status(v_run_id bigint DEFAULT NULL )
RETURNS TABLE (
  run_id bigint,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer,
  status hn_ranker.story_status,
  score integer,
  ts_run timestamptz,
  status_repeat integer
)
LANGUAGE 'plpgsql'

AS $BODY$
BEGIN
RETURN QUERY
--Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
WITH
sel_run_story AS (
  SELECT
    run_story.run_id,
    run_story.story_id,
    run_story.status,
    run_story.score,
    max(run_story.run_id) OVER (
      PARTITION BY run_story.story_id
      ) max_run_id,
    row_number() OVER (
      PARTITION BY run_story.story_id,run_story.status
      ORDER BY run_story.story_id,run_story.run_id,run_story.status
      ) status_repeat
  FROM hn_ranker.run_story
  WHERE v_run_id IS NULL OR run_story.run_id <= v_run_id
)
SELECT
    sel_run_story.run_id,
    sel_run_story.story_id,
    array_position(run.topstories, sel_run_story.story_id) topstories_rank,
    array_position(run.beststories, sel_run_story.story_id) beststories_rank,
    array_position(run.newstories, sel_run_story.story_id) newstories_rank,
    sel_run_story.status status,
    sel_run_story.score score,
    --payload,
    run.ts_run ts_run,
    sel_run_story.status_repeat::integer status_repeat
  FROM sel_run_story
    JOIN hn_ranker.run ON sel_run_story.run_id=run.id
  WHERE sel_run_story.run_id=max_run_id;
END;
$BODY$;

-- FUNCTION: hn_ranker.build_stories_classify(text)

-- DROP FUNCTION hn_ranker.build_stories_classify(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_classify( v_run_id bigint DEFAULT NULL, hnr_ruleset text DEFAULT 'production'::text )
RETURNS TABLE (
  run_id bigint,
  ts_run timestamptz,
  story_id bigint,
  topstories_rank integer,
  beststories_rank integer,
  newstories_rank integer,
  last_score integer,
  last_status hn_ranker.story_status,
  last_status_repeat integer,
  last_ts_run timestamptz,
  new_status hn_ranker.story_status,
  fetch_now boolean
)
LANGUAGE 'plpgsql'

AS $BODY$
DECLARE
f_run_id bigint;
f_ts_run timestamptz;
rule jsonb ;
r_new_repeat integer; 
r_hot_repeat integer; 
r_hot_rank integer; 
r_tepid_rank integer; 
r_tepid_age interval; 
r_cooling_repeat integer; 
r_cooling_age interval; 
r_cold_repeat integer; 
r_cold_age interval; 
r_failed_repeat integer; 
r_frozen_age interval;
r_frozen_window integer;
BEGIN
RAISE NOTICE 'hnr_ruleset: %', hnr_ruleset;

SELECT val INTO STRICT rule FROM hn_ranker.rule WHERE rule.ruleset_id=hnr_ruleset AND rule.rule='run_story_param';
IF rule IS NULL THEN RAISE EXCEPTION 'rule "run_story_param" of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'rule: %', rule; END IF;

r_new_repeat := (rule ->> 'new_repeat')::integer;
IF r_new_repeat IS NULL THEN RAISE EXCEPTION 'new_repeat parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_new_repeat: %', r_new_repeat; END IF;
r_hot_repeat := (rule ->> 'hot_repeat')::integer;
IF r_hot_repeat IS NULL THEN RAISE EXCEPTION 'hot_repeat parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_hot_repeat: %', r_hot_repeat; END IF;
r_hot_rank := (rule ->> 'hot_rank')::integer;
IF r_hot_rank IS NULL THEN RAISE EXCEPTION 'hot_rank parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_hot_rank: %', r_hot_rank; END IF;
r_tepid_rank := (rule ->> 'tepid_rank')::integer;
IF r_tepid_rank IS NULL THEN RAISE EXCEPTION 'tepid_rank parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_tepid_rank: %', r_tepid_rank; END IF;
r_tepid_age := (rule ->> 'tepid_age')::interval;
IF r_tepid_age IS NULL THEN RAISE EXCEPTION 'tepid_age parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_tepid_age: %', r_tepid_age; END IF;
r_cooling_repeat := (rule ->> 'cooling_repeat')::integer;
IF r_cooling_repeat IS NULL THEN RAISE EXCEPTION 'cooling_repeat parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_cooling_repeat: %', r_cooling_repeat; END IF;
r_cooling_age := (rule ->> 'cooling_age')::interval;
IF r_cooling_age IS NULL THEN RAISE EXCEPTION 'cooling_age parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_cooling_age: %', r_cooling_age; END IF;
r_cold_repeat := (rule ->> 'cold_repeat')::integer;
IF r_cold_repeat IS NULL THEN RAISE EXCEPTION 'cold_repeat parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_cold_repeat: %', r_cold_repeat; END IF;
r_cold_age := (rule ->> 'cold_age')::interval;
IF r_cold_age IS NULL THEN RAISE EXCEPTION 'cold_age parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_cold_age: %', r_cold_age; END IF;
r_failed_repeat := (rule ->> 'failed_repeat')::integer;
IF r_failed_repeat IS NULL THEN RAISE EXCEPTION 'failed_repeat parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_failed_repeat: %', r_failed_repeat; END IF;
r_frozen_age := (rule ->> 'frozen_age')::interval;
IF r_frozen_age IS NULL THEN RAISE EXCEPTION 'frozen_age parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_frozen_age: %', r_frozen_age; END IF;
r_frozen_window := (rule ->> 'frozen_window')::integer;
IF r_frozen_window IS NULL THEN RAISE EXCEPTION 'frozen_window parameter of ruleset "%" can''t be NULL!', hnr_ruleset; ELSE RAISE NOTICE 'r_frozen_window: %', r_frozen_window; END IF;

IF v_run_id IS NOT NULL THEN f_run_id := v_run_id; ELSE SELECT last_value INTO STRICT f_run_id FROM hn_ranker.run_id_seq; END IF;
RAISE NOTICE 'f_run_id: %', f_run_id;

SELECT run.ts_run INTO STRICT f_ts_run FROM hn_ranker.run WHERE id=f_run_id;

RETURN QUERY
--Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
WITH
  current AS (SELECT * FROM hn_ranker.build_stories_ranks(ARRAY[f_run_id])),
  last AS (SELECT * FROM hn_ranker.build_stories_status(f_run_id-1)),
  classify AS (
  --Joining currents ranking vs last run and classifying candidates for fetching additional data
    SELECT
    f_run_id run_id,
    f_ts_run ts_run,
    COALESCE(current.story_id,last.story_id) story_id,
    current.topstories_rank,
    current.beststories_rank,
    current.newstories_rank,
    last.score last_score,
    last.status last_status,
    last.status_repeat last_status_repeat,
    last.ts_run last_ts_run,
    CASE
      WHEN
        last.status IS NULL OR --If last status is null the story is new
        last.status='new' AND last.status_repeat < r_new_repeat --Repeat new status at least n time according to parameter
        THEN 'new'
      WHEN
        last.status < 'hot' OR --If story was better than hot it fall back to hot when it isn't anymore
        current.topstories_rank <= r_hot_rank OR --If story rank in topstories is over n promote as hot no matter what
        current.beststories_rank <= r_hot_rank OR --If story rank in beststories is over n promote as hot no matter what
        (last.status='hot' AND last.status_repeat < r_hot_repeat) --Repeat hot status at least n time according to parameter
        THEN 'hot'
      WHEN
        current.topstories_rank <= r_tepid_rank OR --If story rank is over n promote as tepid no matter what
        current.beststories_rank <= r_tepid_rank OR --same
        current.newstories_rank <= r_tepid_rank OR  --same
        (last.status IN ('failed','missing') AND last.status_repeat < r_failed_repeat) --If story fetch failed or miss try n time as tepid to confirm
        THEN 'tepid'
      WHEN
        last.status < 'cooling' OR --If story was better than cooling it start cooling when it isn't anymore
        (last.status='cooling' AND last.status_repeat < r_cooling_repeat) --Repeat cooling status at least n time according to parameter
        THEN 'cooling'
      WHEN
        last.status < 'cold' OR --If story was better than cold earlier it's now cold
        (last.status='cold' AND last.status_repeat < r_cold_repeat) --Repeat cold status at least n time according to parameter
        THEN 'cold'
      WHEN
        last.status <= 'frozen' --If story was better or equal than frozen earlier it's now in the fridge
        THEN 'frozen'                                                     
      ELSE 'unexpected'
    END::hn_ranker.story_status new_status
    --,last.payload as last_payload                                                           
  FROM current FULL JOIN last ON current.story_id=last.story_id 
  )
SELECT
  classify.run_id,
  classify.ts_run,
  classify.story_id,
  classify.topstories_rank,
  classify.beststories_rank,
  classify.newstories_rank,
  classify.last_score,
  classify.last_status,
  classify.last_status_repeat,
  classify.last_ts_run,
  classify.new_status,
  (
    classify.new_status <= 'hot' OR --Always fetch hot & new stories
    classify.new_status < classify.last_status OR--Alaways fetch if status is promoted
    (classify.new_status = 'tepid' AND age(classify.ts_run,classify.last_ts_run) >= r_tepid_age) OR --Fetch if older than age rule
    (classify.new_status = 'cooling' AND age(classify.ts_run,classify.last_ts_run) >= r_cooling_age) OR --Fetch if older than age rule
    (classify.new_status = 'cold' AND age(classify.ts_run,classify.last_ts_run) >= r_cold_age) OR --Fetch if older than age rule
    (
      classify.new_status IN ('unknown','frozen') AND --For frozen and unknow status...
      age(classify.ts_run,classify.last_ts_run) >= r_frozen_age AND --Fetch if older than age rule...
      hn_ranker.check_time_window(classify.ts_run,classify.last_ts_run,r_frozen_window) --AND if within daily time windows from last fetch
    )
  ) AS fetch_now
FROM classify
;
END;
$BODY$;

-- PROCEDURE: hn_ranker.do_run(text)

-- DROP PROCEDURE hn_ranker.do_run(text);

CREATE OR REPLACE PROCEDURE hn_ranker.do_run(
	hnr_config text DEFAULT 'production'::text)
LANGUAGE 'sql'

AS $BODY$
WITH
get_rankings AS (SELECT * FROM hn_ranker.wget_rankings('{topstories,beststories,newstories}')),
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
  classify_fetch_now AS (SELECT * FROM  hn_ranker.build_stories_classify(currval('hn_ranker.run_id_seq'::regclass), hnr_ruleset) WHERE fetch_now),
  get_items AS (SELECT * FROM hn_ranker.wget_items((SELECT array_agg(story_id) FROM classify_fetch_now))),
  insert_run_story AS (
    INSERT INTO hn_ranker.run_story(
      run_id,
      story_id,
      status,
      score,
      descendants,
      ts_payload
      )
    SELECT 
    classify_fetch_now.run_id,
    classify_fetch_now.story_id,
    CASE
      WHEN (get_items.payload ->> 'deleted') = 'true' THEN 'deleted'
      WHEN get_items.payload = '"json_null"' THEN 'missing'
      WHEN get_items.payload IS NULL THEN 'failed'
      ELSE classify_fetch_now.new_status END::hn_ranker.story_status status,
    (get_items.payload ->> 'score')::integer score,
    (get_items.payload ->> 'descendants')::integer descendants,
    /*CASE
    WHEN items.payload IS NULL THEN NULL
    WHEN items.payload - '{"descendants","score"}'::text[] = classify_fetch_now.last_payload THEN NULL
    ELSE items.payload - '{"descendants","score"}'::text[] 
    END::jsonb*/
    get_items.ts_end ts_payload
    FROM classify_fetch_now LEFT JOIN get_items
    ON classify_fetch_now.story_id=get_items.id
    RETURNING *
    )
INSERT INTO hn_ranker.error(run_id, object, object_id, report)
SELECT
run_id, 'run_story' as object, story_id::text object_id, row_to_json(get_items)::jsonb
FROM insert_run_story LEFT JOIN get_items ON story_id=get_items.id
WHERE insert_run_story.status >= 'deleted' OR NOT(get_items.retries = 0);
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
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.topstories_rank IS NOT NULL), COALESCE(array_length(run.topstories,1)::text,'error')) AS topstories,
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.beststories_rank IS NOT NULL), COALESCE(array_length(run.beststories,1)::text,'error')) AS beststories,
	format('%1$s/%2$s',count(*) FILTER (WHERE run_story.newstories_rank IS NOT NULL), COALESCE(array_length(run.newstories,1)::text,'error')) AS newstories,
	count(*) FILTER (WHERE run_story.status='new') AS new,
	count(*) FILTER (WHERE run_story.status='hot') AS hot,
	count(*) FILTER (WHERE run_story.status='tepid') AS tepid,
	count(*) FILTER (WHERE run_story.status='cooling') AS cooling,
	count(*) FILTER (WHERE run_story.status='cold') AS cold,
	count(*) FILTER (WHERE run_story.status='frozen') AS frozen,
	count(*) FILTER (WHERE run_story.status='deleted') AS deleted,
	count(*) FILTER (WHERE run_story.status='missing') AS missing,
	count(*) FILTER (WHERE run_story.status='failed') AS failed,
	(count(*) FILTER (WHERE (error.report ->> 'retries')::integer > 0)) AS retried_count,
	count(*) AS total_count,
	ts_run,
	max(ts_payload)-min(ts_run) as fetch_duration
FROM @extschema@.run
LEFT JOIN @extschema@.run_story ON run.id=run_story.run_id
LEFT JOIN @extschema@.error ON run_story.run_id=error.run_id AND error.object='run_story' AND run_story.story_id=error.object_id::bigint
GROUP BY run.id
ORDER BY run.id desc;
-- View: @extschema@.diagnose_errors

CREATE VIEW @extschema@.diagnose_errors AS
WITH run AS (SELECT max(id) FROM hn_ranker.run)
SELECT
e.run_id,
e.object,
e.object_id,
rs.status,
format('%1$s/%2$s/%3$s',
		coalesce(topstories_rank::text,'*'),
		coalesce(beststories_rank::text,'*'),
		coalesce(newstories_rank::text,'*')
) rankings,
rs.score,
(e.report ->> 'ts_end')::timestamptz ts_end,
(e.report ->> 'duration')::numeric duration,
(e.report ->> 'retries')::integer retries,
(e.report ->> 'batch_failrate')::numeric batch_failrate,
(e.report ->> 'url') url,
jsonb_pretty(e.report -> 'payload')
FROM hn_ranker.error e
LEFT JOIN hn_ranker.run_story rs ON e.object='run_story' AND e.run_id=rs.run_id AND e.object_id::text=rs.story_id::text
--WHERE object='run_story' --AND retries = 0
ORDER BY object, run_id, object_id