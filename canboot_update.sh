#!/bin/bash
cd ~/CanBoot
make menuconfig KCONFIG_CONFIG=~/klipper_config/script/canboot_ebb.cfg OUT=out_ebb/
make clean KCONFIG_CONFIG=~/klipper_config/script/canboot_ebb.cfg OUT=out_ebb/
make KCONFIG_CONFIG=~/klipper_config/script/canboot_ebb.cfg OUT=out_ebb/

python3 ~/CanBoot/scripts/flash_can.py -i can0 -q
python3 ~/CanBoot/scripts/flash_can.py -i can0 -f ~/CanBoot/out_ebb/deployer.bin -u 23c5470ece0e
python3 ~/CanBoot/scripts/flash_can.py -i can0 -q
python3 ~/CanBoot/scripts/flash_can.py -i can0 -f ~/klipper/out_ebb/klipper.bin -u 23c5470ece0e

#make menuconfig KCONFIG_CONFIG=~/klipper_config/script/canboot_manta.cfg OUT=out_manta/
#make clean KCONFIG_CONFIG=~/klipper_config/script/canboot_manta.cfg OUT=out_manta/
#make KCONFIG_CONFIG=~/klipper_config/script/canboot_manta.cfg OUT=out_manta/
