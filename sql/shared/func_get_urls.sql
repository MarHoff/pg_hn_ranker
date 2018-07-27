-- Function: item_json(text, integer, boolean, numeric, numeric, text, text, text)

CREATE OR REPLACE FUNCTION @extschema@.get_urls(
    url_array @extschema@.url_array ,
    wait numeric DEFAULT 0,
    timeout numeric DEFAULT 5,
    tries integer DEFAULT 3,
    workers integer DEFAULT 10,
    delimiter text DEFAULT '@frapi_token@'
)
  RETURNS TABLE (url @extschema@.url, payload text) AS
$BODY$
WITH
get_urls as (SELECT * FROM @extschema@.get_urls_raw(array_to_string(url_array,' '))),
explode AS (SELECT regexp_split_to_array(regexp_split_to_table((SELECT * FROM get_urls) ,'@frapi_token@@frapi_token@\n'),'@frapi_token@') r)
SELECT r[1]::@extschema@.url  url, r[2] payload FROM explode order by r[1];
$BODY$
  LANGUAGE sql VOLATILE
  PARALLEL SAFE
  COST 2000;