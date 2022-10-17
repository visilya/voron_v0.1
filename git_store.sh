#/usr/bin/env bash
cd ~/klipper_config
TODAY=Mon Oct 17 17:30:26 UTC 2022
git add .
git commit -m ""
git push origin main # to my local gitlab repo
git push github main
