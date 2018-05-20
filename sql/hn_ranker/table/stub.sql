SET ROLE postgres;

DROP TABLE IF EXISTS hn_ranker.run_story;
DROP TABLE IF EXISTS hn_ranker.story_comment;
DROP TABLE IF EXISTS hn_ranker.story;
DROP TABLE IF EXISTS hn_ranker.run;
DROP SEQUENCE IF EXISTS hn_ranker.run_id_seq;
DROP TYPE IF EXISTS hn_ranker.story_status;

CREATE SEQUENCE IF NOT EXISTS hn_ranker.run_id_seq AS bigint;

CREATE TABLE hn_ranker.run
(
    id bigint NOT NULL DEFAULT nextval('hn_ranker.run_id_seq'::regclass),
    ts_run timestamptz,
    CONSTRAINT run_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE hn_ranker.story
(
    id bigint NOT NULL,
	  status hn_ranker.story_status,
    title text,
    by text,
    hntime timestamptz,
    type text,
    url text,
    kids bigint[],
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);

CREATE TABLE hn_ranker.run_story
(
    run_id bigint NOT NULL,
    story_id bigint NOT NULL,
    descendants integer,
    score integer,
    hnrank integer,
    CONSTRAINT run_story_pkey PRIMARY KEY (run_id,story_id),
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

CREATE TABLE hn_ranker.story_comment
(
    id bigint NOT NULL,
    story_id bigint NOT NULL,
    parent_id bigint,
    hntext text,
    by text,
    hntime timestamptz,
    type text,
    kids bigint[],
    CONSTRAINT story_comment_pkey PRIMARY KEY (id),
  	CONSTRAINT story_comment_story_id_fkey FOREIGN KEY (story_id)
    REFERENCES hn_ranker.story (id) MATCH SIMPLE
    ON UPDATE RESTRICT
    ON DELETE CASCADE,
    CONSTRAINT story_comment_parent_id_fkey FOREIGN KEY (parent_id)
    REFERENCES hn_ranker.story_comment (id) MATCH SIMPLE
    ON UPDATE RESTRICT
    ON DELETE CASCADE
)
WITH (
    OIDS = FALSE
);
