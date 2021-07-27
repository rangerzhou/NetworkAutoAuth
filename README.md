> 公司自己安装的操作系统，网络每隔 8 小时需要手动点击登录认证一次，若配置 Squid 自动登录的方式，有很多网页无法访问，本脚本每隔 5 秒钟检测一次网络状态，若认证超时则自动重新认证，可代替手动点击认证。

### 修改账号密码

**<font color = red>替换 network_auto_auth.py 中的账号密码，改为自己的 netid 和密码</font>**

``` python
User = 'wjl0n2'
Passwd = '123456'
```

### 配置开机启动（Linux 系统）

**network_auto_auth.service**

``` shell
[Unit]
Description=Aptiv Network Auto Authentication
After=network.target

[Service]
Type=simple
User=ranger
Group=ranger
ExecStart=/usr/bin/python3 /home/ranger/bin/NetworkAutoAuth/network_auto_auth.py &

[Install]
WantedBy=multi-user.target
```

**<font color = red>根据自己电脑环境修改 `ExecStart, User, Group`，User 和 Group 直接改为 root 也可以 。</font>**



**bootstart.sh**

``` shell
#!/bin/bash
# 把开机启动 service 添加到 /etc/systemd/system/ 目录下
sudo cp network_auto_auth.service /etc/systemd/system/network_auto_auth.service

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
```



**把开机启动 service 添加到 /etc/systemd/system/ 目录下，并使其生效：**

``` shell
# 配置启动
$ ./bootstart.sh
enabled
● network_auto_auth.service - Aptiv Network Auto Authentication
     Loaded: loaded (/etc/systemd/system/network_auto_auth.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2021-05-21 14:11:31 CST; 15ms ago
   Main PID: 881306 (python3)
      Tasks: 1 (limit: 38099)
     Memory: 1.8M
     CGroup: /system.slice/network_auto_auth.service
             └─881306 /usr/bin/python3 /home/ranger/bin/NetworkAutoAuth/network_auto_auth.py &

5月 21 14:11:31 mintos systemd[1]: Started Aptiv Network Auto Authentication.

# 查看脚本是否启动成功
$ ps -axu | grep network_auto_auth
ranger    881306  0.2  0.0  35228 22088 ?        Ss   14:11   0:00 /usr/bin/python3 /home/ranger/bin/NetworkAutoAuth/network_auto_auth.py &
```

### 监控进程状态

进程有时会被终结，添加一个守护进程对其监控，一旦被终结，则自动重启

monitor.sh

``` shell
#! /bin/sh

# 当前用户根目录
host_dir=`echo ~`
# 进程名
proc_name="network_auto_auth"
# 日志文件
file_name="/home/ranger/bin/NetworkAutoAuth/monitor.log"
pid=0

# 计算进程数
proc_num()
{
    num=`ps -ef | grep $proc_name | grep -v grep | wc -l`
    return $num
}

# 进程号
proc_id()
{
    pid=`ps -ef | grep $proc_name | grep -v grep | awk '{print $2}'`
}

proc_num
number=$?
# 判断进程是否存在
if [ $number -eq 0 ]
then
    # 重启进程的命令，请相应修改
    sh ~/bin/NetworkAutoAuth/bootstart.sh
    # 获取新进程号
    proc_id
    # 将新进程号和重启时间记录
    echo ${pid}, `date` >> $file_name
fi
```

配置守护进程

``` shell
$ crontab -e
*/5 * * * * /home/ranger/bin/NetworkAutoAuth/monitor.sh
$ sudo service cron restart
$ sudo service cron reload
```

测试

``` shell
# 查询进程号
$ ps aux | grep network_auto_auth
# 终结进程测试
$ sudo kill -9 1591904
$ ps aux | grep network_auto_auth
ranger   1593664  0.0  0.0  35236 21916 ?        Ss   11:10   0:02 /usr/bin/python3 /home/ranger/bin/NetworkAutoAuth/network_auto_auth.py &
$ cat monitor.log
1593664, Tue 27 Jul 2021 11:10:02 AM CST
```

