#!/bin/bash
#自动识别需要更新（60天内修改过的）的静态资源文件，上传oss
#
USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`

git_MK_Home="${USER_HOME}/ArhasMK/"

#设置环境变量
source /etc/profile
#update code
project=${1}

if [[ ${project} == 'mk-imgr-webent' ]]
then
	#static的静态资源
	cd ${git_MK_Home}/mk-static/WebContent
	rm -fr ${USER_HOME}/static/resources
	cp --parents `git log --since=30.days -p resources/ |grep diff |awk '{print $4}' |awk -F '^b/mk-static/WebContent/' '{print $2}'|sort -u` ${USER_HOME}/static/
	cd ${USER_HOME}/static
	python oss_put_imgr.py
#cdn refresh
	echo "flash your-oss-domain/wm/resources"
	python cdn.py Action=RefreshObjectCaches ObjectType=File ObjectPath=your-oss-domain/resources |xargs curl

fi
#wm的静态资源
if [[ ${project} == 'mk-wm-webent' ]]
then
	cd ${git_MK_Home}/mk-wm-webent/src/main/webapp
	rm -fr ${USER_HOME}/static/wm/resources
	cp --parents `git log --since=30.days -p resources/ |grep diff |awk '{print $4}' |awk -F '^b/mk-wm-webent/src/main/webapp/' '{print $2}'|sort -u` ${USER_HOME}/static/wm
	cd ${USER_HOME}/static
	python oss_put_wm.py
	echo "flash your-oss-domain/resources"
	python cdn.py Action=RefreshObjectCaches ObjectType=File ObjectPath=your-oss-domain/wm/resources |xargs curl
fi

