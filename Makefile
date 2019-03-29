EXTENSION = pg_hn_ranker
DATA = $(wildcard releases/*.sql)

DOMAIN := ranking story_status object
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

TABLE := run story run_story error ruleset rule config_dump
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

FUNCTION := max_id rankings item_json items do_run do_run_story do_all
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

VIEW := run_story_stats diagnose_errors
VIEW := $(addprefix sql/view/, $(addsuffix .sql, $(VIEW)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

build : releases/pg_hn_ranker--dev.sql

releases/pg_hn_ranker--dev.sql : $(DOMAIN) $(TABLE) $(FUNCTION) $(VIEW)
	@echo 'Building develloper version'
	cat $(DOMAIN) > $@ && cat $(TABLE) >> $@ && cat $(FUNCTION) >> $@ && cat $(VIEW) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
