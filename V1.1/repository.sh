#!/bin/bash
#shell name :repository.sh
#function purpose 函数主要责任
#working directory/repository Initialization 工作目录,代码库初始化
#git branch management git分支管理
#
##代码编写遵守<Defensive BASH Programming>博客描述的以下原则
########	Immutable global variables 
########	Everything is local
########	Everything is a function
########	Debugging functions(bash -x)(set -x  …… set +x)
########	Code clarity
########	Each line does just one thing
########	


##Default working directory is account's home path like /home/user/, you can define function 'get_work_home_path' to change it
##默认功能目录是登录账户根目录，如需定制，变更get_user_home_path函数的返回值

#设置环境变量
source /etc/profile

# #global parameters
# DEFAULT_WORKING_PATH=`get_work_home_path`
# #Default path
# DEFAULT_PUB_PATH="/arthas/sites/"
# DEFAULT_TOMCAT_PATH="/arthas/servers/apache-tomcat-8.5.4-80/"



##############################################################################
### 	define working directory 定义工作目录
##############################################################################
function get_work_home_path(){
	local user=`whoami`
	local user_home="`cat /etc/passwd | grep ${USER} | awk -F ":" '{print $6}'|head -1`"
	echo "${user_home}/"
}
##############################################################################
###        传参确定要初始化的代码仓库，返回代码库路径
##############################################################################
function get_repository(){
	local repository=${1}
	USER_HOME=`get_work_home_path`
	case ${repository} in
		ArhasMK|mk|MK )
			GIT_REPOSITORY="${USER_HOME}/ArhasMK/"
			GIT_JAVA="${GIT_REPOSITORY}"
			;;
        FICPAY|pay|fic|PAY )
			GIT_REPOSITORY="${USER_HOME}/FICPAY/"
			GIT_JAVA="${GIT_REPOSITORY}mk-pay/"
            ;;
        sn|SN|data_SiNan )
			GIT_REPOSITORY="${USER_HOME}/data_SiNan/"
			GIT_JAVA="${GIT_REPOSITORY}"
			;;
        tianhe|th )
			GIT_REPOSITORY="${USER_HOME}/tianhe/"
			GIT_JAVA="${GIT_REPOSITORY}mk-tianhe"
			;;
        kbase )
			GIT_REPOSITORY="${USER_HOME}/kbase/"
			GIT_JAVA="${GIT_REPOSITORY}"
			;;
	esac
	#判断是否存,并cd到GIT_JAVA
	if [[ -e ${GIT_REPOSITORY} && -e ${GIT_JAVA} ]]
	then
		cd ${GIT_JAVA}
		return 0
	else
	    echo "Make sure ${GIT_REPOSITORY} exist!"
	    return 1	
	fi	
}

##############################################################################
###       更新代码库,branch可以不传，则默认
##############################################################################
function pull_code(){
	local branch=${1}
    git reset --hard HEAD^
    #切换分支，可以为空
    git checkout ${branch}
    echo "git当前分支名称：" `git branch | grep '*' | awk '{print \$2}'`
    echo "拉取当前分支代码"
    git pull origin `git branch | grep '*' | awk '{print \$2}'`
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
###       git分支管理：checkout 分支，本地不存在则拉取后checkout
##############################################################################
function gitcheckout(){
        local branch_checkout=${1}
        local exists="`git branch |grep ${branch_checkout}`"
        if [[ ${exists} ]];then
                git checkout ${branch_checkout}
        else
                gitfetch ${branch_checkout} && git checkout ${branch_checkout}
        fi
}
