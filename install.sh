#!/bin/bash

set -e

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_PATH/config.env"
RESOURCE="$SCRIPT_PATH/.resource"
RES_archs="$RESOURCE/archives"
RES_bins="$RESOURCE/bin"
RES_dirs="$RESOURCE/dirs"
RES_logs="$RESOURCE/logs"

LOG_FILE="$SCRIPT_PATH/log.txt"

if [ -f $LOG_FILE ]; then 
	rm $LOG_FILE
fi

touch $LOG_FILE

source /etc/os-release
source "$CONFIG_FILE"

# Color variables
Cr_D="\e[0;31m"
Cg_D="\e[0;32m"
Cb_D="\e[0;34m"
Cc_D="\e[0;36m"
Cm_D="\e[0;35m"
Cy_D="\e[0;33m"
Cw_D="\e[0;37m"

Cr_B="\e[1;31m"
Cg_B="\e[1;32m"
Cb_B="\e[1;34m"
Cc_B="\e[1;36m"
Cm_B="\e[1;35m"
Cy_B="\e[1;33m"
Cw_B="\e[1;37m"

Cres="\e[0m"

# Log functions
LOG-comp() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cg_D}[${Cg_B}COMPLETE${Cg_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-cmd() {
	LOG-info "Running: $*"
	"$@" || LOG-err "Command failed: $*"
}

LOG-info() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cw_D}[${Cw_B}INFO${Cw_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-warn() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cy_D}[${Cy_B}WARNING${Cy_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-err() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cr_D}[${Cr_B}ERROR${Cr_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
	exit 1
}

pre-install() {	
	LOG-info "Pre-install"
	
	LOG-info "Check config-file..."
	if [ -f "$CONFIG_FILE" ]; then
		LOG-comp "File ${CONFIG_FILE} found..."
	else
		LOG-err "File ${CONFIG_FILE} not found!!!"
	fi
	
	LOG-info "Please enter password..."
	sudo -v || LOG-err "Incorrect password!"

	LOG-info "Check link-addresses..."
#	check-link "$ZJ_URL"
#	check-link "$FISH_URL"
#	check-link "$VP_URL"
#	check-link "$OMF_URL"

	LOG-info "Check directories..."
	check-dir "$RESOURCE"
	check-dir "$RES_archs"
	check-dir "$RES_bins"
	check-dir "$RES_dirs"
	check-dir "$RES_logs"
}

check-dir() {
	if [ ! -d $1 ]; then
		LOG-cmd mkdir $1
	else
		LOG-info "Directory $1 already created."
	fi
}

check-link() {
	local URL="$1"
	local CONDITION=$(curl -sLfI --connect-timeout 2 --retry 3 "$URL" > /dev/null)

	if $CONDITION; then
		LOG-comp "Address $1 worked"
	else
		LOG-warn "Address $1 not worked!"
	fi
}

install-pkgs() {
	LOG-info "Installing apps on ${ID}..."
	case $ID in
		"arch" )
			LOG-cmd sudo pacman -Sy > /dev/null
			LOG-cmd sudo pacman -S "$APPS"
			;;
		"ubuntu" | "debian" )
			LOG-cmd sudo apt-get update
			LOG-cmd sudo apt-get install -y "${APPS[@]}"
			;;
		* )
			LOG-err "Unknown System."
			exit 1
			;;
	esac

	LOG-info "Installing fish..."
	local FISH_TAR="${RES_archs}/fish-${FISH_VER}.tar.xz"
	local FISH_BIN="${RES_bins}/fish"
	
	if [ ! -f ${FISH_TAR} ]; then
		LOG-cmd wget "$FISH_URL" -O "$FISH_TAR"
	fi
	if [ ! -f "$FISH_BIN" ]; then
		LOG-cmd tar -xvf "$FISH_TAR" -C "$RES_bins"
	fi
	LOG-cmd chmod u+x "$FISH_BIN"
	# sudo mv "$FISH_BIN" /usr/local/dir

	LOG-info "installing zellij..."
	local ZJ_TAR="${RES_archs}/zellij-${ZJ_VER}.tar.gz"
	local ZJ_BIN="${RES_bins}/zellij"
	
	if [ ! -f ${ZJ_TAR} ]; then
		LOG-cmd wget "$ZJ_URL" -O "$ZJ_TAR"
	fi
	if [ ! -f "$ZJ_BIN" ]; then
		LOG-cmd tar -xvf "$ZJ_TAR" -C "$RES_bins"
	fi
	LOG-cmd chmod u+x "$ZJ_BIN"
	# sudo mv "$ZJ_BIN" /usr/local/dir
}

install-omf() {
	LOG-info "Installing Oh-My-Fish."
	
	local OMF_TAR="${RES_archs}/omf-${OMF_VER}.tar.gz"
	local OMF_DIR="${RES_dirs}/oh-my-fish-8"

	if [ ! -f ${OMF_TAR} ]; then
		LOG-cmd wget "$OMF_URL" -O "$OMF_TAR"
	fi
	if [ ! -d "$OMF_DIR" ]; then
		LOG-cmd tar -xvf "$OMF_TAR" -C "$RES_dirs"
	fi
}

install-vp() {
	LOG-info "Installing Vim-Plug."
	
	local VP_TAR="${RES_archs}/vp-${VP_VER}.tar.gz"
	local VP_DIR="${RES_dirs}/vim-plug-0.14.0"

	if [ ! -f ${VP_TAR} ]; then 
		LOG-cmd wget "$VP_URL" -O "$VP_TAR"
	fi
	if [ ! -d "$VP_DIR" ]; then
		LOG-cmd tar -xvf "$VP_TAR" -C "$RES_dirs"
	fi
}

post-install() {
	LOG-info "Post-install"
	
	LOG-info "Remove directory $RESOURCES"
	if [ -d "$RESOURCES" ]; then
		rm -rf "$RESOURCES"
	else
		LOG-info "Directory $RESOURCES no found!"
	fi
}

pre-install
install-pkgs
install-omf
install-vp
