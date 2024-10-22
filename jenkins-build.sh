#!/bin/bash
#
# This script is intended to be called from a Jenkins job to rebuild the
# serviced base ISOs
#
if [ -z "${CC_REPO}" ]
then
    echo "ERROR: CC_REPO undefined"
    exit 1
fi

if [ -z "${CC_RPM}" ]
then
    echo "ERROR: CC_RPM undefined"
    exit 1
fi

CONSOLIDATED_OUTPUT=./consolidated-output
rm -rf ${CONSOLIDATED_OUTPUT}
mkdir -p ${CONSOLIDATED_OUTPUT}

set -e

export CENTOS_ISO=CentOS-7-x86_64-Minimal-2009
export ISO_CHECKSUM=a4711c4fa6a1fb32bd555fae8d885b12
./build-serviced-iso.sh

#
# Consolidate all of the artifacts in a single directory
#
mv -f ./output-centos*/update-os* ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/serviced* ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/*.tar.gz ${CONSOLIDATED_OUTPUT}
mv -f ./output-centos*/packer*.log ${CONSOLIDATED_OUTPUT}
