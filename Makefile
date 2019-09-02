#This Makefile is a standard pg_pmbuildext building framework for a PostgreSQL extension
#Dont edit this file directly edit pg_pmbuildext.makefile instead
#Copyright Martin Hoffmann 2019 - Version 0.2

SHELL = /bin/sh
DATA = $(wildcard releases/*.sql)
EXTRA_CLEAN = $(wildcard releases/*dev*.sql)
TESTS = $(wildcard test/sql/*.sql)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT := $(shell git rev-parse --short HEAD)
BUILD := $(if $(findstring $(BRANCH), master release),$(CURRENTRELEASE),dev_$(COMMIT))

.PHONY : test_backup test_deploy test_restore installcheck splash parameters

usage : splash
	@echo 'Usage :'
	@echo '       "make install" : install the extension through PGXS'
	@echo '         "make build" : build/rebuild against source SQL'
	@echo '    "make parameters" : check current active pg_pmbuildext parameters'
	@echo '   "make test_deploy" : wipe and deploy extension for developement purpose in a test database'
	@echo '   "make test_backup" : backup data-only dump of the extension FROM test database'
	@echo '  "make test_restore" : restore data-only dump of the extension TO test database'
	@echo '  "make installcheck" : run pg_prove test against test database'
	@echo

BUILD_MAIN_SCRIPT = releases/$(EXTENSION)--$(BUILD).sql
BUILD_UPDATE_SCRIPT = releases/$(EXTENSION)--$(LASTRELEASE)--$(BUILD).sql
BUILD_EXTENSION_CONTROL = $(EXTENSION).control
BUILD_MAKEFILE := Makefile pg_pmbuildext.makefile

include pg_pmbuildext.makefile

build : splash parameters $(BUILD_EXTENSION_CONTROL) $(BUILD_MAIN_SCRIPT) $(BUILD_UPDATE_SCRIPT)


test_backup :
	sudo -u $(TESTUSER) pg_dump --format=c --no-owner --no-privileges --no-tablespaces --schema "hn_ranker" $(TESTDATABASE) > pg_hn_ranker.bak

test_deploy :
	$(MAKE) build
	sudo $(MAKE) install
	sudo -u $(TESTUSER) psql -c "DROP DATABASE IF EXISTS $(TESTDATABASE);"
	sudo -u $(TESTUSER) psql -c "CREATE DATABASE $(TESTDATABASE);"
	sudo -u $(TESTUSER) psql -d $(TESTDATABASE) -c "CREATE EXTENSION $(EXTENSION) VERSION '$(BUILD)' CASCADE;"

test_restore : test_deploy
	sudo -u $(TESTUSER) psql -d $(TESTDATABASE) -f pg_hn_ranker.bak
	sudo -u $(TESTUSER) psql -d $(TESTDATABASE) -c "SELECT setval('$(EXTENSION_SCHEMA).run_id_seq', (SELECT max(id) FROM $(EXTENSION_SCHEMA).run), true);"

installcheck:
	sudo -u $(TESTUSER) psql -d $(TESTDATABASE) -c "CREATE EXTENSION IF NOT EXISTS pgtap;"
	sudo -u $(TESTUSER) pg_prove -d $(TESTDATABASE) -v --pset tuples_only=1 $(TESTS)

splash :
	@echo '****************************************************'
	@echo 'Build system for PostgreSQL extension $(EXTENSION) '
	@echo 'Powered by pg_pmbuildext building framework Version 0.1'
	@echo '****************************************************'

parameters: splash
	@echo 'Commit $(COMMIT) on branch $(BRANCH)'
	@echo '****************************************************'
	@echo '              EXTENSION : $(EXTENSION)'
	@echo '       EXTENSION_SCHEMA : $(EXTENSION_SCHEMA)'
	@echo '            LASTRELEASE : $(LASTRELEASE)'
	@echo '         CURRENTRELEASE : $(CURRENTRELEASE)'
	@echo '                  BUILD : $(BUILD)'
	@echo 'BUILD_EXTENSION_CONTROL : $(BUILD_EXTENSION_CONTROL)'
	@echo '      BUILD_MAIN_SCRIPT : $(BUILD_MAIN_SCRIPT)'
	@echo '    BUILD_UPDATE_SCRIPT : $(BUILD_UPDATE_SCRIPT)'
	@echo
	@echo '           TESTDATABASE : $(TESTDATABASE)'
	@echo '               TESTUSER : $(TESTUSER)'
	@echo

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
