#!/bin/bash
#设置环境变量
source /etc/profile
source repository.sh
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

##############################################################################
###       以下是MK构建项目VUE的函数群，不具有通用性
##############################################################################
vue_MK_list=(your-vue your-vue2)

function mk_vue(){
	local vue_MK_webent=${1}
	build_vue ${GIT_JAVA} "${vue_MK_list[*]}"
}
function kj_vue(){
	vue_KJ_webent=${1}
	build_vue ${git_KJ_Frontend} "${vue_KJ_list[*]}"
}

########说明####
### 传入vue所在的目录
### vue目录下的vuelist
function build_vue(){
	local vue_Path=${1}
	local vue_List=(${2})
	pull_code ${vue_Path}
	echo ${vue_List[@]}
	local vue_List_longth=${#vue_List[@]}
    local RPM2=0
	while [ $RPM2 -lt ${vue_List_longth} ]
	do
	if [[ -n "`check_new 48 ${vue_Path}${vue_List[$RPM2]}`" ]];
	then 
		cd ${vue_Path}${vue_List[$RPM2]}
		if [[ `cnpm` ]]
			then
			echo "cnpm installed"
		else
			npm install -g cnpm --registry=https://registry.npm.taobao.org
		    cnpm install
		fi
		echo "##### npm run build ###########"
		npm run build
		echo "##### build finished ##########"
		echo "##### we will pub the vue to the source code"
		get_VUE_JSP ${vue_List[$RPM2]}
		#删除原static
		rm -fr ${STATIC_PATH}
		#拷贝新的static
		cd ${vue_Path}${vue}/dist/
		cp -fr `ls ${vue_Path}${vue}/dist/ -I index.html` ${STATIC_PATH}
		update_jsp ${STATIC_PATH} ${VUE_JSP}
		push_code ${vue_Path}	
	fi
		RPM2=`expr $RPM2 + 1`
	done

}
#### 判断vue和webent的关系
#### 传入代码库根目录和vue名，取得被编辑的jsp和静态资源路径
function get_VUE_JSP(){
	vue=${1}
	if [ ${vue} == 'ft-manage-vue' ]
	then
		STATIC_PATH=${GIT_JAVA}"your-project/src/main/webapp/resources/ft-manage-static/"
		VUE_JSP=${GIT_JAVA}"your-project/src/main/webapp/WEB-INF/views/manage_index.jsp"
	fi

    if [ ${vue} == 'ft-scene-vue' ]
    then
		STATIC_PATH=${GIT_JAVA}"your-project/src/main/webapp/resources/ft-scene-static/"
        VUE_JSP=${GIT_JAVA}"your-project/src/main/webapp/WEB-INF/views/deliver_index.jsp"
    fi

    if [ ${vue} == 'ft-wm-vue' ]
    then
	 	STATIC_PATH=${GIT_JAVA}"your-project/src/main/webapp/resources/ft-wm-static/"
        VUE_JSP=${GIT_JAVA}"your-project/src/main/webapp/WEB-INF/views/index.jsp"
    fi

    if [ ${vue} == 'your-vue' ]
    then
		STATIC_PATH=${GIT_JAVA}"your-project/src/main/webapp/resources/smart-static/"
        VUE_JSP=${GIT_JAVA}"your-project/src/main/webapp/WEB-INF/views/index.jsp"
    fi

    if [ ${vue} == 'your-vue2' ]
    then
        STATIC_PATH=${GIT_JAVA}"your-project2/src/main/webapp/resources/mk-weshine-static/"
        VUE_JSP=${GIT_JAVA}"your-project2/src/main/webapp/WEB-INF/views/index.jsp"
    fi

}

#替换关键字函数，传入static路径和需处理jsp路径
function update_jsp(){
	local s_path=${1}
	local ue_jsp=${2}
	local new=()
	local old=()

	new[0]="`ls ${s_path}css/app.* |awk -F '.' '{print $2 }'`"
	new[1]="`ls ${s_path}/js/manifest.*|awk -F '.' '{print $2 }'`"
	new[2]="`ls ${s_path}/js/vendor.*|awk -F '.' '{print $2 }'`"
	new[3]="`ls ${s_path}/js/app.*|awk -F '.' '{print $2 }'`"
	
	old[0]="`grep static ${ue_jsp} |awk -F '.' 'NR==1 {print $2}'`"
    old[1]="`grep static ${ue_jsp} |awk -F '.' 'NR==2 {print $2}'`"
    old[2]="`grep static ${ue_jsp} |awk -F '.' 'NR==3 {print $2}'`"
    old[3]="`grep static ${ue_jsp} |awk -F '.' 'NR==4 {print $2}'`"

	local RPM=0
	echo "new:"${new[@]}
	echo "old:"${old[@]}
	while [ $RPM -lt 4 ]
	do
        	echo ${old[$RPM]}/${new[$RPM]}
        	sed -i "s/${old[$RPM]}/${new[$RPM]}/g" ${ue_jsp}
        	RPM=`expr $RPM + 1`
	done

}

#判断是否需要编译，传入距离现在的时间长度(hour)和vue路径
function check_new(){
	local vue_path=${2}
	local hour=${1}
	cd ${vue_path}
	local check=`git log --since=${hour}.hours -p . |grep diff |awk '{print $4}' |awk -F '^b/' '{print $2}'|sort -u|awk -F '/' '{print $1}'|sort -u`
	echo "${check}"
}

