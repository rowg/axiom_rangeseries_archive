#!/bin/bash

SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519_range_series_archival}"
RADIAL_CONFIGS_DIR="${RADIAL_CONFIGS_DIR:-/Codar/SeaSonde/Configs/RadialConfigs}"
RADIAL_CONFIGS_HEADER="${RADIAL_CONFIGS_DIR}/Header.txt"
RANGE_SERIES_DIR="${RANGE_SERIES_DIR:-/Codar/SeaSonde/Data/RangeSeries}"
SYNC_DIR="${HOME}/range-series-archival"
SSH_HOST="${SSH_HOST:-data.axds.co}"

cat <<EOF
HFR Range Series Archival Data Pipeline Setup Tool
--------------------------------------------------

EOF

#check for required executables
for e in rsync shlock; do
  if ! command -v $e &> /dev/null; then
    echo "Required executable $e not found, please install and retry" >&2
    exit 1
  fi
done
echo "✓ Required executables found"

#create sync dir if necessary
if ! [ -d "$SYNC_DIR" ]; then
  echo "Creating sync directory $SYNC_DIR"
  mkdir -p "$SYNC_DIR"
fi

if [ -d "$SYNC_DIR" ]; then
  echo "✓ Sync directory $SYNC_DIR found"
else
  echo "! Sync directory $SYNC_DIR not found" >&2
  exit 1
fi

#check for ssh user
SSH_USER_FILE="$SYNC_DIR/.ssh_user"
if [ -n "$SSH_USER" ]; then
  echo "✓ SSH user $SSH_USER supplied as environment variable, writing to $SSH_USER_FILE"
  echo "$SSH_USER" > "$SSH_USER_FILE"
elif [ -f "$SSH_USER_FILE" ]; then
  SSH_USER=$(cat "$SSH_USER_FILE")
  if [ -n "$SSH_USER" ]; then
    echo "✓ Found SSH user $SSH_USER in $SSH_USER_FILE"
  fi
fi

#prompt for SSH user and save it if not set
while [ -z "$SSH_USER" ]; do
  echo "Enter the SSH username for the connection to $SSH_HOST and press enter (e.g. hfr_your_org)."
  echo "If you're not sure, please ask the range series data coordinator."
  read -p "SSH username: " SSH_USER
  if [ -n "$SSH_USER" ]; then
    echo "$SSH_USER" > "$SSH_USER_FILE"
  else
    echo "SSH user is required/cannot be blank."
  fi
done

#check ssh key and generate if needed
if ! [ -f "$SSH_KEY" ]; then
  echo "SSH key $SSH_KEY not found, generating a new ed25519 key"
  ssh-keygen -f "${SSH_KEY}" -t ed25519 -P "" -C range_series@$(hostname)
fi

#ensure ssh key is a valid key
if ! ssh-keygen -y -f "$SSH_KEY" > /dev/null; then
  echo "! SSH key $SSH_KEY is invalid, please fix or delete/move and run again to regenerate" >&2
  exit 1
else
  echo "✓ SSH key $SSH_KEY is valid"
fi

#parse site code from radial configs header
SITE_CODE=$(head -1 "$RADIAL_CONFIGS_HEADER" | awk '{print $2}' | tr '[a-z]' '[A-Z]')
if [ -n "$SITE_CODE" ]; then
  echo "✓ Found site code $SITE_CODE"
else
  echo "! Could not parse site code from $RADIAL_CONFIGS_HEADER" >&2
  exit 1
fi

#ensure range series dir exists
if [ -d "${RANGE_SERIES_DIR}" ]; then
  echo "✓ Range series data directory $RANGE_SERIES_DIR exists"
else
  echo "! Range series directory ${RANGE_SERIES_DIR} does not exist" >&2
  exit
fi

#check if recent range series files exist in range series dir
if command -v find &> /dev/null && command -v grep &> /dev/null; then
  if find /Codar/SeaSonde/Data/RangeSeries -type f -name '*.rs' -newermt '1 day ago' | grep -q .; then
    echo "✓ Recent .rs files found in ${RANGE_SERIES_DIR}"
  else
    echo "⚠ No recent .rs files found in ${RANGE_SERIES_DIR}" >&2
  fi
fi

#write sync script
SYNC_SCRIPT="$SYNC_DIR/range-series-sync.sh"
echo "✓ Writing sync script to $SYNC_SCRIPT"
#NOTE: unfortunately the rsync version currently available on macs (2.6.9)
#doesn't support --mkpath, so we have to use extra steps or tricks
#to make sure the target directories exist

cat <<EOF > "$SYNC_SCRIPT"
#!/bin/bash
cd "\$(dirname "\$0")"

RSYNC_EXTRA_ARGS=""
while getopts ":n" opt; do
  case \${opt} in
    n )
      RSYNC_EXTRA_ARGS="\$RSYNC_EXTRA_ARGS -n"
      ;;
    \? )
      echo "Invalid option: \$OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: \$OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift \$((OPTIND -1))

function sync_files {
  LOCAL_PATH="\$1"
  REMOTE_PATH="\$2"

  echo "Syncing \$LOCAL_PATH/ to ${SITE_CODE}/\${REMOTE_PATH}/"
  rsync -e "ssh -o UpdateHostKeys=no -i $SSH_KEY" \
    -rtiuz --partial --delete \$RSYNC_EXTRA_ARGS "\${LOCAL_PATH}/" \
    ${SSH_USER}@${SSH_HOST}:${SITE_CODE}/\${REMOTE_PATH}/
}

#accept new host certificate and create site dir if needed
rsync -e "ssh -o StrictHostKeyChecking=accept-new -o UpdateHostKeys=no -i $SSH_KEY" \
  /dev/null ${SSH_USER}@${SSH_HOST}:${SITE_CODE}/ &>/dev/null

if [ -n "\$1" ] && [ -n "\$2" ]; then
  #specific local and remote paths were passed, sync those
  if ! [ -e "\$1" ]; then
    echo "Target local path \$1 does not exist" >&2
    exit 1
   fi
   sync_files "\$1" "\$2"
else
  #otherwise sync normal set of directories
  LOCK="./sync.lock"
  if shlock -f \$LOCK -p \$\$; then
    sync_files "$RANGE_SERIES_DIR" RangeSeries
    sync_files "$RADIAL_CONFIGS_DIR" RadialConfigs
    rm \$LOCK
  else
    echo "Lock file \$LOCK is already locked"
  fi
fi
EOF

chmod u+x "$SYNC_SCRIPT"

#show SSH public key
cat <<EOF

==============
SSH PUBLIC KEY
==============

Please send the following SSH public key to the range series
data coordinator. Sending in plain text over email, chat, etc
is fine, as this public key is not a secret.

EOF

ssh-keygen -y -f "$SSH_KEY"

#output suggested cronjob
if ! crontab -l | grep -q "$SYNC_SCRIPT"; then
  cat <<EOF

======================
CRONTAB SCHEDULED TASK
======================

Sync script was not detected in the user's crontab. To execute the sync hourly,
run "crontab -e" and add the following line (or similar):

0 * * * * $SYNC_SCRIPT >> $SYNC_DIR/sync.log 2>&1

EOF
fi
