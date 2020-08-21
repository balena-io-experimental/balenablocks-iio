#!/bin/bash
# set -o errexit


I2CBUS=1
i2c_modules_addr=
modprobe_modules=
modules_path=/usr/src/app/output
additional_modules=

# Output usage and halt.
function usage() {
    cat <<EOUSAGE
usage: $0 [options]

options:
  --i2c-modules-addr  Space separated list of modules to enable and the respective i2c address.
  --bus="$I2CBUS"   The I2C bus.
  --modprobe-modules  Built-in modules to load.
  --modules-path="$modules_path"  Root path containing modules to load.
  --additional-modules  Space separated list of externally built modules to load from modules_path(Set to $modules_path). 
EOUSAGE
}
# Args handling
opts="$(getopt -o 'h?' --long 'i2c-modules-addr:,bus:,modprobe-modules:,modules-path:,additional-modules:' -- "$@" || { usage >&2 && exit 1; })"

eval set -- "$opts"




while true; do
    flag=$1
    shift
    case "$flag" in
        --i2c-modules-addr) i2c_modules_addr="$1" && shift ;;
		--bus) I2CBUS="$1" && shift ;;
		--modprobe-modules) modprobe_modules="$1" && shift ;;
		--modules-path) modules_path="$1" && shift ;;
		--additional-modules) additional_modules="$1" && shift ;;
        --) break ;;
        *)
            {
                echo "error: unknown flag: $flag"
                usage
            } >&2
            exit 1
            ;;
    esac
done


OS_VERSION=$(echo "$BALENA_HOST_OS_VERSION" | cut -d " " -f 2)
echo "OS Version is $OS_VERSION"

# Remove existing devices if they are present.
for dev_addr in $i2c_modules_addr;do
	readarray -d : -t dev_addr_arr <<< $dev_addr	
	echo ${dev_addr_arr[1]} > /sys/bus/i2c/devices/i2c-$I2CBUS/delete_device
done

depmod -a
modprobe crc8
modprobe industrialio

# load built in  modules
if [[ -n $modprobe_modules ]]; then
	echo "Enabling built-in modules"
	for mod in $modprobe_modules;do
		modprobe $mod
	done
fi


# load modules built externally, 
if [[ -n $additional_modules ]]; then
    cd $modules_path
    modules=$(find . -print | grep -i '.*[.]ko$')
    for module in $modules;do
        filename=$(basename $module .ko)
        # only load listed modules
        if echo $additional_modules | grep -iqF $filename; then
            echo Loading module from "$filename"
            insmod $module
            lsmod | grep $filename
        fi
    done
fi


# enable the iio i2c sensors
for dev_addr in $i2c_modules_addr;do
	readarray -d : -t dev_addr_arr <<< $dev_addr
	module_name=$(echo ${dev_addr_arr[0]} | tr '[:upper:]' '[:lower:]')
	echo $module_name ${dev_addr_arr[1]} > /sys/bus/i2c/devices/i2c-$I2CBUS/new_device
done

echo "Starting server"
python3 /usr/src/app/server.py

balena-idle