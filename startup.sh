#!/bin/sh

## install GeoServer extensions before starting the tomcat
/opt/install-extensions.sh

# copy additional geoserver libs before starting the tomcat
if [ -d "$ADDITIONAL_LIBS_DIR" ]; then
    cp $ADDITIONAL_LIBS_DIR/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
fi

# copy additional fonts before starting the tomcat
if [ -d "$ADDITIONAL_FONTS_DIR" ]; then
    cp $ADDITIONAL_FONTS_DIR/*.ttf /usr/share/fonts/truetype/
fi

# configure CORS (inspired by https://github.com/oscarfonts/docker-geoserver)
# if enabled, this will add the filter definitions
# to the end of the web.xml
if [ "${CORS_ENABLED}" = "true" ]; then
    sed -i "\:</web-app>:i\\
    <filter>\n\
      <filter-name>CorsFilter</filter-name>\n\
      <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
      <init-param>\n\
          <param-name>cors.allowed.origins</param-name>\n\
          <param-value>${CORS_ALLOWED_ORIGINS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
          <param-name>cors.allowed.methods</param-name>\n\
          <param-value>${CORS_ALLOWED_METHODS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
        <param-name>cors.allowed.headers</param-name>\n\
        <param-value>${CORS_ALLOWED_HEADERS}</param-value>\n\
      </init-param>\n\
    </filter>\n\
    <filter-mapping>\n\
      <filter-name>CorsFilter</filter-name>\n\
      <url-pattern>/*</url-pattern>\n\
    </filter-mapping>" "$CATALINA_HOME/webapps/geoserver/WEB-INF/web.xml";
fi

# start the tomcat
$CATALINA_HOME/bin/catalina.sh run
