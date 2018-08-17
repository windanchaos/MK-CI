本项目是结合jenkins+shell的持续发布代码。可以完成：拉取代码、编译、部署（远程和本地两种）。

依赖以下环境：

* java
* git
* maven
* jenkins
* sshpass

# 文件介绍

* build.sh 构建的主文件，包含定义git仓库、若干常用的函数。
* deploy_function 推送到服务器上的执行操作，主要避免ssh连接后EOF方式各种导致异常问题。
* server.sh 服务器账户密码记录文件。
* vue.sh vue的编译脚本，适用我公司特殊情况。
* jenkins/jenkins_command_Demo.sh jinkens中的样例代码。项目截图。
* deploy_auto.sh 服务器上运行发版脚本Demo，通常结合crontab命令
* cdn-api 阿里云cdn的api，使用参考目录下的readme.txt
* static_demo.sh 阿里云静态资源操作demo，含上传oss和刷新cdn。

# 执行逻辑

jenkins中传入调用参数，在"Execute shell"中使用shell调用参数，调用build.sh提供的函数，驱动执行操作。

执行操作频率可：

* 手动执行
* jenkins定时执行
* crontab 定时执行（发布脚本在服务器）