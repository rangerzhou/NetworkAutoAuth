import logging
import os
import re
import sys
import time
from logging.handlers import TimedRotatingFileHandler

import requests
import schedule


def setup_log(log_name):
    # 创建logger对象, 传入logger名字
    mylogger = logging.getLogger(log_name)
    log_path = os.path.join(sys.path[0], "./", log_name)
    mylogger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "[%(asctime)s] [%(process)d] [%(levelname)s] - %(module)s.%(funcName)s (%(filename)s:%(lineno)d) - %(message)s")

    # 定义日志输出格式,interval: 滚动周期;
    # when="MIDNIGHT": 表示每天0点为更新点
    # interval=1: 每天生成一个文件;
    # backupCount: 表示日志保存个数

    # 使用 FileHandler 输出到文件
    file_handler = TimedRotatingFileHandler(
        filename=log_path, when="MIDNIGHT", interval=1, backupCount=3
    )
    file_handler.setLevel(logging.INFO)
    file_handler.setFormatter(formatter)

    # filename="mylog" suffix设置，会生成文件名为mylog.2020-02-25.log
    file_handler.suffix = "%Y-%m-%d.log"
    # extMatch是编译好正则表达式，用于匹配日志文件名后缀
    # 需要注意的是suffix和extMatch一定要匹配的上，如果不匹配，过期日志不会被删除。
    file_handler.extMatch = re.compile(r"^\d{4}-\d{2}-\d{2}.log$")

    # # 使用 StreamHandler 输出到屏幕
    stream_handler = logging.StreamHandler()
    stream_handler.setLevel(logging.INFO)
    stream_handler.setFormatter(formatter)

    mylogger.addHandler(file_handler)
    mylogger.addHandler(stream_handler)
    return mylogger


logger = setup_log("mylog")


def login(user, passwd):
    format_time = time.strftime("[%Y-%m-%d %H:%M:%S]", time.localtime())
    test_url = 'http://www.baidu.com'
    try:
        logger.info("测试连接..." + test_url)
        r = requests.get(test_url)
        index = r.text.find('Kerberos V5 Authentication Redirection')
        if index != -1:
            # 测试连接失败，尝试认证
            logger.info("连接失败，用户认证中...")
            headers = {
                # "Host":"internet-na.aptiv.com:6082",
                # "Content-Type":"application/x-www-form-urlencoded",
                # "Referer":"https://internet-na.aptiv.com:6082/php/uid.php?vsys=2&rule=73",
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4430.212 Safari/537.36"
            }
            data = {
                'escapeUser': user,
                'user': user,
                'passwd': passwd,
                'ok': 'Login'  # 提交登录
            }
            url = 'https://internet-na.aptiv.com:6082/php/uid.php?vsys=2&rule=73'
            resp = requests.post(url, headers=headers, data=data)
            if resp.text.find('User Authenticated') != -1:
                logger.info("用户认证成功...\n")
            else:
                logger.warning("用户认证失败...status_code: " + str(resp.status_code) + ", text: " + str(resp.text) + "\n")
        elif r.status_code == 200:
            # 连接成功
            logger.info("连接成功，用户已认证...\n")
            return
        else:
            # 连接异常
            logger.error("测试连接异常...status_code: " + str(r.status_code) + ", text: " + str(r.text) + "\n")
            return
    except Exception as e:
        logger.error("网络连接异常---Exception: " + str(e))
        return


User = 'wjl0n2'
Passwd = 'zr.202104'
login(User, Passwd)
schedule.every(5).seconds.do(login, User, Passwd)

while 1:
    schedule.run_pending()
    time.sleep(5)
