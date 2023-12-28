-- Name: rules; Type: TABLE; Schema: hn_ranker; Owner: -
--

CREATE TABLE rules (
    ruleset_id text NOT NULL,
    id text NOT NULL,
    type_val text,
    val text,
    CONSTRAINT rule_pkey PRIMARY KEY (ruleset_id, id),
    CONSTRAINT rule_ruleset_id_fkey FOREIGN KEY (ruleset_id)
        REFERENCES ruleset (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


INSERT INTO rules (ruleset_id, id, type_val, val) (VALUES
('debug'::text, 'run_story_param', 'jsonb',
$${
"new_repeat":1,
"hot_repeat":1,
"hot_rank":30,
"tepid_rank":60,
"tepid_age":"1 minute",
"cooling_repeat":1,
"cooling_age":"1 minute",
"cold_repeat":1,
"cold_age":"1 minute",
"failed_repeat":4,
"frozen_age":"1 minute",
"frozen_window":0
}$$::jsonb),

('production_default', 'run_story_param', 'jsonb',
$${
"new_repeat":12,
"hot_repeat":6,
"hot_rank":30,
"tepid_rank":60,
"tepid_age":"19 minute",
"cooling_repeat":12,
"cooling_age":"59 minute",
"cold_repeat":2,
"cold_age":"6 hour",
"failed_repeat":4,
"frozen_age":"7 day",
"frozen_window":600
}$$)
);