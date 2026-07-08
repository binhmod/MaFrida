#!/system/bin/sh


prepare_logging() {

    [ ! -d $MODPATH/logs ] && mkdir -p $MODPATH/logs

    exec 2> $MODPATH/logs/customize.log
    set -x

}

check_device_arch() {

    case $ARCH in
      arm64)
        ;;
      arm)
        ;;
      x64)
        ;;
      x86)
        ;;
      *)
        ui_print "Unsupported architecture: $ARCH";
        abort;;  
    esac

    ui_print "- Detected architecture: $ARCH"

}


prepare_busybox() {

    ui_print "- preparing busybox..."

    ui_print "- Extracting system files..."
    unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH"

}


prepare_config() {

  CONFIG_DIR="$MODPATH/.config"
  CONFIG_FILE="$CONFIG_DIR/config"

  ui_print "- preparing config file..."

  # make sure that the dir and file does not exists before creating
  if [ -d "$CONFIG_FILE" ]; then
    ui_print "- old configuration directory found."
    ui_print "- removing..."
    rm -rf "$CONFIG_DIR"
  fi;

  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"

  cat > "$CONFIG_FILE" << EOF
SERVER_PORT=27042
START_ON_BOOT=false
FRIDA_VERSION=latest
FRIDA_SERVER_FILENAME=shiny-egg
EOF


}



prepare_logging
check_device_arch
prepare_busybox
prepare_config


ui_print "- Install complete"
ui_print "- Reboot your device to complete your installation!"


