#!/bin/bash
#推送到远程服务器上的函数，供远端调用和执行
#push to remote server, used by remote server to deploy
#设置环境变量
source /etc/profile
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing


##############################################################################
###       kill process，存在进程与否都正确退出
##############################################################################
function kill_process(){
	local process=${1}
	local process_id="`ps -ef |grep ${process}|grep -v grep| awk '{print $2}' | head -1`"
	[[ -n ${process_id} ]] && kill -9 ${process_id} || return 0
}


##############################################################################
###       start rpc
##############################################################################
function start_rpc(){
	local webent_path=${1}
	local webent=${2}
	local IP_Port=${3}
	cd ${webent_path}
	if [ -e ${webent}.jar ]
		then
		nohup java -Xms400m -Xmx1524m -jar ${webent}.jar ${IP_Port} >> ${webent}.log 2>&1 &
		return 0
	else
		echo "${webent}.jar do not exit"
		return 1
	fi 
}

##############################################################################
###       start Little小程序
##############################################################################
function start_little(){
	local webent_path=${1}
	local webent=${2}
	cd ${webent_path}
	if [ -e ${webent}.jar ]
		then
		nohup java -Xms512m -Xmx3048m -jar ${webent}.jar >> ${webent}.log 2>&1 &
		return 0
	else
		echo "${webent}.jar do not exit"
		return 1
	fi
}

##############################################################################
###       start客服
##############################################################################
function start_cs(){
    local webent_path=${1}
    local webent=${2}
    local node=${3}
    local queue=${4}
    local address_port=${5}
    cd ${webent_path}
    if [ -e ${webent}.jar ]
    	then
    	nohup java -Xms512m -Xmx2600m -jar ${webent}.jar -node ${node} -queue ${queue} -address ${address_port} > ${webent}.log 2>&1 &
    	return 0
	else
		echo "${webent}.jar do not exit"
		return 1
	fi    
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
##############################################################################
###       文件是否有更新，有更新则等待输入的时间，直到不再更新返回
##############################################################################
function whether_changed(){
    local file_path=${1}
    local check_time=${2}
	echo "##### `date` : start to wait  ${file_path} has no change"
	if [[ -e ${file_path} ]]
		then
        while [[ true ]]; do
            file_old_stat="`stat ${file_path}|grep Size`"
            sleep ${check_time}
            file_new_stat="`stat ${file_path}|grep Size`"
            if [[ `echo ${file_old_stat}` == `echo ${file_new_stat}` ]]; then
                    break
            else
                    echo "####wait ${check_time}s unless  ${file_path} has no change"
            fi
        done
    else
    	echo "####### ${file_path} does not exist######,default wait 80 seconds"
    	sleep 80
    fi
	echo "##### `date` :end to wait  ${file_path} has no change"
    return 0
}

##############################################################################
###       文件是文尾是否包含关键字，有则返回0退出，没有则尝试等待24s钟，总共尝试3次，没有则返回错误
##############################################################################
function whether_contain(){
    local file_path=${1}
    local check_words=${2}	
    for i in {1..8}
    do
    	if [[ `tail -n 100 ${file_path} |grep ${check_words}` ]]
    		then
    		echo "### found ${check_words}"
    		return 0
    	fi
    	sleep 3
    done
    echo "#### Not found ${check_words}"
    echo "#### Please Check by hands"
    return 1
}