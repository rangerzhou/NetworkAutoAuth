#!/bin/bash
sudo systemctl stop network_auto_auth.service
sudo systemctl enable network_auto_auth.service
sudo systemctl is-enabled network_auto_auth.service
sudo systemctl daemon-reload
sudo systemctl start network_auto_auth.service
sudo systemctl status network_auto_auth.service
exit
