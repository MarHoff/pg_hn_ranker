--SET ROLE postgres;
--SHOW client_min_messages
--SELECT hn_ranker.item_json(17093732);

WITH qtop as (SELECT now() query_time, row_number() OVER () as hnrank, story_id FROM (SELECT jsonb_array_elements_text(hn_ranker.best_json())::integer story_id) q)
SELECT * , hn_ranker.item_json(story_id)
FROM qtop
WHERE hnrank <10