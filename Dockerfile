FROM ubuntu:22.04

# The GS_VERSION argument could be used like this to overwrite the default:
# docker build --build-arg GS_VERSION=2.11.3 -t geoserver:2.11.3 .
ARG TOMCAT_VERSION=9.0.63
ARG GS_VERSION=2.21.0
ARG GDAL_GRASS_VERSION=3.3.3
ARG MARLIN_VERSION=0.9.4.5
ARG GS_DATA_PATH=./geoserver_data/
ARG ADDITIONAL_LIBS_PATH=./additional_libs/
ARG ADDITIONAL_FONTS_PATH=./additional_fonts/
ARG CORS_ENABLED=false
ARG CORS_ALLOWED_ORIGINS=*
ARG CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
ARG CORS_ALLOWED_HEADERS=*
ARG STABLE_PLUGIN_URL=https://sourceforge.net/projects/geoserver/files/GeoServer/${GS_VERSION}/extensions

# Environment variables
ENV CATALINA_HOME=/opt/apache-tomcat-${TOMCAT_VERSION}
ENV GDAL_GRASS_VERSION=$GDAL_GRASS_VERSION
ENV GEOSERVER_VERSION=$GS_VERSION
ENV MARLIN_VERSION=$MARLIN_VERSION
ENV GEOSERVER_DATA_DIR=/opt/geoserver_data/
ENV GEOSERVER_LIB_DIR=$CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
ENV EXTRA_JAVA_OPTS="-Xms256m -Xmx1g -Djava.libary.path=/usr/lib/jni/:/usr/lib/grass78/lib/"
ENV CORS_ENABLED=$CORS_ENABLED
ENV CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS
ENV CORS_ALLOWED_METHODS=$CORS_ALLOWED_METHODS
ENV CORS_ALLOWED_HEADERS=$CORS_ALLOWED_HEADERS
ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALL_EXTENSIONS=false
ENV STABLE_EXTENSIONS=''
ENV STABLE_PLUGIN_URL=$STABLE_PLUGIN_URL
ENV ADDITIONAL_LIBS_DIR=/opt/additional_libs/
ENV ADDITIONAL_FONTS_DIR=/opt/additional_fonts/

# see http://docs.geoserver.org/stable/en/user/production/container.html
ENV CATALINA_OPTS="\$EXTRA_JAVA_OPTS \
    -Djava.awt.headless=true -server \
    -Dfile.encoding=UTF-8 \
    -Djavax.servlet.request.encoding=UTF-8 \
    -Djavax.servlet.response.encoding=UTF-8 \
    -D-XX:SoftRefLRUPolicyMSPerMB=36000 \
    -Xbootclasspath/a:$CATALINA_HOME/lib/marlin.jar \
    -Xbootclasspath/a:$CATALINA_HOME/lib/marlin-sun-java2d.jar \
    -Dsun.java2d.renderer=org.marlin.pisces.PiscesRenderingEngine \
    -Dorg.geotools.coverage.jaiext.enabled=true"

