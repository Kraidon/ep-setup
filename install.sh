#!/bin/bash

set -e

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"

source "$SCRIPT_PATH/config.env"

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
LOG-task() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cw_D}[${Cw_B}TASK${Cw_D} ${TIME}] ${Cres}$*"
}

LOG-comp() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cg_D}[${Cg_B}COMPLETE${Cg_D} ${TIME}] ${Cres}$*"
}

LOG-info() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cw_D}[${Cw_B}INFO${Cw_D} ${TIME}] ${Cres}$*"
}

LOG-warn() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cy_D}[${Cy_B}WARNING${Cy_D} ${TIME}] ${Cres}$*"
}

LOG-err() {
	TIME="$(date '+%H:%M:%S %D')"
	
	echo -e "${Cr_D}[${Cr_B}ERROR${Cr_D} ${TIME}] ${Cres}$*"
}
