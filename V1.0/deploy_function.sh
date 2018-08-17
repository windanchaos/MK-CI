#!/bin/bash
#设置环境变量
source /etc/profile
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing

#time
Today=`date +%Y%m%d`

##############################################################################
### get the user's home path
##############################################################################
function get_user_home(){
	local USER=`whoami`
	echo "`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`"
}

##############################################################################
###       kill process
##############################################################################
function kill_process(){
	local process=${1}
	[ -n "`ps -ef |grep ${process}|grep -v grep| awk '{print $2}' | head -1`" ] && \
	ps -ef |grep ${process}|grep -v grep| awk '{print $2}' | xargs kill -9 || return 0
}

##############################################################################
###       start rpc
##############################################################################
function start_rpc(){
	local Xms=${1}
	local Xmx=${2}
	local webent_path=${3}
	local webent=${4}
	cd ${webent_path}
	BUILD_ID=dontKillMe nohup java -Xms${Xms}m -Xmx${Xmx}m -jar ${webent}.jar > ${webent}.log 2>&1 &
	return 0
}
##############################################################################
###       重启远程tomcat,传入ip和部署tomcat的上级目录
###       restartom IP servers
###       restartom IP servers01
##############################################################################
function restartom(){
	local servers="${1}/"
	kill_process ${servers}
	cd /arthas/${servers}/apache-tomcat-8.5.4-80/bin/
	sleep 1
	./startup.sh
}

#get site name
function get_site_name(){
	webent=${1}
	echo ${webent}|awk -F 'mk-' '{print $2}'|awk -F '-webent' '{print $1}'
}
