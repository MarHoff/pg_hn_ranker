EXTENSION = pg_hn_ranker
DATA = $(wildcard releases/*.sql)

DOMAIN := ranking story_status object
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

TABLE := run story run_story error ruleset rule config_dump
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

FUNCTION := max_id wget_rankings wget_items build_stories_ranks build_stories_last build_stories_fetch do_run do_run_story do_all
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

VIEW := run_story_stats diagnose_errors
VIEW := $(addprefix sql/view/, $(addsuffix .sql, $(VIEW)))

TESTS = $(wildcard test/sql/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

build : releases/pg_hn_ranker--dev.sql

releases/pg_hn_ranker--dev.sql : $(DOMAIN) $(TABLE) $(FUNCTION) $(VIEW)
	@echo 'Building develloper version'
	cat $(DOMAIN) > $@ && cat $(TABLE) >> $@ && cat $(FUNCTION) >> $@ && cat $(VIEW) >> $@

.PHONY : installcheck
installcheck:
	pg_prove -d develop -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
