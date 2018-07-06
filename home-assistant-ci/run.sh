#!/bin/bash

####### config #######
CONFIG_PATH=/data/options.json
GITLAB_PRIVATE_TOKEN=$(jq --raw-output ".gitlab_private_token" $CONFIG_PATH)
VERSION_ENDPOINT=$(jq --raw-output ".version_endpoint" $CONFIG_PATH)
ARTIFACT_ENDPOINT=$(jq --raw-output ".artifact_endpoint" $CONFIG_PATH)
REPEAT_ACTIVE=$(jq --raw-output '.repeat.active' $CONFIG_PATH)
REPEAT_INTERVAL=$(jq --raw-output '.repeat.interval' $CONFIG_PATH)
CURRENT_VERSION_FILE="/config/version.txt"
LATEST_VERSION_FILE="/config/latest-version.txt"
CONFIG_ZIP_FILE="/tmp/config.zip"
######################

##### functions ######
function get-latest-version-number {
    curl --location --silent --show-error --fail --output "${LATEST_VERSION_FILE}" --header "Private-Token: ${GITLAB_PRIVATE_TOKEN}" "${VERSION_ENDPOINT}"
}

function compare-version-numbers {
    echo "[Info] Comparing versions"
    if ! [ -e "${LATEST_VERSION_FILE}" ]; then
        echo "[Error] No latest version.txt present"; exit 1
    fi
    
    if [ -e "${CURRENT_VERSION_FILE}" ]; then
        CURRENT=$(<version.txt)
        LATEST=$(<version.txt)
        if [ CURRENT -ne LATEST]; then
            echo "[Info] No difference in version"; exit 0
        fi
    else
        echo "[Info] No current version file"
    fi
}

function pull-latest-version {
    echo "[Info] Downloading latest version"
    curl --location --silent --show-error --fail --output "${CONFIG_ZIP_FILE}" --header "Private-Token: ${GITLAB_PRIVATE_TOKEN}" "${ARTIFACT_ENDPOINT}"
}

function extract-config {
    echo "[Info] Unzip configuration"
    unzip -o "${CONFIG_ZIP_FILE}" dist/* -d /config
}

function reload-config {
    echo "[Info] reload config"
    #hassio homeassistant restart 2&> /dev/null
}

######################

#### Main program ####
cd /config || { echo "[Error] Failed to cd into /config"; exit 1; }
while true; do
    get-latest-version-number
    compare-version-numbers
    pull-latest-version
    extract-config
    reload-config
    sleep "$REPEAT_INTERVAL"
done
######################
