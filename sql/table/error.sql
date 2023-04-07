-- Table: hn_ranker.error

CREATE TABLE hn_ranker.error
(
    ts_run timestamptz NOT NULL,
    error_source hn_ranker.error_source,
    source_id text,
    report jsonb,
    CONSTRAINT error_pkey PRIMARY KEY (ts_run, error_source, source_id)
)
WITH (
    OIDS = FALSE
);
