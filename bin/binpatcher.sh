#!/bin/bash


[ ! -z "${CONFIG_FILE}" ] && [ -f "${CONFIG_FILE}" ] && . "${CONFIG_FILE}" || { echo "CONFIG_FILE variable not specified or file does not exist" && exit 1; }


# ~~~~~~~~~~~~~~~~~~~~====== Version ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 1.0
# ~~~~~~~~~~~~~~~~~~~~====== Description ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This script takes a pattern in string or hex format and will search for 
# it on a target binary, replacing it by the bytes/string indicated
#
# ~~~~~~~~~~~~~~~~~~~~~====== Functions ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function check_args() {
		
	local i_path 
	i_path="${1}"
	local -n o_path="${2}" # nameref to variable "$2" 	

	if [ ! -f "${i_path}" ]
	then
		exit_with_error "/!\\ Input does not exist: \n\t'$i_path'"
	fi

	if [ "$o_path" = "" ]
	then
		# Place the out put in the same directory as the input, changing $default_string_in_bin_name_to_replace
		# into $default_string_in_bin_name_to_insert
		o_path="$(dirname $i_path)"		
		o_path="${o_path}/$(echo `basename $i_path` \
			| sed "s|${default_string_in_bin_name_to_replace}|${default_string_in_bin_name_to_insert}|g")"
	else
		output_dir=$(dirname $o_path)

		if [ ! -d "${output_dir}" ]
		then
			exit_with_error "Output directory does not exist: \n\t'$output_dir'"
		fi
	fi	
}


function usage() {	
	echo -e "\n"
	echo -e "Usage: $(basename $0) <input-file-path> [<output-file-path>]"
	echo ""
	echo "Examples"
	echo "--------"
	echo "1/"
	echo -e "\t \$ binpatcher.sh raw_samples/mybinary.so patched_samples/patched_binary.so\n"
	echo -e "\t --> patches 'raw_samples/mybinary.so' into 'patched_samples/patched_binary.so'\n"
	echo ""
	echo "2/"
	echo -e "\t \$ binpatcher.sh samples/mybinary.so\n"
	echo -e "\t --> patches 'samples/mybinary.so' into 'samples/my_patched_binary.so'"
	echo -e "\t assuming"
	echo -e "\t\t default_string_in_bin_name_to_replace=\"binary\""
	echo -e "\t and"
	echo -e "\t\t default_string_in_bin_name_to_insert=\"_patched_binary\""
	echo -e "\n\n"

	exit 0
}


function do_other_checks() {
	local length 
	local n
	
	# Check configuration lists size
	if [ ${#list_items_to_replace[@]} -ne ${#list_items_to_insert[@]} ]
	then
		exit_with_error "Pattern lists do not have the same length"
	fi

	length=${#list_items_to_replace[@]}
	let "n = $length - 1"

	# Check patterns length
	for i in $(eval echo {0..${n}})
	do		
		if [ ${#list_items_to_replace[$i]} -ne ${#list_items_to_insert[$i]} ]
		then
			exit_with_error "Patterns at index ${i} do not have the same length"
		fi
	done

	# Check configuration format
	a=$(echo ${CONFIG_FORMATS[*]} | grep -w -i -c "${config_format}")
	if [ $a -eq 0 ]
	then
		exit_with_error "Invalid configuration format : ${config_format}"
	fi
	
}


function exit_with_error() {
	echo -e "/!\\ ${1}. Exiting... \n"
	exit 1
}


function str2hexbytes() {
	echo "${1}" | xxd -p | sed "s/0a$//g" | tr '[[:lower:]]' '[[:upper:]]'
}


function check_hex_string() {
	local input
	input="${1}"
	local -n res="${2}" # nameref to variable "$2" 	
	
	# Check that the input does not contain any non-hex character, i.e. the input is supposed to be an hex string
	if [[ $input == *['!'ghijklmnopqrstuvzxyzGHIJKLMNOPQRSTUVWXYZ]* ]]
	then
		res="NOK"
	else 
		res="OK"
	fi
}


# ~~~~~~~~~~~~~~~~~~====== Global variables ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
BANNER_FILE="$(dirname ${0})/banner"
CONFIG_FORMATS=( "HEX" "STR" )

# ~~~~~~~~~~~~~~~~~~~~====== Start point ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo -e "\n"
cat "${BANNER_FILE}"
echo -e "\n\n"
echo "[+] Configuration loaded ['${CONFIG_FILE}']"
echo -e "\n\n"

if [ $# -lt 1 ]
then		
	usage
fi


input_path="${1}"
output_path="${2}"

check_args "${input_path}" output_path
 
echo -e "input  : '${input_path}'"
echo -e "output : '${output_path}'"

echo ""

do_other_checks

# Parsing binary
cat $input_path > dump
num_items=${#list_items_to_replace[@]}

for index in $(eval echo "{0..$((num_items -1))}")
do
	# if [ "${config_format}" = "STR" ] || [ "${config_format}" = "str" ]
	if [ $(echo "${config_format}" | grep -c -i "str") -gt 0 ]
	then
		# STR format
		# Getting patterns bytes in hexadecimal
		item_to_replace_str=${list_items_to_replace[$index]}
		item_to_insert_str=${list_items_to_insert[$index]}
		item_to_replace_hex=$(str2hexbytes "$item_to_replace_str")
		item_to_insert_hex=$(str2hexbytes "$item_to_insert_str")
		
		echo -e "[*] Patching strings '$item_to_replace_str'='$item_to_replace_hex' --> '$item_to_insert_hex'='$item_to_insert_str' ..."

	elif [ $(echo "${config_format}" | grep -c -i "hex") -gt 0 ]
	then
		# HEX format
		item_to_replace_str=""
		item_to_insert_str=""
		item_to_replace_hex=${list_items_to_replace[$index]}
		item_to_insert_hex=${list_items_to_insert[$index]}

		echo -e "[*] Patching bytes '$item_to_replace_hex' --> '$item_to_insert_hex' ..."
	else
		exit_with_error "Invalid configuration format : ${config_format}"
	fi

	# Check that ${item_to_replace_hex} and ${item_to_insert_hex} are hex strings
	hexcheck=""
	check_hex_string "${item_to_replace_hex}${item_to_insert_hex}" hexcheck

	if [ "${hexcheck}" = "NOK"  ] 
	then
		exit_with_error "Invalid hex string ['s|$item_to_replace_hex|$item_to_insert_hex|g']. \
		\n    If you intend to replace ascii strings, you probably forgot to set 'config_format' to 'str'.\
		\n    If you intend to replace hex patterns, revise the configuration file as they are not correct hexadecimal strings.\
		\n    \n"
	fi
	
	# Patching binary...
	hexdump -ve '1/1 "%.2X"' dump | sed "s|$item_to_replace_hex|$item_to_insert_hex|g" | xxd -r -p > tmp
	cat tmp > dump
done

echo "[+] Binary '${output_path}' generated!"

cat dump > $output_path
chmod +x $output_path
rm dump tmp 2> /dev/null

echo -e "\nAll done!"

exit 0
