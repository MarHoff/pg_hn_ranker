-- Table: hn_ranker.run

CREATE SEQUENCE IF NOT EXISTS hn_ranker.run_id_seq AS bigint;
CREATE TABLE hn_ranker.run
(
    id bigint NOT NULL DEFAULT nextval('hn_ranker.run_id_seq'::regclass),
    ts_run timestamp with time zone,
    topstories bigint[],
    beststories bigint[],
    newstories bigint[],
    ts_end timestamp with time zone,
    CONSTRAINT run_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
;
