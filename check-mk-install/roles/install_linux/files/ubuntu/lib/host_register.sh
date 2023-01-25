#!/bin/bash

hostname=$(hostname)
ipaddress=$(/sbin/ifconfig |egrep '10.1' |  awk '{ print $2}' | sed 's/addr:*//')


echo $hostname
echo $ipaddress

while getopts u:p:f:? ARG; do
        case $ARG in
                u)
                        user=$OPTARG
                        ;;
                p)
                        mk_pass=$(echo $OPTARG)
                        ;;
                f)
                        folder=$(echo $OPTARG)
                        ;;
                ?)
                        usage
                        exit
                        ;;
        esac
done

curl -k "https://10.129.108.18/devops/check_mk/webapi.py?action=add_host&_username=$user&_secret=$mk_pass" -d "request={\"attributes\":{\"tag_OS\": \"Linux\", \"ipaddress\": \"$ipaddress\"}, \"hostname\": \"$hostname\", \"folder\": \"$folder\"}"

exit