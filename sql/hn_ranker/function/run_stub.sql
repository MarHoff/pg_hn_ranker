/*
DROP EXTENSION hn_ranker;
CREATE EXTENSION hn_ranker;
*/

/*
INSERT INTO hn_ranker.run  ( top_json, best_json, new_json, max_id ) SELECT hn_ranker.top_json() , hn_ranker.best_json(), hn_ranker.new_json(), hn_ranker.max_id();

WITH
tunnest as (
  SELECT run_id, story_id::bigint, (row_number() OVER ())::integer AS toprank, NULL::integer bestrank, NULL::integer newrank
    FROM (
      SELECT id run_id, jsonb_array_elements_text(top_json) story_id FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq')
    ) tu
  UNION ALL
  SELECT run_id, story_id::bigint, NULL::integer toprank , (row_number() OVER ())::integer AS bestrank, NULL::integer newrank
    FROM (
      SELECT id run_id, jsonb_array_elements_text(best_json) story_id FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq')
  ) tu
    UNION ALL
  SELECT run_id, story_id::bigint, NULL::integer toprank ,  NULL::integer bestrank,  (row_number() OVER ())::integer AS newrank
    FROM (
      SELECT id run_id, jsonb_array_elements_text(new_json) story_id FROM hn_ranker.run WHERE id=currval('hn_ranker.run_id_seq')
  ) tu
)
INSERT INTO hn_ranker.run_story(run_id, story_id, toprank, bestrank, newrank)
SELECt run_id, story_id, max(toprank) toprank, max(bestrank) bestrank, max(newrank) newrank FROM tunnest
GROUP BY run_id, story_id
ORDER BY toprank;
*/
set force_parallel_mode to true;
SELECT *, hn_ranker.item_json(story_id) FROM hn_ranker.run_story WHERE toprank <= 100 AND run_id=currval('hn_ranker.run_id_seq');
