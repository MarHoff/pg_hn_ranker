-- Table: hn_ranker.run_story

CREATE TABLE hn_ranker.run_story
(
    run_id bigint NOT NULL,
    story_id bigint NOT NULL,
    descendants integer,
    score integer,
    hnrank integer,
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id, story_id),
    CONSTRAINT run_story_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES hn_ranker.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT run_story_story_id_fkey FOREIGN KEY (story_id)
        REFERENCES hn_ranker.story (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
);