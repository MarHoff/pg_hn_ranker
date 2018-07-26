CREATE OR REPLACE FUNCTION @extschema@.is_url_array(
    test_array text[])
  RETURNS boolean AS
$BODY$
SELECT bool_and(@extschema@.is_url(test)) FROM unnest(test_array) a(test);
$BODY$
  LANGUAGE SQL IMMUTABLE
  PARALLEL SAFE
  COST 1;
