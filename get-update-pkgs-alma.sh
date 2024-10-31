#!/bin/bash

set -x
set -e
pwd

mkdir -p /home/alma/tmp
cd /home/alma/tmp

# Get dnf download
sudo dnf -y install dnf-utils tar
# The libcgroup tools were deprecated in RHEL 7.7 then then finally removed in 9.0.
sudo dnf config-manager --add-repo=http://vault.centos.org/centos/8-stream/BaseOS/x86_64/os/
sudo dnf --nogpgcheck install -y libcgroup

#
# Get a list of OS RPMs that need to be updated, then use dnf download to get
# each of those RPMs, and their dependencies
#
dnf makecache --timer
RPMS=`dnf list --updates | tail -n +3 | awk -F '[.]' '{ print $1 }'`
for rpm in $RPMS
do
	dnf download --resolve --alldeps $rpm
done

# Add in all of the other utilities that we want on the appliance images
dnf download --resolve --alldeps telnet
dnf download --resolve --alldeps nfs-utils
dnf download --resolve --alldeps nmap-ncat
dnf download --resolve --alldeps tar
dnf download --resolve --alldeps zip
dnf download --resolve --alldeps unzip
dnf download --resolve --alldeps nano
dnf download --resolve --alldeps sysstat
dnf download --resolve --alldeps dnf-utils
dnf download --resolve --alldeps wget
dnf download --resolve --alldeps python-chardet
dnf download --resolve --alldeps cloud-init
dnf download --resolve --alldeps open-vm-tools
dnf download --resolve --alldeps tcpdump
dnf download --resolve --alldeps dnsmasq
dnf download --resolve --alldeps bind-utils
dnf download --resolve --alldeps slirp4netns
dnf download --resolve --alldeps fuse-overlayfs
dnf download --resolve --alldeps container-selinux
dnf download --resolve --alldeps libcgroup
dnf download --resolve --alldeps sssd-nfs-idmap

tar -czvf ../alma9-os-rpms.tar.gz ./*.rpm

# Install the Zenoss repo so
curl -L -sO http://get.zenoss.io/yum/zenoss-repo-1-1.x86_64.rpm
sudo dnf localinstall -y zenoss-repo-1-1.x86_64.rpm

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/7/x86_64/stable

# Use dnf download to get all 3rd-party dependencies for CC
dnf download --enablerepo=zenoss-$CC_REPO --resolve --alldeps $CC_RPM --setopt=obsoletes=0

# Remove the CC package, so that we only bundling non-zenoss RPMs.
rm -f serviced* zenoss*

tar -czvf ../alma9-rpms.tar.gz ./*.rpm
