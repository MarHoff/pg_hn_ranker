CREATE DOMAIN @extschema@.url_array AS text[] NOT NULL
    CONSTRAINT url_array_check CHECK
    (@extschema@.is_url_array(VALUE))
;
