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
