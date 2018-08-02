EXTENSION = hn_ranker
DATA = $(wildcard *.sql)


FUNCTION := max_id best_json top_json new_json item_json items_json
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

TABLE := run story run_story story_comment
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

build : hn_ranker--dev.sql

hn_ranker--dev.sql : $(FUNCTION) $(TABLE)
	@echo 'Building develloper version'
	cat $(FUNCTION) > $@ && cat $(TABLE) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
