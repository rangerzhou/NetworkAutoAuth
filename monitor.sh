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
