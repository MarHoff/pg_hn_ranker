-- Table: @extschema@.run

CREATE SEQUENCE IF NOT EXISTS @extschema@.run_id_seq AS bigint;
CREATE TABLE @extschema@.run
(
    id bigint NOT NULL DEFAULT nextval('@extschema@.run_id_seq'::regclass),
    ts_run timestamp with time zone DEFAULT now(),
    topstories bigint[],
    beststories bigint[],
    newstories bigint[],
    max_id bigint,
    CONSTRAINT run_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
;
