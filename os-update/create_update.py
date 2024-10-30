#!/usr/bin/env python

import argparse
import logging as log
import os

from subprocess import check_call, check_output
from urllib import urlretrieve
from urllib2 import urlopen

log.basicConfig(level=log.INFO)

# Default location for output is CWD
THIS_DIR = os.path.dirname(os.path.abspath(__file__))

# Config dir is the location of the ISO configuration files and builder script
CONFIG_DIR = os.path.abspath(os.path.join(THIS_DIR, 'builder'))

# Update scripts is in the same directory as this source file
UPDATESCRIPTS_DIR = os.path.abspath(os.path.join(THIS_DIR, 'update-scripts'))

# Note: the only unmodified file between what we need to have here and the
# zenoss-deploy update iso is the Makefile, and that just for which tag to
# use for the builder.  Rather than cloning zenoss-deploy just to parse out
# the ISO_TAG, we'll just use 7.2-10, which should work unless something
# changes in how we want to put this together.

# ISO Builder docker image.
ISO_TAG = "7.2-10"
DOCKER_BUILDER = 'zenoss/serviced-iso-build:%s' % ISO_TAG

# If you do not have access to docker hub:
# 1. Build the image with "make build"
# 2. Tag the resulting image as 'zenoss/serviced-iso-build:7.2-10'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make an update ISO package.')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to save appliance artifacts')
    parser.add_argument('--build-number', type=str, required=True,
                        help='the jenkins job build number')
    parser.add_argument('--os-mirror', type=str, required=True,
                        help='the os mirror rpm file')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)

    # Update builder image
    log.info('Calling docker pull to update the builder image')
    check_call('docker pull %s' % DOCKER_BUILDER, shell=True)

    # Create ISO
    cmd = 'docker run --privileged=true --rm'\
        ' -e "OS_MIRROR=%s"'\
        ' -e "BUILD_NUMBER=%s"'\
        ' -e "CENTOS_ABBREV=%s"'\
        ' -v=%s:/build'\
        ' -v=%s:/config'\
        ' -v=%s:/update-scripts'\
        ' -v=%s:/output'\
        ' %s /bin/bash /config/makeupdateiso.sh' % (
            args.os_mirror,
            args.build_number,
            os.environ.get("CENTOS_ABBREV"),
            build_dir,
            CONFIG_DIR,
            UPDATESCRIPTS_DIR,
            build_dir,
            DOCKER_BUILDER)
    log.info('Calling docker run to create the update ISO package')
    log.info('command is "%s"' % cmd)
    check_call(cmd, shell=True)
