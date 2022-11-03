---
Author: ran.zhou@aptiv.com
Version: v22.11.03
---



> 公司自己安装的操作系统，网络每隔 8 小时需要手动 ~~点击登录~~ 认证一次，本脚本每隔 5 秒钟检测一次网络状态，若认证超时则自动重新认证，可代替手动认证，太懒了没办法 O(∩_∩)O~



**<font color = red>20221103更新：简化脚本配置复杂度，仅 1 步即可完成配置；</font>**

脚本下载地址：https://confluence.asux.aptiv.com/pages/viewpage.action?pageId=313967372

文件说明：

- network_auto_auth.py: 网络认证脚本；
- monitor.sh: 进程监控脚本；
- bootstart.sh: 初始化脚本（包括同步时间、安装依赖、生成 keytab、配置网络认证脚本、配置开机启动服务）；
- SyncTime.sh: 时间同步脚本；
- mylog: 网络认证脚本日志文件；
- monitor.log: 进程监控脚本日志文件；
- aptiv.keytab: 网络认证 key；

---

### 1. 一键完成配置

#### 1.1 执行启动脚本

**终端进入 *NetworkAutoAuth* 目录，执行如下命令即可：**

``` shell
# bash bootstart.sh 邮箱名 邮箱密码
$ bash bootstart.sh abc.xyz@APTIV.COM password
```

<font color=red>**邮箱名后缀一定要是大写的，用户名为小写；**</font>



<font color=red>**以下为非必选项**</font>

#### 1.2 配置进程监控（非必选）

参照第 3 节配置，非必选项；

---

### 2. 生成秘钥表（keytab）

#### 2.1 安装 krb5-user

``` shell
$ sudo apt install krb5-user
```

#### 2.2 生成秘钥表

``` shell
$ ktutil
ktutil:  addent -password -p ran.zhou@APTIV.COM -k 1 -e aes256-cts-hmac-sha1-96
Password for ran.zhou@APTIV.COM:
ktutil:  wkt ~/NetworkAutoAuth/aptiv.keytab # 此处修改为自己的目录
ktutil:  l
slot KVNO Principal
---- ---- ---------------------------------------------------------------------
   1    1                       ran.zhou@APTIV.COM
ktutil:  l -e
slot KVNO Principal
---- ---- ---------------------------------------------------------------------
   1    1                       ran.zhou@APTIV.COM (aes256-cts-hmac-sha1-96)
ktutil:  q
```

<font color = red>**提示：**</font>

- 必须是大写的 @APTIV.COM，需要修改秘钥表的保存位置，在 Linux 生成 keytab 比较方便，经测试生成的 keytab 文件 windows 下也可使用；

- 生成新的秘钥表时必须先删除原有的 keytab 文件，否则有可能生成失败，执行 kinit xxx 命令进行认证时会报如下错误：

  ``` shell
  kinit: Preauthentication failed while getting initial credentials
  ```

#### 2.3 手动认证（用于测试 keytab 是否有效）

``` shell
# kinit 获取并缓存 principal（当前主体）的初始票据授予票据（TGT），用于 Kerberos 系统进行身份安全验证
$ kinit -k -t /home/ranger/bin/NetworkAutoAuth/aptiv.keytab ran.zhou@APTIV.COM # 大写的 @APTIV.COM
# APTIV 网络认证
$ curl -v --negotiate -u : 'http://internet-ap.aptiv.com:6080/php/browser_challenge.php?vsys=1&rule=77&preauthid=&returnreq=y'
```



#### 2.4 测试网络状态

``` shell
# 认证成功
$ curl http://detectportal.firefox.com/success.txt
success
# 认证失败
$ curl http://detectportal.firefox.com/success.txt
curl: (56) Recv failure: Connection reset by peer
```

#### 2.5 常见异常

##### 2.5.1 加密方式错误

如果获取 TGT 过程提示 `kinit: Pre-authentication failed: No key table entry found for ran.zhou@aptiv.com while getting initial credentials`

可能是秘钥表加密方式不对，可以先不使用秘钥表获取 TGT，再使用 `klist -e` 命令获取加密方式

手动获取 TGT 命令：

``` shell
# 获取 TGT
$ kinit ran.zhou@APTIV.COM
Password for ran.zhou@APTIV.COM:
# 显示凭证高速缓存中每个凭证或密钥表文件中每个密钥的会话密钥和票证的加密类型
$ klist -e
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: ran.zhou@APTIV.COM

Valid starting       Expires              Service principal
2021-11-13T09:38:07  2021-11-13T09:40:09  krbtgt/APTIV.COM@APTIV.COM
	renew until 2021-11-13T09:40:09, Etype (skey, tkt): aes256-cts-hmac-sha1-96, aes256-cts-hmac-sha1-96
```

可以看到加密方式为 *aes256-cts-hmac-sha1-96*

##### 2.5.2 密码错误

密码错误时执行 kinit 验证时会输出如下错误：

``` shell
$ kinit -k -t test.keytab abc.xyz@APTIV.COM
kinit: Preauthentication failed while getting initial credentials
```



---

### 3. 监控进程状态(有 bug，非必选项)

进程有时会被终结，添加一个守护进程对其监控，一旦被终结，则自动重启

配置守护进程

``` shell
$ crontab -e
# 分　 时　 日　 月　 周，/5: 表示每 5 分钟
*/5 * * * * ~/NetworkAutoAuth/monitor.sh

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

---

### 4. Windows 下使用

#### 4.1 安装 Kerberos-Windows 客户端

下载地址：http://web.mit.edu/kerberos/dist/，选择 MIT Kerberos for Windows 4.1，重启电脑，会自动配置环境变量到 path，但是需要把对应的环境变量移动到最前面，默认安装路径：C:\Program Files\MIT\Kerberos\bin ，使用 *C:\Program Files\MIT\Kerberos\bin* 下的 `klist` `kinit` 命令

#### 4.2 Windows 安装 curl

下载地址：https://curl.se/windows/

#### 4.3 其他步骤

同 Linux

**最简单的还是在 Linux 生成 keytab，经测试生成的 keytab 文件 windows 下也可使用**
