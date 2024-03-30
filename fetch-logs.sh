#!/usr/env/bin bash
set -e

src=digiges:access.log/
dst=./logs
 # date -d '20240129' or date -d 'now -7days'
min="${1:-now -7days}"
max="${2:-now}"
min_ts=$( date -d "$min" +%s )
max_ts=$( date -d "$max" +%s )

# due to connection rate limiting, simple for loop style with SCP does not work for more than 3 files. Thus, rsync.
rsync --archive --dry-run --no-motd --out-format='%f' "$src" "$dst" | \
    while IFS= read -r fname; do
        archive_date=$( echo "$fname" | grep -oE '[0-9]+' ) || continue
        archive_ts=$( date -d "$archive_date" +%s ) || continue
        if [ $archive_ts -ge $min_ts -a $archive_ts -lt $max_ts ]; then printf '%s\0' "$fname"; fi
    done | \
    rsync --archive --progress --files-from=- -0 "$src" "$dst"