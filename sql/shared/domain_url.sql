CREATE DOMAIN @extschema@.url AS text NOT NULL
    CONSTRAINT url_check CHECK
    (@extschema@.is_url(VALUE))
;
