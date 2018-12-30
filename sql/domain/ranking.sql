CREATE DOMAIN hn_ranker.ranking AS text NOT NULL
    CONSTRAINT ranking_check CHECK
    (VALUE IN ('beststories','newstories','topstories'))
;
