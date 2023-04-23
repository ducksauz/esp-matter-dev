#!/usr/bin/env bash
set -e

. $IDF_PATH/export.sh
. $ESP_MATTER_PATH/export.sh

exec "$@"
