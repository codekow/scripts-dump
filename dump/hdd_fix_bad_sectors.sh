#!/bin/bash
# set -x

# REPAIR=YES

check_bins(){
  which hdparm || exit 0
  which smartctl || exit 0
}

choose_repair(){
  read -r -p "Do you want to attempt repair (enter: YES)?: " REPAIR
}

debug(){
  echo -ne "$1:  ${SECTOR} on ${DRIVE}\r"
}

select_drive(){
  DRIVE=${1:-/dev/sda}
  echo "DRIVE: ${DRIVE}"
  sleep 2
}

dmesg_range(){

  echo "DMESG: START"

  for i in $(dmesg | grep 'error,' | grep 'sector' | sed 's/.* dev //; s/, sector /,/; s/ op.*$//')
  #for i in $(dmesg | grep sector | grep error | sed 's/.* sector \([0-9]*\) .*/\1/' | sort)
  do
    SECTOR=$(echo "$i" | cut -f2 -d',')
    DRIVE=/dev/$(echo "$i" | cut -f1 -d',')

    echo "DRIVE: ${DRIVE}"
    echo "SECTOR: ${SECTOR}"
  done

  echo "DMESG: END"
}

enter_target(){
  RANGE=60
  FOUND=$(smartctl -x "${DRIVE}" | grep ' failure' -m1 | awk '{print $10 }' )
  FOUND=${1:-$FOUND}

  START=$((FOUND-RANGE))
  FINISH=$((FOUND+RANGE))

  [ "${START}" -lt "0" ] && exit 0
  [ -z ${1+x} ] && echo "RANGE: scraped from smartctl"

  echo RANGE: $START $FINISH
  sleep 2
}

check_range(){
  SECTOR=${START:-0}

  while [ "${SECTOR}" -le ${FINISH} ]
  do
    check_sector && {
      debug GOOD
    } || {
      echo ""
      debug BAD
      [ "${REPAIR}" == "YES" ] && {
        repair_sector
        BAD_LIST="${SECTOR},${BAD_LIST}"
      }
    }

    ((++SECTOR))

  done

  unset SECTOR

}

check_sector(){
  RESULT=$(hdparm \
    --read-sector \
    "${SECTOR}" \
    "${DRIVE}" 2>&1 >/dev/null)
  RC=$?
  if [ "${RESULT}" = "" ]; then
    return ${RC}
  else
    return 1
  fi
}

repair_sector(){
  hdparm \
    --yes-i-know-what-i-am-doing \
    --repair-sector \
    "${SECTOR}" \
    "${DRIVE}"
}

smart_retest(){
  echo -ne '\n'
  [ "${BAD_LIST}" == "" ] && exit
  smartctl -t short "${DRIVE}"
}

check_bins
dmesg_range
choose_repair
select_drive "${1}"
enter_target "${2}"
check_range
smart_retest
