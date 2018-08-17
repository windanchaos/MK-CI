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

#[[base_config]]
#本地git代码库
repository_MK="ArhasMK"
repository_KJ="KillJaeden_MK"

#user's home
USER=`whoami`
USER_HOME="`cat /etc/passwd | grep ${USER} | awk -F ":" '{print $6}'|head -1`"

#default git home 
repository="${USER_HOME}/ArhasMK/"

#MK
git_MK_Home="${USER_HOME}/ArhasMK/"
git_MK_Java="${USER_HOME}/ArhasMK/"
git_MK_Frontend="${git_MK_Home}/"

#KJ
git_KJ_Home="${USER_HOME}/KillJaeden_MK/"
git_KJ_Java="${git_KJ_Home}ft-java/"
git_KJ_Frontend="${git_KJ_Home}ft-frontend/"
#Pay
git_Pay_Home="${USER_HOME}/FICPAY"
git_Pay_Java="${git_Pay_Home}/mk-pay/"

#init parameter
git_Java="${git_MK_Java}"

SITE_PATH="/arthas/sites/"
SITES_BACK="/arthas/back_product/"

#引用
##Server信息
source ${USER_HOME}/server.sh
#vue shell
source ${USER_HOME}"/vue.sh"

#git编译的参数
PROFILE="product"

#远程服务器链接信息，需设置ssh免密登陆l
CONFIG_REMOTE_IP="121.43.164.242"
CONFIG_REMOTE_USER="mkstar"
CONFIG_REMOTE_PORT="5180"

#远程服务器tomcat路径
REMOTE_TOMCAT="/arthas/servers01/apache-tomcat-8.5.4-80/"


#MK default
WEBENTS_MK=(mk-demon-webent mk-app-webent mk-job-webent mk-openApi mk-wm-webent mk-yum-webent mk-imgr-webent mk-uic-webent mk-weshine-webent mk-weshine-imgr-webent mk-sn-webent mk-intf-webent mk-kunlun-webent mk-smart-webent)
WEBENTS_MK_RPC=(mk-uic-rpc mk-imgr-rpc mk-yum-rpc mk-mdata-rpc mk-sn-rpc mk-msg-mid mk-fic-rpc)

#KJ default
WEBENTS_KJ=(ft-bm-webent ft-wm-webent ft-job-webent ft-uic-webent ft-OpenApi)
WEBENTS_KJ_RPC=(ft-uic-interface)
#Pay default
WEBENTS_Pay=(mk-pay-gateway mk-pay-web-settlement)
WEBENTS_Pay_RPC=(mk-pay-orderpolling mk-pay-notify mk-pay-rpc-service)
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
###       git分支管理：fetch 分支
##############################################################################
function gitfetch(){
        local branch_fetch=${1}
        local exists="`git branch |grep ${branch_fetch}`"
        if [[ ${exists} ]];then
                echo "${branch_fetch} localbranch exists"
        else
                git pull
                git fetch origin ${branch_fetch}:${branch_fetch} && echo 'fetch success'
        fi
}
##############################################################################
###       git分支管理：checkout 分支
##############################################################################
function gitcheckout(){
        local branch_checkout=${1}
        local exists="`git branch |grep ${branch_checkout}`"
        if [[ ${exists} ]];then
                git checkout ${branch_checkout}
        else
                gitfetch branch_checkout && git checkout ${branch_checkout}
        fi
}

function get_site_name(){
        webent=${1}
        filter=`echo ${webent}|awk -F '-' '{print $1}'`
        echo ${webent}|awk -F ${filter}'-' '{print $2}'|awk -F '-webent' '{print $1}'
}
##############################################################################
###       更新代码库
##############################################################################

function pull_code(){
	repository=${1}
	branch=${2}
    cd ${repository}
    git reset --hard HEAD^
    git checkout ${branch}
    echo "git分支名称：" `git branch | grep '*' | awk '{print \$2}'`
    echo "拉取当前分支代码"
    git pull origin `git branch | grep '*' | awk '{print \$2}'`
}

##############################################################################
### init Parameters ,must be called first
##############################################################################

function init_parmaters(){
	repository="${USER_HOME}/${1}"
	case ${1} in
		ArhasMK|mk|MK )
			git_Java=${git_MK_Java}
			PROFILE='product'
			WEBENTS=(${WEBENTS_MK[*]})
			WEBENTS_RPC=(${WEBENTS_MK_RPC[*]})
			;;
		KillJaeden_MK|KJ|kj|ft )
			git_Java=${git_KJ_Java}
			PROFILE='product'
			WEBENTS=(${WEBENTS_KJ[*]})
			WEBENTS_RPC=(${WEBENTS_KJ_RPC[*]})
			;;
                FICPAY|pay )
                        git_Java=${git_Pay_Java}
                        PROFILE='product'
                        WEBENTS=(${WEBENTS_Pay[*]})
                        WEBENTS_RPC=(${WEBENTS_Pay_RPC})
                        ;;

	esac
}
##############################################################################
###	编译依赖库
##############################################################################
function build_agg(){
	if [[ -e ${git_Java}ft-aggregator ]];then
       		cd ${git_Java}ft-aggregator && echo "building ft-aggregator"
       		mvn -q -ff clean install
	elif [[ -e ${git_Java}mk-aggregator ]];then
		cd ${git_Java}mk-aggregator && echo "building mk-aggregator"
		mvn -q -ff clean install
	fi
}

