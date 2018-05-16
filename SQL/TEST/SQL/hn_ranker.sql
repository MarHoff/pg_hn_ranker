SET ROLE postgres;
SET client_min_messages TO 'DEBUG1';
--SELECT to_timestamp((hn_ranker.item_json(17080279)->>'time')::integer);

SELECT hn_ranker.top_json();