SELECT 
FORMAT ($$ALTER TABLE %1$s DROP CONSTRAINT %2$s;$$, conrelid::regclass, conname) pre_update,
NULL post_update
FROM pg_constraint WHERE connamespace = 'hn_ranker'::regnamespace
UNION ALL
SELECT 
FORMAT ($$ALTER TABLE %1$s RENAME TO %2$s_migrate; $$,oid::regclass::text, relname) pre_update,
FORMAT ($$INSERT INTO %1$s SELECT * FROM %1$s_migrate; DROP TABLE %1$s_migrate;$$,oid::regclass::text, relname) post_update
from pg_class WHERE relnamespace = 'hn_ranker'::regnamespace and relkind='r'
