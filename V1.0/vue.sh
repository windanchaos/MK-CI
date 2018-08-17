#!/bin/bash
#前端vue工程编译打包工具，编译结果自动提交代码到git代码库
#
USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`

git_MK_Home="${USER_HOME}/ArhasMK/"
git_MK_Frontend="${git_MK_Home}/"

git_KJ_Home="${USER_HOME}/KillJaeden_MK/"
git_KJ_Frontend="${git_KJ_Home}ft-frontend/"
git_KJ_Java="${git_KJ_Home}ft-java/"
#设置环境变量
source /etc/profile
#update code
echo "pull code from git Server"
vue_MK_list=(fontend-vue mk-weshine-vue)
vue_KJ_list=(ft-manage-vue ft-scene-vue ft-wm-vue)

#vuejsp
vue_jsp=${git_MK_Home}"mk-smart-webent/src/main/webapp/WEB-INF/views/index.jsp"
static_path=${git_MK_Home}"mk-smart-webent/src/main/webapp/resources/smart-static/"

#vue的执行函数，传入vue的根目录和根目录下的vue项目list
function mk_vue(){
	vue_MK_webent=${1}
	build_vue ${git_MK_Home} "${vue_MK_webent[*]}"

}
function kj_vue(){
	vue_KJ_webent=${1}
	build_vue ${git_KJ_Frontend} "${vue_KJ_list[*]}"
}

########说明####
### 传入vue所在的目录
### vue目录下的vuelist
function build_vue(){
	vue_Path=${1}
	vue_List=(${2})
	pull_code ${vue_Path}
	echo ${vue_List[@]}
	vue_List_longth=${#vue_List[@]}
        local RPM2=0
	while [ $RPM2 -lt ${vue_List_longth} ]
	do
	if [[ -n "`check_new 24 ${vue_Path}${vue_List[$RPM2]}`" ]];
	then 
		cd ${vue_Path}${vue_List[$RPM2]}
		#npm install -g cnpm --registry=https://registry.npm.taobao.org
		#cnpm install
		echo "##### npm run build ###########"
		npm run build
		echo "##### build finished ##########"
		echo "##### we will pub the vue to the source code"
		get_vue_jsp ${vue_List[$RPM2]}
		#删除原static
		rm -fr ${static_path}
		#拷贝新的static
		cd ${vue_Path}${vue}/dist/
		cp -fr `ls ${vue_Path}${vue}/dist/ -I index.html` ${static_path}
		update_jsp ${static_path} ${vue_jsp}
		push_code ${vue_Path}
	
	fi
		RPM2=`expr $RPM2 + 1`
	done

}
#### 判断vue和webent的关系
#### 传入代码库根目录和vue名，取得被编辑的jsp和静态资源路径
function get_vue_jsp(){
	vue=${1}
	if [ ${vue} == 'ft-manage-vue' ]
	then
		static_path=${git_KJ_Java}"ft-wm-webent/src/main/webapp/resources/ft-manage-static/"
		vue_jsp=${git_KJ_Java}"ft-wm-webent/src/main/webapp/WEB-INF/views/manage_index.jsp"
	fi

        if [ ${vue} == 'ft-scene-vue' ]
        then
			static_path=${git_KJ_Java}"ft-wm-webent/src/main/webapp/resources/ft-scene-static/"
            vue_jsp=${git_KJ_Java}"ft-wm-webent/src/main/webapp/WEB-INF/views/deliver_index.jsp"
        fi


        if [ ${vue} == 'ft-wm-vue' ]
        then
	 		static_path=${git_KJ_Java}"ft-wm-webent/src/main/webapp/resources/ft-wm-static/"
            vue_jsp=${git_KJ_Java}"ft-wm-webent/src/main/webapp/WEB-INF/views/index.jsp"
        fi

        if [ ${vue} == 'fontend-vue' ]
        then
			static_path=${git_MK_Home}"mk-smart-webent/src/main/webapp/resources/smart-static/"
            vue_jsp=${git_MK_Home}"mk-smart-webent/src/main/webapp/WEB-INF/views/index.jsp"
        fi

        if [ ${vue} == 'mk-weshine-vue' ]
        then
            static_path=${git_MK_Home}"mk-weshine-webent/src/main/webapp/resources/mk-weshine-static/"
            vue_jsp=${git_MK_Home}"mk-weshine-webent/src/main/webapp/WEB-INF/views/index.jsp"
        fi


}

#替换关键字函数，传入static路径和需处理jsp路径
function update_jsp(){
	s_path=${1}
	ue_jsp=${2}
	new=()
	old=()
	new[0]="`ls ${s_path}css/app.* |awk -F '.' '{print $2 }'`"
	new[1]="`ls ${s_path}/js/manifest.*|awk -F '.' '{print $2 }'`"
	new[2]="`ls ${s_path}/js/vendor.*|awk -F '.' '{print $2 }'`"
	new[3]="`ls ${s_path}/js/app.*|awk -F '.' '{print $2 }'`"
	old[0]="`grep static ${ue_jsp} |awk -F '.' 'NR==1 {print $2}'`"
        old[1]="`grep static ${ue_jsp} |awk -F '.' 'NR==2 {print $2}'`"
        old[2]="`grep static ${ue_jsp} |awk -F '.' 'NR==3 {print $2}'`"
        old[3]="`grep static ${ue_jsp} |awk -F '.' 'NR==4 {print $2}'`"
	RPM=0
	echo "new:"${new[@]}
	echo "old:"${old[@]}
	while [ $RPM -lt 4 ]
	do
        	echo ${old[$RPM]}/${new[$RPM]}
        	sed -i "s/${old[$RPM]}/${new[$RPM]}/g" ${ue_jsp}
        	RPM=`expr $RPM + 1`
	done

}
#pull code
function pull_code(){
	GIT_HOME=${1}
        cd ${GIT_HOME}
        git reset --hard HEAD^
        git checkout .
        echo "git分支名称：" `git branch | grep '*' | awk '{print $2}'`
        echo "拉取当前分支代码"
        git pull origin `git branch | grep '*' | awk '{print $2}'`
}

#push code
function push_code(){
	GIT_HOME=${1}
	cd ${GIT_HOME}
	git pull origin `git branch | grep '*' | awk '{print $2}'`
	git add -A ${static_path} ${static_path}js 
	echo "test"
	git commit ${static_path} ${vue_jsp} -m "compile and push vue automatically by shell" || return 0
	push origin `git branch | grep '*' | awk '{print $2}'` || return 0
}

#判断是否需要编译，传入距离现在的时间长度(hour)和vue路径
function check_new(){
	vue_path=${2}
	hour=${1}
	cd ${vue_path}
	check=`git log --since=${hour}.hours -p . |grep diff |awk '{print $4}' |awk -F '^b/' '{print $2}'|sort -u|awk -F '/' '{print $1}'|sort -u`
	echo "${check}"
	#if [ -z ${check} ]
	#then
	#    	echo "in ${hour} hours code update"
	#	return 0
	#fi
}

