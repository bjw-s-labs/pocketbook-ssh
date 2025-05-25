#!/bin/sh
# Change this if the 'pb_sshd' directory has been installed elsewhere.
SSHDIR=/mnt/ext1/applications/dropbear

network_up()
{
	/ebrmain/bin/netagent status > /tmp/netagent_status_wb
	read_cfg_file /tmp/netagent_status_wb NETAGENT_
	if [ "$NETAGENT_nagtpid" -gt 0 ]; then
		:
		#network enabled
	else
		/ebrmain/bin/netagent net on
	fi
	/ebrmain/bin/netagent connect
}

# Connect to the net first if necessary.
ifconfig eth0 > /dev/null 2>&1
if [ $? -ne 0 ]; then
	touch /tmp/dropbear-connected-to-wifi
	network_up
fi

mkdir -p "$SSHDIR"/keys

"$SSHDIR"/dropbear \
	-R \
	-s \
	-p 1125 \
	-D "$SSHDIR"/keys \
	1> "$SSHDIR"/sshd.log 2> "$SSHDIR"/sshd.log
