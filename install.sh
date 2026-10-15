#!/bin/bash

set -e

SCRIPT_path="$(dirname "$(readlink -f "$0")")"
CONFIG_path="$SCRIPT_path/configs"
PATTERN_path="$CONFIG_path/patterns"
RESOURCE="$SCRIPT_path/resources"
RES_archs="$RESOURCE/archives"
RES_bins="$RESOURCE/bins"
RES_srcs="$RESOURCE/srcs"
RES_logs="$RESOURCE/logs"
LOG_file="$RES_logs/log_$(date '+%y%m%d-%H%M%S').txt"

SCRIPT_ver="v0.0.8"

CONFIG_links="$CONFIG_path/links.env"
APPS_list="$CONFIG_path/apps.txt"
CONFIG_vim="$PATTERN_path/vim/vim.env"
CONFIG_fish="$PATTERN_path/fish/fish.env"
CONFIG_zj="$PATTERN_path/zellij/zellij.env"

APPS=""

SET_dev="no"
SET_modules="all"

# Source from configs and system-data
source /etc/os-release
source "$CONFIG_links"

### COLOR CODE'S ###
CL0_reset="\e[0m"

CL1_red="\e[0;31m" 
CL1_grn="\e[0;32m"
CL1_blu="\e[0;34m"
CL1_cyn="\e[0;36m"
CL1_mag="\e[0;35m"
CL1_yel="\e[0;33m"
CL1_whi="\e[0;37m"

CL2_red="\e[1;31m"
CL2_grn="\e[1;32m"
CL2_blu="\e[1;34m"
CL2_cyn="\e[1;36m"
CL2_mag="\e[1;35m"
CL2_yel="\e[1;33m"
CL2_whi="\e[1;37m"

### LOG FUNCTIONS ###
LOG-info() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${CL1_whi}[${CL2_whi}INFO${CL1_whi} ${TIME}] ${CL0_reset}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_file})
}

LOG-err() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${CL1_red}[${CL2_red}ERROR${CL1_red} ${TIME}] ${CL0_reset}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_file})
	exit 1
}

LOG-warn() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${CL1_yel}[${CL2_yel}WARNING${CL1_yel} ${TIME}] ${CL0_reset}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_file})
}

LOG-comp() {
	local TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${CL1_grn}[${CL2_grn}COMPLETE${CL1_grn} ${TIME}] ${CL0_reset}$*" | tee -a >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> ${LOG_file})
}

LOG-cmd() {
	LOG-info "Running: $*"
	"$@" || LOG-err "Command failed: $*"
}

LOG-parse() {
	sleep 0.05
	echo -e "${CL1_cyn}$*${CL0_reset}"
}

