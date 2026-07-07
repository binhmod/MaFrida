MODPATH=${0%/*}
BASE="https://github.com/frida/frida/releases"
BASE_API="https://api.github.com/repos/frida/frida/releases"
ARCH=$(getprop ro.product.cpu.abi | cut -d '-' -f1)
RETRY=10
CONFIG_DIR="$MODPATH/.config"
CONFIG_FILE="$CONFIG_DIR/config"


set_config() {

    local key="$1"
    local value="$2"


    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi;


}


get_config() {

    local key="$1"
    local default="$2"

    local value
    value=$(grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)

    echo "${value:-$default}"

}


set_config_to_default() {

    set_config SERVER_PORT 27042
    set_config START_ON_BOOT false
    set_config FRIDA_VERSION latest
    set_config FRIDA_SERVER_FILENAME shiny-egg

}


function get_frida_version() {

    frida_version=$(get_config FRIDA_VERSION latest)

    # make sure the version exists in the repo
    if [ "$frida_version" != "latest" ]; then
    
        tag_response=$(curl --retry $RETRY -k "$BASE_API/tags/$frida_version" | sed -n 's/.*"status": "\([^"]*\)".*/\1/p')
            
         # if the tag reponse is 404, default to latest
        if [ "$tag_response" == "404" ]; then
            frida_version="latest"
        else
            echo "$frida_version"
        fi;
    
    else
        echo $(curl --retry $RETRY -k "$BASE_API/latest" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')
    
    fi;



}


function init_download_dir() {

    frida_server_filename=$(get_config FRIDA_SERVER_FILENAME shiny-egg)

    if [ -d "$MODPATH/files/$frida_server_filename" ]; then
        echo "- '$frida_server_filename' directory exists, cleaning..."
        rm -f "$MODPATH/files/$frida_server_filename"
    else
        echo "- Creating 'files' directory"
        mkdir "$MODPATH/files"
    fi;

}


function init_frida_server() {

    frida_version=$(get_frida_version)
    server_file="frida-server-${frida_version}-android-${ARCH}"
    download_url="$BASE/download/${frida_version}/${server_file}.xz"
    frida_server_filename=$(get_config FRIDA_SERVER_FILENAME shiny-egg)


    if [ -f "$MODPATH/files/$frida_server_filename" ]; then

        # get downloaded frida server version
        current_server_version=$($MODPATH/files/$frida_server_filename --version | tr -d '[:space:]')

        if [ $current_server_version == $frida_version ]; then
            echo "- Server already downloaded!"
        else
            curl --retry $RETRY -L -k --progress-bar -o "$MODPATH/files/$frida_server_filename.xz" "$download_url"

            # extract
            xz -f -d "$MODPATH/files/$frida_server_filename.xz"
            
            # set exec permission
            chmod +x "$MODPATH/files/$frida_server_filename"
        
        fi;
    
    else
        curl --retry $RETRY -L -k --progress-bar -o "$MODPATH/files/$frida_server_filename.xz" "$download_url"
            
        # extract
        xz -f -d "$MODPATH/files/$frida_server_filename.xz"
            
        # set exec permission
        chmod +x "$MODPATH/files/$frida_server_filename"

    fi;

}


function rename_server_filename() {

    frida_server_filename=$(get_config FRIDA_SERVER_FILENAME shiny-egg)

    if [ -f "$MODPATH/files/$frida_server_filename" ]; then
        mv "$MODPATH/files/$frida_server_filename" "$MODPATH/files/$1"
    fi;

}



function run_frida() {

    frida_server_filename=$(get_config FRIDA_SERVER_FILENAME shiny-egg)
    port=$(get_config SERVER_PORT 27042)

    if pgrep -f "$frida_server_filename" > /dev/null; then
        pkill "$frida_server_filename"
        # second time is the charm ;)
        kill -9 $(pidof $frida_server_filename)
    fi;

    # start server
    nohup "$MODPATH/files/$frida_server_filename" --listen "127.0.0.1:$port"


}