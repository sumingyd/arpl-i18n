. /opt/arpl/include/i18n.sh
. /opt/arpl/include/consts.sh
. /opt/arpl/include/configFile.sh

###############################################################################
# Read key value from model config file
# 1 - Model
# 2 - Key
# Return Value
function readModelKey() {
  readConfigKey "${2}" "${MODEL_CONFIG_PATH}/${1}.yml"
}

###############################################################################
# Read Entries as map(key=value) from model config
# 1 - Model
# 2 - Path of key
# Returns map of values
function readModelMap() {
  readConfigMap "${2}" "${MODEL_CONFIG_PATH}/${1}.yml"
}

###############################################################################
# Read an array from model config
# 1 - Model
# 2 - Path of key
# Returns array/map of values
function readModelArray() {
  readConfigArray "${2}" "${MODEL_CONFIG_PATH}/${1}.yml"
}

###############################################################################
# Check if loader is fully configured
# Returns 1 if not
function loaderIsConfigured() {
  SN="$(readConfigKey "sn" "${USER_CONFIG_FILE}")"
  [ -z "${SN}" ] && return 1
  [ ! -f "${MOD_ZIMAGE_FILE}" ] && return 1
  [ ! -f "${MOD_RDGZ_FILE}" ] && return 1
  return 0 # OK
}

###############################################################################
# Just show error message and dies
function die() {
  echo -e "\033[1;41m$@\033[0m"
  exit 1
}

###############################################################################
# Show error message with log content and dies
function dieLog() {
  echo -en "\n\033[1;41mUNRECOVERY ERROR: "
  cat "${LOG_FILE}"
  echo -e "\033[0m"
  sleep 3
  exit 1
}

###############################################################################
# Generate a number with 6 digits from 1 to 30000
function random() {
  printf "%06d" $((${RANDOM} % 30000 + 1))
}

###############################################################################
# Generate a hexa number from 0x00 to 0xFF
function randomhex() {
  printf "&02X" "$((${RANDOM} % 255 + 1))"
}

###############################################################################
# Generate a random letter
function generateRandomLetter() {
  for i in A B C D E F G H J K L M N P Q R S T V W X Y Z; do
    echo ${i}
  done | sort -R | tail -1
}

###############################################################################
# Generate a random digit (0-9A-Z)
function generateRandomValue() {
  for i in 0 1 2 3 4 5 6 7 8 9 A B C D E F G H J K L M N P Q R S T V W X Y Z; do
    echo ${i}
  done | sort -R | tail -1
}

###############################################################################
# Generate a random serial number for a model
# 1 - Model
# Returns serial number
function generateSerial() {
  SERIAL="$(readModelArray "${1}" "serial.prefix" | sort -R | tail -1)"
  SERIAL+=$(readModelKey "${1}" "serial.middle")
  case "$(readModelKey "${1}" "serial.suffix")" in
  numeric)
    SERIAL+=$(random)
    ;;
  alpha)
    SERIAL+=$(generateRandomLetter)$(generateRandomValue)$(generateRandomValue)$(generateRandomValue)$(generateRandomValue)$(generateRandomLetter)
    ;;
  esac
  echo ${SERIAL}
}

###############################################################################
# Generate a MAC address for a model
# 1 - Model
# 2 - number
# Returns serial number
function generateMacAddress() {
  PRE="$(readModelArray "${1}" "serial.macpre")"
  SUF="$(printf '%02x%02x%02x' $((${RANDOM} % 256)) $((${RANDOM} % 256)) $((${RANDOM} % 256)))"
  NUM=${2:-1}
  for I in $(seq 1 ${NUM}); do
    printf '%06x%06x' $((0x${PRE:-"001132"})) $(($((0x${SUF})) + ${I}))
    [ ${I} -lt ${NUM} ] && printf ' '
  done
}

