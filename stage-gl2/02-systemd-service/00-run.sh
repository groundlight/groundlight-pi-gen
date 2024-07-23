#!/bin/bash -e

GL_DIR="${ROOTFS_DIR}/opt/groundlight"
mkdir -p "${GL_DIR}/systemd"

install -v  files/service-up.sh             "${GL_DIR}/systemd/"
install -v  files/service-down.sh           "${GL_DIR}/systemd/"
install -v  files/groundlight-mns.service   "${ROOTFS_DIR}/etc/systemd/system/"

on_chroot << EOF
systemctl enable groundlight-mns
EOF

