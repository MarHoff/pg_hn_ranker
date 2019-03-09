-- Name: rules; Type: TABLE; Schema: hn_ranker; Owner: -
--

CREATE TABLE rule (
    ruleset_id text NOT NULL,
    rule text NOT NULL,
    type_val text,
    val text,
    CONSTRAINT rule_pkey PRIMARY KEY (ruleset_id, rule),
    CONSTRAINT rule_ruleset_id_fkey FOREIGN KEY (ruleset_id)
        REFERENCES ruleset (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


INSERT INTO rule (ruleset_id, rule, type_val, val) (VALUES
('debug'::text, 'run_story_param', 'jsonb',
$${
"new_repeat":1,
"hot_repeat":1,
"hot_rank":30,
"hot_rankbump":30,
"tepid_rank":60,
"tepid_age":"1 minute",
"cooling_repeat":1,
"cooling_age":"1 minute",
"cold_repeat":1,
"cold_age":"1 minute",
"frozen_age":"1 minute"
}$$::jsonb),

('production', 'run_story_param', 'jsonb',
$${
"new_repeat":12,
"hot_repeat":6,
"hot_rank":30,
"hot_rankbump":30,
"tepid_rank":60,
"tepid_age":"19 minute",
"cooling_repeat":12,
"cooling_age":"59 minute",
"cold_repeat":1,
"cold_age":"6 hours",
"frozen_age":"60 second"
}$$)
);