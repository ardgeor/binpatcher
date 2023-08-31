# MODEL STRING

list_items_to_replace=( "this is" "AN EXAMPLE" "with strings" )
list_items_to_insert=(  "it goes" "FAR BETTER" "LIKE THIS !!"  )

config_format="str" # str or hex
default_string_in_bin_name_to_replace="input" # pattern in binary name to be replaced if no output name is given
default_string_in_bin_name_to_insert="output" # name to insert in binary name if no output name is given




# MODEL HEXADECIMAL
list_items_to_replace=( "616263" "AABB" "7F7F7F00" )
list_items_to_insert=(  "414243" "0000" "20202020" )

config_format="hex" # str or hex
default_string_in_bin_name_to_replace="binary" # pattern in binary name to be replaced if no output name is given
default_string_in_bin_name_to_insert="_patched_binary" # name to insert in binary name if no output name is given
