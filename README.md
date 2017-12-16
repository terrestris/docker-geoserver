## A geoserver docker image

Based on [buehner/tomcat](https://github.com/buehner/docker-tomcat):

* Alpine Linux
* Java Server JRE 8 with unlimited JCE Policy
* Tomcat 8.5
* GeoServer
  * Java advanced imaging (JAI)
  * Marlin renderer

#### How to build?

`docker build -t {YOUR_TAG} .`

#### How to quickstart?

`docker run -it -p 80:8080 {YOUR_TAG}`

Check http://localhost/geoserver to see the geoserver page.

#### How to build a specific GeoServer version?

`docker build --build-arg GS_VERSION={YOUR_VERSION} -t {YOUR_TAG} .`
