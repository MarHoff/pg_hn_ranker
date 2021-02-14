-- Table: hn_ranker.error

CREATE TABLE hn_ranker.error
(
    ts_run timestamptz NOT NULL,
    object hn_ranker.object,
    object_id text,
    report jsonb,
    CONSTRAINT error_pkey PRIMARY KEY (ts_run, object, object_id)
)
WITH (
    OIDS = FALSE
);
