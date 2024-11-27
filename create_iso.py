#!/usr/bin/env python

import argparse
import logging as log
import os

from subprocess import check_call


log.basicConfig(level=log.INFO)

# If you do not have access to docker hub:
# 1. Build the image in ./builder with "docker build ."
# 2. Tag the resulting image as base-1.0.2

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make a CentOS ISO.')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to find all of the inputs and outputs')
    parser.add_argument('--build-number', type=str, default="dev",
                        help='the build number')
    parser.add_argument('--base-iso', type=str, required=True,
                        help='CentOS original ISO to start from')
    parser.add_argument('--yum-mirror', type=str, required=True,
                        help='the name of the tar file containing RPM updates')
    parser.add_argument('--output-name', type=str, required=True,
                        help='the name of the ISO file to be created')
    parser.add_argument('--linux-os', type=str, required=True,
                        help='the name of linux distribution of docker builder')
    args = parser.parse_args()

    build_dir = os.path.abspath(args.build_dir)

    # Get builder image
    log.info('Calling docker pull to update ISO builder image')
    # ISO Builder docker image.
    DOCKER_BUILDER = 'zenoss/serviced-iso-build:%s-base-1.0.2' % args.linux_os
    check_call('docker pull %s' % DOCKER_BUILDER, shell=True)

    # Create the Serviced ISO from base_iso + yum mirror.
    # The result is saved as an ISO
    log.info('Calling docker run to create ISO')
    cmd = 'docker run -e "BASE_ISO_NAME=%s.iso" -e "YUM_MIRROR=%s" -e "ISO_FILENAME=%s" --privileged=true --rm -v=%s:/mnt/build -v=%s:/mnt/output %s' % (
                args.base_iso, args.yum_mirror, args.output_name,
                build_dir, build_dir,
                DOCKER_BUILDER)
    log.info('>%s' % cmd)
    check_call(cmd, shell=True)

