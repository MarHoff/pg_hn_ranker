-- Table: hn_ranker.story

CREATE TABLE hn_ranker.story
(
    id bigint NOT NULL,
    status hn_ranker.story_status,
    CONSTRAINT story_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);
