RUN sudo yum install -y epel-release

# Install ESP dependencies
RUN \
	sudo yum update -y && \
	sudo yum install -y git octave octave-io jq python python-pip python3 python3-pip python3-tkinter perl perl-YAML perl-XML-Simple xterm csh ksh zsh tcl glibc-devel glibc-devel.i686 glibc-static glibc-static.i686 mesa-libGL.i686 mesa-libGLU.i686 mesa-libGL mesa-libGLU mesa-dri-drivers mesa-dri-drivers.i686 readline-devel readline-devel.i686 libXp libXp.i686 openmotif ncurses gdbm-devel gdbm-devel.i686 libSM libSM.i686 libXcursor libXcursor.i686 libXft libXft.i686 libXrandr libXrandr.i686 libXScrnSaver libXScrnSaver.i686 libmpc-devel libmpc-devel.i686 nspr nspr.i686 nspr-devel nspr-devel.i686 tk-devel libpng12 libpng12.i686 gcc libXtst wget lbzip2 && \
	pip3 install --user Pmw && \
	sudo ln -s /lib64/libtiff.so.5 /lib64/libtiff.so.3 && \
	sudo ln -s /usr/lib64/libmpc.so.3 /usr/lib64/libmpc.so.2 && \
	sudo ln -s /usr/bin/qmake-qt5 /usr/bin/qmake && \
true

RUN sudo yum install -y which file gcc-c++ unzip patch bc bzip2 'perl(ExtUtils::MakeMaker)' 'perl(Thread::Queue)'

# Install ESP repository
RUN \
	mkdir -p $HOME/esp && \
	git clone --recursive https://github.com/sld-columbia/esp.git $HOME/esp && \
true

# This chown necessary because I volume mount $HOME/opt/xilinx
# so opt might not be owned by user
RUN sh -c "mkdir -p $HOME/opt && sudo chown $(id --user):$(id --group) $HOME/opt"

# I use sh -c so that I can cd without side-effects
RUN sh -c "sudo rm -rf $HOME/tmp $HOME/opt/leon && mkdir $HOME/tmp && cd $HOME/tmp && printf '\n$HOME/opt/leon\n\n\n' | $HOME/esp/utils/scripts/build_leon3_toolchain.sh"

ENV PATH=${HOME}/opt/leon/mklinuximg:${HOME}/opt/leon/sparc-elf-4.4.2/bin/:/home/grayson5/opt/leon/bin:${PATH}

RUN printf '. ./xilinx.sh\necho Initialized Xlinx\n' > $HOME/.bashrc

# cd "${HOME}/esp/socs/xilinx-vc707-xc7vx485t/"
# make -j48 esp-config &&  make -j48 soft && make vivado-syn && make -j48 linux
# FPGA_HOST=localhost XIL_HW_SERVER_PORT=3121 make fpga-program
