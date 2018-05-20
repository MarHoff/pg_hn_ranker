EXTENSION = hn_ranker
DATA = $(wildcard *.sql)

FRAPI_SHARED := func_get_url
FRAPI_SHARED := $(addprefix sql/shared/, $(addsuffix .sql, $(FRAPI_SHARED)))

FUNCTION := func_best_json func_top_json func_item_json
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

TABLE := run story run_story story_comment
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

.PHONY : build
build : hn_ranker--dev.sql
	@echo 'Building develloper version'

hn_ranker--dev.sql : $(FRAPI_SHARED) #$(FRAPI_HN_RANKER)
	cat $(FRAPI_SHARED) > $@ && cat $(FUNCTION) >> $@ && cat $(TABLE) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