##############################################################################
###       构建项目函数，传入webent名称和profile
###       build mk-wm-webent st-https
##############################################################################
function build(){
	local webent=${1}
	PROFILE=${2}
	case ${webent} in
		mk-smart-webent)
			mk_vue mk-smart-vue
		;;
		mk-weshine-webent)
			mk_vue mk-weshine-vue
		;;
		ft-wm-webent)
			kj_vue "ft-manage-vue ft-scene-vue ft-wm-vue"
		;;
	esac

	cd ${git_Java}/${webent} && echo "building ${webent}"
	mvn -q -ff clean install -P $PROFILE
	
	# webent_name="`echo ${webent}|awk -F '-' '{print $2}'`"
	# rpc_name="${2#*-}"
	# if [[ -e target/ROOT.war ]] ;then
	# 	#同步发版文件到目录
	# 	rm -fr ${SITES_PUB}/${webent_name}
	# 	mkdir -p ${SITES_PUB}/${webent_name}
	# 	cp -f target/ROOT.war "${SITES_PUB}/${webent_name}/"
	# 	echo "$webent build and pub move finished! "
	# fi
	# if [[ -e ${git_Java}/${webent}/target/${webent}.jar ]] ;then
	# 	cd ${git_Java}/${webent}/target/${webent}
	# 	tar -zcf ${webent}.tar.gz lib ${webent}.jar
		#同步发版文件到目录
		# rm -fr ${SITES_PUB}/${rpc_name}
		# mkdir -p ${SITES_PUB}/${rpc_name}
		# cp -frR lib ${webent}.jar ${webent}.tar.gz "${SITES_PUB}/${rpc_name}/"
		# echo "$webent build and pub move finished! "
    # fi
}


##############################################################################
###       部署webent到tomcat的函数，传入webent名称和IP
##############################################################################
function deploy_webent(){
	cd ${git_Java}
	webent=${1}
	CONFIG_REMOTE_IP=${2}
	SITES=${3}
	echo "###### deploy ${webent} to ${CONFIG_REMOTE_IP} ${SITES}"
	webent_name=`get_site_name ${webent} `
	#传入部署site的名称（支撑生产的部署方式）
	if [[ ${SITES} ]];then
		SITE_PATH="/arthas/${SITES}/"
	fi
	local war_path="${git_Java}${webent}/target/ROOT.war"
	local webent_path="${SITE_PATH}/${webent_name}/"
	local site_back_path="${SITES_BACK}${webent_name}/"
	local deploy_function="${USER_HOME}/deploy_function.sh"
	
	#本地部署
	#存在war包则执行下一步，否则提示不存在
	if [[ -e ${war_path} ]] ;then
		if [[ ${CONFIG_REMOTE_IP} == '127.0.0.1' ]] || [[ ${CONFIG_REMOTE_IP} == 'localhost' ]];then
			if [[ ! -e "${webent_path}" ]];then
					mkdir -p ${webent_path}
			fi
			rm -fr ${webent_path}/ROOT*
			cp -fr ${war_path} ${webent_path}
		#远端部署
		else
			get_server_UPP ${CONFIG_REMOTE_IP}
			#back site
			if [[ ${IS_PRODUCT} == 'true' ]] && sshpass -p $PASSWORD ssh -p ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} "test -e ${webent_path}ROOT.war";then
				mkdir -p ${site_back_path}
				sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${webent_path}ROOT.war ${site_back_path}${Today}_ROOT.war
			fi
			#upload
			sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${deploy_function} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${SITE_PATH}
			sshpass -p $PASSWORD ssh -p ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} "test -e ${webent_path}" || \
			sshpass -p $PASSWORD ssh -p ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} "mkdir -p ${webent_path}"
			sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${war_path} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:"${webent_path}ROOT.war"	 
			return 0
		fi
	
	else
		echo "${git_Java}${webent}/target/ROOT.war not exist,check your mvn building "
	fi
}

