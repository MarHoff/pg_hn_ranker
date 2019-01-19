EXTENSION = hn_ranker
DATA = $(wildcard *.sql)

DOMAIN := ranking story_status object
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

FUNCTION := max_id rankings item_json items
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

TABLE := run story run_story error
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

VIEW := run_story_stats
VIEW := $(addprefix sql/view/, $(addsuffix .sql, $(VIEW)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

build : hn_ranker--dev.sql

hn_ranker--dev.sql : $(DOMAIN) $(FUNCTION) $(TABLE) $(VIEW)
	@echo 'Building develloper version'
	cat $(DOMAIN) > $@ && cat $(FUNCTION) >> $@ && cat $(TABLE) >> $@ && cat $(VIEW) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
