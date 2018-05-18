--SET ROLE postgres;
--SET client_min_messages TO 'WARNING';
--SELECT hn_ranker.item_json(17093732);

WITH qtop as (SELECT now() query_time, row_number() OVER () as hnrank, story_id FROM (SELECT jsonb_array_elements_text(hn_ranker.top_json())::integer story_id LIMIT 60) q)
SELECT * FROM qtop