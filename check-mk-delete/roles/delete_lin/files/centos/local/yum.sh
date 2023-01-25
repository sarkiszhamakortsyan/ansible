#!/bin/bash

MK_VARDIR="/var/lib/check_mk_agent"
yum_content=$(cat $MK_VARDIR/cache/yum_check.cache |sed -e '1,1d')

#### TEST SECTION ONLY
#echo $yum_content

    if [ $yum_content -lt 600 ] ; then
        status=0
        statustxt=OK
    elif [ $yum_content -lt 900 ] ; then
        status=1
        statustxt=WARNING
    else
        status=2
        statustxt=CRITICAL
    fi
    echo "$status PendingUpdates count=$yum_content;50;100;0; $statustxt - $count pending updates $yum_content"
