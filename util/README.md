This command lists the last 100 geoserver versions and writes them to the gs-versions text file:

`curl -s "https://api.github.com/repos/geoserver/geoserver/tags?per_page=100" | jq '.[].name' | sed -e 's/"//g' > gs-versions.txt`

**Note:** We only support geoserver versions since 2.15.0 (which is the first version that supports Java 11)

To re-build images and replace existing ones on docker hub (maybe to fix security issues or other bugs), the following steps are necessary:

1. List all versions that you want to re-build in the gs-versions.txt. The curl command from above will help here!
2. Execute the `update-version-branches.sh` script. Be careful! This will replace the branches (and delete existing ones before), to trigger new github action builds, which will finally push new images to docker hub. Please keep in mind that only 20 github actions can run in parallel on a basic account level!
