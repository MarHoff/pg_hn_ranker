-- Name: ruleset; Type: TABLE; Schema: hn_ranker; Owner: -
--

CREATE TABLE ruleset (
    id text NOT NULL,
    CONSTRAINT ruleset_pkey PRIMARY KEY (id)

);


INSERT INTO ruleset (id) (VALUES
('debug'),
('production_default')
);