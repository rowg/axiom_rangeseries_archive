#!/bin/bash
#hf-radar-archive-manager
#Organizes incoming HF radar range series and config files, either by
#watching a directory for new data via inotify or scanning the entire contents
#of a directory for matching files.
#See README for more details.

ARCHIVE_DIR=${ARCHIVE_DIR:-./archive}

DRY_RUN=0
WATCH=0
RESCAN_WAIT_SECONDS=0
while getopts ":a:no:r:s:w" opt; do
  case ${opt} in
    a )
      ARCHIVE_DIR="$OPTARG"
      ;;
    n )
      DRY_RUN=1
      ;;
    o )
      OPERATOR="$OPTARG"
      ;;
    r )
      RESCAN_WAIT_SECONDS="$OPTARG"
      ;;
    w )
      WATCH=1
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

SOURCE_DIR="${SOURCE_DIR:-$1}"

if [ -z "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR must be specified as an argument or environment variable" >&2
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR $SOURCE_DIR doesn't exist" >&2
  exit 1
fi

if [ -z "$OPERATOR" ]; then
  echo "OPERATOR must be set with the -o flag (e.g. -o UCSB)" >&2
  exit 1
fi

function check_command {
  for c in $@; do
    if ! command -v $c &> /dev/null; then
      echo "$c is required" >&2
      exit 1
    fi
  done
}

function site_archive_dir {
  local SITE="$1"
  local SITE_ARCHIVE_DIR="${ARCHIVE_DIR}/${OPERATOR}/${1}"
  if [ "$DRY_RUN" -eq "0" ]; then
    mkdir -p "$SITE_ARCHIVE_DIR" &> /dev/null
  fi
  echo "$SITE_ARCHIVE_DIR"
}

function filename_date_offset {
  echo -n "Rng_$1_" | wc -m
}

function organize_range_series_file {
  local RANGE_SERIES_PATH="$1"
  local RANGE_SERIES_FILENAME="$(basename $RANGE_SERIES_PATH)"
  local SITE_ARCHIVE_DIR=$2
  local DATE_OFFSET=$3

  #if SITE_ARCHIVE_DIR and/or DATE_OFFSET were not passed, determine them
  if [ -z "$SITE_ARCHIVE_DIR" ] || [ -z "$DATE_OFFSET" ]; then
    local SITE=$(cut -d_ -f2 <<< "$RANGE_SERIES_FILENAME" | tr '[:lower:]' '[:upper:]')
    if [ "$SITE" == "XXXX" ]; then
      echo "Skipping site XXXX (instrument startup artifact)"
      return
    fi

    if [ -z "$SITE_ARCHIVE_DIR" ]; then
      SITE_ARCHIVE_DIR="$(site_archive_dir $SITE)"
    fi

    if [ -z "$DATE_OFFSET" ]; then
      DATE_OFFSET=$(filename_date_offset $SITE)
    fi
  fi

  DATE=${RANGE_SERIES_FILENAME:$DATE_OFFSET:10}
  YEAR=${DATE:0:4}
  MONTH=${DATE:5:2}
  DAY=${DATE:8:2}

  #sanity check date
  if ! date -d "${YEAR}-${MONTH}-${DAY}" &> /dev/null; then
    echo -n "${RANGE_SERIES_PATH} parsed date is invalid" >&2
    echo " (${YEAR}-${MONTH}-${DAY}, offset ${DATE_OFFSET}, skipping" >&2
    return
  fi

  TARGET_DIR="${SITE_ARCHIVE_DIR}/RangeSeries/${YEAR}/${MONTH}/${DAY}"
  TARGET_PATH="${TARGET_DIR}/${RANGE_SERIES_FILENAME}"
  #make sure source file still exists, as it may have been deleted
  #before the while loop finishes processing (older file)
  if [ "$DRY_RUN" -eq "0" ] && [ -f "${RANGE_SERIES_PATH}" ]; then
    test -d "${TARGET_DIR}" || mkdir -p "${TARGET_DIR}"
    cp --update "${RANGE_SERIES_PATH}" "${TARGET_PATH}"
  else
    ! test -f "${TARGET_PATH}" && echo "${RANGE_SERIES_PATH} -> ${TARGET_PATH}"
  fi
}

function snapshot_configs {
  local SITE_SOURCE_DIR="$1"
  local SITE_ARCHIVE_DIR="$2"
  if [ -z "$SOURCE_DIR" ]; then
    echo "Site source dir must be passed as first arugment to archive_configs" >&2
  fi
  if [ -z "$SITE_ARCHIVE_DIR" ]; then
    echo "Site archive dir must be passed as second arugment to archive_configs" >&2
  fi
  local DATE=$(date -u "+%Y%m%dT%H%M%SZ")
  local TARGET_DIR="$SITE_ARCHIVE_DIR/Configs"

  find "$SITE_SOURCE_DIR" -name Configs -o -name RadialConfigs -print0 | while read -d $'\0' d; do
    #if $d is empty the below rsync will copy the root filesystem into the config backup,
    #so guard against it even though it should never happen
    if [ -z "$d" ]; then
      echo "WARN: Empty config directory variable found for $SITE_SOURCE_DIR" >&2
      return
    fi

    if [ -d "./$TARGET_DIR/current" ]; then
      LINKDEST="--link-dest ../current"
    fi

    mkdir -p "${TARGET_DIR}"
    #only create a new snapshot if rsync has changes to propagate
    if rsync -na --delete -i $LINKDEST "${d}/" "${TARGET_DIR}/current" | grep . &> /dev/null; then
      echo "Creating new snapshot of config state for ${TARGET_DIR} at ${DATE}"
      if [ "$DRY_RUN" -eq "0" ]; then
        mkdir -p "$TARGET_DIR"
        rsync -a --delete $LINKDEST "${d}/" "${TARGET_DIR}/$DATE"
        #point $TARGET_DIR/current symlink to the new incremental backup directory
        ln -fnrs "${TARGET_DIR}/$DATE" "${TARGET_DIR}/current"
      fi
    fi
  done
}

if [ "$WATCH" -eq "1" ]; then
  #Watch the source dir for new or updated range series files
  echo "Watching directory $SOURCE_DIR for range series files"
  check_command inotifywait
  inotifywait -q -m -r -e close_write -e moved_to "$SOURCE_DIR" | while read path action file; do
    lcasefile="${file,,}"
    if [ "${lcasefile: -3}" == ".rs" ]; then
      echo $action ${path}${file}
      organize_range_series_file "${path}${file}"
    fi
  done
else
  while true; do
    #Scan the source dir for all matching files
    check_command rsync
    find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z | while read -d $'\0' site_dir; do
      echo $site_dir
      SITE=$(basename "$site_dir" | tr '[:lower:]' '[:upper:]')
      SITE_ARCHIVE_DIR="$(site_archive_dir $SITE)"

      #organize range series files
      DATE_OFFSET=$(filename_date_offset $SITE)
      find $site_dir -type f -iname "Rng_$SITE_*" -print0 | sort -z | while read -d $'\0' file; do
        organize_range_series_file "$file" "$SITE_ARCHIVE_DIR" $DATE_OFFSET
      done

      #snapshot configs
      snapshot_configs "$site_dir" "$SITE_ARCHIVE_DIR"
    done

    #exit or sleep specified seconds and scan again
    if [ "$RESCAN_WAIT_SECONDS" == "0" ]; then
       break
    else
       echo "Sleeping $RESCAN_WAIT_SECONDS seconds"
       sleep $RESCAN_WAIT_SECONDS
    fi
  done
fi
