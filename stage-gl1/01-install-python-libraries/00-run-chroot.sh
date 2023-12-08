#!/bin/bash -e

pipit() {
    /usr/bin/pip3 $@ --break-system-packages
}

pipit install groundlight
# Framegrab will try to re-install opencv, which won't go well.
pipit install --no-deps framegrab
