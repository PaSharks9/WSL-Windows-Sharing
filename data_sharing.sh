#! /bin/bash

# Script per fare l'import o l'export di dati dati tra WSL e Windows. 
# Utilizzo:
# 	$ data_sharing <windows_SOURCE_dir> <windows_DEST_dir> <linux_SOURCE_dir> <linux_DEST_dir>
#
# Se allo script non viene passato nessun parametro:
# - Valori di default delle cartelle Windows
# 	1) "/mnt/c/Users/<whoami>/Desktop/linux_sharing/export-zone"
#	2) "/mnt/c/Users/<whoami>/Desktop/linux_sharing/land-zone"
# 
# - Valori di default delle cartelle Linux
#	1) "/home/<whoami>/windows-hub/export-zone"
#	2) "/home/<whoami>/windows-hub/land-zone"

# ============================================ Menu ==================================================

# Stampa il menu principale
# Usage:
#	$ main_menu
function main_menu() {
	local CHOICE="0" 
	echo ""
	echo ""
	print_header "Linux/Windows Sharing Hub"
	echo ""
	echo -e " \e[33m* Working Dir\e[0m: $(pwd)"
	echo ""
	echo -e " \e[33m* Windows Source Default Directory\e[0m: ${WINDOWS_SOURCE_DIR}"
	echo -e " \e[33m* Windows Destination Default Directory\e[0m: ${WINDOWS_DEST_DIR}"
	echo ""
	echo -e " \e[33m* Linux Source Default Directory\e[0m: ${LINUX_SOURCE_DIR}"
	echo -e " \e[33m* Linux Destination Default Directory\e[0m: ${LINUX_DEST_DIR}"
	echo ""
	print_header ""

	while [ ${CHOICE} = "0" ]; do 
		echo ""
		echo -e "\e[33mMenu:\e[0m "
		echo ""
		echo " 1) Import from Windows"
		echo " 2) Export to Windows"
		echo ""
		echo -e " \e[31me) Exit\e[0m"
		echo ""
		read -p " Choice: " CHOICE
		echo ""

		case ${CHOICE} in
		  1|2)  return ${CHOICE} ;;
		  	e)  exit 0;;
			*)	echo " Wrong input (${CHOICE}). Retype ..."
				CHOICE="0" 
				echo "";;
		esac
	done
}

# Funzione per fare l'import/export dei dati tra wsl e windows
# Usage:
# 	$ transfer_data <source_dir> <dest_dir>	<mode>
function transfer_data_menu() {

	local CHOICE="a"
	local INSPECT="0"

	local SOURCE_DIR="${1}"
	local DEST_DIR="${2}"
	local MODE="${3}"

	if [ ${MODE} == "import" ]; then

		local TEXT="Change Windows Source Directory"
		local MENU_TYPE="Import from Windows Menu"
	else
		local TEXT="Change Linux Source Directory"
		local MENU_TYPE="Export to Windows Menu"
	fi

	while [[ ${CHOICE} != "0" ]]; do
		echo ""
		print_header "${MENU_TYPE}"
		echo ""

		# Contenuto cartelle
		show_content ${SOURCE_DIR}
		print_header ""
		
		echo ""
		echo -e "\e[33mChoose: \e[0m"
		echo ""		
		echo -e " 1) \e[34mFile\e[0m"
		echo -e " 2) \e[34mDirectory\e[0m"
		echo -e " 3) \e[34mInspect Source Directory\e[0m"
		echo -e " 4) \e[34m${TEXT}\e[0m"
		echo ""
		echo -e " \e[31mb) Back\e[0m"
		echo ""
		read -p "Chose: " CHOICE
		echo ""
		case "${CHOICE}" in
			1)  
				print_header ""
				echo ""
				read -p " Filename to copy (relative path): " FILENAME
				import_data ${FILENAME} "-f" ${SOURCE_DIR} ${DEST_DIR}
				CHOICE=$? 
				;;
			2) 	print_header ""
				echo ""
				read -p " Directory to copy (relative path): " DIRNAME
				import_data ${DIRNAME} "-d" ${SOURCE_DIR} ${DEST_DIR}
				CHOICE=$?
				;;
			3)  inspect_dir "${SOURCE_DIR}"
				RES=$?
				if [ $RES -ne 0 ]; then
					echo -e "${ERR} function inspect_dir error."
				fi
				;;
			4)	read -p " Insert new source dir path: " SOURCE_DIR
				;;
			b|B) break ;;
			*)  echo "Wrong input. Insert a number between 1 or 2" 
				echo "" 
				;;
		esac
	done

}

