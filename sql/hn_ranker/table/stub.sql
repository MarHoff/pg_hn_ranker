SET ROLE postgres;

CREATE SEQUENCE IF NOT EXISTS hn_ranker.run_id_seq AS bigint;
DROP TABLE IF EXISTS hn_ranker.run;
CREATE TABLE hn_ranker.run
(
    id bigint NOT NULL DEFAULT nextval('hn_ranker.run_id_seq'::regclass),
    ts timestamp with time zone,
    CONSTRAINT run_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
);

DROP TABLE IF EXISTS hn_ranker.ranks;
CREATE TABLE hn_ranker.ranks
(
    run_id bigint NOT NULL DEFAULT nextval('hn_ranker.run_id_seq'::regclass),
    story_id bigint,
	hnrank bigint,
    CONSTRAINT run_pkey PRIMARY KEY (run_id,story_id)
)
WITH (
    OIDS = FALSE
)