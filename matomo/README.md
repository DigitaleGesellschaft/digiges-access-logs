---
runme:
  id: 01HKZKVREX1HQJA5V03WNN2GA6
  version: v2.2
---

# Setup matomo using docker

Adjust db.env if this is a production like setup!

```bash {"id":"01HKZM8PQQX15AS0GVDFH7DRKP"}
docker compose up
open http://localhost:8081
```

1. Follow wizard
2. Create an admin user (required to login to web ui afterwards).
3. Use https://digiges.ch as website url.
4. As root user modify ./config/config.ini.php and set localhost:8081 as trusted_host

# Import access logs

Place log files (e.g. *.tar.gz archives) in ./logs folder (requires root). Then run (replace password):

```bash {"id":"01HKZKVREX1HQJA5V03PPKJMVM"}
docker run --rm --volumes-from="matomo-app-1" --link matomo-app-1 \
    --network matomo_default python:3.6-alpine python /var/www/html/misc/log-analytics/import_logs.py \
    --url=http://app:80 --login=admin --password=123456 --idsite=1 --recorders=6 /var/www/html/logs/*.tar.gz
```

Trigger log processing, to see them immediately in the web UI:

```bash {"id":"01HKZKVREX1HQJA5V03RTC9YK8"}
docker exec -it matomo-app-1 ./console core:archive \
    --force-all-websites --url='http://app:80'
```

# Delete all reports and logs from matomo

Run prune.sql in matomo database container:

```bash {"id":"01HKZKVREX1HQJA5V03SHPVTDR"}
docker exec -i matomo-db-1 /bin/mysql -uroot -p1234 matomo < ./prune.sql
```

This maybe handy, because the importer re-imports existing logs :/!

# Remove docker containers and associated volumes

```sh {"id":"01HKZKVREX1HQJA5V03TKS8RKM"}
docker compose down --volumes
sudo rm -rf ./config
```