# ===================================== Menu Functions ===============================================
# Import di un file/directory
# Usage:
#	$ import_data <path> <-d|-f> <source_dir> <dest_dir>
function import_data() {
	local INSERT=0
	local LOCAL_PATH="$(pwd)/landing-zone"

	local SOURCE_DIR="${3}"
	local DEST_DIR="${4}"

	check_file "${SOURCE_DIR}/${1}" "${2}"
	RES=$?
	if [[ $RES -ne 0 ]]; then 																		    # Vuol dire che il file non è stato trovato
		return 0
	fi

	echo ""
	while [[ ${INSERT} == 0 ]]; do
		
		echo " Destination base path: ${DEST_DIR}"
		echo ""
		read -p " Insert destination path (absolute): " ABS_DEST_PATH
		echo -e " Insered path: \e[33m${ABS_DEST_PATH}/.\e[0m"
		read -p " Is that correct (y|n) ?  " CHOICE
		echo ""
		case ${CHOICE} in 
			y|Y) INSERT=1
				 if [ ! "${2}" "${ABS_DEST_PATH}" -a "${2}" == "-d" ]; then								# Se la cartella non esiste, la creo
					echo -e "${INFO} Dir ${ABS_DEST_PATH} not existing. Creating..."
					mkdir -p "${ABS_DEST_PATH}"
					if [ $? -ne 0 ]; then
						echo -e "${ERR} Creating dir ${ABS_DEST_PATH}. Exit..."
						exit 1
					else
						echo -e "${SUCC} Dir ${ABS_DEST_PATH} successfully created."
					fi
				 else
					echo -e "${INFO} ${ABS_DEST_PATH} exists."
				 fi
				 ;;
			*) ;;
		esac
		echo ""
	done

	cp -r "${SOURCE_DIR}/${1}" "${ABS_DEST_PATH}"
	RES=$?

	if [ $? -ne 0 ]; then
		echo -e "${ERR} Copying ${1} to ${ABS_DEST_PATH}" 
		echo -e "$(print_date): [ERR] Copying ${SOURCE_DIR}/${1} to ${ABS_DEST_PATH}" >> "${LOG_FILE}"
		exit 2
	else
		echo -e "${SUCC} Data imported successfully" 
		echo -e "$(print_date): [SUCC] Data imported successfully from ${SOURCE_DIR}/${1} to ${ABS_DEST_PATH}" >> "${LOG_FILE}"
	fi	
}

# Mostra il contenuto della cartella passata come parametro
# Usage:
#	$ show_content <dir>
function show_content() {
	
	echo ""
	echo -e "\e[33m * Source Directory Content\e[0m (${1})"
	echo ""
	
	for dir in $(ls ${1}); do
		echo -e "   - ${dir}"
	done
	echo ""

}

# Permette la navigazione e la stampa del contenuto della cartella sorgente
# Usage: 
#	$ inspect_dir <source_dir>
function inspect_dir() {

	SOURCE_DIR="${1}"
	print_header ""
	echo ""
	echo -e " 			\e[33mWelcome to the inspection tool...\e[0m"
	echo ""
	echo -e " Commands allowed: \e[32mls\e[0m, \e[32mcat\e[0m, \e[32mclear\e[0m, \e[32mexit\e[0m"
	echo ""
	echo -e "  \e[31m!\e[0m Command options are not allowed"
	echo ""
	echo -e "  \e[31m!\e[0m Root Dir: ${SOURCE_DIR}. It is forbidden to navigate"
	echo "	      in parents directories."
	echo ""
	echo -e "  \e[31m!\e[0m For <cat> command, remember to insert as argument the relative path to the file "
	echo "    to print (file path starts from <SOURCE_DIR> path)" 
	echo ""
	print_header ""
	echo ""

	CMD="a"
	while [ ${CMD} != "exit" ]; do
		CMD="a"
		ARG=""
		read -p "${SOURCE_DIR} >>> " CMD
		CMD=${CMD,,}									# Trasformo tutti i caratteri della stringa in caratteri minuscoli
		
		read -ra CMD_ARRAY <<< "$CMD"                             
        if [ ${#CMD_ARRAY[@]} -gt 1 ]; then
            CMD="${CMD_ARRAY[0]}"
            ARG="${SOURCE_DIR}/${CMD_ARRAY[1]}"
        fi
		
		case "${CMD}" in 
			ls) if [ -z "${ARG}" ]; then				# Allora è un comando ls della cartella attuale
					echo "${SOURCE_DIR} >>> $(${CMD} -la ${SOURCE_DIR})"
				else
					echo "${SOURCE_DIR} >>> $(${CMD} -la ${ARG})"
				fi
				;;
			cat) if [ -z "${ARG}" ]; then
					echo "${SOURCE_DIR} >>> Command ${CMD} need an argument"
				else
					echo "${SOURCE_DIR} >>> $(${CMD} ${ARG})"
				fi
				;;
			clear) echo "${SOURCE_DIR} >>> $(${CMD})" ;;
			exit) ;;
			*) echo -e "${SOURCE_DIR} >>> ${ERR} Command \e[31mforbidden\e[0m"
			   ;;
		esac
	done
}

