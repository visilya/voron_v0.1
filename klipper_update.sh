#!/usr/bin/env bash
# Get CAN devicies id
# ~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0

set -e

### Start config ###
MCU_NAME=mcu

MB_NAME=CB1
#MB_CAN=ce5f75f5c4f0
#MB_FLASH_DEVICE=0483:df11
MB_FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_stm32g0b1xx_4A00280011504B4633373520-if00
MB_PID=1d50
MB_VID=614e

HEAD_NAME=ebb
HEAD_CAN=23c5470ece0e

WORKING_DIR=/home/biqu
### End config ###


#===================================================#
#=================== KIAUH SCRIPTS =================#
#===================================================#
git -C $WORKING_DIR/kiauh/ pull 

### sourcing all additional scripts
#KIAUH_SRCDIR="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
KIAUH_SRCDIR=$WORKING_DIR/kiauh
for script in "${KIAUH_SRCDIR}/scripts/"*.sh; do . "${script}"; done
for script in "${KIAUH_SRCDIR}/scripts/ui/"*.sh; do . "${script}"; done

set_globals
#kiauh_update_dialog
#main_menu

#update_klipper
$WORKING_DIR/moonraker-env/bin/python -m pip install --upgrade pip
update_moonraker
update_mainsail
#update_fluidd
#update_klipperscreen
#update_pgc_for_klipper
#update_telegram_bot
#update_moonraker_obico
#update_octoeverywhere
#update_crowsnest
#update_system
#===================================================#
#===================== KIAUH END ===================#
#===================================================#

ask=$1
forceflash=$2

build_klipper() {
  pid=$3
  vid=$4
  echo ----------- $1 -----------
  KCONFIG_FILE=$WORKING_DIR/klipper_config/script/klipper_$1.cfg
  if [ ! -f "$KCONFIG_FILE" ]; then
    if [[ "$ask" == "1" ]]; then
      echo "$KCONFIG_FILE does not exists."
      read -p "Do you want to configure $1? [Y:n]" -n 1 -r REPLY
      REPLY=${REPLY:-Y}
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        make menuconfig KCONFIG_CONFIG=$KCONFIG_FILE
      else
        read -p "Abort bash file? [y:N]" -n 1 -r REPLY
        REPLY=${REPLY:-N}
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          exit 1
        fi
      fi
    else
      echo "$KCONFIG_FILE does not exists."
      exit 1
    fi
  fi
  if [[ "$ask" == "2" ]]; then
    read -p "Do you want to configure $1? [Y:n]" -n 1 -r REPLY
    REPLY=${REPLY:-Y}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      make menuconfig KCONFIG_CONFIG=$KCONFIG_FILE
    fi
  fi
  if [ -f "$KCONFIG_FILE" ]; then
    # sed -i -e '1iOUT=out_'"$1"'/' -e '/OUT=/d' $KCONFIG_FILE
    sed -i -e '/OUT=/d' $KCONFIG_FILE
    if [[ "$2" == "build" ]]; then
      make clean KCONFIG_CONFIG=$KCONFIG_FILE OUT=out_$1/
      make KCONFIG_CONFIG=$KCONFIG_FILE OUT=out_$1/
    fi
    if [[ "$2" == "flash" ]]; then
      make flash $3 KCONFIG_CONFIG=$KCONFIG_FILE OUT=out_$1/
    fi
    if [[ "$2" == "add_dfu_suffix" ]]; then
      dfu-suffix -D $WORKING_DIR/klipper/out_$1/klipper.bin
      dfu-suffix -p $pid -v $vid -a $WORKING_DIR/klipper/out_$1/klipper.bin
    fi
  fi
}

main() {
  cd $WORKING_DIR/klipper/
  klipper_ver=$(git rev-parse HEAD)
  git pull
  if [[ $klipper_ver == $(git rev-parse HEAD)]] && ! [["$forceflash" == "1" ]]; then
    # Same klipper version.
    echo "Exiting."
    exit 0
  fi

  rm -rf $WORKING_DIR/klipper/out

  echo "Building klipper"
  #build_klipper $MCU_NAME
  build_klipper $MB_NAME build
  build_klipper $HEAD_NAME build

  echo "Stoping services"
  service klipper stop
  #service klipper_mcu stop

  echo "Flashing"
  ### Flash MCU (rpi)
  #build_klipper $MCU_NAME flash

  ### Flash MB
  build_klipper $MB_NAME add_dfu_suffix $MB_PID $MB_VID || true
  build_klipper $MB_NAME flash FLASH_DEVICE=$MB_FLASH_DEVICE || true

  ### Flash HEAD
  python3 $WORKING_DIR/CanBoot/scripts/flash_can.py -i can0 -f $WORKING_DIR/klipper/out_$HEAD_NAME/klipper.bin -u $HEAD_CAN

  echo "List CAN devices"
  $WORKING_DIR/klippy-env/bin/python $WORKING_DIR/klipper/scripts/canbus_query.py can0 || true

  echo "Starting services"
  #service klipper_mcu start
  service klipper start
}

main

exit 0
