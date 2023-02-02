FROM ubuntu:22.04 AS builder

# The GS_VERSION argument could be used like this to overwrite the default:
# docker build --build-arg GS_VERSION=2.11.3 -t geoserver:2.11.3 .
ARG TOMCAT_VERSION=9.0.68
ARG GS_VERSION=2.22.1
ARG GRASS_VERSION_FULL=8.2.0
ARG GRASS_VERSION=82
ARG GDAL_GRASS_VERSION=1.0.1
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
ENV GRASS_VERSION_FULL=$GRASS_VERSION_FULL
ENV GRASS_VERSION=$GRASS_VERSION
ENV GDAL_GRASS_VERSION=$GDAL_GRASS_VERSION
ENV GEOSERVER_VERSION=$GS_VERSION
ENV MARLIN_VERSION=$MARLIN_VERSION
ENV GEOSERVER_DATA_DIR=/opt/geoserver_data/
ENV GEOSERVER_LIB_DIR=$CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
ENV EXTRA_JAVA_OPTS="-Xms256m -Xmx1g -Djava.libary.path=/usr/lib/jni/:/usr/lib/grass${GRASS_VERSION}/lib/"
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
    apt install -y openssl zip gdal-bin wget curl openjdk-11-jdk libpq-dev \
    devscripts make g++ checkinstall && \
    rm -rf $CATALINA_HOME/webapps/*

RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ kinetic universe" >> /etc/apt/sources.list
RUN apt update
RUN apt-get source grass
RUN apt build-dep grass -y
WORKDIR /grass-${GRASS_VERSION_FULL}
RUN debuild -b -uc -us
RUN echo /usr/lib/grass${GRASS_VERSION}/lib > /etc/ld.so.conf.d/grass.conf && ldconfig

# install GRASS GIS packages for GDAL-GRASS driver compilation
RUN dpkg -i /grass-core_${GRASS_VERSION_FULL}*_amd64.deb \
    /grass-dev_${GRASS_VERSION_FULL}*_amd64.deb \
    /grass-doc_${GRASS_VERSION_FULL}*_all.deb

WORKDIR /tmp
RUN wget -q --no-check-certificate --content-disposition https://github.com/OSGeo/gdal-grass/archive/refs/tags/${GDAL_GRASS_VERSION}.tar.gz
RUN tar xf gdal-grass-${GDAL_GRASS_VERSION}.tar.gz
RUN rm gdal-grass-${GDAL_GRASS_VERSION}.tar.gz
WORKDIR /tmp/gdal-grass-${GDAL_GRASS_VERSION}
RUN ./configure \
 --prefix=/usr/local \
 --with-postgres-includes=/usr/include/postgresql \
 --with-gdal=/usr/bin/gdal-config \
 --with-grass=/usr/lib/grass${GRASS_VERSION}/ \
 --with-autoload="/usr/lib/gdalplugins/" \
 --with-ld-shared="g++ -shared"

RUN make -j2 && checkinstall && ldconfig

FROM ubuntu:22.04

# The GS_VERSION argument could be used like this to overwrite the default:
# docker build --build-arg GS_VERSION=2.11.3 -t geoserver:2.11.3 .
ARG TOMCAT_VERSION=9.0.68
ARG GS_VERSION=2.22.1
ARG GRASS_VERSION_FULL=8.2.0
ARG GRASS_VERSION=82
ARG GDAL_GRASS_VERSION=1.0.1
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
ENV GRASS_VERSION_FULL=$GRASS_VERSION_FULL
ENV GRASS_VERSION=$GRASS_VERSION
ENV GDAL_GRASS_VERSION=$GDAL_GRASS_VERSION
ENV GEOSERVER_VERSION=$GS_VERSION
ENV MARLIN_VERSION=$MARLIN_VERSION
ENV GEOSERVER_DATA_DIR=/opt/geoserver_data/
ENV GEOSERVER_LIB_DIR=$CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
ENV EXTRA_JAVA_OPTS="-Xms256m -Xmx1g -Djava.libary.path=/usr/lib/jni/:/usr/lib/grass${GRASS_VERSION}/lib/"
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

COPY --from=builder /grass-core_${GRASS_VERSION_FULL}*_amd64.deb /tmp/
COPY --from=builder /grass-doc_${GRASS_VERSION_FULL}*_all.deb /tmp/
COPY --from=builder /tmp/gdal-grass-${GDAL_GRASS_VERSION}/gdal-grass_${GDAL_GRASS_VERSION}-1_amd64.deb /tmp/

# init
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends openssl zip unzip gdal-bin wget curl openjdk-11-jdk git maven \
    libbz2-dev libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev libfftw3-dev fakeroot libjs-jquery \
    libcairo2-dev libgdal-dev libzstd-dev libpq-dev libproj-dev python3-numpy \
    python3-pil python3-ply python3-six && \
    rm -rf $CATALINA_HOME/webapps/* && \
    apt clean && \
    wget -q https://nexus.terrestris.de/repository/raw-public/debian/libgdal-java_1.0_all.deb && \
    dpkg -i libgdal-java_1.0_all.deb && \
    rm libgdal-java_1.0_all.deb && \
    apt install -y --no-install-recommends  -f /tmp/grass-doc_${GRASS_VERSION_FULL}*_all.deb && \
    apt install -y --no-install-recommends  -f /tmp/grass-core_${GRASS_VERSION_FULL}*_amd64.deb && \
    rm /tmp/grass-core_${GRASS_VERSION_FULL}*_amd64.deb && \
    rm /tmp/grass-doc_${GRASS_VERSION_FULL}*_all.deb && \
    dpkg -i /tmp/gdal-grass_${GDAL_GRASS_VERSION}-1_amd64.deb && \
    rm /tmp/gdal-grass_${GDAL_GRASS_VERSION}-1_amd64.deb && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/* && \
    echo /usr/lib/grass${GRASS_VERSION}/lib > /etc/ld.so.conf.d/grass.conf && \
    ldconfig

WORKDIR /opt/
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    tar xf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    rm apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    rm -rf /opt/apache-tomcat-${TOMCAT_VERSION}/webapps/ROOT && \
    rm -rf /opt/apache-tomcat-${TOMCAT_VERSION}/webapps/docs && \
    rm -rf /opt/apache-tomcat-${TOMCAT_VERSION}/webapps/examples

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

RUN zip -qr9 ../gs-web-core-${GEOSERVER_VERSION}.jar * && \
    cd .. && \
    rm -rf tmp_extract

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
    mv /tmp/jai_imageio-1_1/lib/*.so $JAVA_HOME/lib/ && \
    rm *tar.gz

# uninstall JAI default installation from geoserver to avoid classpath conflicts
# see http://docs.geoserver.org/latest/en/user/production/java.html#install-native-jai-and-imageio-extensions
WORKDIR $GEOSERVER_LIB_DIR
RUN rm jai_core-*jar jai_imageio-*.jar jai_codec-*.jar

# install marlin renderer
RUN wget -q -O $CATALINA_HOME/lib/marlin.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$(echo "$MARLIN_VERSION" | sed "s/\./_/g")/marlin-$MARLIN_VERSION-Unsafe.jar && \
    wget -q -O $CATALINA_HOME/lib/marlin-sun-java2d.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$(echo "$MARLIN_VERSION" | sed "s/\./_/g")/marlin-$MARLIN_VERSION-Unsafe-sun-java2d.jar

# cleanup
RUN apt purge -y && \
    apt autoremove --purge -y && \
    rm -rf /tmp/*

# test GDAL-GRASS driver
RUN grass /usr/lib/grass${GRASS_VERSION}/demolocation/PERMANENT --exec r.mapcalc "testmap = 1.1" && \
    gdalinfo /usr/lib/grass${GRASS_VERSION}/demolocation/PERMANENT/cellhd/testmap && \
    grass /usr/lib/grass${GRASS_VERSION}/demolocation/PERMANENT --exec g.remove type=raster name=testmap -f

# copy scripts
COPY *.sh /opt/
RUN chmod +x /opt/*.sh

ENTRYPOINT /opt/startup.sh

WORKDIR /opt