# Controlla se un file o una directory esiste
# Usage:
#	$ check_file <path> <-d|-f>
function check_file() {
	echo ""
	echo ""
	echo " ************************************************************************"
	echo 
	if [ "${2}" "${1}" ]; then
		echo -e " ${SUCC} ${1} \e[32mexists\e[0m"
		echo ""
		echo " ************************************************************************"
		return 0
	else
		echo -e " ${ERR} ${1} doesn't exists."
		echo ""
		echo " ************************************************************************"
		return 1
	fi
}

# ==================================== Utilities Functions ===========================================
# Funzione per inizializzare il file di log
# Usage:
#	$ init_log_file
function init_log_file() {
	cat << EOF > "$LOG_FILE"
	======================================================
					SYSTEM LOG FILE
	======================================================
	Created on: $(date '+%Y-%m-%d %H:%M:%S')
	Hostname: $(hostname)
	System: $(uname -s)
	Kernel Version: $(uname -r)
	====================================================== 
EOF
}

# Stampa data e orario del log
# Usage:
#	$ print_date
function print_date(){
    echo -e "($(date '+%Y-%m-%d %H:%M:%S'))"
}

# Stampa l'header dei menù mantenendo una lunghezza massima di 100 caratteri a prescindere 
# dal titolo del menù, il quale sarà centrato
# Usage: 
#	$ print_header <message>
function print_header() {
    local title="$1"
    local total_length=100
    
    # Se il titolo è vuoto, stampa una linea di 100 caratteri '='
    if [ -z "$title" ]; then
        local line=$(printf '=%.0s' $(seq 1 $total_length))
        echo -e "${BLUE}${line}${NC}"
        return
    fi
    
    local title_length=${#title}
    
    # Calcola quanti caratteri '=' servono prima e dopo il titolo
    local padding_length=$(( (total_length - title_length - 2) / 2 ))  # -2 per gli spazi attorno al titolo
    
    # Gestisce il caso in cui la lunghezza totale meno il titolo è dispari
    local extra_padding=$(( (total_length - title_length - 2) % 2 ))
    
    # Crea le stringhe di padding
    local padding_left=$(printf '=%.0s' $(seq 1 $padding_length))
    local padding_right=$(printf '=%.0s' $(seq 1 $(($padding_length + $extra_padding))))
    
    # Stampa l'header colorato
    echo -e "${BLUE}$padding_left $title $padding_right${NC}"
}

# ============================================ ENTRYPOINT ============================================

# Print colorati
BLUE='\033[0;34m'
NC='\033[0m'

ERR="\e[31m[ERR]\e[0m"
WARN="\e[33m[WARN]\e[0m"
SUCC="\e[32m[SUCC]\e[0m"
INFO="\e[34m[INFO]\e[0m"

WINDOWS_SOURCE_DIR=${1:-"/mnt/c/Users/$(whoami)/Desktop/linux_sharing/export-zone"}							    # Cartella base Windows dalla quale fare l'import
WINDOWS_DEST_DIR=${2:-"/mnt/c/Users/$(whoami)/Desktop/linux_sharing/land-zone"}									# Cartella base Windows dalla quale fare l'export

LINUX_SOURCE_DIR=${3:-"$(pwd)/export-zone"}																		# Cartella base Linux dalla quale fare l'import
LINUX_DEST_DIR=${4:-"$(pwd)/land-zone"}																			# Cartella base Linux dalla quale fare l'export

LOG_DIR="logs/"
LOG_FILE="${LOG_DIR}/$(date +%Y_%m_%d).log"																	    # Imposto il nome del file di log in base alla data corrente

# Crea la directory dei log se non esiste
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"																			# Imposta i permessi appropriati (rwxr-xr-x)
fi

# Crea il file se non esiste
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

# Controlla se il file è vuoto (dimensione 0 bytes)
if [ ! -s "$LOG_FILE" ]; then
	init_log_file
fi

SELECTION="0"
while [ "${SELECTION}" = "0" ]; do
	main_menu
	RES=$?

	case ${RES} in
		1) transfer_data_menu ${WINDOWS_SOURCE_DIR} ${LINUX_DEST_DIR} "import" ;;
		2) transfer_data_menu ${LINUX_SOURCE_DIR} ${WINDOWS_DEST_DIR} "export" ;;
		*) echo -e "${ERR} Wrong input ${RES}. Exit.."
		   exit 1
		   ;;
	esac
done

