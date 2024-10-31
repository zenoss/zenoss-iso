FROM almalinux:9.4

RUN <<EOT
set -eux
# Install FPM.
dnf install -y wget mkisofs dnf-utils createrepo
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
