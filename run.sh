#!/bin/bash
set -e -x
cd "$(dirname "${0}")"

if [ $(hostname) = 'dholak' ]
then
	extra_args="sameplace_mounts=$HOME/opt/Xilinx /software/cadence-Feb2019"
	if [ ! -d /software/cadence-Feb2019 ]
	then
		echo "Cadence is not loaded. Run"
		echo
		echo "    module load cadence/Feb2019"
		echo
		exit 1
	fi
fi

env \
	os=centos \
	os_tag=centos7 \
	os_type=redhat \
	"${extra_args}" \
	mount_cwd=yes \
	mounts="${PWD}/xilinx-vc707-xc7vx485t:${HOME}/esp/socs/xilinx-vc707-xc7vx485t ${PWD}/drivers:${HOME}/esp/soft/leon3/drivers ${PWD}/vivado_hls:${HOME}/esp/accelerators/vivado_hls" \
	be_user=yes \
	forward_x11=yes \
	docker_run_args="--env LM_LICENSE_FILE=${LM_LICENSE_FILE} --env __LMOD_STACK_LM_LICENSE_FILE=${__LMOD_STACK_LM_LICENSE_FILE}" \
	command=./entrypoint.sh \
	./docker.sh
