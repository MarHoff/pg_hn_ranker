-- Table: @extschema@.story

CREATE TABLE @extschema@.story
(
    id bigint NOT NULL,
    status @extschema@.story_status,
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);
