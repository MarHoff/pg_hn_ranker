--Placeholder for old_drop
Should erase temp table and do post clean

DROPPER tous les éléments de l'extension ce truc est un stub pqrtir de lq pour trouver les objet
Les join c'est crade vaudrait mieux faire une union

SELECT
CASE
  WHEN c.oid IS NOT NULL THEN 'TABLE'
  WHEN p.oid IS NOT NULL THEN 'ROUTINE'
  WHEN t.oid IS NOT NULL THEN 'TYPE'
END AS type_depend,
coalesce(c.relname,p.proname,t.typname) AS oname,
coalesce(c.relnamespace,p.pronamespace,t.typnamespace) AS onamespace,
*
FROM
pg_catalog.pg_extension e
JOIN pg_depend d
  ON e.oid=d.refobjid
LEFT JOIN pg_class c ON d.objid=c.oid
LEFT JOIN pg_proc p ON d.objid=p.oid
LEFT JOIN pg_type t ON d.objid=t.oid
LEFT JOIN pg_namespace ON 

WHERE extname='pg_hn_ranker';