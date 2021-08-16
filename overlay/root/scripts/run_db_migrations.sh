#!/bin/cshrc

set -eu

occ --no-interaction db:add-missing-columns
occ --no-interaction db:add-missing-indices
occ --no-interaction db:add-missing-primary-keys
