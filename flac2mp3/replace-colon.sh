#!/bin/bash
# Media Transfer Protocol Compatibility
# Replace 'colon' with 'equal sign', recursively.
find . -depth -name '*:*' \
    -execdir bash -c 'mv -- "$1" "${1//:/=}"' bash {} \;
