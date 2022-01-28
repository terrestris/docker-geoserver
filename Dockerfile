FROM tomcat:9-jre11-openjdk-slim

# The GS_VERSION argument could be used like this to overwrite the default:
# docker build --build-arg GS_VERSION=2.11.3 -t geoserver:2.11.3 .
ARG GS_VERSION=2.20.2
ARG GS_DATA_PATH=./geoserver_data/
ARG ADDITIONAL_LIBS_PATH=./additional_libs/
ARG ADDITIONAL_FONTS_PATH=./additional_fonts/
ARG CORS_ENABLED=false
ARG CORS_ALLOWED_ORIGINS=*
ARG CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
ARG CORS_ALLOWED_HEADERS=*
ARG STABLE_PLUGIN_URL=https://sourceforge.net/projects/geoserver/files/GeoServer/${GS_VERSION}/extensions

# Environment variables
ENV GEOSERVER_VERSION=$GS_VERSION
ENV MARLIN_TAG=0_9_4_3
ENV MARLIN_VERSION=0.9.4.3
ENV GEOSERVER_DATA_DIR=/opt/geoserver_data/
ENV GEOSERVER_LIB_DIR=$CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
ENV EXTRA_JAVA_OPTS="-Xms256m -Xmx1g"
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

WORKDIR /tmp

# init
RUN apt update && \
    apt install -y curl openssl zip gdal-bin libgdal-grass wget && \
    rm -rf $CATALINA_HOME/webapps/*

# install geoserver
RUN curl -jkSL -o /tmp/geoserver.zip http://downloads.sourceforge.net/project/geoserver/GeoServer/$GEOSERVER_VERSION/geoserver-$GEOSERVER_VERSION-war.zip && \
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

RUN curl -jkSL -o ${GEOSERVER_LIB_DIR}gs-geostyler-${GEOSERVER_VERSION}.jar https://repo.osgeo.org/repository/Geoserver-releases/org/geoserver/community/gs-geostyler/$GEOSERVER_VERSION/gs-geostyler-$GEOSERVER_VERSION.jar

COPY $GS_DATA_PATH $GEOSERVER_DATA_DIR
COPY $ADDITIONAL_LIBS_PATH $GEOSERVER_LIB_DIR
COPY $ADDITIONAL_FONTS_PATH /usr/share/fonts/truetype/

# install java advanced imaging
RUN wget https://download.java.net/media/jai/builds/release/1_1_3/jai-1_1_3-lib-linux-amd64.tar.gz && \
    wget https://download.java.net/media/jai-imageio/builds/release/1.1/jai_imageio-1_1-lib-linux-amd64.tar.gz && \
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
RUN curl -jkSL -o $CATALINA_HOME/lib/marlin.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$MARLIN_TAG/marlin-$MARLIN_VERSION-Unsafe.jar && \
    curl -jkSL -o $CATALINA_HOME/lib/marlin-sun-java2d.jar https://github.com/bourgesl/marlin-renderer/releases/download/v$MARLIN_TAG/marlin-$MARLIN_VERSION-Unsafe-sun-java2d.jar

# cleanup
RUN rm -rf /tmp/* /var/cache/apt/*

# copy scripts
COPY *.sh /opt/
RUN chmod +x /opt/*.sh

ENTRYPOINT /opt/startup.sh

WORKDIR /opt
