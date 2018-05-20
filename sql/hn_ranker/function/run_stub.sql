--DROP EXTENSION hn_ranker;
--CREATE EXTENSION hn_ranker;

INSERT INTO hn_ranker.run  (ts_run, top_json, best_json)
SELECT now(), hn_ranker.top_json() , hn_ranker.best_json();

SELECT * FROM hn_ranker.run;