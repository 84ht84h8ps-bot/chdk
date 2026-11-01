#!/bin/zsh
# ==============================================================================
# Canon EOS M3 — macOS CHDK SD Card Installer & Boot Sector Preparer
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILDS_DIR="$SCRIPT_DIR/builds"

echo "========================================================"
echo "  Canon EOS M3 — CHDK + Scripts SD Card Installer (Mac)"
echo "========================================================"
echo ""
echo "1) Check Firmware Version of a Photo (JPG / CR2)"
echo "2) Install CHDK + All 4 Scripts to SD Card"
echo "3) Quit"
echo ""
read "CHOICE?Select an option (1-3): "

if [[ "$CHOICE" == "1" ]]; then
    read "PHOTO_PATH?Drag and drop a JPG or CR2 photo from your EOS M3 here and press Enter: "
    # Strip quotes if dragged from Finder
    PHOTO_PATH="${PHOTO_PATH//\'/}"
    PHOTO_PATH="${PHOTO_PATH//\"/}"
    PHOTO_PATH="${PHOTO_PATH//\\ / }"
    echo ""
    echo "Scanning photo metadata for Canon Firmware Version..."
    strings "$PHOTO_PATH" | grep -E -i "Firmware Version|1\.01|1\.20|1\.21|GM1\." | head -n 10 || echo "Could not auto-detect from strings. Check Canon Menu -> Wrench Tab 4 -> Firmware Ver."
    exit 0
fi

if [[ "$CHOICE" != "2" ]]; then
    exit 0
fi

echo ""
echo "Select your Canon EOS M3 Firmware Version:"
echo "  a) 1.01A  (m3-101a-1.7.0-6358-full_BETA.zip)"
echo "  b) 1.20F  (m3-120f-1.7.0-6358-full_BETA.zip)  <-- Recommended! (Includes Canon 1.1.0 -> 1.2.0 official updater)"
echo "  c) 1.21A  (m3-121a-1.7.0-6358-full_ALPHA.zip)"
echo "  u) Currently on 1.1.0 -> Install Official Canon 1.2.0 Update + CHDK 1.20F together!"
read "FW_CHOICE?Enter a, b, c, or u: "

INCLUDE_CANON_120=0
case "$FW_CHOICE" in
    a|A|101a|1.01a) ZIP_FILE="$BUILDS_DIR/m3-101a-1.7.0-6358-full_BETA.zip" ;;
    b|B|120f|1.20f) ZIP_FILE="$BUILDS_DIR/m3-120f-1.7.0-6358-full_BETA.zip" ;;
    c|C|121a|1.21a) ZIP_FILE="$BUILDS_DIR/m3-121a-1.7.0-6358-full_ALPHA.zip" ;;
    u|U|110|1.1.0)
        ZIP_FILE="$BUILDS_DIR/m3-120f-1.7.0-6358-full_BETA.zip"
        INCLUDE_CANON_120=1
        ;;
    *) echo "Invalid selection."; exit 1 ;;
esac

echo ""
echo "Available external volumes under /Volumes:"
ls -1 /Volumes
echo ""
read "SD_NAME?Enter the exact name of your SD card volume (e.g. EOS_DIGITAL or CANON_DC): "
SD_PATH="/Volumes/$SD_NAME"

if [[ ! -d "$SD_PATH" ]]; then
    echo "Error: $SD_PATH does not exist. Make sure your SD card is mounted."
    exit 1
fi

# Find device node and filesystem type
DISK_INFO=$(df "$SD_PATH" | tail -n 1 | awk '{print $1}')
FS_TYPE=$(diskutil info "$SD_PATH" | grep -i "Type (Bundle):" | awk -F': *' '{print $2}')
FILE_SYS=$(diskutil info "$SD_PATH" | grep -i "File System Personality:" | awk -F': *' '{print $2}')

echo ""
echo "Target SD Card : $SD_PATH ($DISK_INFO)"
echo "File System    : $FILE_SYS"
echo "CHDK Package   : $(basename "$ZIP_FILE")"
echo ""

if [[ "$FILE_SYS" == *"ExFAT"* || "$FILE_SYS" == *"exFAT"* ]]; then
    echo "WARNING: Your SD card is formatted as exFAT!"
    echo "The Canon EOS M3 can ONLY boot CHDK from FAT32 or FAT16."
    echo "Please format the card as MS-DOS (FAT32) in Disk Utility first, then re-run this script."
    exit 1
fi

echo "1/4 Extracting CHDK to $SD_PATH ..."
unzip -oq "$ZIP_FILE" -d "$SD_PATH"

if [[ "$INCLUDE_CANON_120" == "1" ]]; then
    echo "    -> Also copying official Canon Firmware 1.2.0 updater (M3_120.FI2) to root of SD card..."
    cp "$BUILDS_DIR/canon_fw_120/eosm3-v120-win/M3_120.FI2" "$SD_PATH/M3_120.FI2"
fi

echo "2/4 Copying your 4 custom Lua scripts to $SD_PATH/CHDK/SCRIPTS/ ..."
mkdir -p "$SD_PATH/CHDK/SCRIPTS"
cp "$SCRIPT_DIR/astro_interval.lua" "$SD_PATH/CHDK/SCRIPTS/"
cp "$SCRIPT_DIR/bracket5_opt.lua" "$SD_PATH/CHDK/SCRIPTS/"
cp "$SCRIPT_DIR/pano_helper.lua" "$SD_PATH/CHDK/SCRIPTS/"
cp "$SCRIPT_DIR/focus_stack.lua" "$SD_PATH/CHDK/SCRIPTS/"

echo "3/4 Cleaning macOS hidden resource files (._*) ..."
dot_clean -m "$SD_PATH" 2>/dev/null || true

echo "4/4 Writing 'BOOTDISK' signature to SD card boot sector ($DISK_INFO)..."
echo "    (macOS will ask for your password to write the boot sector flag)"
diskutil unmount "$SD_PATH"

if [[ "$FILE_SYS" == *"FAT16"* ]]; then
    # Offset 0x40 (64 decimal) for FAT16
    printf "BOOTDISK" | sudo dd of="$DISK_INFO" bs=1 seek=64 count=8 conv=notrunc
else
    # Offset 0x1E0 (480 decimal) for FAT32
    printf "BOOTDISK" | sudo dd of="$DISK_INFO" bs=1 seek=480 count=8 conv=notrunc
fi

diskutil eject "$DISK_INFO"
echo ""
echo "=================================================================="
echo "SUCCESS! Your SD card is now CHDK-bootable and safely ejected."
echo "NEXT STEP: Slide the physical switch on the SD card to LOCK,"
echo "           insert it into your EOS M3, and power it on!"
echo "           (Press the M-Fn button on your EOS M3 for <ALT> mode)"
echo "=================================================================="
