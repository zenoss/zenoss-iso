#!/bin/bash
##############################################################################
#
# Copyright (C) Zenoss, Inc. 2017, all rights reserved.
#
# This content is made available according to terms specified in
# License.zenoss under the directory where your Zenoss product is installed.
#
##############################################################################

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="/tmp/upgrade-zenoss-os-$(date +'%Y-%m%d-%H%M%S').log"

function green () {
    tput setaf 2
    echo "$@"
    tput sgr0
}

# Sometimes the user will press keys while a task is
# executing.  We want to clear these keystrokes before
# prompting for input.
function clear_input() {
    while read -e -t 0.1; do : ; done
}

> $LOGFILE
exec > >(tee -a $LOGFILE)
exec 2> >(tee -a $LOGFILE >&2)
green "Operating System upgrade log stored at $LOGFILE."

function remove_os_mirror() {
    OLD_MIRROR=$(yum list --disablerepo=\* | awk '/^zenoss-os-mirror/ { print $1}')
    if [ ! -z "$OLD_MIRROR" ]; then
        green "Removing the Zenoss operating system mirror repository.."
        yum remove -y $OLD_MIRROR &> /dev/null
        green "...operating system mirror repository removed."
    fi
}

function replace_os_mirror() {
    green "Installing Zenoss operating system mirror repository..."
    # Replace old yum-mirror, if any, with new one.
    # TODO define OS and package manager
    RHEL_VERSION=$(awk '{print $4}' /etc/redhat-release)
    YUM_MIRROR=$(ls ${DIR}/centos${RHEL_VERSION}-os-bld-*)
    remove_os_mirror
    yum install -y $YUM_MIRROR 2>/dev/null
    yum clean all
    green "...Zenoss operating system mirror repository installed..."
}

# Update the OS based on our mirror.
function update_os() {
    # This should update the OS and other system libraries from our base mirror.
    yum -y --disablerepo=\* --enablerepo=zenoss-os-mirror update --skip-broken
}

replace_os_mirror

update_os

remove_os_mirror

green "The operating system update attempt succeeded."
green "The update log is $LOGFILE."
echo
clear_input
read -n1 -r -p "Press any key to reboot..."
reboot
