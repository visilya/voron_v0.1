#!/bin/bash
cd ~/klipper/
sudo service klipper stop
git pull
make clean
make flash FLASH_DEVICE=/dev/serial/by-id/usb-Klipper_stm32g0b1xx_4A00280011504B4633373520-if00
cd ~/klipper_ebb/
git pull
make clean
make
python3 ~/CanBoot/scripts/flash_can.py -i can0 -f ./out/klipper.bin -u 23c5470ece0e
sudo service klipper start
