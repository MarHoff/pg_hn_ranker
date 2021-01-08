-- FUNCTION: hn_ranker.build_stories_classify(text)

-- DROP FUNCTION hn_ranker.build_stories_classify(text);

CREATE OR REPLACE FUNCTION hn_ranker.build_stories_classify( v_ts_run timestamptz DEFAULT NULL, hnr_ruleset text DEFAULT 'production'::text )
RETURNS TABLE (
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
f_ts_run timestamptz;
f_ts_lastrun timestamptz;
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

IF v_ts_run IS NOT NULL THEN f_ts_run := v_ts_run; ELSE SELECT max(ts_run) INTO STRICT f_ts_run FROM hn_ranker.ts_run_seq; END IF;
RAISE NOTICE 'f_ts_run: %', f_ts_run;

--Getting last run that actually returned run_story records
SELECT ts_run INTO STRICT f_ts_last_run FROM hn_ranker.run_story
WHERE ts_run < f_ts_run
GROUP BY ts_run ORDER BY ts_run DESC
LIMIT 1;

RETURN QUERY
--Looking for candidates in last recorded run_story, gathering last status and "age" (in run) of that status
WITH
  current AS (SELECT * FROM hn_ranker.build_stories_ranks(ARRAY[f_ts_run])),
  last AS (SELECT * FROM hn_ranker.build_stories_status(f_ts_last_run)),
  classify AS (
  --Joining currents ranking vs last run and classifying candidates for fetching additional data
    SELECT
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