### MINI UTILS ###
CREATE-dir() {
	if [ ! -d "$1" ]; then
		mkdir -p "$1"
	fi
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

WRITE-sed-end() {
	local LINE="$1"
	local FILE="$2"

	if grep -q "$1" "$2"; then
		LOG-info "Line \"${1}\" already include in ${2}"
	else
		LOG-comp "Add \"${1}\" to ${2}"
		echo "${1}" >> "${2}"
	fi
}

WRITE-awk-change() {
	local OLD_TEXT="$1"
	local NEW_TEXT="$2"
	local FILE="$3"

	SAFE_TEXT=$(echo "$BAD_TEXT" | sed -e 's/\\/\\\\\\\\/g' -e 's/&/\\\\\&/g')

	awk -v old="${OLD_TEXT}" -v new="${NEW_TEXT}" '
	' "${FILE}.tmp" && mv "${FILE}.tmp" "${FILE}"
}

WRITE-sed-after() {
	local AFTER_LINE="$1"
	local INPUT_LINE="$2"
	local FILE="$3"

	sed -i "/${AFTER_LINE}/a ${INPUT_LINE}" "${FILE}"
}

WRITE-eof-add() {
	local TEXT="$1"
	local FILE="$2"

	cat <<EOF >> ${FILE}
$TEXT
EOF
}

# App installation
#
# 1 args: Name of cli
# 2 args: Version app
# 3 args: Link-address
# 4 args: Name for bin-file after extracted
# 5 args: Name for arcive-file
#
# Example:
# APP-install-bin 'yourapp' 'v1' 'https://any-site.com/yourapp-v1.tar.gz' 'yourapp-v1' 'yourapp-v1.tar.gz'
#
APP-install-bin() {
	local BIN_name="$1"
	local BIN_ver="$2"
	local TAR_url="$3"
	local TAR_path="$4"
	local BIN_path="$5"

	if ! command -v "${BIN_name}" &> /dev/null; then	
		LOG-info "installing ${BIN_name} (${BIN_ver})..."
		if [ ! -f "$BIN_path" ]; then
			if [ ! -s ${TAR_path} ]; then
				# Download archive to /resources/archives
				LOG-cmd wget "$TAR_url" -O "$TAR_path"
			fi
			# Extract from /resources/archives to /resources/bins
			LOG-cmd tar -xvf "$TAR_path" -C "$RES_bins"
			LOG-cmd chmod u+x "$BIN_path"
		fi
		# Moving from /resources/bins to /usr/local/bin
		LOG-cmd sudo mv "$BIN_path" "/usr/local/bin/${BIN_cli}"
		LOG-comp "${BIN_name} has been successfully installed!"
	else
		LOG-info "${BIN_name} is already installed!"
	fi
}

APP-install-src() {
	local SRC_name="$1"
	local SRC_ver="$2"
	local TAR_url="$3"
	local TAR_path="$4"
	local SRC_path="$5"

	LOG-info "installing ${SRC_name} (${SRC_ver})..."
	if [ ! -d "$SRC_path" ]; then
		if [ ! -s ${TAR_path} ]; then
			# Download archive to /resources/archives
			LOG-cmd wget "$TAR_url" -O "$TAR_path"
		fi
		# Extract from /resources/archives to /resources/srcs
		LOG-cmd tar -xvf "$TAR_path" -C "$RES_srcs"
	fi
}

PRE-install() {
	LOG-info "Pre-install"
	
	SCAN-config "$APPS_list"
	SCAN-config "$CONFIG_links"
	SCAN-config "$CONFIG_vim"
	SCAN-config "$CONFIG_fish"
	SCAN-config "$CONFIG_zj"

	LOG-info "Please enter password..."
	sudo -v || LOG-err "Incorrect password!"

	LOG-info "Scan link-addresses..."
	SCAN-link "$ZJ_url"
	SCAN-link "$FISH_url"
	SCAN-link "$VP_url"
	SCAN-link "$YQ_url"
}

INSTALL-pkgs() {
	LOG-info "Installing apps on ${ID}..."

	APPS+=( $(< $APPS_list) )

	# Installing vim mc btop
	case $ID in
		"arch" )
			LOG-cmd sudo pacman -Sy > /dev/null
			LOG-cmd sudo pacman -S "${APPS[@]}"
			;;
		"ubuntu" | "debian" )
			LOG-cmd sudo apt-get update
			LOG-cmd sudo apt-get install "${APPS[@]}" -y
			;;
		* )
			LOG-err "Unknown System."
			exit 1
			;;
	esac

	APP-install-bin "fish" "$FISH_ver" "$FISH_url" \
		"${RES_archs}/fish-$FISH_ver.tar.xz" \
		"${RES_bins}/fish"
	
	APP-install-bin "zellij" "$ZJ_ver" "$ZJ_url" \
		"${RES_archs}/zellij-$ZJ_ver.tar.gz" \
		"${RES_bins}/zellij"
}

INSTALL-dev() {
	LOG-info "Installing dev-apps..."

	APP-install-bin "yq" "$YQ_ver" "$YQ_url" \
		"${RES_archs}/yq-$YQ_ver.tar.gz" \
		"${RES_bins}/yq_linux_${SHORT_ARCH}"
}

THEME-set() {
	LOG-err "Setting theme not working."
}

