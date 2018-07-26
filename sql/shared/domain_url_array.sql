--
-- Regular Expression for URL validation
--
-- Author: Diego Perini
-- Updated: 2010/12/05
-- License: MIT
--
-- Copyright (c) 2010-2013 Diego Perini (http://www.iport.it)


CREATE DOMAIN @extschema@.url_array AS text[] NOT NULL
    CONSTRAINT url_array_check CHECK
    (@extschema@.is_url_array(VALUE))
;
