#!/usr/bin/env bash
# Nils Bühner, Andreas Schmitz, Marc Jansen, terrestris GmbH & Co KG
# Copyright (c) 2018, terrestris.de

# credits go to https://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit
set -o pipefail
set -o nounset

git checkout master > /dev/null 2>&1
git pull upstream master > /dev/null 2>&1

for GS_VERSION in $(cat gs-versions.txt); do
    echo "Processing GS-Version: $GS_VERSION"
    git checkout master > /dev/null 2>&1
    # check if the branch exists
    if (git rev-parse --verify "v$GS_VERSION" > /dev/null 2>&1); then
        # delete the branch locally
        git branch -D "v$GS_VERSION" > /dev/null 2>&1
    fi
    git checkout -b "v$GS_VERSION" > /dev/null 2>&1
    sed -i "s;^ARG GS_VERSION=[0-9.]\+;ARG GS_VERSION=$GS_VERSION;g" ../Dockerfile
    git commit --allow-empty -m "Update to version $GS_VERSION" ../Dockerfile
    # push force to assure that remote is the same as local,
    # which will trigger a new build on docker cloud
    git push --force upstream "v$GS_VERSION"
done

git checkout master > /dev/null 2>&1
