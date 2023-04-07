--Create type used in error table to distinguish wich step function

CREATE TYPE hn_ranker.error_source AS ENUM ('run','run_story');