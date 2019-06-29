#Changelog

##Version 0.X
- TODO use rulsets in pg_pmwget wrappers
- TODO Implements garbage collector
- TODO Alter schema to avoid redundancy between run and run_story rankings storage

- Stories with 'frozen' or 'unknown' status will be fetched not only based on age parameter but also according to a parametrable daily time windows.
  This is useful after a server failure so that a massive number of olds stories won't be fetched all at once.
  Rule 'frozen_window' will define a time window in seconds so that frozen/unknow story can only be fetched if within widow from same 'seconds past midnight' than last day they were fetched. Maximum value is number of second in a day 86399. If set to 0 no time window is applied and all old enought stories according to 'frozen_age' will be fetched unconditionally.

- Fixing a nasty bug of previous versions, due to a wrong JOIN clause, onlys stories that appeared to at least one ranking were fetched.
  Going further old stories will kept on being fetched according to age parameter
  The upgrade script will include an update statement that will set last run_story of each story that are older than one week will be flagged as 'unknow' to avoid massive fetch after update and use frozen_window mechanism to ease the process.



###Version 0.1.3
- Tuning retries parameters for rankings wrapper
- Adding a proper diagnose_error view
- Removing foreign key for dump/restore performance as we don't handle constraints eception anyway for now

###Version 0.1.2
- Handling case when API return missing or deleted stories
- Improving stats view

###Version 0.1.1
- Hot fix for a parameter


##Version 0.1 
- First deployable realease 


