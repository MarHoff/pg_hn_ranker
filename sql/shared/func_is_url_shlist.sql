CREATE OR REPLACE FUNCTION @extschema@.is_url_shlist(
    test_shlist text)
  RETURNS boolean AS
$BODY$
SELECT @extschema@.is_url_array(string_to_array(test_shlist,' '::text));
$BODY$
  LANGUAGE SQL IMMUTABLE
  PARALLEL SAFE
  COST 1;
