# Setup matomo using docker
Adjust db.env if this is a production like setup!

`docker compose up`
`open http://localhost:8081`

1. Follow wizard
1. Create an admin user (required to login to web ui afterwards).
1. Use https://digiges.ch as website url.
1. As root use modify ./config/config.ini.php and set http://localhost:8081 as trusted_host

# Import access logs
Place log files (e.g. *.tar.gz archives) in ./logs folder (requires root). Then run (replace password):

`docker run --rm --volumes-from="matomo-app-1" --link matomo-app-1 \
    --network matomo_default python:3.6-alpine python /var/www/html/misc/log-analytics/import_logs.py \
    --url=http://app:80 --login=admin --password=123456 --idsite=1 --recorders=4 /var/www/html/logs/*.tar.gz`


Trigger log processing, to see them immediately in the web UI:

`docker exec -it matomo-app-1 ./console core:archive --force-all-websites --url='http://app:80'`


# Delete all reports and logs from matomo
Run prune.sql in matomo database container:

`docker exec -i matomo-db-1 /bin/mysql -uroot -p1234 matomo < ./prune.sql`

This maybe handy, because the importer re-imports existing logs :/!

# Remove docker containers and associated volumes

```
docker compose down --volumes
sudo rm -rf ./config
```