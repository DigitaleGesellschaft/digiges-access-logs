#!/usr/env/bin bash

# page_slug value must contain the end of the page URI without the trailing /
page_slug="$1"
report_name="$2"

zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text GET | grep --text -E "$page_slug( |/ )HTTP" > ./logs/$report_name.log
cat ./logs/$report_name.log \
    | grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' \
    | grep --text --invert-match -E 'preview_id' > ./logs/$report_name-nostatic.log
cat ./logs/$report_name-nostatic.log | sed  's|/ HTTP| HTTP|' > ./logs/$report_name-nostatic-normalized.log
cat ./logs/$report_name-nostatic-normalized.log | deno run --reload exclude-bots.ts > ./logs/$report_name-nostatic-normalized-nobot.log
# remove -o option to render report in terminal
goaccess ./logs/$report_name-nostatic-normalized-nobot.log -p ./goaccess.conf --html-report-title "$report_name" -o report-$report_name.html