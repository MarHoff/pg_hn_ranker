#This Makefile for a PostgreSQL extension is based on pg_pmbuildex building framework
#This line include pre-script that make available numerous shortcuts and recipe to use in you Makefile
include pg_gitbuildext.premake


##########################################################################################
# Mandatory parameters                                                                   #
##########################################################################################

#General information about the extension
EXTENSION := pg_hn_ranker
EXTENSION_SCHEMA := hn_ranker

#Versioning management
LASTRELEASE    := 0.1.4
CURRENTRELEASE := 0.1.5

#Parameters for deploying test database
TESTDATABASE := pg_hn_ranker_test
TESTUSER := postgres


##########################################################################################
# Mandatory recipes                                                                      #
##########################################################################################

#Recipe to build the ccontrol file of the extension
$(BUILD_EXTENSION_CONTROL) :
	@echo 'Building $(BUILD_EXTENSION_CONTROL)'
	@echo "# $(EXTENSION) extension" > $@ && \
	echo "comment = 'Side project to gather data about hn post ranking evolution'" >> $@ && \
	echo "default_version = '$(CURRENTRELEASE)'" >> $@ && \
	echo "relocatable = false" >> $@ && \
	echo "schema = $(EXTENSION_SCHEMA)" >> $@ && \
	echo "requires = 'plsh, pmwget'" >> $@

#Recipe to build current release instalation script
$(BUILD_MAIN_SCRIPT) : $(DOMAIN) $(TABLE) $(FUNCTION) $(VIEW)
	@echo 'Building $(BUILD_MAIN_SCRIPT)'
	@cat $(DOMAIN) > $@ && \
	cat $(TABLE) >> $@ && \
	cat $(FUNCTION) >> $@ && \
	cat $(VIEW) >> $@

#Recipe to build upgrade script from last release to current release
#Keep recipe empty if not needed
$(BUILD_UPDATE_SCRIPT) :
	@echo 'Building $(BUILD_UPDATE_SCRIPT)'
	@echo 'No upgrade script defined yet!'


##########################################################################################
# Additional content                                                                     #
##########################################################################################

#Any 
DOMAIN := ranking story_status object
DOMAIN := $(addprefix sql/domain/, $(addsuffix .sql, $(DOMAIN)))

TABLE := run story run_story error ruleset rule config_dump
TABLE := $(addprefix sql/table/, $(addsuffix .sql, $(TABLE)))

FUNCTION := check_time_window max_id wget_rankings wget_items build_stories_ranks build_stories_status build_stories_classify do_run do_run_story do_all
FUNCTION := $(addprefix sql/function/, $(addsuffix .sql, $(FUNCTION)))

VIEW := run_story_stats diagnose_errors
VIEW := $(addprefix sql/view/, $(addsuffix .sql, $(VIEW)))


#This line include post-script that perform the actual build & deployement + link PGXS
include pg_gitbuildext.postmake