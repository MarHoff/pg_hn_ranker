EXTENSION = hn_ranker
DATA = $(wildcard *.sql)

FRAPI_SHARED := func_get_url
FRAPI_SHARED := $(addprefix SQL/SHARED/, $(addsuffix .sql, $(FRAPI_SHARED)))
#FRAPI_HN_RANKER := type_adresse_search func_adresse_search_format func_adresse_search_json func_adresse_reverse_json func_adresse_search func_adresse_reverse
#FRAPI_HN_RANKER := $(addprefix SQL/ADRESSE/, $(addsuffix .sql, $(FRAPI_HN_RANKER)))

#TESTS = $(wildcard TEST/SQL/*.sql)

usage:
	@echo 'pg_hn_ranker usage : "make install" to instal the extension, "make build" to build dev version against source SQL'

.PHONY : build
build : hn_ranker--dev.sql
	@echo 'Building develloper version'

hn_ranker--dev.sql : $(FRAPI_SHARED) #$(FRAPI_HN_RANKER)
	cat $(FRAPI_SHARED) > $@ #&& cat $(FRAPI_HN_RANKER) >> $@

#test:
#	pg_prove -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
