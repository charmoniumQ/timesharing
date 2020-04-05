#!/usr/bin/env bash

# copy="rsync -avhW --no-compress --progress"
# ${copy} xilinx-vc707-xc7vx485t ${HOME}/esp/socs/

. ./xilinx.sh
cd ${HOME}/esp/socs/xilinx-vc707-xc7vx485t
bash

# make -j48 esp-config &&  make -j48 soft && make vivado-syn && make -j48 linux && make fpga-program
