#!/bin/sh
set -e -x
cd "$(dirname "${0}")"

if [ -d $HOME/opt/Xilinx ]
then
	# if you have Xilinx installed, change this path
	# otherwise, this arg will be omitted
	extra_args="sameplace_mounts=$HOME/opt/Xilinx"
	# network=bridge is required to access the hw_server
fi

env \
	os=centos \
	os_tag=centos7 \
	os_type=redhat \
	${extra_args} \
	mount_cwd=yes \
	mounts=${PWD}/xilinx-vc707-xc7vx485t:${HOME}/esp/socs/xilinx-vc707-xc7vx485t\
	be_user=yes \
	forward_x11=yes \
	command=./entrypoint.sh \
	./docker.sh
