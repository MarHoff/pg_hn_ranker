-- Table: hn_ranker.story_comment

CREATE TABLE hn_ranker.story_comment
(
    id bigint NOT NULL,
    story_id bigint NOT NULL,
    parent_id bigint,
    hntext text COLLATE pg_catalog."default",
    by text COLLATE pg_catalog."default",
    hntime timestamp with time zone,
    type text COLLATE pg_catalog."default",
    kids bigint[],
    CONSTRAINT story_comment_pkey PRIMARY KEY (id),
    CONSTRAINT story_comment_parent_id_fkey FOREIGN KEY (parent_id)
        REFERENCES hn_ranker.story_comment (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE,
    CONSTRAINT story_comment_story_id_fkey FOREIGN KEY (story_id)
        REFERENCES hn_ranker.story (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE
)
WITH (
    OIDS = FALSE
);