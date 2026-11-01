#!/bin/zsh
set -e

VOL="/Volumes/M3"
if [[ ! -d "$VOL" ]]; then
  echo "Error: SD card volume '$VOL' is not mounted."
  echo "Please insert the SD card into your Mac and wait a second for it to mount."
  exit 1
fi

DEV=$(diskutil info "$VOL" | awk -F': *' '/Device Node:/{print $2}')
FS=$(diskutil info "$VOL" | awk -F': *' '/File System Personality:/{print $2}')
REMOVABLE=$(diskutil info "$VOL" | awk -F': *' '/Removable Media:/{print $2}')
RDEV="${DEV/disk/rdisk}"

echo "Found SD Card: $DEV ($RDEV) | Filesystem: $FS | Removable: $REMOVABLE"

if [[ "$REMOVABLE" != "Removable" ]]; then
  echo "Safety stop: Target device is not marked Removable!"
  exit 1
fi

case "$FS" in
  *FAT32*) OFFSET=480; SIG_OFF=82 ;;
  *FAT16*) OFFSET=64;  SIG_OFF=54 ;;
  *) echo "Unsupported filesystem: $FS (must be FAT32 or FAT16)"; exit 1 ;;
esac

echo ""
echo "Please enter your Mac password to grant disk access:"
sudo -v

# Clean up any leftover temporary files as root so permission denied never happens
sudo rm -f /tmp/m3_bootsector.bin /tmp/m3_verify.bin

echo ""
echo "1. Unmounting $VOL to access raw device..."
diskutil unmount "$VOL"

echo "2. Reading first sector (512 bytes) from $RDEV..."
sudo dd if="$RDEV" of=/tmp/m3_bootsector.bin bs=512 count=1 2>/dev/null

# Backup original sector to user home
cp /tmp/m3_bootsector.bin "$HOME/m3_bootsector_backup.bin"
echo "   Backup saved to ~/m3_bootsector_backup.bin"

# Patch the sector with BOOTDISK at offset 480
sudo python3 -c "
with open('/tmp/m3_bootsector.bin', 'r+b') as f:
    f.seek($OFFSET)
    f.write(b'BOOTDISK')
"

echo "3. Writing patched boot sector back to $RDEV..."
sudo dd if=/tmp/m3_bootsector.bin of="$RDEV" bs=512 count=1 conv=notrunc 2>/dev/null

echo "4. Verifying BOOTDISK on physical SD card..."
sudo dd if="$RDEV" of=/tmp/m3_verify.bin bs=512 count=1 2>/dev/null

VERIFY_STR=$(python3 -c "
with open('/tmp/m3_verify.bin', 'rb') as f:
    f.seek($OFFSET)
    print(f.read(8).decode('ascii', errors='ignore'))
")

if [[ "$VERIFY_STR" == "BOOTDISK" ]]; then
  echo ""
  echo "=========================================================="
  echo "✅ SUCCESS: 'BOOTDISK' is verified on the SD card at byte $OFFSET!"
  echo "=========================================================="
  diskutil eject "$DEV"
  echo "Card safely ejected."
  echo "Now slide the SD card lock switch DOWN to LOCK and insert into EOS M3!"
else
  echo "❌ Verification failed: found '$VERIFY_STR' instead of 'BOOTDISK'."
  exit 1
fi
