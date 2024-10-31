#!/bin/bash

# Builds an ISO-based update package for Zenoss appliances
#
# Expects:
#   - /build the directory with the build bundle
#     (must include /build/manifest.json)
#   - /common the directory with shared appliance files
#   - /update-scripts maps to this source tree's update-scripts dir
#   - /output the directory where the resulting ISO goes

ISO_ID="${LINUX_OS_ABBREV}_os_update"
ISO_FILENAME="update-os-${LINUX_OS_ABBREV}-bld-${BUILD_NUMBER}.x86_64.iso"

cd /

# make working directory
mkdir -p working

# stage files needed for update. Note that we need standard and type files
# but we don't want to include files for other target types.
cp update-scripts/* working
cp /build/$OS_MIRROR working
chmod +x working/update-zenoss.sh

# build ISO
cd /working
mkisofs -o /output/$ISO_FILENAME \
        -V "$ISO_ID" \
        -R -J -v -T .

chmod a+rw /output/$ISO_FILENAME
