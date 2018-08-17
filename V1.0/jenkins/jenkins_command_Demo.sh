USER=`whoami`
USER_HOME=`cat /etc/passwd | grep $USER | awk -F ":" '{print $6}'|head -1`
GIT_HOME="${USER_HOME}/ArhasMK"
#source ${GIT_HOME}/mk-dbscript-mysql/mkci/build.sh
source ${USER_HOME}/build.sh
webents=${webents//,/' '}
RPCS=${RPC//,/' '}
Server=${SERVER#* }
sites=${SITES}

echo ${Server}
init_parmaters ArhasMK
pull_code ${GIT_HOME} ${branch}

if [[  -n  ${webents[*]} ]] || [[ -n ${RPCS[@]} ]]
then
  build_agg
fi

#RPC
if [[ ${profile} == "st-https" ]] ;then
for rpc in ${RPCS[@]} ;do
        build ${rpc} $profile
        deploy_RPC ${rpc} 172.16.0.11 ${sites}
done
else
for rpc in ${RPCS[@]} ;do
        build ${rpc} $profile
        deploy_RPC ${rpc} ${Server} ${sites}
done
fi
#webent
for webent in ${webents[@]} ;do
        build ${webent} $profile
        deploy_webent ${webent} ${Server} ${sites}
done

if [ ${restart_tomcat} == 'true' ]
then
		restartom ${Server} servers
fi

if [ ${copy_without_restart} == 'true' ]
then
        bash ${USER_HOME}/ci/cpauto.sh
        bash ${USER_HOME}/static_sd.sh
fi