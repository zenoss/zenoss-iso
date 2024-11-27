FROM centos:7.9.2009

RUN <<EOT
set -eux
# Add a new repository to replace CentOS 7 mirrorlist
echo "[CentOS-Base]" > /etc/yum.repos.d/CentOS-Base.repo
echo "name=CentOS-Base" >> /etc/yum.repos.d/CentOS-Base.repo
echo "baseurl=http://vault.centos.org/7.9.2009/os/x86_64/" >> /etc/yum.repos.d/CentOS-Base.repo
echo "enabled=1" >> /etc/yum.repos.d/CentOS-Base.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/CentOS-Base.repo
# Clear yum cache and update system
yum clean all
yum update -y
# Install FPM.
yum install -y wget mkisofs yum-utils createrepo
EOT
COPY isolinux.cfg /
COPY zenoss-5-ks.cfg /
COPY makeiso.sh /
#
# /build is the directory that makeiso.sh expects to contain the ISO and tarball of RPMs
RUN mkdir -p /mnt/build
#
# /output is the directory that makeiso.sh will write the final ISO to
RUN mkdir -p /mnt/output

CMD /bin/bash /makeiso.sh
