#!/bin/bash

# version: v22.11.03
# 1.同步时间(如果网络异常，获取的时间也会异常)
sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"


# 2.安装必要依赖
sudo apt install krb5-user -y
sudo apt install python3-pip -y
sudo pip3 install schedule
sudo apt install curl

# 获取当前脚本绝对路径
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd) # $BASH_SOURCE是一个数组，它的第0个元素是脚本的名称
# 定义开机启动服务名称
SERVICE_NAME="network_auto_auth.service"


# 3.生成 keytab，$1 是邮箱名参数，$2 是邮箱密码参数
rm $SCRIPT_DIR/aptiv.keytab # 删除旧 keytab 文件
ktutil << EOD
addent -password -p $1 -k 1 -e aes256-cts-hmac-sha1-96
$2
wkt $SCRIPT_DIR/aptiv.keytab
EOD


# 4.编写开机启动 service 并添加到 /etc/systemd/system/ 目录下，传入的 $1 是执行 bootstart.sh 脚本时后面跟的邮箱名参数
sudo sh -c "cat > /etc/systemd/system/$SERVICE_NAME << EOF
[Unit]
Description=Aptiv Network Auto Authentication
After=network.target

[Service]
Type=simple
User=$(whoami)
Group=$(whoami)
ExecStart=$(which python3) $SCRIPT_DIR/network_auto_auth.py $SCRIPT_DIR/aptiv.keytab $1 &

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl stop $SERVICE_NAME
sudo systemctl enable $SERVICE_NAME
sudo systemctl is-enabled $SERVICE_NAME
sudo systemctl daemon-reload


# 5.启动服务
sudo systemctl start $SERVICE_NAME
# 查看状态
sudo systemctl status $SERVICE_NAME

ps -axu | grep ${SERVICE_NAME%.*} # 删除第一个.号及右边的字符

exit
