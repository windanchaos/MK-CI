#!/bin/bash
source /etc/profile
#user port passport(UPP)

function get_server_UPP(){
        if [[ ${1} == '10.188.*.*' ]];then
                CONFIG_REMOTE_USER='user'
                CONFIG_REMOTE_IP='10.188.*.*'
                CONFIG_REMOTE_PORT='22'
                PASSWORD='passwd'
        elif [[ ${1} == '10.188.*.*' ]];then
                CONFIG_REMOTE_USER='user'
                CONFIG_REMOTE_IP='10.188.*.*'
                CONFIG_REMOTE_PORT='22'
                PASSWORD='passwd'
         else
		CONFIG_REMOTE_USER=''
        fi

        if [[ ${1} =~ '172.16.0.' ]];then
                IS_PRODUCT='true'
        else
                IS_PRODUCT='false'
        fi
}
