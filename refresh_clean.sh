#!/bin/bash
set -eux

sudo make build
sudo make install
#sudo -u postgres pg_dump --format=p --data-only --no-owner --no-privileges --no-tablespaces --schema "hn_ranker" "postgres" > hn_ranker_backup.sql
sudo -u postgres psql -c "DROP EXTENSION IF EXISTS hn_ranker;"
sudo -u postgres psql -c "CREATE EXTENSION hn_ranker;"
#sudo -u postgres psql -f hn_ranker_backup.sql
#sudo -u postgres psql -c "SELECT setval('hn_ranker.run_id_seq', (SELECT max(id) FROM hn_ranker.run), true);"
