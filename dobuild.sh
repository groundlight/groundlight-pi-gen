#!/bin/bash

# local build - seems like maybe it's leaking system resources sometimes?
# time sudo $@ ./build.sh -c gl-config
# Instead we'll use docker build, which is slower but more reliable.
# docker build - slower but more reliable.

# check if the IS_RELEASE variable is set to "1"
if [ "$IS_RELEASE" = "1" ]; then
    echo "Building release version"
    CONFIG_FILE=gl-config-release
    rm -rf ./deploy
else
    echo "Building dev version"
    CONFIG_FILE=gl-config
fi

time PRESERVE_CONTAINER=1 $@ ./build-docker.sh -c $CONFIG_FILE

# If it's a release, rename the image files to include the tag name
# and take out the date.
if [ "$IS_RELEASE" = "1" ]; then
    TAG_NAME=${GITHUB_REF#refs/tags/}
    # See if tag name is set
    if [ -z "$TAG_NAME" ]; then
        echo "No tag name set.  Expecting TAG_NAME for release buid."
        exit 1
    fi

    cd deploy
    # Loop over every file named "image_*.img.xz"
    for file in ./image_*.img.xz; do
        # Get the filename without the path
        filename=$(basename -- "$file")

        # Files are named like image_2023-12-10-GroundlightPi-sdk.img.xz
        # Figure out the variant name by removing the image_date- predfix
        variant=$(echo $filename | cut -d '-' -f5-)
        # check that $variant is not empty, and does not include "Groundlight"
        if [ -z "$variant" ] || [[ "$variant" == *"Groundlight"* ]]; then
            echo "Failed to parse filename $filename - got $variant"
            exit 1
        fi
        new_file="GroundlightPi-$TAG_NAME-$variant.img.xz"

        # Rename the file
        echo "Renaming $file to $new_file"
        mv "$file" "$new_file"
    done

fi
