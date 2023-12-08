#!/bin/bash

# local build - seems like maybe it's leaking system resources sometimes?
# time sudo $@ ./build.sh -c glmns-config

# docker build - slower but more reliable.
time PRESERVE_CONTAINER=1 $@ ./build-docker.sh -c glmns-config
