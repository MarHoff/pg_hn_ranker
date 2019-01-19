-- Table: @extschema@.error

CREATE TABLE @extschema@.error
(
    run_id bigint NOT NULL,
    object hn_ranker.object,
    object_id text,
    report jsonb,
    CONSTRAINT error_pkey PRIMARY KEY (run_id, object, object_id),
    CONSTRAINT error_run_id_fkey FOREIGN KEY (run_id)
        REFERENCES @extschema@.run (id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
WITH (
    OIDS = FALSE
);
