---
runme:
  id: 01HKTA1PWQ3C4AJDY3N8ABKZ6V
  version: v3
---

Instructions on how to analyze apache2 access logs with different open source tools.

# Tools

* docker (awstats)
* goaccess (>1.8)
* matomo
* duckdb

# Commands

Note: All ssh, rsync, scp commands use a configured ssh Host named 'digiges'.

Create a ./logs dir `mkdir logs` before you start.

## Download Apache access logs of yesterday

The date in the archive name relates to the create date of the archive, which is always one day after the dates of the contained logs.
`scp digiges:access.log/www.digitale-gesellschaft.ch-$( date "+%Y%m%d" ).tar.gz ./logs`

### Download archives of last n days

For example the last 8 days, starting today (containing the logs of yesterday ;)).

```bash {"id":"01HKTBECEEP0TVNNEXGHAHD20R"}
bash ./fetch-logs.sh "20231201" "20231231" # or "now -8days"
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

`goaccess ./logs/digitalerechte-source_query.log -p ./goaccess.conf`

## Remove crawlers / spiders / bots from logs

goaccess and matomo both have built in support to remove crawlers. However, a more flexible (and hopefully more complete) way to remove crawlers offers https://github.com/omrilotan/isbot:

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | deno run --reload exclude-bots.ts`

Remove the reload flag to not always download the latest list of crawlers before log processing.

## Remove irrelevant URIs from logs

Static resources such as js files and theme images are part of the wordpress theme or other plugins. These are sometimes not correctly identified as static resources, but as pages. Simply excluding those URIs might help, depending on the report use case. 'preview_id' is the query parameter used by wordpress when previewing a post.

`zcat ./logs/www.digitale-gesellschaft.ch-*.tar.gz | grep --text --invert-match -E '\.(txt|js|php|css|png|gif|jpeg|jpg|webp|svg|env|asp|woff|woff2)' | grep --text --invert-match -E 'preview_id'`

# Presets

## Page

Generate a goaccess report of a particular page, identified via slug.

Syntax: `report-page_slug.sh :report_name :page_slug [:min_date] [:max_date]`

page_slug value must contain the end of the page URI without the trailing slash (/). Use '' (empty slug name) to create a report covering all paths.

min_date and max_date is of format YYYYmmdd (e.g. '20230125') or 'now -7days'.

Beware that logs must have been already fetched before.

```bash {"id":"01HKTBECEEP0TVNNEXGMK72A14"}
bash ./report-page_slug.sh "könnsch" "koennsch-fuer-digitale-grundrechte" "20231214" "20231231"

bash ./report-page_slug.sh "geheimjustiz" "geheimjustiz-am-bundesverwaltungsgericht-kabelaufklaerung-durch-geheimdienst" "20240107" "20240207"
```

# Hits per Weekday
Use duckdb to plot a histogram, which shows the number of total hits and hits by social media platform per day (including weekday).

Replace log file name in following statement before run:

```bash
duckdb -box -s "DROP TABLE IF EXISTS acclogs; CREATE TABLE acclogs AS SELECT * FROM read_csv_auto('logs/grundrechte-wahren-nostatic-normalized-nobot.log', delim=' ', header=false, names = ['clientIp', 'userId', 'nA', 'datetime', 'tzOffset', 'methodAndPath', 'responseStatus', 'bytes', 'referrer', 'userAgent'], types={'datetime':'DATE'}, dateformat='[%d/%b/%Y:%H:%M:%S'); SELECT datetrunc('day', datetime) || '-' || dayofweek(datetime) AS 'week-dayofweek', count(*) FILTER (WHERE methodAndPath ILIKE '%s=x H%') AS hitsX, count(*) FILTER (WHERE methodAndPath ILIKE '%s=i H%') AS hitsInstagram, count(*) FILTER (WHERE methodAndPath ILIKE '%s=m H%') AS hitsMastodon, count(*) FILTER (WHERE methodAndPath ILIKE '%s=l H%') AS hitsLinkedIn, count(*) AS hitsTotal FROM acclogs GROUP BY 1 ORDER BY 1 ASC;"
```

Just total hits per day, but in a nice bar chart in the terminal (requires YouPlot):

```bash
duckdb -s "DROP TABLE IF EXISTS acclogs; CREATE TABLE acclogs AS SELECT * FROM read_csv_auto('logs/grundrechte-wahren-nostatic-normalized-nobot.log', delim=' ', header=false, names = ['clientIp', 'userId', 'nA', 'datetime', 'tzOffset', 'methodAndPath', 'responseStatus', 'bytes', 'referrer', 'userAgent'], types={'datetime':'DATE'}, dateformat='[%d/%b/%Y:%H:%M:%S'); COPY (SELECT datetrunc('day', datetime) || '-' || dayofweek(datetime) AS 'week-dayofweek', count(*) AS hits FROM acclogs GROUP BY 1 ORDER BY 1 ASC) TO '/dev/stdout' WITH (FORMAT 'csv', HEADER)" | uplot bar -d, -H
```