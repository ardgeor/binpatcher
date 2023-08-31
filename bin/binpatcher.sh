#!/bin/bash


[ ! -z "${CONFIG_FILE}" ] && [ -f "${CONFIG_FILE}" ] && . "${CONFIG_FILE}" || { echo "CONFIG_FILE variable not specified" && exit 1; }
# . ./config.sh
echo "[+] Configuration loaded"
cat "${CONFIG_FILE}"
echo -e "\n\n"

# ~~~~~~~~~~~~~~~~~~~~====== Description ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This script takes a pattern in string or hex format and will search for 
# it on a target binary, replacing it by the bytes/string indicated
#
# ~~~~~~~~~~~~~~~~~~~~~====== Functions ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function check_args() {
	
	if [ $# -lt 1 ]
	then		
		usage
	fi
	
	local input_path output_path
	input_path="${1}"
	output_path="${2}"

	if [ ! -f "${input_path}" ]
	then
		exit_with_error "/!\\ Input does not exist: \n\t'$input_path'"
	fi

	if [ "$output_path" = "" ]
	then
		# Place the out put in the same directory as the input, changing $default_string_in_bin_name_to_replace
		# into $default_string_in_bin_name_to_insert
		output_path="$(dirname $input_path)"		
		output_path="${output_path}/$(echo `basename $input_path` \
			| sed "s|${default_string_in_bin_name_to_replace}|${default_string_in_bin_name_to_insert}|g")"
	else
		output_dir=$(dirname $output_path)

		if [ ! -d "${output_dir}" ]
		then
			exit_with_error "Output directory does not exist: \n\t'$output_dir'"
		fi
	fi
	echo "$output_path"	
}


function usage() {
	echo -e "\n"
	cat "${BANNER_FILE}"
	echo -e "\n"
	echo -e "Usage: $(basename $0) <input-file-path> [<output-file-path>]"
	echo ""
	echo "Examples"
	echo "--------"
	echo "1/"
	echo -e "\t ./binpatcher.sh ../../../test/mybinary.so ../../../test/samples/patched_binary.so\n"
	echo -e "\t --> patches '../../../test/mybinary.so' into '../../../test/samples/patched_binary.so'\n"
	echo ""
	echo "2/"
	echo -e "\t ./binpatcher.sh ../../../test/mybinary.so\n"
	echo -e "\t --> patches '../../../test/mybinary.so' into '../../../test/my_patched_binary.so'"
	echo -e "\t assuming"
	echo -e "\t\t default_string_in_bin_name_to_replace=\"binary\""
	echo -e "\t and"
	echo -e "\t\t default_string_in_bin_name_to_insert=\"_patched_binary\""
	echo ""
	
	exit 0
}


function do_other_checks() {
	local length 
	
	# Check configuration lists size
	if [ ${#list_items_to_replace[@]} -ne ${#list_items_to_insert[@]} ]
	then
		exit_with_error "Pattern lists do not have the same length"
	fi

	length=${#list_items_to_replace[@]}

	# Check patterns length
	for i in $(eval echo {1..${length}})
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
	echo -e "/!\\ ${1}. Exiting..."
	exit 1
	# If called from a subshell this will not stop the script!
	# e.g.
	# 	fn () {
	#		# (...)
	#		if [ ... ]
	#		then
	#			exit_with_error	"error message"
	#		fi
	# 	}
	# 	var=$(fn a) 							# The script does not stop
	# 	var=$(fn a) || exit 1  					# The script stops, but no error message
	# 	var=$(fn a) || { echo $var; exit 1; }  	# Error message and then the script stops
}


function str2hexbytes() {
	echo "${1}" | xxd -p | sed "s/0a$//g" | tr '[[:lower:]]' '[[:upper:]]'
}


# ~~~~~~~~~~~~~~~~~~====== Global variables ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BANNER_FILE="./banner"
CONFIG_FORMATS=( "HEX" "STR" )

# ~~~~~~~~~~~~~~~~~~~~====== Start point ======~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo -e "\n"
cat "${BANNER_FILE}"
echo -e "\n"

# Checks on input
output_path="$(check_args $@)" || { echo ${output_path} && exit 1; }

input_path="${1}"

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
	
	# Patching binary...
	hexdump -ve '1/1 "%.2X"' dump | sed "s|$item_to_replace_hex|$item_to_insert_hex|g" | xxd -r -p > tmp
	cat tmp > dump
done

echo "output_path: $output_path"

cat dump > $output_path
chmod +x $output_path
rm dump tmp 2> /dev/null

echo -e "[*] Done"

exit 0
