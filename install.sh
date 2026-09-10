#!/bin/bash

set -e

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
CONFIG_FILE="$SCRIPT_PATH/config.env"
SCRIPT_ver="v0.0.3"

RESOURCE="$SCRIPT_PATH/.resource"
RES_archs="$RESOURCE/archives"
RES_bins="$RESOURCE/bin"
RES_dirs="$RESOURCE/dirs"
RES_logs="$RESOURCE/logs"

# Source from config.env and system-data
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
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cg_D}[${Cg_B}COMPLETE${Cg_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-cmd() {
	LOG-info "Running: $*"
	"$@" || LOG-err "Command failed: $*"
}

LOG-info() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cw_D}[${Cw_B}INFO${Cw_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-warn() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cy_D}[${Cy_B}WARNING${Cy_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
}

LOG-err() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cr_D}[${Cr_B}ERROR${Cr_D} ${TIME}] ${Cres}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_FILE})
	exit 1
}

# Check config-file and connection to link-addresses
pre-install() {	
	LOG-info "Pre-install"
	
	if [ -f "$CONFIG_FILE" ]; then
		LOG-comp "File ${CONFIG_FILE} found..."
	else
		LOG-err "File ${CONFIG_FILE} not found!!!"
	fi
	
	LOG-info "Please enter password..."
	sudo -v || LOG-err "Incorrect password!"

	LOG-info "Scan link-addresses..."
	scan-link "$ZJ_url"
	scan-link "$FISH_url"
	scan-link "$VP_url"
	scan-link "$OMF_url"
}

# Scan link-address
scan-link() {
	local URL="$1"
	local CONDITION=$(curl -sLfI --connect-timeout 2 --retry 3 "$URL" > /dev/null)
	
	if $CONDITION; then
		LOG-comp "Address $1 worked"
	else
		LOG-warn "Address $1 not worked!"
	fi
}

# Install pkgs (default: fish, zellij, vim, btop, mc)
install-pkgs() {
	LOG-info "Installing apps on ${ID}..."

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

	# Installing fish
	if ! command -v fish &> /dev/null; then
		LOG-info "Installing fish (${FISH_ver})..."
		
		local FISH_tar="${RES_archs}/fish-${FISH_ver}.tar.xz"
		local FISH_bin="${RES_bins}/fish"
	
		if [ ! -f "$FISH_bin" ]; then
			if [ ! -f ${FISH_tar} ]; then
				LOG-cmd wget "$FISH_url" -O "$FISH_tar"
			fi
			LOG-cmd tar -xvf "$FISH_tar" -C "$RES_bins"
			LOG-cmd chmod u+x "$FISH_bin"
		fi
		sudo mv "$FISH_BIN" /usr/local/dir
	fi

	# Installing zellij
	if ! command -v zellij &> /dev/null; then	
		LOG-info "installing zellij (${ZJ_ver})..."
		
		local ZJ_tar="${RES_archs}/zellij-${ZJ_ver}.tar.gz"
		local ZJ_bin="${RES_bins}/zellij"

		if [ ! -f "$ZJ_bin" ]; then
			if [ ! -f ${ZJ_tar} ]; then
				LOG-cmd wget "$ZJ_url" -O "$ZJ_tar"
			fi
			LOG-cmd tar -xvf "$ZJ_tar" -C "$RES_bins"
			LOG-cmd chmod u+x "$ZJ_bin"
		fi
		sudo mv "$ZJ_BIN" /usr/local/dir
	fi
}

# install and setup Oh-My-Fish
install-omf() {
	LOG-info "Installing Oh-My-Fish (${OMF_ver})..."
	
	local OMF_tar="${RES_archs}/omf-${OMF_ver}.tar.gz"
	local OMF_dir="${RES_dirs}/oh-my-fish-8"

	if [ ! -d "$OMF_dir" ]; then
		if [ ! -f ${OMF_tar} ]; then
			LOG-cmd wget "$OMF_url" -O "$OMF_tar"
		fi
		LOG-cmd tar -xvf "$OMF_tar" -C "$RES_dirs"
	fi
	
	# LOG-cmd fish "$OMF_dir/bin/install" --offline="$OMF_tar"	
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
	
	# edit .vimrc
	LOG-info "Edit $VIMRC..."
	cat <<EOF > $VIMRC
:set nu
:set tabstop=4
:set cursorline

:hi CursorLine cterm = bold
:hi CursorLineNr cterm = bold

call plug#begin('~/.vim/plugged')
	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-surround'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'airblade/vim-gitgutter'
    Plug 'arcticicestudio/nord-vim'
call plug#end()

let g:airline_powerline_fonts = 1
let g:airline_theme = 'nord'
let g:gitgutter_enabled = 1
let g:airline#extensions#whitespace#enabled = 0

colorscheme nord
EOF
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
		mkdir "$1"
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
	create-dir "$RESOURCE"
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

	# install-pkgs
	# install-omf
	install-vp
}

main
