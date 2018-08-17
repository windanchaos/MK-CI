#!/bin/bash
#自动识别需要更新（7天内修改过的）的静态资源文件，上传oss
#
USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`

git_MK_Home="${USER_HOME}/ArhasMK/"

#设置环境变量
source /etc/profile
#update code

#static的静态资源
cd ${git_MK_Home}/mk-static/WebContent
rm -fr ${USER_HOME}/static/resources
rm -fr ${USER_HOME}/static/sandbox/resources
cp --parents `git log --since=7.days -p resources/ |grep diff |awk '{print $4}' |awk -F '^b/mk-static/WebContent/' '{print $2}'|sort -u` ${USER_HOME}/static/sandbox
#wm的静态资源
cd ${git_MK_Home}/mk-wm-webent/src/main/webapp
rm -fr ${USER_HOME}/static/wm/resources
rm -fr ${USER_HOME}/static/sandbox/wm/resources
cp --parents `git log --since=7.days -p resources/ |grep diff |awk '{print $4}' |awk -F '^b/mk-wm-webent/src/main/webapp/' '{print $2}'|sort -u` ${USER_HOME}/static/sandbox/wm

cd ${USER_HOME}/static
python ${USER_HOME}/static/oss_put_sandbox.py
#cdn refresh
python cdn.py Action=RefreshObjectCaches ObjectType=File ObjectPath=Your_IP/sandbox |xargs curl
