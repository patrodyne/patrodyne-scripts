#!/bin/sh
# PatroDyne: Patron Supported Dynamic Executables, http://patrodyne.org
# MIT license: https://raw.githubusercontent.com/patrodyne/patrodyne-scripts/master/LICENSE
#
# flac2mp3.sh - Linux script to convert FLAC audio files to MP3 files.
#
# Usage:
#
#   Background: flac2mp3.sh </dev/null >flac2mp3.log 2>&1 &
#   Foreground: flac2mp3.sh 2>&1 | tee flac2mp3.log
#
# Description: This script recursively finds all files with '*.flac' suffix
# within the SOURCEDIR, it uses ffmpeg to convert each file and write the
# '*.mp3' transformation into the TARGETDIR. Hidden files are ignored. Target
# folders are created, as needed.  Files are processed in groups of parallel
# background jobs. The group size is set using the CORES variable. Set CORES to
# the number of CPU core(s) that you have (or less to reserve CPU(s) for other
# work). If the source directories contain a COVERART image file, it will be
# embedded in each associated target file.
#
# Set the SOURCEDIR, TARGETDIR, COVERART, BITRATE and CORES for your needs.
#

SOURCEDIR="PATH_TO_FLAC/flac"
TARGETDIR="PATH_TO_MP3/mp3"
COVERART="cover.jpg"
BITRATE="192k"
CORES=4

BASEDIR="$(dirname $0)"
SOURCEFMT="flac"
TARGETFMT="mp3"
COUNTER=0
INDEX=0

DONE=false
find ${BASEDIR}/${SOURCEDIR} -name '*' | until ${DONE}
  do
    read SOURCE || DONE=true
    # Copy non-FLACs as is, insert FLACs to process in array
    if [[ ! "${SOURCE}" =~ .*/\..* ]]; then
      TARGET=$(echo "${SOURCE}" | sed -e "s#^${BASEDIR}/${SOURCEDIR}#${BASEDIR}/${TARGETDIR}#")
      if [[ -d "${SOURCE}" && ! -e "${TARGET}" ]]; then
        mkdir -p "${TARGET}"
      elif [[ -f "${SOURCE}" && ! -e "${TARGET}" ]]; then
        if [[ "${SOURCE}" =~ .*\.${SOURCEFMT} ]]; then
          COUNTER=$(expr ${COUNTER} + 1)
          INDEX=$(expr ${INDEX} + 1)
          SOURCE[$INDEX]="${SOURCE}"
          TARGET[$INDEX]="${TARGET%.*}.${TARGETFMT}"
        else
          cp "${SOURCE}" "${TARGET}"
        fi
      fi
    fi

    # Process multiple FLACs in parallel.
    if [[ "${DONE}" = "true" || $(expr ${COUNTER} % ${CORES}) -eq 0 ]]; then
      while [ ${INDEX} -gt 0 ]
        do
          SOURCEART=$(dirname "${SOURCE[$INDEX]}")/${COVERART}
          if [ -f "${SOURCEART}" ]; then
            echo "${COUNTER}.${INDEX}, COVER: ${SOURCE[$INDEX]}"
            ffmpeg -nostdin -loglevel error -i "${SOURCE[$INDEX]}" \
              -i "${SOURCEART}" -map 0:0 -map 1:0 \
              -metadata:s:v title="Album cover" \
              -metadata:s:v comment="Cover (front)" \
              -map_metadata 0 -id3v2_version 3 -b:a ${BITRATE} "${TARGET[$INDEX]}" &
            PID[INDEX]=$!
          else
            echo "${COUNTER}.${INDEX}, NOCOVER: ${SOURCE[$INDEX]}"
            ffmpeg -nostdin -loglevel error -i "${SOURCE[$INDEX]}" \
              -map_metadata 0 -id3v2_version 3 -b:a ${BITRATE} "${TARGET[$INDEX]}" &
            PID[INDEX]=$!
          fi
          INDEX=$(expr ${INDEX} - 1)
        done
      wait $(printf "%s " "${PID[@]}") >/dev/null 2>&1
    fi
  done
