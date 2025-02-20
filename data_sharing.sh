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
		read -p " Insert value: " CHOICE
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
		read -p "Insert value: " CHOICE
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
    local SOURCE_PATH="${SOURCE_DIR}/${1}"

    check_file "${SOURCE_PATH}" "${2}"
    RES=$?
    if [[ $RES -ne 0 ]]; then
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
                 if [ ! "${2}" "${ABS_DEST_PATH}" -a "${2}" == "-d" ]; then
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

    # Scansiona per .gitignore
    local respect_gitignore="false"
    local verbose="false"
    
    if scan_for_gitignore "${SOURCE_PATH}"; then
        echo -e "${WARN} .gitignore files found in the directory structure."
        echo ""
        echo "Choose how to proceed:"
        echo " 1) Copy everything (ignore .gitignore rules)"
        echo " 2) Respect .gitignore rules"
        echo " 3) Respect .gitignore rules with verbose output"
        echo ""
        local valid_choice=false
        while [ "${valid_choice}" = "false" ]; do
            read -p "Your choice (1-3): " CHOICE
            case ${CHOICE} in
                1)  respect_gitignore="false"
                    verbose="false"
                    valid_choice=true
                    ;;
                2)  respect_gitignore="true"
                    verbose="false"
                    valid_choice=true
                    ;;
                3)  respect_gitignore="true"
                    verbose="true"
                    valid_choice=true
                    ;;
                *)  echo -e "${ERR} Invalid choice. Please select 1, 2, or 3."
                    ;;
            esac
        done
    fi

    # Usa la nuova funzione copy_files
    copy_files "${SOURCE_PATH}" "${ABS_DEST_PATH}/$(basename "${SOURCE_PATH}")" "${respect_gitignore}" "${verbose}"
    RES=$?

    if [ $RES -ne 0 ]; then
        echo -e "${ERR} Copying ${1} to ${ABS_DEST_PATH}" 
        echo -e "$(print_date): [ERR] Copying ${SOURCE_PATH} to ${ABS_DEST_PATH}" >> "${LOG_FILE}"
        exit 2
    else
        echo -e "${SUCC} Data imported successfully" 
        echo -e "$(print_date): [SUCC] Data imported successfully from ${SOURCE_PATH} to ${ABS_DEST_PATH}" >> "${LOG_FILE}"
    fi
}

