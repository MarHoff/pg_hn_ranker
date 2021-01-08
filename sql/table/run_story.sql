-- Table: @extschema@.run_story

CREATE TABLE @extschema@.run_story
(
    ts_run timestamptz NOT NULL,
    story_id bigint NOT NULL,
    status hn_ranker.story_status,
    score integer,
    descendants bigint,
    ts_payload timestamp with time zone,
    CONSTRAINT run_story_pkey PRIMARY KEY (ts_run, story_id)
)
WITH (
    OIDS = FALSE
);
