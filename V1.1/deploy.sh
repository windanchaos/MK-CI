#!/bin/bash
#设置环境变量
source /etc/profile
source /home/user/mkci/servers.sh
source /home/user/mkci/build.sh
source /home/user/mkci/repository.sh
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing

##变量命名规则：局部变量小写，下划线区分单词；全局变量大写，下滑线分单词

##Default working directory is account's home path like /home/user/, you can define function 'get_work_home_path' in repository.sh to change it
##默认功作目录是登录账户根目录，如需定制，变更get_user_home_path函数的返回值

##deploy本代码中的意思仅为放置项目到服务器，类似scp功能。
##真正意义上的deploy是一个工作流，本代码中使用deploy_flow来定义这一套流程。

##############################################################################
###       远端拷贝，传入源文件名、IP、远端路径
###		  含远端目录初始化
##############################################################################
function remote_push(){
	local locat_file=${1}
	local remote_ip=${2}
	local deploy_path=${3}
	echo "###### copy ${locat_file} to remote server: ${remote_ip} ,path :${deploy_path}"
	if [ -e ${locat_file} ]
		then
		#上传，目录不存在则新建
		`ssh -p 22 user@${remote_ip} "test -e ${deploy_path}"` || \
		ssh -p 22 user@${remote_ip} "mkdir -p ${deploy_path}"
		scp -r -P 22 ${locat_file} user@${remote_ip}:"${deploy_path}"	 
		return 0
	else
		echo "${locat_file} not exist,check your mvn building "
		exit 1
	fi
}

##############################################################################
###       远端部署webent到tomcat的函数，传入webent名称、IP、上级路径
##############################################################################
function remote_deploy_war(){
	local webent=${1}
	local remote_ip=${2}
	local webent_name=`get_webent_name ${webent}`
	local deploy_path=${3}/${webent_name}
	local war_path="${GIT_JAVA}${webent}/target/ROOT.war"
	local today=`date +%Y-%m-%d`
	local back_path="/arthas/back_product/${webent_name}"
	local war_back_path="${back_path}/${today}_ROOT.war"
	#backup
	test -e ${back_path} || mkdir -p ${back_path} 
	if [ ! -e ${war_back_path} ]
		then
		echo "###### back ${war_back_path} from ${remote_ip}"
		#远端备份文件检查
		`ssh -p 22 user@${remote_ip} "test -e ${deploy_path}/ROOT.war"` && \
		scp -r -P 22 user@${remote_ip}:${deploy_path}/ROOT.war ${war_back_path} echo "###### back up finished " && \
 		return 0
	else
		echo "###### ${webent} backup already,no longer backup "
	fi	
	echo "###### deploy ${war_path} to remote server: ${remote_ip} ,path :${deploy_path}"
	remote_push ${war_path} ${remote_ip} ${deploy_path}
}


