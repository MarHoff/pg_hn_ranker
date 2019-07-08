EXTENSION = pg_hn_ranker
DATA = $(wildcard releases/*.sql)

DOMAIN := ranking story_status object
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

TABLE := run story run_story error ruleset rule config_dump
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

FUNCTION := check_time_window max_id wget_rankings wget_items build_stories_ranks build_stories_status build_stories_classify do_run do_run_story do_all
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

VIEW := run_story_stats diagnose_errors
VIEW := $(addprefix sql/view/, $(addsuffix .sql, $(VIEW)))

TESTS = $(wildcard test/sql/*.sql)

usage:
	@echo 'pg_hn_ranker usage :'
	@echo '  "make install" to instal the extension'
	@echo '  "make build" to build dev version against source SQL'
	@echo '  "make do_backup" to backup curent data-only dump of the extension in custom format'
	@echo '  "make do_reinstall" to wipe and reinstal extension'
	@echo '  "make do_restore" to wipe and reinstal extension then restore previous backup'



build : releases/pg_hn_ranker--dev.sql

releases/pg_hn_ranker--dev.sql : $(DOMAIN) $(TABLE) $(FUNCTION) $(VIEW)
	@echo 'Building develloper version'
	cat $(DOMAIN) > $@ && cat $(TABLE) >> $@ && cat $(FUNCTION) >> $@ && cat $(VIEW) >> $@

.PHONY : installcheck do_backup do_reinstall do_restore

do_backup :
	sudo -u postgres pg_dump --format=p --data-only --no-owner --no-privileges --no-tablespaces --schema "hn_ranker" "develop" > pg_hn_ranker.bak

do_reinstall :
	$(MAKE) build
	$(MAKE) install
	sudo -u postgres psql -d develop -c "DROP EXTENSION IF EXISTS pg_hn_ranker;"
	sudo -u postgres psql -d develop -c "CREATE EXTENSION pg_hn_ranker;"

do_restore : do_reinstall
	sudo -u postgres psql -d develop -f pg_hn_ranker.bak
	sudo -u postgres psql -d develop -c "SELECT setval('hn_ranker.run_id_seq', (SELECT max(id) FROM hn_ranker.run), true);"

installcheck:
	pg_prove -d develop -v --pset tuples_only=1 $(TESTS)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
