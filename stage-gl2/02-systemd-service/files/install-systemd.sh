#!/bin/bash

set -ex

sudo cp ./groundlight-mns.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable groundlight-mns

