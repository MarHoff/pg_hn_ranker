-- Function: get_urls(text, numeric, numeric, integer)

-- DROP FUNCTION @extschema@.get_urls(text, numeric, numeric, integer);

CREATE OR REPLACE FUNCTION @extschema@.get_urls_raw
(
    url_shlist @extschema@.url_shlist ,
    wait numeric DEFAULT 0,
    timeout numeric DEFAULT 5,
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
pexec -a '%l' -p "$1" -e URL -n $5 -R -c 'echo "$URL$FRAPI_TOKEN$(wget -T $FRAPI_TIMOUT -t $FRAPI_TRIES -qO- $URL)$FRAPI_TOKEN$FRAPI_TOKEN"'
#Options
# -p <space separated list of parameters>
# -e <environmental variable name>
# -n <number of parallel processes>
# -R --normal-redirection (This is equivalent to specifying --output - and --error - and --input /dev/null)
# -c Use a shell (see -s|--shell also) to interpret the command(s) instead of direct execution.
# -a --output-format <Ioutput line format> (The line buffering yielded by the simple format of %l can also be useful if all of the standard outputs (or errors) are collected in a single file and the invoker wants to avoid the inter-line confusion of output (i.e. if this redirection formatting is omitted, no line buffering is done at all).)
$BODY$
  LANGUAGE plsh VOLATILE
  COST 200;
