#!/usr/bin/env bash
# Nils Bühner, Andreas Schmitz, terrestris GmbH & Co KG
# Copyright (c) 2018, terrestris.de

# credits go to https://kvz.io/blog/2013/11/21/bash-best-practices/
set -o errexit
set -o pipefail
set -o nounset

for GS_VERSION in $(cat gs-versions.txt); do
    echo "Deleting GS-Version branch on github: $GS_VERSION"
    git push upstream --delete "v${GS_VERSION}"  > /dev/null 2>&1
done
