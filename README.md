# Binpatcher

## Description
Tool to patch patterns across a binary. 

## Table of Contents


<details>

<summary>How to use</summary>

* [`Make the binpatcher.sh script visible from everywhere`](#1-make-the-binpatchersh-script-be-visible-from-everywhere)
* [`Define the way you want to patch a binary`](#2-define-the-way-you-want-to-patch-a-binary)
* [`Indicate to binpatcher what your file configuration is`](#3-indicate-to-binpatcher-what-your-file-configuration-is)
* [`Patch a specific binary`](#4-patch-a-specific-binary)

</details>

<details>

<summary>Use case</summary>

* [`Frida gadget patcher`](#use-case)

</details>


## How to use
The patterns to be replaced and the patterns to be inserted can be defined as ASCII strings or as hexadecimal strings. All this is defined in a configuration file.

### 1. Make the `binpatcher.sh` script be visible from everywhere

Make sure that the `binpatcher/bin` path is in your `PATH` variable
    
   One way to do this is by adding the following line into your `~\.bashrc` or `~\.zshrc` file: 

```shell
   BINARY_PATCHER="/home/apps/binpatcher/bin" 
   PATH="$PATH":"${BINARY_PATCHER}"
   export PATH
```

<br>[⬆ top](#table-of-contents)

### 2. Define the way you want to patch a binary

Create a configuration file, defining which patterns are to be replaced by which patterns.

#### ASCII format

In the example below, binaries will be patched as follows:
* "this is" will be replaced by "it goes"
* "AN EXAMPLE" will be replaced by "FAR BETTER"
* "with strings" will be replaced by "LIKE THIS !!"

Note that the `config_format` variable is set to "str".

```
# ASCII STRINGS

list_items_to_replace=( "this is" "AN EXAMPLE" "with strings" )
list_items_to_insert=(  "it goes" "FAR BETTER" "LIKE THIS !!"  )

config_format="str" # str or hex
default_string_in_bin_name_to_replace="input" # pattern in binary name to be replaced if no output name is given
default_string_in_bin_name_to_insert="output" # name to insert in binary name if no output name is given

```

#### Hexadecimal format

In the example below, binaries will be patched as follows:
* "616263" will be replaced by "414243"
* "AABB" will be replaced by "0000"
* "7F7F7F00" will be replaced by "20202020"

Note that the `config_format` variable is set to "hex".

```
# ASCII STRINGS

list_items_to_replace=( "616263" "AABB" "7F7F7F00" )
list_items_to_insert=(  "414243" "0000" "20202020" )

config_format="hex" # str or hex
default_string_in_bin_name_to_replace="binary" # pattern in binary name to be replaced if no output name is given
default_string_in_bin_name_to_insert="_patched_binary" # name to insert in binary name if no output name is given

```

<br>[⬆ top](#table-of-contents)

### 3. Indicate to binpatcher what your file configuration is

Set in the `CONFIG_FILE` variable the path to the configuration file you want to use and export the variable:

```console
    $ export CONFIG_FILE="./config.sh"

```

<br>[⬆ top](#table-of-contents)

### 4. Patch a specific binary

For example: 

patch `raw_samples/mybinary.so` into `patched_samples/patched_binary.so`

```console
    $ binpatcher.sh raw_samples/mybinary.so patched_samples/patched_binary.so    
```

or: 

patch `samples/mybinary.so` into `samples/my_patched_binary.so`

```console
    $ binpatcher.sh samples/mybinary.so
```

Note that in this last case, the generated binary name is given by the `default_string_in_bin_name_to_replace` and `default_string_in_bin_name_to_insert` variables in the configuration file.

<br>[⬆ top](#table-of-contents)

## Use case

Patch the Frida gadget to make it harder to detect. See `examples\frida_gadget_patcher`.

```console
$ binpatcher.sh frida-gadget-16.1.4-android-arm64.so 


 __, _ _, _ __,  _, ___  _, _,_ __, __,
 |_) | |\ | |_) /_\  |  / ` |_| |_  |_)
 |_) | | \| |   | |  |  \ , | | |   | \
 ~   ~ ~  ~ ~   ~ ~  ~   ~  ~ ~ ~~~ ~ ~
                ~ .                   ´
                `   .   ardgeor , ´
                       .   
                            .
                            
                               ~


[+] Configuration loaded ['./config.sh']



input  : 'frida-gadget-16.1.4-android-arm64.so'
output : './flipa-gadget-16.1.4-android-arm64.so'

[*] Patching bytes '6672696461' --> '666C697061' ...
[*] Patching bytes '4652494441' --> '464C495041' ...
[*] Patching bytes '6167656E74' --> '67656E7465' ...
[*] Patching bytes '676D61696E' --> '67656E7465' ...
[*] Patching bytes '67756D2D6A732D6C6F6F70' --> '656E642D69742D68657265' ...
[+] Binary './flipa-gadget-16.1.4-android-arm64.so' generated!

All done!

```

Observe like the "agent" string has been replaced by "gente":

```
$ strings flipa-gadget-16.1.4-android-arm64.so | grep -c agent
0
$ strings flipa-gadget-16.1.4-android-arm64.so | grep -c gente
22
$ 
```

<br>[⬆ top](#table-of-contents)

