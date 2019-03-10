#!/bin/bash
set -eux

sudo make build
sudo make install
sudo -u postgres pg_dump --format=p --data-only --no-owner --no-privileges --no-tablespaces --schema "hn_ranker" "develop" > pg_hn_ranker_develop.bak
sudo -u postgres psql -d develop -c "DROP EXTENSION IF EXISTS pg_hn_ranker;"
sudo -u postgres psql -d develop -c "CREATE EXTENSION pg_hn_ranker;"
sudo -u postgres psql -d develop -f pg_hn_ranker_develop.bak
sudo -u postgres psql -d develop -c "SELECT setval('hn_ranker.run_id_seq', (SELECT max(id) FROM hn_ranker.run), true);"