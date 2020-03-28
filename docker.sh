#!/bin/sh
set -e -x

###############################################################################
# About
###############################################################################

# This script automates many common tasks I need to do using docker,
# such as emulating the current user in the container. Some of these
# tasks require changes at build-time, run-time, or both, so this
# script controls building and running docker images.

# See "Inputs" for the tasks that this script can automate.

# Inputs can be supplied from the shell like so,
#
#     $ forward_x11=yes /path/to/docker.sh
#
# Or in the case where there is no shell,
#
#     $ env forward_x11=yes /path/to/docker.sh

###############################################################################
# Inputs
###############################################################################

# Name of the output image
image_out="${image:-$(basename ${PWD})}"

# Base-image of the docker image
os="${os:-ubuntu}"
os_tag="${os_tag:-latest}"

# os_type in {debian, redhat}
# This determines the initial setup phase
os_type="${os_type:-debian}"

# Forward X11 outside of the docker container
forward_x11="${forward_x11:-no}"

# Uses --interactive --terminal
interactive="${interactive:-yes}"

# Emulate the current user in the Docker container.
# This adds a user with the same group, UID, and GID as the current user.
# It switches to them for the rest of the dockerfile build and execution.
# This makes files written to host-mounted volumes from inside the container readable outside the container
be_user="${be_user:-yes}"

# Extra packages to install
# If you are using a Dockerfile, probably put this there instead.
packages="${packages:-}"

# Use the current-working directory as the context
# If you don't use COPY or ADD, probably say "no"
context_cwd="${context_cwd:-no}"

# Mount the current-working directory of the host in the container
# and move to that directory.
mount_cwd="${mount_cwd:-yes}"

# Space-separated list of dirs
# Mounts these dirs in the same path in the container
sameplace_mounts="${sameplace_mounts:-}"

# Space-separated list of colon-separated pairs
mounts="${mounts:-}"

# The dockerfile to apply after the generated dockerfile
# Defaults to "Dockerfile" if that file is present else no further dockerfile is applied.
dockerfile_in="${dockerfile:-}"

# Output for the resulting dockerfile
# No output is generated if this is unset
dockerfile_out="${dockerfile_out:-$(mktemp)}"

# Add any other flags here
docker_run_args="${docker_run_args:-}"

# Command to run after upping, if any
command="${command:-}"

###############################################################################
# Building
###############################################################################

if [ "${os_type}" = "debian" ]
then
	cat <<EOF > "${dockerfile_out}"
FROM ${os}:${os_tag}

# I am putting the packages necessary for adding other packages here.
# Without these, other packages could not be immediately installed by the user.
# sudo is necessary once I de-escalate priveleges.
# curl and gnupg2 is necessary for adding apt keys.
# apt-transport-https and ca-certificates for HTTPS apt sources.
# nano is necessary to debug
RUN \
    apt-get update && apt-get upgrade -y && apt-get autoremove -y && \
    apt-get install -y locales sudo gnupg2 curl apt-transport-https ca-certificates nano && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    apt-get update && \
true
ENV LANG=en_US.utf8
EOF
else if [ "${os_type}" = "redhat" ]
	 then
		 cat <<EOF > "${dockerfile_out}"
FROM ${os}:${os_tag}
RUN \
    yum update -y && \
    yum install -y sudo curl nano && \
true
EOF
	 else
		 echo "Unrecognized os_type ${os_type}"
		 exit
	 fi
fi

if [ "${be_user}" = "yes" ]; then
	GROUP="$(id -g -n)"
	GID="$(id -g)"
	UID="$(id -u)"
    cat <<EOF >> "${dockerfile_out}"
RUN groupadd --gid "${GID}" "${GROUP}" && \
    useradd --base-dir /home --gid "${GID}" --create-home --uid "${UID}" -o --shell /bin/bash "${USER}" && \
    echo "%${GROUP} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
true
# In the case where be_user = yes, I de-escalate priveleges here.
# This is so that if you write files in the Dockerfile, they will be accessible to the end-user, who is running non-root.
# Root can still be used in the Dockerfile via sudo.
USER ${USER}:${GROUP}
ENV HOME=/home/${USER}
EOF
fi

if [ -n "${packages}" ]
then
	if [ "${os_type}" = "debian" ]
	then
		installer=apt-get
	else if [ "${os_type} = redhat" ]
		 then
			 installer=yum
		 else
			 echo "Unrecognized os_type ${os_type}"
			 exit
		 fi
	fi
	# Could be be_user=yes or not. In either case, using 'sudo' is safe.
	cat <<EOF >> "${dockerfile_out}"
RUN sudo ${installer} install -y ${packages}
EOF
fi

if [ "${context_cwd}" = "yes" ]
then
	context="${PWD}"
else
	context="$(mktemp --directory)"
fi

# fill in default arg in the case where dockerfile is empty
if [ -z "${dockerfile_in}" ]
then
	if [ -f "Dockerfile" ]
	then
		dockerfile_in="Dockerfile"
	fi
fi

if [ ! -z "${dockerfile_in}" ]
then
   cat "${dockerfile_in}" >> "${dockerfile_out}"
fi

docker build --tag="${image_out}" --file="${dockerfile_out}" "${context}"

###############################################################################
# Running
###############################################################################

# You should almost always want these args
docker_run_args="${docker_run_args} --rm --init"

if [ "${be_user}" = "yes" ]; then
	docker_run_args="${docker_run_args} --user=${USER}:${GROUP} --env HOME=${HOME}"
fi

if [ "${forward_x11}" = "yes" ]; then
	# https://stackoverflow.com/a/25280523/1078199
    XSOCK=/tmp/.X11-unix
    XAUTH=/tmp/.docker.xauth
    xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTH}" nmerge -
    docker_run_args="${docker_run_args} --network=host --env DISPLAY=${DISPLAY} --env XAUTHORITY=${XAUTH} --volume ${XSOCK}:${XSOCK} --volume ${XAUTH}:${XAUTH}"
fi

if [ "${interactive}" = "yes" ]; then
        docker_run_args="${docker_run_args} --interactive --tty"
fi

if [ "${mount_cwd}" = "yes" ]; then
	wd="$(realpath ${PWD})"
    docker_run_args="${docker_run_args} --volume ${wd}:${wd} --workdir ${wd}"
fi

for sameplace_mount in ${sameplace_mounts}
do
	docker_run_args="${docker_run_args} --volume ${sameplace_mount}:${sameplace_mount}"
done

for mount in ${mounts}
do
	docker_run_args="${docker_run_args} --volume ${mount}"
done

if [ ! -z "${network}" ]
then
	docker_run_args="${docker_run_args} --network=${network}"
fi

if [ ! -z "${dockerfile_out}" ]
then
	echo "# docker run ${docker_run_args} ${image_out} ${command}" >> "${dockerfile_out}"
fi

docker run ${docker_run_args} ${image_out} ${command}
