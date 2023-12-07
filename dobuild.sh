#!/bin/bash

# local build - seems like maybe it's leaking system resources sometimes?
# time sudo $@ ./build.sh -c glmns-config

# docker build - slower but more reliable.
time $@ ./build-docker.sh -c glmns-config
