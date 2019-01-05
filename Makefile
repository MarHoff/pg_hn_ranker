EXTENSION = hn_ranker
DATA = $(wildcard *.sql)

DOMAIN := ranking story_status
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

FUNCTION := max_id rankings item_json items
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

TABLE := run story run_story
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

build : hn_ranker--dev.sql

hn_ranker--dev.sql : $(DOMAIN) $(FUNCTION) $(TABLE)
	@echo 'Building develloper version'
	cat $(DOMAIN) > $@ && cat $(FUNCTION) >> $@ && cat $(TABLE) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
