CREATE DOMAIN @extschema@.url_shlist AS text NOT NULL
    CONSTRAINT url_array_check CHECK
    (@extschema@.is_url_shlist(VALUE))
;
