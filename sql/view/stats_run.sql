-- View: hn_ranker.stats_run

CREATE VIEW hn_ranker.stats_run AS
SELECT 
to_char(now(),'YYYY-MM-DD HH24:MI:SS') as pointage,
pg_read_file('/etc/hostname') hostname, --Must run as superuser
current_catalog as database,
max(ts_run)-max(ts_run) AT TIME ZONE 'UTC' diff_utc,
to_char(min(ts_run) AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') min_ts_utc,
to_char(max(ts_run) AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') max_ts_utc,
(SELECT extversion FROM pg_catalog.pg_extension WHERE extname='pg_hn_ranker') extversion,
(max(ts_run) AT TIME ZONE 'UTC' - min(ts_run) AT TIME ZONE 'UTC')::text durée_activite
FROM hn_ranker.run;