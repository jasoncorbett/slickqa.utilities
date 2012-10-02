#!/bin/bash

#################################################################################
# Customize this section for your needs
LOCAL_SLICKIJ_URL="http://localhost:8080/slickij"
LOCAL_SLICKIJ_WAR=/Library/Tomcat/runtime/webapps/slickij.war
# A list of urls to jar files you want to add to slick
JARS_TO_ADD=""

# optionally put them in a file in your home directory
if [ -e ~/.slick-deploy ]
then
	. ~/.slick-deploy
fi
#################################################################################



LATEST_SLICKIJ_URL=`curl -s http://code.google.com/p/slickqa/downloads/list |grep "files.slickij-war" |head -1 |perl -pi -e 's/.*(\/\/.*?\d.war).*/http:$1/'`
LATEST_SLICKIJ_BUILD_NUMBER=`echo ${LATEST_SLICKIJ_URL} |perl -pi -e 's/.*?slickij-war-(.*?).war$/$1/'`

CURRENT_SLICKIJ_BUILD_NUMBER=`curl -s "${LOCAL_SLICKIJ_URL}/api/version/slick" |python -m json.tool |grep versionString |perl -pi -e 's/.*versionString.. .(.*).$/$1/'`

if [ "-f" = "$1" ]
then
    CURRENT_SLICKIJ_BUILD_NUMBER="Forced Upgrade"
fi

echo "Latest from google code: ${LATEST_SLICKIJ_BUILD_NUMBER}"
echo "Currently Deployed Version: ${CURRENT_SLICKIJ_BUILD_NUMBER}"

if [ "${LATEST_SLICKIJ_BUILD_NUMBER}" != "${CURRENT_SLICKIJ_BUILD_NUMBER}" ]
then
    echo "Downloading version ${LATEST_SLICKIJ_BUILD_NUMBER} from ${LATEST_SLICKIJ_URL}"

    if [ -e "slickij.war" ]
    then
        rm -f slickij.war
    fi

    curl -s -o slickij.war "${LATEST_SLICKIJ_URL}"
    echo "Done"
    if [ -n "${JARS_TO_ADD}" ]
    then
        if [ -e "WEB-INF" ]
        then
            rm -rf WEB-INF
        fi
        mkdir -p WEB-INF/lib
        for jarurl in ${JARS_TO_ADD};
        do
            cd WEB-INF/lib
            curl -O $jarurl
            cd -
        done
        jar uvf slickij.war WEB-INF/lib/*
    fi

    echo "Deploying slickij.war to ${LOCAL_SLICKIJ_WAR}"
    mv slickij.war "${LOCAL_SLICKIJ_WAR}"
	echo "Calling update REST call"
	sleep 10
	curl -X PUT "${LOCAL_SLICKIJ_URL}/api/updates"
fi
