-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.get_urls(
    urls text[],
    wait numeric,
    timeout numeric,
    tries integer DEFAULT 3,
    workers integer DEFAULT 10,
    delimiter text DEFAULT '@frapi_token@'
)
  RETURNS jsonb AS
$BODY$
WITH
tapitable AS (SELECT regexp_split_to_array(regexp_split_to_table((SELECT * FROM tapi) ,'@frapi_token@@frapi_token@\n'),'@frapi_token@') r)
SELECT substring(r[1]  from '(\d*)\.json$') num, r[1] url, r[2] payload FROM tapitable order by substring(r[1]  from '(\d*)\.json$')::integer
$BODY$
  LANGUAGE plgsql VOLATILE
  PARALLEL SAFE
  COST 2000;