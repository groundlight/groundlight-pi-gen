#!/bin/bash

set -ex

mkdir -p "${ROOTFS_DIR}/opt/groundlight/systemd"
cp files/* "${ROOTFS_DIR}/opt/groundlight/systemd"

# rm first because layer caching
rm -f "${ROOTFS_DIR}/etc/systemd/system/groundlight-mns"
cp "${ROOTFS_DIR}/opt/groundlight/systemd/groundlight-mns.service" "${ROOTFS_DIR}/etc/systemd/system/"

log "$(cat ${ROOTFS_DIR}/etc/systemd/system/groundlight-mns.service)"

on_chroot << EOF
systemctl enable groundlight-mns
EOF

