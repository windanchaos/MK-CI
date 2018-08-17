#!/bin/bash
#shell name :backups.sh
#function purpose 函数主要责任
#rolling back 回滚


source deploy.sh
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

