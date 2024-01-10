---
runme:
  id: 01HKTA1PWQ3C4AJDY3N8ABKZ6V
  version: v2.2
---

Instructions on how to analyze apache2 access logs with different open source tools.

# Tools

* docker (awstats)
* goaccess (>1.8)
* matomo

# Commands

Create a ./logs dir `mkdir logs` before you start.

## Download Apache access logs of yesterday

The date in the archive name relates to the create date of the archive, which is always one day after the dates of the contained logs.
`scp digiges:access.log/www.digitale-gesellschaft.ch-$( date "+%Y%m%d" ).tar.gz ./logs`

### Download archives of last n days

For example the last 8 days, starting today (containing the logs of yesterday ;)).

Due to connection rate limiting, simple for loop style with SCP does not work for more than 3 files. Thus, rsync.

```bash {"id":"01HKTBECEEP0TVNNEXGHAHD20R"}
src=digiges:access.log/
dst=./logs

since_ts=$( date -d '-7 days' +%s ) # or e.g.  date -d '20240129'
rsync --archive --dry-run --no-motd --out-format='%f' "$src" "$dst" | \
    while IFS= read -r fname; do
        archive_date=$( echo "$fname" | grep -oE '[0-9]+' ) || continue
        archive_ts=$( date -d "$archive_date" +%s ) || continue
        if [ $archive_ts -ge $since_ts ]; then printf '%s\0' "$fname"; fi
    done | \
    rsync --archive --progress --files-from=- -0 "$src" "$dst"
```

## Import logs to awstats

Existing logs are not overwritten

`docker run --rm -v $(pwd)/logs:/web-logs:ro -eLOG_FORMAT=1 -v awstats-db:/var/lib/awstats openmicroscopy/awstats /web-logs/www.digit\*.gz`

## Run awstats web server

`docker run --rm -p 8081:8080 -v awstats-db:/var/lib/awstats openmicroscopy/awstats httpd`

## Create goaccess report

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | goaccess -p ./goaccess.conf -o report.html -`

## Filter apache acces logs by URL path

In this example all GET request to digitalerechte/ or digitalerechte are extracted.

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text GET | grep --text -E 'digitalerechte( |/ )H' > ./logs/digitalerechte.log`

The next example extracts all requests originating from a social media campaign that used query parameter markers.

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text GET | grep --text -E 'digitalerechte/?\?s=(t|i|m|x|l) H' > ./logs/digitalerechte-source_query.log`

The output file can be used to create a goaccess report, that only contains non-crawler visitors.

`goaccess ./logs/geheimjustiz.log -p ./goaccess.conf`


## Remove crawlers / spiders / bots from logs

goaccess and matomo both have built in support to remove crawlers. However, a more flexible (and hopefully more complete) way to remove crawlers offers https://github.com/omrilotan/isbot:

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | deno run --reload exclude-bots.ts`

Remove the reload flag to not always download the latest list of crawlers before log processing.

## Remove irrelevant URIs from logs

Static resources such as js files and theme images are part of the wordpress theme or other plugins. These are sometimes not correctly identified as static resources, but as pages. Simply excluding those URIs might help, depending on the report use case. 'preview_id' is the query parameter used by wordpress when previewing a post.

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' | grep --text --invert-match -E 'preview_id'`

# Presets

## Page

```bash {"id":"01HKTBECEEP0TVNNEXGMK72A14"}
page_slug="geheimjustiz-am-bundesverwaltungsgericht-kabelaufklaerung-durch-geheimdienst"
report_name="geheimjustiz"

zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text GET | grep --text -E "$page_slug( |/ )H" > ./logs/$report_name.log
cat ./logs/$report_name.log | grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' | grep --text --invert-match -E 'preview_id' > ./logs/$report_name-nostatic.log
cat ./logs/$report_name-nostatic.log | deno run --reload exclude-bots.ts > ./logs/$report_name-nostaticandbot.log
# remove -o option to render report in terminal
goaccess ./logs/geheimjustiz-nostaticandbot.log -p ./goaccess.conf -o report-$report_name.html
open ./report-$report_name.html
```