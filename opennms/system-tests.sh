#!/bin/sh -e
# We need a url
if [ $# -ne 1 ]; then
    echo "Usage: $0 <url>"
    exit 1
fi

# PARSE URL
URL=$1
BUILD=$(echo $URL | awk -F'/' '{ print $NF }')
PLAN_KEY=$(echo $BUILD | awk -F'-' '{ print $(NF-2) "-" $(NF-1) }')
BUILD_ID=$(echo $BUILD | awk -F'-' '{ print $NF }')

# Figure out RPM_VERSION
RPM_VERSION=$(curl -s https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/ | grep -i opennms-core | sed -E 's/(.*>)(opennms-core-)(.*)\.noarch.rpm<\/a>.*/\3/g')

# Start Downloading
export OPENNMS_RPM_ROOT=/tmp/docker_bamboo
mkdir -p $OPENNMS_RPM_ROOT
pushd $OPENNMS_RPM_ROOT

echo "Downloading rpms to build docker images"
echo "BUILD: $BUILD"
echo "PLAN_KEY: $PLAN_KEY"
echo "BUILD_ID: $BUILD_ID"
echo "RPM_VERSION: $RPM_VERSION"
echo "OPENNMS_RPM_ROOT: $OPENNMS_RPM_ROOT"

# ensure everything is initialized
if [ -z "$BUILD" -o -z "$PLAN_KEY" -o -z "$BUILD_ID" -o -z "$RPM_VERSION" ]; then
    echo "Something went wrong, not initialized correctly. Bailing.."
    exit 2
fi

rm -f *.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-core-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-minion-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-minion-container-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-minion-features-core-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-minion-features-default-$RPM_VERSION.noarch.rpm
wget https://bamboo.opennms.org/artifact/$PLAN_KEY/shared/build-$BUILD_ID/RPMs/opennms-webapp-jetty-$RPM_VERSION.noarch.rpm

pushd /Users/mvrueden/dev/opennms-system-test-api/docker
./copy-rpms.sh
./build-docker-images.sh