##############################################################################
###       部署RPC的函数，传入RPC名称和IP，部署的路径的上级目录名，通常sites
##############################################################################
function deploy_RPC(){
	cd ${git_Java}
	webent=${1}
	CONFIG_REMOTE_IP=${2}
	SITES=${3}
	RPC_IP_Port=${4}
	echo "###### deploy ${webent} to ${CONFIG_REMOTE_IP} ${SITES}"
	webent_name="${webent#*-}"
	#传入部署site的名称（支撑生产的部署方式）
	if [[ ${SITES} ]];then
		SITE_PATH="/arthas/${SITES}/"
	fi
	local jar_path="${git_Java}${webent}/target/${webent}.jar"
        [[ -e "${git_Java}${webent}/target/lib" ]] && local lib_path="${git_Java}${webent}/target/lib"
	local resources_path="${git_Java}${webent}/target/resources"
	local webent_path="${SITE_PATH}${webent_name}/"
	local site_back_path="${SITES_BACK}${webent_name}/"
	local deploy_function="${USER_HOME}/deploy_function.sh"
	#本地部署
	#存在jar包则执行下一步，否则提示不存在
	if [[ -e ${jar_path} ]] ;then
		if [[ ${CONFIG_REMOTE_IP} == '127.0.0.1' ]] || [[ ${CONFIG_REMOTE_IP} == 'localhost' ]];then
			if [[ ! -e "${webent_path}" ]];then
					mkdir -p ${webent_path}
			fi
			rm -fr ${webent_path}*
			cp -fr ${jar_path} ${lib_path} ${webent_path}
			([ -e ${resources_path} ] && cp -fr ${resources_path} ${webent_path}) || echo "it is not msger"
			kill_process ${webent}
			sleep 13
			start_rpc 128 300 ${webent_path} ${webent}
	
		#远端部署
		else
			get_server_UPP ${CONFIG_REMOTE_IP}
			#back site,and only back one
			if [[ ${IS_PRODUCT} == "true" ]] && [[ ! -e ${site_back_path}${Today} ]] && \
		        sshpass -p $PASSWORD ssh -p ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} "test -e ${webent_path}";then
				mkdir -p ${site_back_path}${Today}
				sshpass -p $PASSWORD scp -r -P ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:"${webent_path}/*" "${site_back_path}${Today}"
				#rm -fr ${site_back_path}${Today}/*.log
			fi
			#upload
			sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${deploy_function} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${SITE_PATH}
			sshpass -p $PASSWORD ssh -p ${CONFIG_REMOTE_PORT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} "rm -fr ${webent_path} && mkdir -p ${webent_path}"
			sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} -r ${jar_path} ${lib_path} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:"${webent_path}"	
			sshpass -p $PASSWORD ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT} << EOD
source ${SITE_PATH}deploy_function.sh
kill_process ${webent}
sleep 15
if [[ ${IS_PRODUCT} == "true" ]];then
start_rpc 256 1024 ${webent_path} ${webent} ${RPC_IP_Port}
else
start_rpc 128 200 ${webent_path} ${webent} ${RPC_IP_Port}
fi
echo "${webent} deploy finised"
logout
EOD
sleep 1
		return 0
		fi
	fi
}	

##############################################################################
###       kill process
##############################################################################
function kill_process(){
	local process=${1}
	[ -n `ps -ef |grep ${process}|grep -v grep|grep -v activemq | awk '{print $2}' | head -1` ] && \
	ps -ef |grep ${process}|grep -v grep|grep -v activemq| awk '{print $2}' | xargs kill -9 ||return 0
}

##############################################################################
###       kill remote process
##############################################################################
function kill_remote_process(){
	local deploy_function="${USER_HOME}/deploy_function.sh"
	local ip=${1}
	local process=${2}
	local SITE_PATH="/arthas/sites/"
	get_server_UPP ${ip}
	sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${deploy_function} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${SITE_PATH}
	sshpass -p $PASSWORD ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
source ${SITE_PATH}deploy_function.sh
kill_process ${process}
logout
EOF
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
#	return 0
}
##############################################################################
###       重启远程tomcat,传入ip和部署tomcat的上级目录
###       restartom IP servers
###       restartom IP servers01
##############################################################################
function restartom(){
	CONFIG_REMOTE_IP=${1}
	servers="${2}/"
	if [[ ${CONFIG_REMOTE_IP} == '127.0.0.1' ]] || [[ ${CONFIG_REMOTE_IP} == 'localhost' ]];then
		kill_process ${servers}
		cd /arthas/${servers}apache-tomcat-8.5.4-80/bin/
		BUILD_ID=dontKillMe ./startup.sh
	else
	get_server_UPP ${CONFIG_REMOTE_IP}
sshpass -p $PASSWORD ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
source ${SITE_PATH}deploy_function.sh
kill_process ${servers}
cd /arthas/${servers}/apache-tomcat-8.5.4-80/bin/
sleep 1
./startup.sh
logout
EOF
	fi
}