###############################################################################
# Validate a serial number for a model
# 1 - Model
# 2 - Serial number to test
# Returns 1 if serial number is valid
function validateSerial() {
  PREFIX=$(readModelArray "${1}" "serial.prefix")
  MIDDLE=$(readModelKey "${1}" "serial.middle")
  S=${2:0:4}
  P=${2:4:3}
  L=${#2}
  if [ ${L} -ne 13 ]; then
    echo 0
    return
  fi
  echo "${PREFIX}" | grep -q "${S}"
  if [ $? -eq 1 ]; then
    echo 0
    return
  fi
  if [ "${MIDDLE}" != "${P}" ]; then
    echo 0
    return
  fi
  echo 1
}

###############################################################################
# Check if a item exists into array
# 1 - Item
# 2.. - Array
# Return 0 if exists
function arrayExistItem() {
  EXISTS=1
  ITEM="${1}"
  shift
  for i in "$@"; do
    [ "${i}" = "${ITEM}" ] || continue
    EXISTS=0
    break
  done
  return ${EXISTS}
}

###############################################################################
# Get values in .conf K=V file
# 1 - key
# 2 - file
function _get_conf_kv() {
  grep "${1}" "${2}" | sed "s|^${1}=\"\(.*\)\"$|\1|g"
}

###############################################################################
# Replace/remove/add values in .conf K=V file
# 1 - name
# 2 - new_val
# 3 - path
function _set_conf_kv() {
  # Delete
  if [ -z "${2}" ]; then
    sed -i "${3}" -e "s/^${1}=.*$//"
    return $?
  fi

  # Replace
  if grep -q "^${1}=" "${3}"; then
    sed -i "${3}" -e "s\"^${1}=.*\"${1}=\\\"${2}\\\"\""
    return $?
  fi

  # Add if doesn't exist
  echo "${1}=\"${2}\"" >>"${3}"
}

###############################################################################
# Get fastest url in list
# @ - url list
function _get_fastest() {
  local speedlist=""
  for I in $@; do
    speed=$(ping -c 1 -W 5 ${I} 2>/dev/null | awk '/time=/ {print $7}' | cut -d '=' -f 2)
    speedlist+="${I} ${speed:-999}\n"
  done
  fastest="$(echo -e "${speedlist}" | tr -s '\n' | sort -k2n | head -1 | awk '{print $1}')"
  echo "${fastest}"
}

###############################################################################
# sort netif name
# @1 -mac1,mac2,mac3...
function _sort_netif() {
  ETHLIST=""
  ETHX=$(ls /sys/class/net/ | grep eth) # real network cards list
  for ETH in ${ETHX}; do
    MAC="$(cat /sys/class/net/${ETH}/address | sed 's/://g' | tr '[:upper:]' '[:lower:]')"
    BUS=$(ethtool -i ${ETH} | grep bus-info | awk '{print $2}')
    ETHLIST="${ETHLIST}${BUS} ${MAC} ${ETH}\n"
  done

  if [ -n "${1}" ]; then
    MACS=$(echo "${1}" | sed 's/://g' | tr '[:upper:]' '[:lower:]' | tr ',' ' ')
    ETHLISTTMPC=""
    ETHLISTTMPF=""

    for MACX in ${MACS}; do
      ETHLISTTMPC="${ETHLISTTMPC}$(echo -e "${ETHLIST}" | grep "${MACX}")\n"
    done

    while read -r BUS MAC ETH; do
      [ -z "${MAC}" ] && continue
      if echo "${MACS}" | grep -q "${MAC}"; then continue; fi
      ETHLISTTMPF="${ETHLISTTMPF}${BUS} ${MAC} ${ETH}\n"
    done <<EOF
$(echo -e ${ETHLIST} | sort)
EOF
    ETHLIST="${ETHLISTTMPC}${ETHLISTTMPF}"
  else
    ETHLIST="$(echo -e "${ETHLIST}" | sort)"
  fi
  ETHLIST="$(echo -e "${ETHLIST}" | grep -v '^$')"

  echo -e "${ETHLIST}" > /tmp/ethlist
  # cat /tmp/ethlist

  # sort
  IDX=0
  while true; do
    # cat /tmp/ethlist 
    [ ${IDX} -ge $(wc -l < /tmp/ethlist) ] && break
    ETH=$(cat /tmp/ethlist | sed -n "$((${IDX} + 1))p" | awk '{print $3}')
    # echo "ETH: ${ETH}"
    if [ -n "${ETH}" ] && [ ! "${ETH}" = "eth${IDX}" ]; then
      # echo "change ${ETH} <=> eth${IDX}"
      ip link set dev eth${IDX} down
      ip link set dev ${ETH} down
      sleep 1
      ip link set dev eth${IDX} name tmp
      ip link set dev ${ETH} name eth${IDX}
      ip link set dev tmp name ${ETH}
      sleep 1
      ip link set dev eth${IDX} up
      ip link set dev ${ETH} up
      sleep 1
      sed -i "s/eth${IDX}/tmp/" /tmp/ethlist
      sed -i "s/${ETH}/eth${IDX}/" /tmp/ethlist
      sed -i "s/tmp/${ETH}/" /tmp/ethlist
      sleep 1
    fi
    IDX=$((${IDX} + 1))
  done

  rm -f /tmp/ethlist
}

###############################################################################
# Find and mount the DSM root filesystem
# (based on pocopico's TCRP code)
function findAndMountDSMRoot() {
  [ $(mount | grep -i "${DSMROOT_PATH}" | wc -l) -gt 0 ] && return 0
  dsmrootdisk="$(blkid /dev/sd* | grep -i raid | awk '{print $1 " " $4}' | grep UUID | grep sd[a-z]1 | head -1 | awk -F ":" '{print $1}')"
  [ -z "${dsmrootdisk}" ] && return -1
  [ $(mount | grep -i "${DSMROOT_PATH}" | wc -l) -eq 0 ] && mount -t ext4 "${dsmrootdisk}" "${DSMROOT_PATH}"
  if [ $(mount | grep -i "${DSMROOT_PATH}" | wc -l) -eq 0 ]; then
    echo "Failed to mount"
    return -1
  fi
  return 0
}
