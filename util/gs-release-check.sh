#!/usr/bin/env bash
# Nils Bühner, terrestris GmbH & Co KG
# Copyright (c) 2018, terrestris.de

# credits go to https://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit
set -o pipefail
set -o nounset

# helper function to compare versions
# credits go to https://stackoverflow.com/a/24067243
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

git checkout master > /dev/null 2>&1
git pull upstream master > /dev/null 2>&1

# get the current GS version that is used in the docker file
DOCKER_GS_VERSION=$(cat ../Dockerfile | grep "ARG GS_VERSION" | cut -d'=' -f2)

# get the last 100 tags/versions of geoserver on github (ordered from old to new)
GITHUB_GS_VERSIONS=$(curl -s "https://api.github.com/repos/geoserver/geoserver/tags?per_page=100" | jq '.[].name' | sed -e 's/"//g' | tac)

# a variable to remember the latest GS_VERSION (to update master branch in the end)
LATEST_GS_VERSION=

for GS_VERSION in $GITHUB_GS_VERSIONS; do
  if [[ $GS_VERSION =~ ^([0-9.]+)$ ]]; then
    if version_gt $GS_VERSION $DOCKER_GS_VERSION; then
      git checkout master > /dev/null 2>&1
      # create a new branch for the new gs version
      if (git rev-parse --verify "v$GS_VERSION" > /dev/null 2>&1); then
          # delete the local branch if it should exist for some reason
          # (this should not really happen)
          git branch -D "v$GS_VERSION" > /dev/null 2>&1
      fi
      git checkout -b "v$GS_VERSION" > /dev/null 2>&1
      sed -i "s;^ARG GS_VERSION=[0-9.]\+;ARG GS_VERSION=$GS_VERSION;g" ../Dockerfile
      git commit --allow-empty -m "Update to version $GS_VERSION" ../Dockerfile
      git push --force upstream "v$GS_VERSION"

      # update the latest known gs version
      LATEST_GS_VERSION=$GS_VERSION
    fi
  fi
done

# update master branch if there is a new version
if [[ -z "$LATEST_GS_VERSION" ]]; then
  echo "No new geoserver version available!"
else
  git checkout master > /dev/null 2>&1
  sed -i "s;^ARG GS_VERSION=[0-9.]\+;ARG GS_VERSION=$LATEST_GS_VERSION;g" ../Dockerfile
  git commit --allow-empty -m "Update to latest version $LATEST_GS_VERSION" ../Dockerfile
  git push upstream master

  echo "Finished! Latest geoserver version is $LATEST_GS_VERSION!"
fi
