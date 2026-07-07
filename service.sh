#!/system/bin/sh


MODPATH=${0%/*}

# logging
exec 2> $MODPATH/logs/service.log
set -x


. $MODPATH/common.sh

sleep 20 # sleep for 20 second, to warm up the device
init_download_dir
init_frida_server

start_on_boot=$(get_config START_ON_BOOT false)
if [ "$start_on_boot" == "false" ]; then
    echo "- Frida server auto-start is disabled!"
    exit 1;
elif [ "$start_on_boot" == "true" ]; then
        run_frida
else
    echo "- Unknown option '$start_on_boot'"
fi;
