#!/usr/bin/env bash

. ./xilinx.sh
cd ${HOME}/esp/socs/xilinx-vc707-xc7vx485t

export PATH=${HOME}/opt/leon/mklinuximg:${HOME}/opt/leon/sparc-elf-4.4.2/bin/:/home/grayson5/opt/leon/bin:/software/cadence-Feb2019/STRATUS182/tools.lnx86/bin:/software/cadence-Feb2019/INCISIVE152/tools.lnx86/bin/:/software/cadence-Feb2019/XCELIUM1809/tools.lnx86/bin/:${PATH}
bash

# make -j48 esp-config && make -j48 soft && make vivado-syn && make -j48 linux && make fpga-program
