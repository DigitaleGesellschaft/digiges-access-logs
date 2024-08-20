#!/usr/env/bin bash
set -e

report_name="$1"
# page_slug value must contain the end of the page URI without the trailing /
page_slug="$2"
 # date -d '20240129' or date -d 'now -7days'
min="${3:-now -7days}"
max="${4:-now}"
min_ts=$( date -d "$min" +%s )
max_ts=$( date -d "$max" +%s )

# bash ./fetch-logs.sh "$min" "$max"

find ./logs -name '*-*.tar.gz' |  \
    while IFS= read -r fname; do
        archive_date=$( echo "$fname" | grep -oE '[0-9]+' ) || continue
        archive_ts=$( date -d "$archive_date" +%s ) || continue
        if [ $archive_ts -ge $min_ts -a $archive_ts -le $max_ts ]; then printf '%s\0' "$fname"; fi
    done | \
    xargs -0 -n1 zcat | grep --text GET | grep --text -E "$page_slug( |/ )HTTP" > ./logs/$report_name.log

cat ./logs/$report_name.log \
    | grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' \
    | grep --text --invert-match -E 'preview_id' > ./logs/$report_name-nostatic.log
cat ./logs/$report_name-nostatic.log | sed 's|/ HTTP| HTTP|' > ./logs/$report_name-nostatic-normalized.log
cat ./logs/$report_name-nostatic-normalized.log | deno run --reload exclude-bots.ts > ./logs/$report_name-nostatic-normalized-nobot.log
# remove -o option to render report in terminal
goaccess ./logs/$report_name-nostatic-normalized-nobot.log -p ./goaccess.conf --html-report-title "$report_name" -o report-$report_name.html