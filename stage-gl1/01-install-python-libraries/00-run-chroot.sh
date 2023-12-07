#!/bin/bash -e

set -ex

mkdir -p /opt/groundlight/venv
python3 -m venv /opt/groundlight/venv
source /opt/groundlight/venv/bin/activate

pipit() {
    /usr/bin/pip3 $@ 
}

pipit install groundlight
pipit install framegrab