# Copia ricorsivamente i file, con o senza rispetto del .gitignore
# Usage:
#   $ copy_files <source> <destination> <respect_gitignore> [verbose]
function copy_files() {
    local source="$1"
    local destination="$2"
    local respect_gitignore="$3"
    local base_source="$(dirname "${source}")"
    export VERBOSE="${4:-false}"
    
    # Se il path sorgente non esiste, esci
    if [[ ! -e "${source}" ]]; then
        echo -e "${ERR} Source path ${source} does not exist" >&2
        return 1
    fi
    
    # Se è un file
    if [[ -f "${source}" ]]; then
        if [ "${respect_gitignore}" = "false" ] || ! should_ignore "${source}" "${base_source}"; then
            mkdir -p "$(dirname "${destination}")"
            cp "${source}" "${destination}"
            if [ "${VERBOSE}" = "true" ]; then
                echo -e "${INFO} Copied file: ${source} -> ${destination}"
            fi
        fi
    # Se è una directory
    elif [[ -d "${source}" ]]; then
        if [ "${respect_gitignore}" = "false" ] || ! should_ignore "${source}" "${base_source}"; then
            mkdir -p "${destination}"
            
            # Itera su tutti gli elementi nella directory
            while IFS= read -r -d '' item; do
                local basename="$(basename "${item}")"
                local new_dest="${destination}/${basename}"
                
                # Chiamata ricorsiva per ogni elemento
                copy_files "${item}" "${new_dest}" "${respect_gitignore}" "${VERBOSE}"
            done < <(find "${source}" -mindepth 1 -maxdepth 1 -print0)
        fi
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
		
		read -ra CMD_ARRAY <<< "$CMD"                             
        if [ ${#CMD_ARRAY[@]} -gt 1 ]; then
            CMD="${CMD_ARRAY[0]}"
			CMD=${CMD,,}									# Trasformo tutti i caratteri della stringa in caratteri minuscoli
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

# Funzione per ottenere il percorso relativo
# Usage:
#   $ get_relative_path <path> <base>
function get_relative_path() {
    local path="$1"
    local base="$2"
    echo "${path#"${base}/"}"
}

# Funzione per scansionare una directory alla ricerca di file .gitignore
# Usage:
#   $ scan_for_gitignore <directory>
function scan_for_gitignore() {
    local directory="$1"
    local gitignore_files=()
    
    echo -e "${INFO} Scanning directory structure for .gitignore files..."
    echo ""
    
    while IFS= read -r -d '' file; do
        gitignore_files+=("$file")
    done < <(find "${directory}" -name ".gitignore" -type f -print0)
    
    if [ ${#gitignore_files[@]} -eq 0 ]; then
        echo -e "${INFO} No .gitignore files found in the directory structure."
        echo ""
        return 1
    else
        echo -e "${WARN} Found ${#gitignore_files[@]} .gitignore file(s):"
        echo ""
        for file in "${gitignore_files[@]}"; do
            echo -e "   - ${file}"
            echo -e "     Contains the following patterns:"
            echo ""
            while IFS= read -r pattern || [[ -n "${pattern}" ]]; do
                [[ "${pattern}" =~ ^[[:space:]]*# ]] && continue
                [[ -z "${pattern}" ]] && continue
                pattern="$(echo "${pattern}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
                echo -e "     * ${pattern}"
            done < "${file}"
            echo ""
        done
        return 0
    fi
}

# Controlla se un path deve essere ignorato in base al .gitignore più vicino
# Usage:
#   $ should_ignore <path_to_check> <current_dir>
function should_ignore() {
    local path_to_check="$1"
    local current_dir="$2"
    local gitignore_file=""
    local relative_path=""
    
    # Controlla se il path contiene una cartella .git
    if [[ "${path_to_check}" =~ /\.git(/|$) ]]; then
        if [ "${VERBOSE}" = "true" ]; then
            echo -e "${INFO} Ignoring ${path_to_check} (Git directory)" >&2
        fi
        return 0
    fi
    
    # Trova il .gitignore più vicino risalendo la struttura delle directory
    local dir="${current_dir}"
    while [[ -n "${dir}" && "${dir}" != "/" ]]; do
        if [[ -f "${dir}/.gitignore" ]]; then
            gitignore_file="${dir}/.gitignore"
            relative_path="$(get_relative_path "${path_to_check}" "${dir}")"
            break
        fi
        dir="$(dirname "${dir}")"
    done
    
    # Se non è stato trovato alcun .gitignore, non ignorare il file
    if [[ -z "${gitignore_file}" ]]; then
        return 1
    fi
    
    # Legge il .gitignore ed elabora ogni pattern
    while IFS= read -r pattern || [[ -n "${pattern}" ]]; do
        # Ignora commenti e linee vuote
        [[ "${pattern}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pattern}" ]] && continue
        
        # Rimuove spazi iniziali e finali
        pattern="$(echo "${pattern}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        
        # Converte il pattern in una regex
        local regex_pattern="${pattern}"
        regex_pattern="$(echo "${regex_pattern}" | sed 's/\./\\./g')"  # Escape dei punti
        regex_pattern="$(echo "${regex_pattern}" | sed 's/\*/.*/g')"   # * diventa .*
        regex_pattern="$(echo "${regex_pattern}" | sed 's/\?/./g')"    # ? diventa .
        
        # Se il pattern inizia con /, rimuovilo per il matching relativo
        regex_pattern="$(echo "${regex_pattern}" | sed 's/^\///')"
        
        # Verifica se il path corrisponde al pattern
        if [[ "${relative_path}" =~ ^${regex_pattern}(/|$) ]]; then
            if [ "${VERBOSE}" = "true" ]; then
                echo -e "${INFO} Ignoring ${path_to_check} due to pattern ${pattern} in ${gitignore_file}" >&2
            fi
            return 0
        fi
    done < "${gitignore_file}"
    
    return 1
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

