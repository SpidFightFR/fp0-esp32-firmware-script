#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

BACKUPBINFILE='esp32-flash-backup.bin'

cd "$(dirname "$0")"

function printHelp {
    echo -e "Usage: ./firmware-script.sh <option>\n"
    echo -e "Options possible:
        help: Prints this help message.
        backup: Backups the current state of the board's flash into ${BACKUPBINFILE}.
        restore: Flashes ${BACKUPBINFILE} back into the board's flash chip.
        update: Fetches and flashes the latest firmware into the board's flash chip."
}

if [[ $# -ne 1 ]]; then
    echo "Expected 1 argument, got $#";
    printHelp
    exit 1;
fi

# Checking deps
for CMD in curl wget uv jq; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Missing script dependency: $CMD" && exit 1;
    fi
done




function displayWarning {
    echo -e "${YELLOW}WARNING: This script needs to have the dev wifi board in Bootloader mode."
    echo -e "For that you will need to:
    1 - maintain the BOOT button on the board;
    2 - press the RESET button while holding the BOOT button;
    3 - then release everything."
    echo -e "${NC}Press enter when ready.";
    read choice
}

function getESP32ACMDevice {
    ESP32DEV=$(ls /dev/ttyACM* |sort -V |tail -n 1)
    echo -e "${BLUE}[LOG] - ESP32 Device is ${ESP32DEV}."
}

function backupCurrentFirmware {
    echo -e "${YELLOW}Backuping the current state of the chip.${NC}"
    uv run esptool --chip esp32s2 --port ${ESP32DEV} read-flash 0 ALL ${BACKUPBINFILE}
    echo -e "${GREEN}Backup finished.${NC}"
}



function restoreFirmwareFromBackup {
    echo -e "${YELLOW}Restoring chip memory from backup.${NC}"
    uv run esptool --chip esp32s2 --port ${ESP32DEV} write-flash 0x0 ${BACKUPBINFILE}
    echo -e "${GREEN}Restore finished.${NC}"
}


function flashLatestFirmware {
    echo -e "${YELLOW}Starting update.${NC}"
    LATESTRELURL="https://api.github.com/repos/justcallmekoko/ESP32Marauder/releases/latest"
    LATESTREL=$(curl -s ${LATESTRELURL} | jq -r '.tag_name')

    ITTERATION=0
    BINFILE=$(curl -s ${LATESTRELURL} | jq -r ".assets[${ITTERATION}].name")
    while grep -q "flipper" <<< ${BINFILE}; [ $? -eq 1 ]; do
        ITTERATION=$((${ITTERATION}+1))
        BINFILE=$(curl -s ${LATESTRELURL} | jq -r ".assets[${ITTERATION}].name")
    done

    echo -e "${BLUE}[LOG] - Found file ${BINFILE} with asset number ${ITTERATION}.${NC}"

    BINFILEURL="https://github.com/justcallmekoko/ESP32Marauder/releases/download/${LATESTREL}/${BINFILE}"
    wget "${BINFILEURL}" -O ${BINFILE}

    # Technically we only flash at address 0x10000, the application marauder.
    # So it's not flashing a whole firmware...
    # Oh well !
    uv run esptool --chip esp32s2 --port ${ESP32DEV} --baud 921600 write-flash 0x10000 ${BINFILE}
    echo -e "${GREEN}Finished updating app.${NC}"
}


case $1 in
    help)
        printHelp;
        ;;
    backup)
        displayWarning;
        getESP32ACMDevice;
        backupCurrentFirmware; #Systematic backup of current flash state - just in case
        ;;
    restore)
        displayWarning;
        getESP32ACMDevice;
        restoreFirmwareFromBackup;
        ;;
    update)
        displayWarning;
        getESP32ACMDevice;
        if [[ ! -f esp32-flash-backup.bin ]]; then
            echo -e "${YELLOW}Ain't no way i'm doing an update without a backup first.${NC}"
            backupCurrentFirmware; #Systematic backup of current flash state - just in case
            echo -e "${BLUE}Please restart your esp32 chip in bootloader mode before re-launching this command.${NC}"
        else
            flashLatestFirmware
        fi
        ;;
    *)
       echo -e "${RED}Invalid option \"$1\".${NC}\n"
       printHelp;
       exit 1;
       ;;
esac
