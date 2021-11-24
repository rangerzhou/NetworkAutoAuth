#!/bin/bash
# 把开机启动 service 添加到 /etc/systemd/system/ 目录下
# sudo cp network_auto_auth.service /etc/systemd/system/network_auto_auth.service

sudo systemctl stop network_auto_auth.service
sudo systemctl enable network_auto_auth.service
sudo systemctl is-enabled network_auto_auth.service
sudo systemctl daemon-reload
# 启动服务
sudo systemctl start network_auto_auth.service
# 查看状态
sudo systemctl status network_auto_auth.service
ps -axu | grep network_auto_auth
exit
