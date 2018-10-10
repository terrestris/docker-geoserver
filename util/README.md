This command lists the last 100 geoserver versions and writes them to the gs-versions text file:

`curl -s "https://api.github.com/repos/geoserver/geoserver/tags?per_page=100" | jq '.[].name' | sed -e 's/"//g' > gs-versions.txt`

**Note:** We only support geoserver versions since 2.5.
