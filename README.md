# Tools

* docker (awstats)
* goaccess

# Commands

Create a ./logs dir `mkdir logs` before you start.

## download apache access logs of today

`scp digiges:/var/log/apache2/www.digitale-gesellschaft.ch ./logs && tar zcf ./logs/www.digitale-gesellschaft.ch.$( date "+%Y%m%d" ).tar.gz ./logs/www.digitale-gesellschaft.ch`

## import logs to awstats
existing logs are not overwritten

`docker run --rm -v $(pwd)/logs:/web-logs:ro -eLOG_FORMAT=1 -v awstats-db:/var/lib/awstats openmicroscopy/awstats /web-logs/www.digit\*.gz`

## run awstats web server

`docker run --rm -p 8081:8080 -v awstats-db:/var/lib/awstats openmicroscopy/awstats httpd`

## create goaccess report

`zcat ./logs/www.digitale-gesellschaft.ch.*.tar.gz | goaccess -o report.html --log-format=COMBINED --ignore-crawlers -c -`

## filter apache acces logs by URL path
in this example all GET request to digitalerechte/ or digitalerechte are extracted.

`zcat ./logs/www.digitale-gesellschaft.ch.*.tar.gz | grep --text GET | grep --text -E 'digitalerechte( |/ )H' > ./logs/digitalerechte.log`

the output file can be used to create a goaccess report, that only contains non-crawler visitors

`goaccess ./logs/digitalerechte.log -o report.html --log-format=COMBINED --ignore-crawlers -c`
