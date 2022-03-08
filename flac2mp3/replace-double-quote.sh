#!/bin/bash
# Media Transfer Protocol Compatibility
# Replace 'double quote' with 'single quote', recursively.
find . -depth -name '*"*' \
    -execdir bash -c 'mv -- "$1" "${1//\"/'"\'"'}"' bash {} \;
