#!/bin/bash

# This file is not part of the official Check_MK.
# The official homepage is at http://mathias-kettner.de/check_mk.
#
# check_mk and this software is free software;  
# you can redistribute it and/or modify it
# under the  terms of the  GNU General Public License  as published by
# the Free Software Foundation in version 2.  check_mk is  distributed
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;  with-
# out even the implied warranty of  MERCHANTABILITY  or  FITNESS FOR A
# PARTICULAR PURPOSE. See the  GNU General Public License for more de-
# ails.  You should have  received  a copy of the  GNU  General Public
# License along with GNU Make; see the file  COPYING.  If  not,  write
# to the Free Software Foundation, Inc., 51 Franklin St,  Fifth Floor,
# Boston, MA 02110-1301 USA.

# Author: Lance Tost (lance.tost@gmail.com)
# Title: linux_updates Check_Mk plugin
# Based on "windows_updates" by Lars Michelsen <lm@mathias-kettner.de>

# !! Place this script into your agent plugins directory on each host  !!


missingStatus=0
rebootNeeded=0
numUpdates=0
numSecurityUpdates=0

maxAge=1

statFile="/var/cache/mk_linuxupdates.stat"
statFileSecurity="/var/cache/mk_linuxsecurityupdates.stat"
updateLogFile="/var/log/yum.log"

echo "<<<linux_updates>>>"

statFileTimestamp=`stat --printf=%Y $statFile 2>/dev/null || echo 0` 
statFileSecurityTimestamp=`stat --printf=%Y $statFileSecurity 2>/dev/null || echo 0` 
updateLogFileTimestamp=`stat --printf=%Y $updateLogFile 2>/dev/null || echo 0` 

now=`date +%s`
statFileAge=$(((now-statFileTimestamp)/60/60/24))   # convert to days
statFileSecurityAge=$(((now-statFileSecurityTimestamp)/60/60/24))   # convert to days
updateLogFileAge=$(((now-updateLogFileTimestamp)/60/60/24))   # convert to days

#echo "now: ${now}" > /tmp/mk_linuxupdates.debug
#echo "statFileTimeStamp: ${statFileTimestamp}, updateLogFileTimeStamp: ${updateLogFileTimestamp}" >> /tmp/mk_linuxupdates.debug
#echo "statFileAge: ${statFileAge}, updateLogFileAge: ${updateLogFileAge}" >> /tmp/mk_linuxupdates.debug
#echo "statFileSecurityTimeStamp: ${statFileSecurityTimestamp}, updateLogFileTimeStamp: ${updateLogFileTimestamp}" >> /tmp/mk_linuxupdates.debug
#echo "statFileSecurityAge: ${statFileSecurityAge}, updateLogFileAge: ${updateLogFileAge}" >> /tmp/mk_linuxupdates.debug

# refresh if statFile missing, older than maxAge days, or older than update log file
if [ ! -f $statFile ] || [ $statFileAge -gt $maxAge ] || [ $updateLogFileTimestamp -gt $statFileTimestamp ]
then	
#	echo "updating $statFile and $statFileSecurity" >> /tmp/mk_linuxupdates.debug
	/usr/bin/yum --security check-update | egrep '(.i386|.x86_64|.noarch|.src)' | awk '{print $1}' > $statFileSecurity
	/usr/bin/yum check-update | egrep '(.i386|.x86_64|.noarch|.src)' > $statFile
	cat $statFileSecurity | while read update 
	do
		sed -i "s/$update/$update(!!)/" $statFile
	done
fi

if [ ! -f $statFile ] || [ ! -f $statFileSecurity ]
then	
	# unable to create statFile apparently
	missingStatus=1
	echo 0 1
	exit 
fi

numUpdatesSecurity=`cat $statFileSecurity | wc -l`

numUpdates=`cat $statFile | wc -l`
updates=`cat $statFile | sed 's/$/,/g'`


# Check if the running kernel matches the latest kernel installed
latestKernel=`ls -t /boot/vmlinuz-* | sed "s/\/boot\/vmlinuz-//g" | head -n1` 
currentKernel=`uname -r`

if [ "$latestKernel" != "$currentKernel" ]
then
	rebootNeeded=1
fi

# output data in a format that the Check_Mk plugin understands
echo $rebootNeeded 0 $numUpdates $numUpdatesSecurity
echo $updates | sed 's/,$//'

exit