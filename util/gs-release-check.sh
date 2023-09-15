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
LATEST_DOCKER_GS_VERSION=$(cat ../Dockerfile | grep "ARG GS_VERSION" | cut -d'=' -f2)

DOCKER_VERSION_PAGE=1

DOCKER_GS_VERSIONS=$(curl -s "https://api.github.com/repos/terrestris/docker-geoserver/branches?per_page=100&page=${DOCKER_VERSION_PAGE}" | jq '.[].name' | sed -e 's/"//g' | tac)
DOCKER_GS_ALL_VERSIONS=

while ( test ! -z "$DOCKER_GS_VERSIONS" )
do
  DOCKER_GS_ALL_VERSIONS="$DOCKER_GS_ALL_VERSIONS $DOCKER_GS_VERSIONS"
  DOCKER_VERSION_PAGE=$((DOCKER_VERSION_PAGE+1))
  DOCKER_GS_VERSIONS=$(curl -s "https://api.github.com/repos/terrestris/docker-geoserver/branches?per_page=100&page=${DOCKER_VERSION_PAGE}" | jq '.[].name' | sed -e 's/"//g' | tac)
done

echo $DOCKER_GS_ALL_VERSIONS

# get the last 100 tags/versions of geoserver on github (ordered from old to new)
GITHUB_GS_VERSIONS=$(curl -s "https://api.github.com/repos/geoserver/geoserver/tags?per_page=100" | jq '.[].name' | sed -e 's/"//g' | tac)

# a variable to remember the latest GS_VERSION (to update master branch in the end)
LATEST_GS_VERSION=

for GS_VERSION in $GITHUB_GS_VERSIONS; do
  if [[ $GS_VERSION =~ ^([0-9.]+)$ ]] && version_gt $GS_VERSION "2.4.8"; then

    GS_VERSION_EXISTS_ON_DOCKER=false

    # check if our GS_VERSION is already present on docker
    for DOCKER_GS_VERSION in $DOCKER_GS_ALL_VERSIONS; do
      if [ "${DOCKER_GS_VERSION}" = "v${GS_VERSION}" ]; then
        GS_VERSION_EXISTS_ON_DOCKER=true
        break
      fi
    done

    if [ "${GS_VERSION_EXISTS_ON_DOCKER}" = false ] ; then
      if (curl --head --silent --fail http://downloads.sourceforge.net/project/geoserver/GeoServer/$GS_VERSION/geoserver-$GS_VERSION-war.zip > /dev/null); then
        echo "v${GS_VERSION} is not yet on docker! A new branch will be created now."
        git checkout master > /dev/null 2>&1
        # create a new branch for the new gs version
        if (git rev-parse --verify "v$GS_VERSION" > /dev/null 2>&1); then
            # delete the local branch if it should exist for some reason
            # (this should not really happen)
            git branch -D "v$GS_VERSION" > /dev/null 2>&1
        fi
        git checkout -b "v$GS_VERSION" > /dev/null 2>&1
        sed -i "s;^ARG GS_VERSION=[0-9.]\+;ARG GS_VERSION=$GS_VERSION;g" ../Dockerfile
        sed -i "s;^        - GS_VERSION=[0-9.]\+;        - GS_VERSION=$GS_VERSION;g" ../docker-compose-demo.yml
        git commit --allow-empty -m 'Update to version $GS_VERSION


on-behalf-of: @terrestris info@terrestris.de' ../Dockerfile ../docker-compose-demo.yml > /dev/null 2>&1
        git push --force upstream "v$GS_VERSION"
      else
        echo "v${GS_VERSION} is not yet available on SourceForge! Skipping docker build for now."
      fi
    fi

    if version_gt $GS_VERSION $LATEST_DOCKER_GS_VERSION; then
      # update the latest known gs version
      LATEST_GS_VERSION=$GS_VERSION
    fi
  fi
done

# update master branch if there is a new 'latest/stable' version
if [[ -z "$LATEST_GS_VERSION" ]]; then
  echo "No new 'latest/stable' geoserver version available!"
else
  git checkout master > /dev/null 2>&1
  sed -i "s;^ARG GS_VERSION=[0-9.]\+;ARG GS_VERSION=$LATEST_GS_VERSION;g" ../Dockerfile
  sed -i "s;^        - GS_VERSION=[0-9.]\+;        - GS_VERSION=$LATEST_GS_VERSION;g" ../docker-compose-demo.yml
  git commit --allow-empty -m 'Update to latest version $LATEST_GS_VERSION


on-behalf-of: @terrestris info@terrestris.de' ../Dockerfile ../docker-compose-demo.yml
  git push upstream master

  echo "Finished! Latest geoserver version is $LATEST_GS_VERSION!"
fi
