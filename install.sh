#!/bin/bash

set -e

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_PATH="$SCRIPT_PATH/configs"
PATTERN_PATH="$CONFIG_PATH/patterns"
SCRIPT_ver="v0.0.4"

CONFIG_LINKS="$CONFIG_PATH/links.env"
APPS_LIST="$CONFIG_PATH/apps.txt"
CONFIG_VIM="$PATTERN_PATH/vim/vim.env"
CONFIG_FISH="$PATTERN_PATH/fish/fish.env"
CONFIG_ZJ="$PATTERN_PATH/zellij/zellij.env"

RESOURCE="$SCRIPT_PATH/resources"
RES_archs="$RESOURCE/archives"
RES_bins="$RESOURCE/bin"
RES_dirs="$RESOURCE/dirs"
RES_logs="$RESOURCE/logs"

APPS=""

# Source from configs and system-data
source /etc/os-release
source "$CONFIG_VIM"
source "$CONFIG_LINKS"
source "$CONFIG_FISH"
source "$CONFIG_ZJ"

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
LOG-info() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cw_D}[${Cw_B}INFO${Cw_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-err() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cr_D}[${Cr_B}ERROR${Cr_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
	exit 1
}

LOG-warn() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cy_D}[${Cy_B}WARNING${Cy_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-comp() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cg_D}[${Cg_B}COMPLETE${Cg_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-cmd() {
	LOG-info "Running: $*"
	"$@" || LOG-err "Command failed: $*"
}

# Scan path's
SCAN-config() {
	local FILE="$1"

	if [ -e $FILE ]; then
		LOG-comp "File $FILE found."
	else
		LOG-err "File $FILE not found!!!"
	fi
}

# Scan link-address
SCAN-link() {
	local URL="$1"
	local CONDITION=$(curl -sLfI --connect-timeout 2 --retry 3 "$URL" > /dev/null)
	
	if $CONDITION; then
		LOG-comp "Address $1 worked"
	else
		LOG-warn "Address $1 not worked!"
	fi
}

# Check config-file and connection to link-addresses
pre-install() {
	LOG-info "Pre-install"
	
	SCAN-config "$APPS_LIST"
	SCAN-config "$CONFIG_LINKS"
	SCAN-config "$CONFIG_VIM"
	SCAN-config "$CONFIG_FISH"
	SCAN-config "$CONFIG_ZJ"

	LOG-info "Please enter password..."
	sudo -v || LOG-err "Incorrect password!"

	LOG-info "Scan link-addresses..."
	SCAN-link "$ZJ_url"
	SCAN-link "$FISH_url"
	SCAN-link "$VP_url"
}

# Install pkgs (default: fish, zellij, vim, btop, mc)
install-pkgs() {
	LOG-info "Installing apps on ${ID}..."

	APPS+=( $(< $APPS_LIST) )

	# Installing vim mc btop
	case $ID in
		"arch" )
			LOG-cmd sudo pacman -Sy > /dev/null
			LOG-cmd sudo pacman -S "${APPS[@]}"
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

	install-fish	
	install-zellij
}

install-fish() {
	if ! command -v fish &> /dev/null; then
		LOG-info "Installing fish (${FISH_ver})..."
		
		local FISH_tar="${RES_archs}/fish-${FISH_ver}.tar.xz"
		local FISH_bin="${RES_bins}/fish"
	
		if [ ! -f "$FISH_bin" ]; then
			if [ ! -f ${FISH_tar} ]; then
				# Download archive
				LOG-cmd wget "$FISH_url" -O "$FISH_tar"
			fi
			# Extract
			LOG-cmd tar -xvf "$FISH_tar" -C "$RES_bins"
			LOG-cmd chmod u+x "$FISH_bin"
		fi
		# Moving to /usr/local/bin
		LOG-cmd sudo mv "$FISH_BIN" "/usr/local/bin"
		LOG-comp "Fish has been successfully installed!"
	else
		LOG-info "Fish is already installed!"
	fi

	LOG-info "Setup fish..."
	
	local CONFD_dir="${HOME}/.config/fish/conf.d"
	local FUNC_dir="${HOME}/.config/fish/functions"

	local THEME_conf="${CONFD_dir}/fish_frozen_theme.fish"
	local PROMPT_conf="${FUNC_dir}/fish_prompt.fish"
	
	if [ -f "$THEME_conf" ]; then
		if [ -d "$CONFD_dir" ]; then
			LOG-cmd mkdir -p "$CONFD_dir"
		fi
		if [ -d "$FUNC_dir" ]; then
			LOG-cmd mkdir -p "$FUNC_dir"
		fi

		LOG-cmd touch "$THEME_conf"
		LOG-cmd touch "$PROMPT_conf"
	fi

	EDIT-fish_frozen_theme "${THEME_conf}"
	EDIT-fish_prompt "${PROMPT_conf}"
}

install-zellij() {
	if ! command -v zellij &> /dev/null; then	
		LOG-info "installing zellij (${ZJ_ver})..."
		
		local ZJ_tar="${RES_archs}/zellij-${ZJ_ver}.tar.gz"
		local ZJ_bin="${RES_bins}/zellij"

		if [ ! -f "$ZJ_bin" ]; then
			if [ ! -f ${ZJ_tar} ]; then
				# Download archive
				LOG-cmd wget "$ZJ_url" -O "$ZJ_tar"
			fi
			# Extract
			LOG-cmd tar -xvf "$ZJ_tar" -C "$RES_bins"
			LOG-cmd chmod u+x "$ZJ_bin"
		fi
		# Moving to /usr/local/bin
		LOG-cmd sudo mv "$ZJ_BIN" /usr/local/dir
		LOG-comp "Zellij has been successfully installed!"
	else
		LOG-info "Zellij is already installed!"
	fi
}

# install and setup Vim-Plug
install-vp() {
	LOG-info "Installing Vim-Plug (${VP_ver})..."
	
	# download and untar archive
	local VP_tar="${RES_archs}/vp-${VP_ver}.tar.gz"
	local VP_dir="${RES_dirs}/vim-plug-0.14.0"
	
	if [ ! -d "$VP_dir" ]; then
		if [ ! -f ${VP_tar} ]; then 
			LOG-cmd wget "$VP_url" -O "$VP_tar"
		fi
		LOG-cmd tar -xvf "$VP_tar" -C "$RES_dirs"
	fi
	
	# add plug.vim
	local AUTOLOAD_dir="${HOME}/.vim/autoload/"
	local PLUG_VIM="$VP_dir/plug.vim"

	local VIMRC="${HOME}/.vimrc"
	
	if [ ! -f "$PLUG_VIM" ]; then
		if [ ! -d "$AUTOLOAD_dir" ]; then
			LOG-cmd mkdir -p "$AUTOLOAD_dir"
		fi
		LOG-cmd cp "$PLUG_VIM" "$AUTOLOAD_dir"
	fi

	EDIR-vimrc "${VIMRC}"
}

post-install() {
	LOG-info "Post-install"
	
	# Clean .resources/bins
	if [ -d "$RES_bins" ]; then
		LOG-cmd rm -rf "$RES_bins/*"
	fi
	# Clean .resources/dirs
	if [ -d "$RES_dirs" ]; then
		LOG-cmd rm -rf "$RES_dirs/*"
	fi
}

create-dir() {
	if [ ! -d "$1" ]; then
		mkdir -p "$1"
	fi
}

parse-args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			"-h" | "--help" )
				echo -e "EP-SETUP ($SCRIPT_ver)"
				echo -e "-f | --force   - Ignore unworking link-addresses."
				echo -e "-a | --add-app - Add application to install (...include in apt / pacman)."
				echo -e ""
				
				exit 0
				;;
			"-a" | "--add-app" )
				echo -e "ADD: add application $2..."
				APPS+=("$2")
				
				shift 2
				;;
			"-f" | "--force" )
				echo -e "ADD: ignore unworking link-addresses..."
				
				shift 1
				;;
			"-v" | "--version" )
				echo -e "$SCRIPT_ver"
				exit 0
				;;
			* )
				echo -e "ERR: Unknown parameter: $1"
				exit 1
				;;
		esac
	done
}

parse-args "${@}"

main() {
	# Create directories (this operations not write to log-file)
	create-dir "$RES_archs"
	create-dir "$RES_bins"
	create-dir "$RES_dirs"
	create-dir "$RES_logs"

	# Initializate log-file
	LOG_FILE="$RES_logs/log_$(date '+%y%m%d-%H%M%S').txt"
	
	if [ -f $LOG_FILE ]; then 
		rm $LOG_FILE
	fi
	
	touch $LOG_FILE
	
	# Installation	
	# pre-install
	install-pkgs
	# install-vp
	# post-install
}

main
