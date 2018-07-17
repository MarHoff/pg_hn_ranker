-- Function: get_urls(text, numeric, numeric, integer)

-- DROP FUNCTION @extschema@.get_urls(text, numeric, numeric, integer);

CREATE OR REPLACE FUNCTION @extschema@.get_urls
(
    url text,
    wait numeric,
    timeout numeric,
    tries integer DEFAULT 3,
    workers integer DEFAULT 10,
    delimiter text DEFAULT '@frapi_token@'
  )
  RETURNS text AS
$BODY$
#!/bin/sh
export FRAPI_WAIT=$2
export FRAPI_TIMOUT=$3
export FRAPI_TRIES=$4
export FRAPI_TOKEN=$6
pexec -p "$1" -e URL -n $5 -R -c 'echo "$URL$FRAPI_TOKEN$(wget -T $FRAPI_TIMOUT -t $FRAPI_TRIES -qO- $URL)$FRAPI_TOKEN$FRAPI_TOKEN"'
$BODY$;
  LANGUAGE plsh VOLATILE
  COST 200;
