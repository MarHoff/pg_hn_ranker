-- Table: @extschema@.story

CREATE TYPE hn_ranker.story_status AS ENUM ('new','hot','tepid','cold','frozen');
CREATE TABLE @extschema@.story
(
    id bigint NOT NULL,
    status @extschema@.story_status,
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);