##############################################################################
###       重启远程tomcat,传入ip和部署tomcat的上级目录
###       restartom IP servers
###       restartom IP servers01/apache-tomcat-8.5.4-80-demon
##############################################################################
function startom(){
	local deploy_function="${USER_HOME}/deploy_function.sh"
	CONFIG_REMOTE_IP=${1}
	servers="${2}/"
	if [[ ${CONFIG_REMOTE_IP} == '127.0.0.1' ]] || [[ ${CONFIG_REMOTE_IP} == 'localhost' ]];then
		kill_process ${servers}
		cd /arthas/${servers}bin/
		BUILD_ID=dontKillMe ./startup.sh
	else
	get_server_UPP ${CONFIG_REMOTE_IP}
	sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${deploy_function} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${SITE_PATH}
sshpass -p $PASSWORD ssh -tt ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP} -p ${CONFIG_REMOTE_PORT}<<EOF
source ${SITE_PATH}deploy_function.sh
kill_process ${servers}
cd /arthas/${servers}bin/
./startup.sh
logout
EOF
	fi
}
##############################################################################
###       比较文件生成是否在一个小时内生成过，传入文件路径
##############################################################################
function wether_new(){
	timestamp=`date +%s`
	filepath=${1}
	if [[ -e $filepath ]];then
		echo "文件存在！路径为：$filepath"
		filetimestamp=`stat -c %Y $filepath`
		echo "文件最后修改时间戳：$filetimestamp"
 		timecha=$[[$timestamp - $filetimestamp]]
 		if [[ $timecha -gt 3600 ]];then
			echo "bigger"
			return 0
		else
			echo "not bigger"
			return 1
		fi
	else
		echo "文件不存在或者您输入的路径有误"
	fi
}

#自动拷贝静态文件
#远程拷贝需告知IP和webent全名，如mk-wm-webent
function cp_auto(){
	cd ${git_Java}
	webent=${1}
	CONFIG_REMOTE_IP=${2}
	SITES=${3}
	echo "###### auto copy ${webent} to ${CONFIG_REMOTE_IP} ${SITES}"
	webent_name="${webent#*-}"
	#传入部署site的名称（支撑生产的部署方式）
	if [[ ${SITES} ]];then
		SITE_PATH="/arthas/${SITES}/"
	fi
	local copy_source_files=(`git log --since=24.hours -p . |grep diff |grep webent|awk '{print $4}' |awk -F 'b/' '{print $2}'|sort -u|egrep -v '(.java$|.xml$)')
	local webents=(`git log --since=24.hours -p . |grep diff |grep webent|awk '{print $4}' |awk -F '/src' '{print $1}'|sort -u|awk -F '/' '{print $2}'|sort -u`)
		
	i=0

	if [[ ${CONFIG_REMOTE_IP} == '127.0.0.1' ]] || [[ ${CONFIG_REMOTE_IP} == 'localhost' ]];then
		#local copy,copy all the files
		for source_file in ${copy_source_files[@]}
		do
		    webent_name=`echo ${source_file}}|awk -F '/' '{print $1}'|awk -F '-' '{print $2}'|sort -u`
		    filepath=`echo ${source_file}|awk -F 'webapp' '{print $2}'|sort -u`
			cp -f $h /arthas/sites/$webent/ROOT$filepath
		done
	else
		#remote copy,need tell which webent need copy ,otherwise do nothing
		for wb in ${webents[@]} ;do
			if [[ ${webent} == ${wb} ]];then
			    cd ${git_MK_Java}/${wb}/src/main/webapp
			    mkdir ROOT
		        files=`echo ${copy_source_file}|grep ${wb} |awk -F 'webapp/' '{print $2}'`
		        cp --parents ${files} ROOT
		        webent_name=get_site_name ${wb}
		        get_server_UPP ${CONFIG_REMOTE_IP}
			    sshpass -p $PASSWORD scp -P ${CONFIG_REMOTE_PORT} ${ROOT} ${CONFIG_REMOTE_USER}@${CONFIG_REMOTE_IP}:${SITE_PATH}/${webent_name}
			    rm -fr ROOT
			fi
		done
	fi
}

#push code
function push_code(){
	GIT_HOME=${1}
	cd ${GIT_HOME}
	git pull origin `git branch | grep '*' | awk '{print $2}'`
	git add -A ${static_path} ${static_path}js
	echo "main function"
	git commit ${static_path} ${vue_jsp} -m "compile and push vue automatically by shell" || return 0
	git push origin `git branch | grep '*' | awk '{print $2}'` || return 0
}

#判断是否需要编译，传入距离现在的时间长度和vue路径
function check_new(){
	vue_path=${2}
	hour=${1}
	cd ${vue_path}
	check=`git log --since=${hour}.hours -p . |grep diff |awk '{print $4}' |awk -F 'b/' '{print $2}'|sort -u|awk -F '/' '{print $1}'|sort -u`
	echo ${check}
}

