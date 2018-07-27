--
-- Regular Expression for URL validation
--
-- Author: Diego Perini
-- Updated: 2010/12/05
-- License: MIT
--
-- Copyright (c) 2010-2013 Diego Perini (http://www.iport.it)

CREATE OR REPLACE FUNCTION @extschema@.is_url(
    test_string text)
  RETURNS boolean AS
$BODY$
SELECT test_string ~* (
    E'^' ||
    -- protocol identifier
    E'(?:(?:https?|ftp)://)' ||
    -- user:pass authentication
    E'(?:\\S+(?::\\S*)?@)?' ||
    E'(?:' ||
      -- IP address exclusion
      -- private & local networks
      E'(?!(?:10|127)(?:\\.\\d{1,3}){3})' ||
      E'(?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})' ||
      E'(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})' ||
      -- IP address dotted notation octets
      -- excludes loopback network 0.0.0.0
      -- excludes reserved space >= 224.0.0.0
      -- excludes network & broacast addresses
      -- (first & last IP address of each class)
      E'(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])' ||
      E'(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}' ||
      E'(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))' ||
    E'|' ||
      -- host name
      E'(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)' ||
      -- domain name
      E'(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*' ||
      -- TLD identifier
      E'(?:\\.(?:[a-z\\u00a1-\\uffff]{2,}))' ||
      -- TLD may end with dot
      E'\\.?' ||
    E')' ||
    -- port number
    E'(?::\\d{2,5})?' ||
    -- resource path
    E'(?:[/?#]\\S*)?' ||
    E'$'
  );
$BODY$
  LANGUAGE SQL IMMUTABLE
  PARALLEL SAFE
  COST 1;
