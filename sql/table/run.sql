-- Table: hn_ranker.run

CREATE TABLE hn_ranker.run
(
    ts_run timestamptz NOT NULL,
    topstories bigint[],
    beststories bigint[],
    newstories bigint[],
    ts_end timestamp with time zone,
    CONSTRAINT run_pkey PRIMARY KEY (ts_run)
)
WITH (
    OIDS = FALSE
)
;
