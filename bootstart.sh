#!/bin/bash
# 安装必要依赖
sudo apt install krb5-user
sudo apt install python3-pip
sudo pip3 install schedule

servicename="network_auto_auth.service"
#email="ran.zhou@APTIV.COM"

# 编写开机启动 service 并添加到 /etc/systemd/system/ 目录下，传入的 $1 是执行 bootstart.sh 脚本时后面跟的邮箱名参数（也可如第 8 行代码定义邮箱名，这样执行 bootstart.sh 脚本时就不用加邮箱名参数了）
sudo sh -c "cat > /etc/systemd/system/$servicename << EOF
[Unit]
Description=Aptiv Network Auto Authentication
After=network.target

[Service]
Type=simple
User=$(whoami)
Group=$(whoami)
ExecStart=$(which python3) $(pwd)/network_auto_auth.py $(pwd) $1 &

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl stop $servicename
sudo systemctl enable $servicename
sudo systemctl is-enabled $servicename

sudo systemctl daemon-reload
# 启动服务
sudo systemctl start $servicename
# 查看状态
sudo systemctl status $servicename
servicename
ps -axu | grep ${servicename%.*} # 删除第一个.号及右边的字符
exit
