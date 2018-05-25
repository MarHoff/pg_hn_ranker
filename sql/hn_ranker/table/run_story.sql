-- Table: @extschema@.run_story

CREATE TABLE @extschema@.run_story
(
    run_id bigint NOT NULL,
    story_id bigint NOT NULL,
    descendants integer,
    score integer,
    toprank integer,
    bestrank integer,
    newrank integer,
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id),
    CONSTRAINT run_story_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES @extschema@.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
);