# init
RUN apt update && apt -y upgrade && \
    apt install -y maven openssl zip gdal-bin wget curl openjdk-11-jdk grass-dev libpq-dev make g++ checkinstall && \
    rm -rf $CATALINA_HOME/webapps/*

RUN wget -q https://nexus.terrestris.de/repository/raw-public/debian/libgdal-java_1.0_all.deb
RUN dpkg -i libgdal-java_1.0_all.deb
RUN rm libgdal-java_1.0_all.deb

WORKDIR /tmp
RUN wget -q --no-check-certificate https://github.com/OSGeo/gdal/releases/download/v${GDAL_GRASS_VERSION}/gdal-grass-${GDAL_GRASS_VERSION}.tar.gz
RUN tar xf gdal-grass-${GDAL_GRASS_VERSION}.tar.gz
RUN rm gdal-grass-${GDAL_GRASS_VERSION}.tar.gz
RUN echo /usr/lib/grass78/lib > /etc/ld.so.conf.d/grass.conf
WORKDIR /tmp/gdal-grass-${GDAL_GRASS_VERSION}
RUN ./configure \
 --prefix=/usr/local \
 --with-postgres-includes=/usr/include/postgresql \
 --with-gdal=/usr/bin/gdal-config \
 --with-grass=/usr/lib/grass78/ \
 --with-autoload="/usr/lib/gdalplugins/" \
 --with-ld-shared="g++ -shared"

RUN make -j2 && checkinstall && ldconfig

WORKDIR /opt/
RUN rm -rf /tmp/gdal-grass-${GDAL_GRASS_VERSION}
RUN wget -q https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
RUN tar xf apache-tomcat-${TOMCAT_VERSION}.tar.gz
RUN rm apache-tomcat-${TOMCAT_VERSION}.tar.gz

WORKDIR /tmp

# install geoserver
RUN wget -q -O /tmp/geoserver.zip http://downloads.sourceforge.net/project/geoserver/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-war.zip && \
    unzip geoserver.zip geoserver.war -d $CATALINA_HOME/webapps && \
    mkdir -p $CATALINA_HOME/webapps/geoserver && \
    unzip -q $CATALINA_HOME/webapps/geoserver.war -d $CATALINA_HOME/webapps/geoserver && \
    rm $CATALINA_HOME/webapps/geoserver.war && \
    mkdir -p $GEOSERVER_DATA_DIR

# apply custom css by extracting JAR,
# replacing css and repacking the JAR
RUN mkdir -p ${GEOSERVER_LIB_DIR}tmp_extract
WORKDIR ${GEOSERVER_LIB_DIR}tmp_extract

RUN unzip -q ../gs-web-core-${GEOSERVER_VERSION}.jar
COPY ./minimalistic.css org/geoserver/web/css/minimalistic.css
RUN cat org/geoserver/web/css/minimalistic.css >> org/geoserver/web/css/geoserver.css

COPY ./modifications.js org/geoserver/web/js/modifications.js
RUN sed -i 's|</wicket:head>|<wicket:link><script type="text/javascript" src="js/modifications.js"></script></wicket:link></wicket:head>|g' org/geoserver/web/GeoServerBasePage.html

RUN zip -qr9 ../gs-web-core-${GEOSERVER_VERSION}.jar *
RUN cd .. && rm -rf tmp_extract

WORKDIR /tmp
COPY ./settings.xml .
# use fake version 2.15.6 to avoid build error
RUN echo ${GEOSERVER_VERSION} > /tmp/version.txt; echo "2.15.6" >> /tmp/version.txt; \
    if(test $(sort -V /tmp/version.txt|head -n 1) != "2.15.6"); then \
        echo "Skipping installation of GeoStyler due to version incompatibility."; \
    else \
        if ! (curl --head --silent --fail https://repo.osgeo.org/repository/Geoserver-releases/org/geoserver/community/gs-geostyler/$GEOSERVER_VERSION/gs-geostyler-$GEOSERVER_VERSION.jar > /dev/null); then \
            echo "GeoStyler extension not available in OSGeo repo for GeoServer version ${GEOSERVER_VERSION}! Trying to build on sources now." ; \
            git clone --depth 1 --no-checkout --branch ${GEOSERVER_VERSION} https://github.com/geoserver/geoserver.git ; \
            cd geoserver ; \
            # checkout only the sources we need
            git checkout ${GEOSERVER_VERSION} -- src/community/geostyler ; \
            cd src/community/geostyler ; \
            echo "Building the GeoStyler extension now. This will take some time. Be patient!" ; \
            mvn -s "/tmp/settings.xml" -q -B -e -T 2C install ; \
            cp target/gs-geostyler-${GEOSERVER_VERSION}.jar ${GEOSERVER_LIB_DIR}gs-geostyler-${GEOSERVER_VERSION}.jar ; \
        else \
            echo "Downloading GeoStyler extension from OSGeo repo now."; \
            wget -q -O ${GEOSERVER_LIB_DIR}gs-geostyler-${GEOSERVER_VERSION}.jar https://repo.osgeo.org/repository/Geoserver-releases/org/geoserver/community/gs-geostyler/$GEOSERVER_VERSION/gs-geostyler-$GEOSERVER_VERSION.jar; \
        fi \
    fi

COPY $GS_DATA_PATH $GEOSERVER_DATA_DIR
COPY $ADDITIONAL_LIBS_PATH $GEOSERVER_LIB_DIR
COPY $ADDITIONAL_FONTS_PATH /usr/share/fonts/truetype/

# install java advanced imaging
RUN wget -q https://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz && \
    wget -q https://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz && \
    gunzip -c jai-1_1_3-lib-linux-amd64.tar.gz | tar xf - && \
    gunzip -c jai_imageio-1_1-lib-linux-amd64.tar.gz | tar xf - && \
    mv /tmp/jai-1_1_3/lib/*.jar $CATALINA_HOME/lib/ && \
    mv /tmp/jai-1_1_3/lib/*.so $JAVA_HOME/lib/ && \
    mv /tmp/jai_imageio-1_1/lib/*.jar $CATALINA_HOME/lib/ && \
    mv /tmp/jai_imageio-1_1/lib/*.so $JAVA_HOME/lib/

# uninstall JAI default installation from geoserver to avoid classpath conflicts
# see http://docs.geoserver.org/latest/en/user/production/java.html#install-native-jai-and-imageio-extensions
WORKDIR $GEOSERVER_LIB_DIR
RUN rm jai_core-*jar jai_imageio-*.jar jai_codec-*.jar

# install marlin renderer
RUN wget -q -O $CATALINA_HOME/lib/marlin.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$(echo "$MARLIN_VERSION" | sed "s/\./_/g")/marlin-$MARLIN_VERSION-Unsafe.jar && \
    wget -q -O $CATALINA_HOME/lib/marlin-sun-java2d.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$(echo "$MARLIN_VERSION" | sed "s/\./_/g")/marlin-$MARLIN_VERSION-Unsafe-sun-java2d.jar

# cleanup
RUN rm -rf /tmp/* /var/cache/apt/*

# copy scripts
COPY *.sh /opt/
RUN chmod +x /opt/*.sh

ENTRYPOINT /opt/startup.sh

WORKDIR /opt