POST-install() {
	LOG-info "Post-install"
	
	# Clean ./resources/bins
	if [ -d "$RES_bins" ]; then
		LOG-cmd rm -rf "$RES_bins/*"
	fi
	# Clean ./resources/srcs
	if [ -d "$RES_srcs" ]; then
		LOG-cmd rm -rf "$RES_srcs/*"
	fi
}

PARSE-args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			"-h" | "--help" | "h" | "help" )
				LOG-parse "EP-SETUP ($SCRIPT_ver)"
				LOG-parse "--- | --------------- -"
				LOG-parse "-sc | --skip-check    - Ignore pre-install module (scan config-files, check link-address)."
				LOG-parse "-a  | --add-app       - Add application to install (...include in apt / pacman)."
				LOG-parse "-d  | --dev-app       - Add any-application to install for development (yq)."
				LOG-parse "-t  | --theme         - Choose your color-theme."
				LOG-parse "-fa | --file-apps     - Path to custom app-list (only .txt)."
				LOG-parse "--- | --------------- -"
				LOG-parse "-oi | --only-install  - Only install apps."
				LOG-parse "-ot | --only-theme    - Only set theme."
				LOG-parse "-oc | --only-config   - Only set config (plugins for vim-plug, prompt for fish and zellij)."
				LOG-parse ""
				
				exit 0
				;;
			"-a" | "--add-app" )
				LOG-parse "ADD: add application $2..."
				APPS+=("$2")
				
				shift 2
				;;
			"-d" | "--dev-app" )
				LOG-parse "ADD: add dev-applications (yq)..."
				SET_dev="yes"

				shift 1
				;;
			"-sc" | "--skip-check" )
				LOG-parse "ADD: skip checkers..."
				SET_checkers="no"
				
				shift 1
				;;
			"-oi" | "--only-install" )
				LOG-parse "ADD: only installation pkgs..."
				SET_modules="install"

				shift 1
				;;
			"-ot" | "--only-theme" )
				LOG-parse "ADD: only setting theme..."
				SET_modules="theme"

				shift 1
				;;
			"-oc" | "--only-config" )
				LOG-parse "ADD: only setting configuration..."
				SET_modules="config"

				shift 1
				;;
			"-fa" | "--file-apps" )
				LOG-parse "ADD: set custom apps-list..."
				if [ -f "$2" ]; then
					LOG-info "Set custom APPS-list file."
					APPS_list="$2"
				else
					LOG-err "File not found!"
				fi

				shift 2
				;;
			"-v" | "--ver" | "--version" | "v" | "ver" | "version" )
				LOG-parse "$SCRIPT_ver"
				exit 0
				;;
			"" )
				LOG-parse "INF: Without parameters..."
				shift 1;
				;;
			* )
				LOG-parse "ERR: Unknown parameter: $1"
				exit 1
				;;
		esac
	done
}

PARSE-args "${@:-}"

MAIN() {
	### CREATE DIRS
	CREATE-dir "$RES_archs"
	CREATE-dir "$RES_bins"
	CREATE-dir "$RES_srcs"
	CREATE-dir "$RES_logs"

	### INITIALIZE LOG-FILE
	if [ -f $LOG_file ]; then 
		rm $LOG_file
	fi
	
	touch $LOG_file
	
	### START INSTALLATION PROCESS
	# if [[ $SET_checkers = "yes" ]]; then
	# 	PRE-install
	# fi
	
	LOG-cmd source "$CONFIG_fish"
	LOG-cmd source "$CONFIG_zj"
	LOG-cmd source "$CONFIG_vim"
	
	case $SET_modules in
		"install" )
			INSTALL-pkgs
			;;
		"config" ) 
			SETUP-fish
			SETUP-zellij
			SETUP-vimplug
			;;
		"theme" )
			THEME-set
			;;
		"all" )
			# INSTALL-pkgs

			SETUP-fish
			# SETUP-zellij
			# SETUP-vimplug
			;;
	esac
	
	if [[ $SET_dev = "yes" ]]; then
		INSTALL-dev
	fi

	#POST-install
}

MAIN
