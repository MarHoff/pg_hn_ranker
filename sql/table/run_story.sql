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
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id)
)
WITH (
    OIDS = FALSE
);
