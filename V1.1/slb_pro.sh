#!/bin/bash
#自动识别需要更新（60天内修改过的）的静态资源文件，上传oss
#
USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`

git_MK_Home="${USER_HOME}/ArhasMK/"

#设置环境变量
source /etc/profile
#update code



function setBlance(){
	LoadBalancerId=${1}
	ServerId=${2}
	Weight=${3}
	cd /home/mkstar/mkci/slb-api
	python slb.py -u http://slb.aliyuncs.com Action=SetBackendServers RegionId=cn-hangzhou LoadBalancerId=${LoadBalancerId} BackendServers=[{"\"ServerId\"":"\"${ServerId}\"","\"Weight\"":"\"${Weight}\"","\"Type\"":"\"ecs\""}] |xargs curl	
}
