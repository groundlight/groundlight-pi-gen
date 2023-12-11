#!/bin/bash -e

mkdir -p /opt/groundlight
cd /opt/groundlight

# Make sure the directory we'll clone into is gone, or else git will error.
# (This happens with cached partial builds.)
rm -rf monitoring-notification-server
git clone https://github.com/groundlight/monitoring-notification-server

