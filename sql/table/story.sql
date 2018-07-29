-- Table: @extschema@.story

CREATE TYPE hn_ranker.story_status AS ENUM ('active', 'archived', 'archivable');
CREATE TABLE @extschema@.story
(
    id bigint NOT NULL,
    status @extschema@.story_status,
    title text COLLATE pg_catalog."default",
    by text COLLATE pg_catalog."default",
    hntime timestamp with time zone,
    type text COLLATE pg_catalog."default",
    url text COLLATE pg_catalog."default",
    kids bigint[],
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);
