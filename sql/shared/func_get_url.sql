-- Function: get_url(text, numeric, numeric, integer)

-- DROP FUNCTION @extschema@.get_url(text, numeric, numeric, integer);

CREATE OR REPLACE FUNCTION @extschema@.get_url(
    url @extschema@.url,
    wait numeric DEFAULT 0,
    timeout numeric DEFAULT 5,
    tries integer DEFAULT 3)
  RETURNS text AS
$BODY$
#!/bin/sh
sleep $2 & wget -T $3 -t $4 -qO- "$1" & wait
$BODY$
  LANGUAGE plsh VOLATILE
  PARALLEL SAFE
  COST 200;
