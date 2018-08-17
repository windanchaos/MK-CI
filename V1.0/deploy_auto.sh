#!/bin/bash

#服务器定时执行发版工作的脚本，由系统调用或构建工具调用
#设置环境变量
source /etc/profile

USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`
GIT_HOME="${USER_HOME}/ArhasMK"
profile='st-https'
source ${USER_HOME}/build.sh

#build and deploy RPC
function build_Test(){
	pull_code ${GIT_HOME}
	build_agg

	for webent in ${WEBENTS[@]} ;do
	       build ${webent} ${profile}
	done

	for webent in ${WEBENTS_RPC[@]} ;do
	       build ${webent} ${profile}
	done
}

function pub_Test(){
	for webent in ${WEBENTS_RPC[@]} ;do
	       deploy_RPC ${webent} *.*.*.* sites
	done
	kill_process 'servers/'
	for webent in ${WEBENTS[@]} ;do
	       deploy_webent ${webent} 127.0.0.1 sites
	done

}
#deploy local


init_parmaters ArhasMK
build_Test
pub_Test
restartom 127.0.0.1 servers
