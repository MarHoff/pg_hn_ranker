# Changelog

## Version 0.1.6 (next)
- Schema change! Adding extversion and ruleset_id to the run table to help merging data from distinct instances

- As timestamp is now the id building a more robust way to propagate ts_run from do_run() to do_run_story()
  It is now explicit while past behavior relied on the now() function returning same value inside a transaction.

- Rework tests to be sorted by name and adjust to schema changes + don't drop database after tests for debug (still dropped before)

- TODO Add a target for and Postgresql Extension upgrade script between previous release and current build
- TODO use rulsets in pg_pmwget wrappers
- TODO Implement a garbage collector : Once a story reach frozen state it should be possible to reclaim storage space by replacing
- TODO Investigate opportunity to introduce submodules for pm_wget and pg_gitbuildext


## Version 0.1.5
- Switching to a timestamp based natural primary key to identify each run instead of a run_id (PK serial)
  This should dramatically help merging dataset when if needed because you don't have to care about run_id (PK) collision anymore.

- Refactoring the build system which is now called pg_gitbuildext
  The main extension logic is now moved back to the main Makefile
  The framework logic is splitted into two files "pg_gitbuildext.premake" and "pg_gitbuildext.postmake" which are included from the main Makefile.
  Until it should gracefully handle git branch logic for naming target:
    - When in branch main/master/release the build target will reflect the "current_realease" variable of the main Makefile
      It is recomended to bump version as soon as you start a new dev cycle, that way a bare CREATE EXTENSION (without version) instruction from a dev branch will fail.
    - When in any otherly named branch the build target will correpond to the current short git hash of the branch HEAD prefixed wit dev (eg : dev_2c01fff )
      If testing recipes are invoked (test_deploy/testbackup/test_restore/installcheck) they will automatically pick the extension version correponding to current hash

- Extension is now non-relocatable and use fixed shema name
- When using "test_deploy" command if extension creation fail it'll run again as an unpackaged script to provide more usefull error messages
- Updating test_backup and test_restore recipes to use pg_dump custom format instead of plain SQL
- Adding a dummy upgrade path from 'dev_2c01fff' version number to the clean '0.1.5' release wich is codewise equivalent
- Various minors enhancement of buildsystem and tests


## Version 0.1.4
- Altering schema to avoid redundancy between run and run_story rankings storage
  Dropping theses columns on table run_story : topstories_rank, beststories_rank, newstories_rank, success

- Refactoring code of the previously monolithic do_run_story function into multiple more easily testable and reusable functions

- Fixing a nasty bug of previous versions, due to a wrong JOIN clause, onlys stories that appeared to at least one ranking were fetched.
  Going further old stories will kept on being fetched according to age parameter
  The upgrade script will include an update statement that will set last run_story of each story that are older than one week will be flagged as 'unknow' to avoid massive fetch after update and use frozen_window mechanism to ease the process.

- Reworking Makefile build system to prefigure a cross-software building framework pg_pmbuildext.
  Versioning and configuration is now handled in a sub-makefile "pg_pmbuildext.makefile"

  Usage :
       "make install" : install the extension through PGXS
         "make build" : build/rebuild against source SQL
    "make parameters" : check current active pg_pmbuildext parameters
   "make test_deploy" : wipe and deploy extension for developement purpose in a test database
   "make test_backup" : backup data-only dump of the extension FROM test database
  "make test_restore" : restore data-only dump of the extension TO test database
  "make installcheck" : run pg_prove test against test database

- Stories with 'frozen' or 'unknown' status will be fetched not only based on age parameter but also according to a parametrable daily time windows.
  This is useful after a server failure so that a massive number of olds stories won't be fetched all at once.
  Rule 'frozen_window' will define a time window in seconds so that frozen/unknow story can only be fetched if within widow from same 'seconds past midnight' than last day they were fetched. Maximum value is number of second in a day 86399. If set to 0 no time window is applied and all old enought stories according to 'frozen_age' will be fetched unconditionally.

- Introducing test with a rather minimalist intial coverage
  calls them using 'make installcheck'
  It expect that an application is deployed on a database called 'develop' (typically using make do_reinstall)


### Version 0.1.3
- Tuning retries parameters for rankings wrapper
- Adding a proper diagnose_error view
- Removing foreign key for dump/restore performance as we don't handle constraints exception anyway for now

### Version 0.1.2
- Handling case when API return missing or deleted stories
- Improving stats view

### Version 0.1.1
- Hot fix for a parameter


## Version 0.1 
- First deployable realease 


