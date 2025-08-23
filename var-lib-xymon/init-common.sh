#!/run/current-system/sw/bin/bash

	export PATH=$PATH:/run/current-system/sw/bin/
	. /etc/default/xymon-client
	if [ "$XYMONSERVERS" = "" ]; then
		echo "Please configure XYMONSERVERS in /etc/default/xymon-client"
		exit 0
	fi

	umask 022

	if ! [ -d /run/xymon ] ; then
		mkdir /run/xymon
		chown xymon:xymon /run/xymon
	fi

	set -- $XYMONSERVERS
	if [ $# -eq 1 ]; then
		echo "XYMSRV=\"$XYMONSERVERS\""
		echo "XYMSERVERS=\"\""
	else
		echo "XYMSRV=\"0.0.0.0\""
		echo "XYMSERVERS=\"$XYMONSERVERS\""
	fi > /run/xymon/bbdisp-runtime.cfg

	for cfg in /etc/xymon/clientlaunch.d/*.cfg ; do
		test -e $cfg && echo "include $cfg"
	done > /run/xymon/clientlaunch-include.cfg

	for cfg in /etc/xymon/xymonclient.d/*.cfg ; do
		test -e $cfg && echo "include $cfg"
	done > /run/xymon/xymonclient-include.cfg

	if test -x /usr/lib/xymon/server/bin/xymond ; then
		for cfg in /etc/xymon/tasks.d/*.cfg ; do
			test -e $cfg && echo "include $cfg"
		done > /run/xymon/tasks-include.cfg

		for cfg in /etc/xymon/graphs.d/*.cfg ; do
			test -e $cfg && echo "include $cfg"
		done > /run/xymon/graphs-include.cfg

		for cfg in /etc/xymon/xymonserver.d/*.cfg ; do
			test -e $cfg && echo "include $cfg"
		done > /run/xymon/xymonserver-include.cfg
	fi
