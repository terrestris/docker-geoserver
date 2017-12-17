## A geoserver docker image

Based on [buehner/tomcat](https://github.com/buehner/docker-tomcat):

* Alpine Linux
* Java Server JRE 8 (unlimited [JCE Policy](http://docs.geoserver.org/latest/en/user/production/java.html#installing-unlimited-strength-jurisdiction-policy-files))
* Tomcat 8.5
* GeoServer
  * Native Java advanced imaging (JAI) is installed
  * (but) [JAI-EXT](http://docs.geoserver.org/stable/en/user/configuration/image_processing/index.html#jai-ext) is enabled by default
  * Marlin renderer
  * Strong cryptography enabled (Hash/Digest)
  * Default logging profile: PRODUCTION
  * Default WFS service level: Basic

#### How to build?

`docker build -t {YOUR_TAG} .`

#### How to quickstart?

Build the image as described above, then:

`docker run -it -p 80:8080 {YOUR_TAG}`

Check http://localhost/geoserver to see the geoserver page and login with geoserver defaults `admin:geoserver`

#### How to build a specific GeoServer version?

`docker build --build-arg GS_VERSION={YOUR_VERSION} -t {YOUR_TAG} .`

#### How to watch geoserver.log from host?

`docker exec -it {CONTAINER_ID} tail -f /opt/geoserver_data/logs/geoserver.log`
