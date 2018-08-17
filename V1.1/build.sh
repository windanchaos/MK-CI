#!/bin/bash
#设置环境变量
source /etc/profile
source /home/mkstar/mkci/repository.sh
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
##time
TODAY=`date +%Y-%m-%d`

##############################################################################
### 	取项目名
##############################################################################
function get_webent_name(){
        local webent=${1}
        local filter=`echo ${webent}|awk -F '-' '{print $1}'`
        echo ${webent}|awk -F ${filter}'-' '{print $2}'|awk -F '-webent' '{print $1}'
}
##############################################################################
### 	取项目名
##############################################################################
function get_jar_name(){
        local webent=${1}
        echo "${webent#*-}"
}
##############################################################################
###       构建项目函数，传入webent名称和profile,需cd到对应目录
###       build mk-wm-webent st-https
##############################################################################
function build(){
	local webent=${1}
	local profile=${2}
	cd ${GIT_JAVA}${webent}
	if [[ -e "pom.xml" ]]
		then
		if [[ -n ${profile} ]]
			then
			echo "Building path with profile ${profile} "
			echo `pwd`
			mvn -q -ff clean install -P ${profile}
		else
			echo "Building path without profile"
			echo `pwd`
			mvn -q -ff clean install
		fi
	else
		echo "make sure `pwd` is a maven project"
		exit 0
	fi
}

##############################################################################
###       打包,传入webent名称
##############################################################################
function package(){
	local webent=${1}
	cd ${GIT_JAVA}${webent}
	mvn package
}
##############################################################################
###       build_agg 依赖库编译，mk独有，不具有通用性
##############################################################################
function build_agg(){
	local aggregator=${1}
	build ${aggregator}
}

##############################################################################
###       打包到阿里云，将包上传到阿里云
##############################################################################
function package_to_ali(){
	echo "do nothing"
}