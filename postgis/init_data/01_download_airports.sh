#!/bin/sh

cd # go to home directory for permisson reasons (/var/lib/postgresql)
if [ ! -f /var/lib/postgresql/airports.csv ]; then
    wget https://ourairports.com/data/airports.csv # download the file
fi
