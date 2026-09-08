#!/bin/bash -xe

# This script is intended to be run from a systemd timer.  We use our own log
# file because there can be a lot of output and it seems better not to spam the
# systemd journal.

logfile=/var/log/opendylan.org/gendoc-`date +%Y%m%d%H%M`.log
exec > $logfile 2>&1

export PATH=/root/dylan/bin:/opt/opendylan/bin:/opt/python3-venv/bin:${PATH}

gendoc_dir="$(realpath $(dirname $0))"
dest_dir=/var/www/package.opendylan.org

# Update gendoc first so we get any changes to the update.sh script.
cd "${gendoc_dir}"

git checkout -- .               # cleanup after previous run.
git pull --rebase --tags origin main

${gendoc_dir}/update.sh "${dest_dir}"

echo "Done updating package.opendylan.org"
bzip2 $logfile
# Keep 10 days of logs.
find /var/log/opendylan.org -name 'gendoc-2*.log*' -mtime +10 -print -exec rm {} \;
