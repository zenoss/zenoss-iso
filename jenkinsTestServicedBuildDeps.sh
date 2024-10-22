#!/bin/bash
set -e
set -x

if [ -z ${SERVICED_RPM} ]
then
  echo "ERROR: SERVICED_RPM is undefined"
  exit 1
fi

if [ ! -d ./output ]; then
    mkdir -p output
fi

export BUILD_DIR=output
export PACKER_CACHE_DIR="${HOME}/packer_cache"
export PACKER_LOG=1
export PACKER_LOG_PATH="${BUILD_DIR}/packer-${SERVICED_RPM}.log"
SERVICED_ARTIFACT_BASENAME=serviced-1.10.1-1-stable-centos7.9.2009-bld-8
SERVICED_CENTOS_ISO_URL=http://artifacts.zenoss.eng/isos/serviced/${SERVICED_ARTIFACT_BASENAME}.iso
CHECKSUM_FILEPATH=output/${SERVICED_ARTIFACT_BASENAME}.md5sum.txt

wget -q http://artifacts.zenoss.eng/isos/serviced/${SERVICED_ARTIFACT_BASENAME}.md5sum.txt -O ${CHECKSUM_FILEPATH}
if [ ! -f ${CHECKSUM_FILEPATH} ]
then
  echo "ERROR: Cannot find ${CHECKSUM_FILEPATH}"
  exit 1
fi

SERVICED_CENTOS_ISO_CHECKSUM=`cat ${CHECKSUM_FILEPATH} | grep iso | awk '{print $1}'`

packer -machine-readable build -force -only=vmware-iso \
  -var iso_url=${SERVICED_CENTOS_ISO_URL} \
  -var iso_checksum=${SERVICED_CENTOS_ISO_CHECKSUM} \
  -var outputdir=./vm-output \
  -var cc_rpm=${SERVICED_RPM} \
  test-centos-base.json
