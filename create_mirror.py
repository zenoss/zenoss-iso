#!/usr/bin/env python

import argparse
import logging as log
import os
import shutil

from subprocess import check_call


log.basicConfig(level=log.INFO)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description= 'Make a Linux OS ISO.')
    parser.add_argument('--build-dir', type=str, required=True,
                        help='where to find all of the inputs and outputs')
    parser.add_argument('--build-number', type=str, default="dev",
                        help='the build number')
    parser.add_argument('--base-iso', type=str, required=True,
                        help='Linux OS original ISO to start from')
    parser.add_argument('--rpm-tarfile', type=str, required=True,
                        help='the name of the tar file containing RPM updates')
    parser.add_argument('--output-name', type=str, required=True,
                        help='the name of the RPM file to be created')
    parser.add_argument('--mirror-name', type=str, default="yum-mirror",
                        help='the name of the yum/dnf mirror to be created')
    parser.add_argument('--mirror-key', type=str, default="zenoss-mirror",
                        help='the name of the yum/dnf mirror key')
    parser.add_argument('--mirror-dirname', type=str, default="zenoss-repo-mirror",
                        help='the directory name under /opt for the mirror')
    args = parser.parse_args()

    scripts_dir = os.getcwd()
    build_dir = os.path.abspath(args.build_dir)
    output_path = os.path.join(build_dir, args.output_name)
    mirror_name = args.mirror_name

    mirror_dir = os.path.join(build_dir, "mirror")
    rpmroot = os.path.join(mirror_dir, "rpmroot")
    cleanup_cmd = "sudo rm -rf {}".format(rpmroot)
    check_call(cleanup_cmd, shell=True)

    log.info("Creating %s repo definition" % args.mirror_key)
    reposdir = os.path.join(rpmroot, "etc/yum.repos.d")
    os.makedirs(reposdir)
    zenoss_mirror_def = """[%s]
name=Local Zenoss mirror for offline installs
baseurl=file:///opt/%s
enabled=1
gpgcheck=0
""" % (args.mirror_key, args.mirror_dirname)
    with open(os.path.join(reposdir, "%s.repo" % args.mirror_key), 'w') as f:
        f.write(zenoss_mirror_def)

    log.info("Untarring RPMs ...")
    mirror_rpm_dir = os.path.join(rpmroot, "opt/%s" % args.mirror_dirname)
    os.makedirs(mirror_rpm_dir)
    os.chdir(mirror_rpm_dir)
    untar_cmd="tar xvf ../../../../{}".format(args.rpm_tarfile)
    check_call(untar_cmd, shell=True)

    # Make sure we have access to the mkyum repo.
    mkyum_path = os.path.join(scripts_dir, "mkyum")
    mkrepo_path = os.path.join(mkyum_path, 'mkrepo')
    if not os.path.exists(mkyum_path):
        log.info("Retrieving mkyum..")
        # Clone the mkyum repo from the master branch.
        branch = "master"
        cmd = ["git", "clone", "git@github.com:zenoss/mkyum.git", "--branch", branch, "--single-branch", mkyum_path]
        check_call(cmd)

    # Build the zenoss/mkyum docker image.
    os.chdir(mkrepo_path)
    log.info("Building the mkyum image..")
    base_iso_mkyum_target = {
        "Rocky-9.4-x86_64-minimal": "rocky9",
        "AlmaLinux-9.4-x86_64-minimal": "almalinux9",
        "CentOS-7-x86_64-Minimal-2009": "centos7"
    }
    check_call("make mkyum-build LINUX_OS=%s" % base_iso_mkyum_target[args.base_iso], shell=True)

    log.info("Building mirror RPM ...")
    version_file = os.path.join(mkrepo_path, 'VERSION')
    with open(version_file, 'r') as fd:
        mkyum_version = fd.read().strip()
    docker_image = "zenoss/mkyum:{}-{}".format(base_iso_mkyum_target[args.base_iso], mkyum_version)
    docker_run="docker run --rm -e MIRROR_DIRNAME={} -e MIRROR_FILE={} -e MIRROR_VERSION=1 -v {}:/scripts -v {}:/shared {} /scripts/convert-repo-mirror.sh".format(
        args.mirror_dirname, mirror_name, scripts_dir, mirror_dir, docker_image)
    print ">%s" % docker_run
    check_call(docker_run, shell=True)

    mirror_file = "{}-1-1.x86_64.rpm".format(mirror_name)
    mirror_path = os.path.join(mirror_dir, mirror_file)
    log.info("mirror_path %s" % mirror_path)
    log.info("output_path %s" % output_path)
    shutil.move(mirror_path, output_path)
    check_call(cleanup_cmd, shell=True)

    # sign the rpm
    os.chdir(mkrepo_path)
    os.environ["HOST_RPM_LOC"] = build_dir
    check_call("make sign-rpms LINUX_OS=%s" % base_iso_mkyum_target[args.base_iso], shell=True)
