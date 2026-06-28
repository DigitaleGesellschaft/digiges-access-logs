#!/usr/env/bin bash
set -e

# Fetch logs for given month (YYYYMM) and aggregates them into a single file for that month. 
# The fetched logs are cleaned: no static resources, no bot requests; and paths are normalized.
# The aggregated log file is stored in logs/access-YYYYMM.log.
# NOTE: A log archive from the remote always contains the previous day data (e.g. 20260101 contains the data for 20251231).
# We ignore that, thus the last day of a month is contained in the aggregated log archive of the next month.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <YYYYMM>"
  exit 1
fi

year_month=$1
year=${year_month:0:4}
month=${year_month:4:2}
dst="./logs"
agg_log="${dst}/access-${year_month}"
last_day=$(date -d "${year}-${month}-01 +1 month -1 day" "+%d")
min_ts=$(date -d "${year_month}01" +%s)
max_ts=$(date -d "${year_month}${last_day}" +%s)

bash ./fetch-logs.sh "${year_month}01" "${year_month}${last_day}"

# Combine all fetched logs into a single log file
find ./logs -name '*-*.tar.gz' |  \
    while IFS= read -r fname; do
        archive_date=$( echo "$fname" | grep -oE '[0-9]+' ) || continue
        archive_ts=$( date -d "$archive_date" +%s ) || continue
        if [ $archive_ts -ge $min_ts -a $archive_ts -le $max_ts ]; then printf '%s\0' "$fname"; fi
    done | \
    xargs -0 -n1 zcat | \
    deno run --reload exclude-bots.ts | \
    # remove static resources and irrelevant URIs
    grep --text GET | \
    grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' | \
    grep --text --invert-match -e 'preview_id' | \
    # remove trailing slash
    sed 's|[^ ]/ HTTP| HTTP|' > "$agg_log.log"

echo "Aggregated log file created: $agg_log.log"