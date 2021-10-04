#!/bin/sh

ADDITIONAL_LIBS_DIR=/opt/additional_libs/
ADDITIONAL_FONTS_DIR=/opt/additional_fonts/

# copy additional geoserver libs before starting the tomcat
if [ -d "$ADDITIONAL_LIBS_DIR" ]; then
    cp $ADDITIONAL_LIBS_DIR/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/
fi

# copy additional fonts before starting the tomcat
if [ -d "$ADDITIONAL_FONTS_DIR" ]; then
    cp $ADDITIONAL_FONTS_DIR/*.ttf /usr/share/fonts/truetype/
fi

# start the tomcat
$CATALINA_HOME/bin/catalina.sh run
