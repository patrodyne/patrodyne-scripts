#!/bin/bash
# Media Transfer Protocol Compatibility
# Replace 'question mark' with 'underscore', recursively.
find . -depth -name '*\?*' \
    -execdir bash -c 'mv -- "$1" "${1//\?/_}"' bash {} \;
