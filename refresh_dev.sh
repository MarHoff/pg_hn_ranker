#!/bin/bash
set -eux

sudo make build
sudo make install
sudo -u postgres psql -c "DROP EXTENSION IF EXISTS hn_ranker;"
sudo -u postgres psql -c "CREATE EXTENSION hn_ranker;"