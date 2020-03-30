#!/bin/sh
if [ $# -ne 2 ]; then
  echo 'Usage: ./release.sh tag committish' >&2 
  echo 'Example: ./release.sh 1.0.0.20200212 $(git rev-list -n 1 master)' >&2 
  exit 2
fi
export DOCKER_BUILDKIT=1
SQL_MIGRATE_VERSION="$1"
SQL_MIGRATE_COMMIT="$2"
docker build -t sql-migrate --build-arg SQL_MIGRATE_VERSION="$SQL_MIGRATE_VERSION" --build-arg SQL_MIGRATE_COMMIT="$SQL_MIGRATE_COMMIT" --secret id=github_token,src=.github_token .