##############################################################################
###       打包jar包的函数，打包在target目录下，tar.gz格式
#		  Mk专用，不具有通用性
##############################################################################
function tar_local_jar(){
	local webent=${1}
	local jar_path="${GIT_JAVA}${webent}/target/${webent}.jar"
	if [ -e ${jar_path} ]
		then
		#卖客多种jar包，有独立jar的，有搭配lib的，还有带静态资源的
		[ -e "${GIT_JAVA}${webent}/target/lib" ] && local lib_path="lib"
		[ -e "${GIT_JAVA}${webent}/target/resources" ] && local resources_path="resources"
		cd ${GIT_JAVA}${webent}/target/
		#打包引用不存在的参数不会报错，存在则打包，投机取巧
		tar -zcf ${webent}.tar.gz ${webent}.jar ${lib_path} ${resources_path}
	else
		echo "${jar_path} not exist,check your mvn building "
		exit 1
	fi
}
##############################################################################
###       远端解压缩，输入IP和解压缩文件全路径，解压到压缩文件所在目录，支持.tar.gz和zip
##############################################################################
function remote_uncompression(){
	local remote_ip=${1}
	local remote_file=${2}
	
	#字符截取
	local remote_file_path=${remote_file%\/*.*}
	local remote_file_type=${remote_file#*.}
	if `ssh -p 22 user@${remote_ip} "test -e ${remote_file}"`
		then
		[[ ${remote_file_type} =~ "tar.gz" ]] && ssh -p 22 user@${remote_ip} "tar -zxf ${remote_file} -C ${remote_file_path}" 
		[[ ${remote_file_type} =~ "zip" ]] && ssh -p 22 user@${remote_ip} "tar -zxf ${remote_file} -d ${remote_file_path}" 
		return 0
	else
		echo "remote ${remote_ip} ,${remote_file} does not exist "
		exit 1
	fi
}

##############################################################################
###      远程kill/启动java进程，默认sites，需传入执行函数（传参处理不当）
##############################################################################
function start_remote_jar(){
	local USER_HOME=`get_work_home_path`
	local remote_functions="${USER_HOME}/remote_functions.sh"
	local cmd=${1}
	local webent=${2}
	local remote_ip=${3}
	local IP_Port=${4}
	local webent_path=${5}
	local SITE_PATH="/arthas/sites/"
	local webent_name=`get_jar_name ${webent}`
	[ -n "${webent_path}" ] || webent_path=${SITE_PATH}${webent_name}
	scp -P 22 ${remote_functions} user@${remote_ip}:${SITE_PATH}
	ssh -tt user@${remote_ip} -p 22 <<EOF
source ${SITE_PATH}remote_functions.sh 
kill_process ${webent}
sleep 15 
${cmd} ${webent_path} ${webent} ${IP_Port} || exit 1
logout
EOF
sleep 1
	return 0
}

##############################################################################
###       压缩打包文件、备份、拷贝到服务器并解压
##############################################################################
function remote_deploy_jar(){
	local webent=${1}
	local remote_ip=${2}
	local deploy_path=${3}
	local webent_name=`get_jar_name ${webent}`
	[ -n "${deploy_path}" ] || deploy_path=/arthas/sites/${webent_name}
	local remote_functions="`get_work_home_path`remote_functions.sh"
	local jar_package="${GIT_JAVA}${webent}/target/${webent}.tar.gz"
	local today=`date +%Y-%m-%d`
	local back_path="/arthas/back_product/${webent_name}"
	local jar_back_path="${back_path}/${today}_${webent}.tar.gz"
	tar_local_jar ${webent}
	test -e ${back_path} || mkdir -p ${back_path} 
	if [ -e ${jar_package} ]
		then		
		if `ssh -p 22 user@${remote_ip} "test -e ${deploy_path}/${webent}.tar.gz"`
			then
			#backup
			`ssh -p 22 user@${remote_ip} "test -e ${deploy_path}/${webent}.tar.gz"` && \
			scp -r -P 22 user@${remote_ip}:${deploy_path}/${webent}.tar.gz ${jar_back_path} && return 0 
			#delete
			ssh -p 22 user@${remote_ip} "cd ${deploy_path} && rm -fr *.jar lib" 
		fi
		remote_push ${jar_package} ${remote_ip} ${deploy_path}
		remote_uncompression ${remote_ip} ${deploy_path}/${webent}.tar.gz
	else
		echo "${jar_package} does not exist,please check "
		exit 1
	fi	
}
##############################################################################
###       部署RPC的函数，传入RPC名称\IP\路径，将本地压缩包拷贝到服务器（同时拷贝function.sh）
##############################################################################
function remote_deploy_rpc(){
	local webent=${1}
	local remote_ip=${2}
	local IP_Port=${3}
	local deploy_path=${4}
	[ -n "${deploy_path}" ] || deploy_path=/arthas/sites/${webent_name}

	remote_deploy_jar ${webent} ${remote_ip} ${deploy_path}
	start_remote_jar start_rpc ${webent} ${remote_ip} ${IP_Port} ${deploy_path}
}

##############################################################################
###       部署小程序的函数，传入RPC名称\IP\路径，将本地压缩包拷贝到服务器（同时拷贝function.sh）
##############################################################################
function remote_deploy_little(){
	local webent=${1}
	local remote_ip=${2}
	local deploy_path=${3}
	local webent_name=`get_jar_name ${webent}`
	[ -n "${deploy_path}" ] || deploy_path=/arthas/sites/${webent_name}
	
	remote_deploy_jar ${webent} ${remote_ip} ${deploy_path}
	start_remote_jar start_little ${webent} ${remote_ip}
}


##############################################################################
###       打包到阿里云，将包上传到阿里云，保留
##############################################################################
function package_to_ali(){
	echo "do nothing"
}

##############################################################################
###       kill process
##############################################################################
function kill_process(){
	local process=${1}
	[ -n `ps -ef |grep ${process}|grep -v grep|awk '{print $2}' | head -1` ] && \
	ps -ef |grep ${process}|grep -v grep| awk '{print $2}' | xargs kill -9 ||return 0
}

##############################################################################
###       kill remote process
##############################################################################
function remote_kill_process(){
	local USER_HOME=`get_work_home_path`
	local remote_functions="${USER_HOME}/remote_functions.sh"
	local remote_ip=${1}
	local process=${2}
	local SITE_PATH="/arthas/sites/"
	#scp -P 22 ${remote_functions} user@${remote_ip}:${SITE_PATH}
	ssh -tt user@${remote_ip} -p 22 <<EOF
source ${SITE_PATH}remote_functions.sh
kill_process ${process}
logout
EOF
}
##############################################################################
###       start local rpc
##############################################################################
function start_local_rpc(){
	local Xms=${1}
	local Xmx=${2}
	local deploy_path=${3}
	local webent=${4}
	cd ${deploy_path}
	BUILD_ID=dontKillMe nohup java -Xms${Xms}m -Xmx${Xmx}m -jar ${webent}.jar > ${webent}.log 2>&1 &
	return 0
}
##############################################################################
###       重启远程tomcat,传入ip和部署tomcat的上级目录
###       restartom IP servers
###       restartom IP servers01
##############################################################################
function remote_restartom(){
	remote_ip=${1}
	servers="${2}/"
	
	remote_push ${USER_HOME}/mkci/remote_functions.sh ${remote_ip} /arthas/sites/
	ssh -tt user@${remote_ip} -p 22 <<EOF
source /arthas/sites/remote_functions.sh
kill_process ${servers}
cd /arthas/${servers}/apache-tomcat-8.5.4-80/bin/
sleep 1
./startup.sh
logout
EOF
}

##############################################################################
###       远程文件更新与否
### 	  有更新则等待输入的时间，直到不再更新返回
##############################################################################
function remote_whether_changed(){
	local remote_ip=${1}
	local remote_file_path=${2}
	local wait_time=${3}
	USER_HOME=`get_work_home_path`
	
	remote_push ${USER_HOME}/mkci/remote_functions.sh ${remote_ip} /arthas/sites/
	ssh -tt user@${remote_ip} -p 22 <<EOF
source /arthas/sites/remote_functions.sh
whether_changed ${remote_file_path} ${wait_time}
logout
EOF
}

##############################################################################
###       远程文件是否包含关键字
### 	  没有则等待输入的时间，等待5次
##############################################################################
function remote_whether_contain(){
	local remote_ip=${1}
	local remote_file_path=${2}
	local check_words=${3}
	USER_HOME=`get_work_home_path`
	remote_push ${USER_HOME}/mkci/remote_functions.sh ${remote_ip} /arthas/sites/
	ssh -tt user@${remote_ip} -p 22 " source /arthas/sites/remote_functions.sh && whether_contain ${remote_file_path} ${check_words} " && \
	return 0 || return 1
}

##############################################################################
###      war包回滚，传入ip、原路径和目标路径
##############################################################################
function roll_back_war(){
	local back_war_path=${1}
	local remote_ip=${2}
	local remote_war_path=${3}
	remote_push ${remote_ip} ${back_war_path}  ${remote_war_path}/ROOT.war
}


##############################################################################
# ###       本地部署webent到tomcat的函数，传入webent名称、路径
# ###		  含目录初始化
# ##############################################################################
# function local_deploy_war(){
# 	local webent=${1}
# 	local deploy_path=${2}
# 	local war_path="${GIT_JAVA}${webent}/target/ROOT.war"

# 	echo "###### deploy ${webent} to local ${deploy_path}"
# 	#存在war包则执行下一步，否则提示不存在
# 	if [ -e ${war_path} ]
# 		then
# 		#拷贝，目录不存在则新建
# 		test -e ${deploy_path} || mkdir -p ${deploy_path}
# 		cp -fr ${war_path} ${deploy_path}	 
# 		return 0
# 	else
# 		echo "${war_path} not exist, check your mvn building "
# 		exit 1
# 	fi
# }