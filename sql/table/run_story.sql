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
    payload jsonb,
    ts_payload timestamp with time zone,
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id),
    CONSTRAINT run_story_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES @extschema@.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
);
