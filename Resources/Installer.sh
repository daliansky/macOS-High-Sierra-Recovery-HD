#!/bin/bash
# macOS High Sierra Recovery HD
# Copyright (c) 2017, Chris1111 <leblond1111@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.

# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

if [[ $(mount | awk '$3 == "/Volumes/USB-RECOVERY" {print $3}') != "" ]]; then
 /usr/sbin/diskutil rename "/Volumes/USB-RECOVERY" "USB=RECOVERY"
fi

# Vars
apptitle="macOS High Sierra Recovery HD"
version="1.0"
# Set Icon directory and file 
iconfile="/System/Library/CoreServices/Installer.app/Contents/Resources/Installer.icns"



# Select Erase
response=$(osascript -e 'tell app "System Events" to display dialog "Select the USB volume you want to use.\n\nSelect Cancel for Quit" buttons {"Cancel","USB"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')

action=$(echo $response | cut -d ':' -f2)

# Exit if Canceled
if [ ! "$action" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
  exit 0
fi

### RESTORE : Select usbdisk location
if [ "$action" == "USB" ] ; then

  # Get input folder of usbdisk disk 
  usbdiskpath=`/usr/bin/osascript << EOT
    tell application "Finder"
        activate
        set folderpath to choose folder default location "/Volumes" with prompt "Select the USB volumes you want to use"
    end tell 
    return (posix path of folderpath) 
  EOT`

  # Cancel is user selects Cancel
  if [ ! "$usbdiskpath" ] ; then
    osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
    exit 0
  fi

  # Parse vars for dd
  inputfile=$imagepath

  # Check if Compressed from extension
  extension="${inputfile##*.}"
  if [ "$extension" == "gz" ] || [ "$extension" == "zip" ] || [ "$extension" == "xz" ]; then
    compression="Yes"
  else
    compression="No"
  fi

fi

# Parse usbdisk disk volume
usbdisk=$( echo $usbdiskpath | awk -F '\/Volumes\/' '{print $2}' | cut -d '/' -f1 )
disknum=$( diskutil list | grep "$usbdisk" | awk -F 'disk' '{print $2}' | cut -d 's' -f1 )
devdisk="/dev/disk$disknum"
# use rdisk for faster copy
devdiskr="/dev/rdisk$disknum"
# Get Drive size
drivesize=$( diskutil list | grep "disk$disknum" | grep "0\:" | cut -d "*" -f2 | awk '{print $1 " " $2}' )

# Set output option
if [ "$action" == "Backup" ] ; then
  inputfile=$devdiskr
  source="$drivesize $usbdisk (disk$disknum)"
  dest=$outputfile
  check=$dest
fi
if [ "$action" == "USB" ] ; then
  source=$inputfile
  dest="$drivesize $usbdisk (disk$disknum)"
  outputfile=$devdiskr
  check=$source
fi

# Confirmation Dialog
response=$(osascript -e 'tell app "System Events" to display dialog "Please confirm your choice and Select OK\n\nDestination: \n'"$dest"' \n\n\nNOTE: The volumes will be formatted and the data erased!" buttons {"Cancel", "OK"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'" ')
answer=$(echo $response | grep "OK")

# Cancel is user does not select OK
if [ ! "$answer" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
  exit 0
fi

# Unmount Volume
response=$(diskutil unmountDisk $devdisk)
answer=$(echo $response | grep "successful")

# Cancel if unable to unmount
if [ ! "$answer" ] ; then
  osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "Cannot Unmount '"$usbdisk"'"'
  exit 0
fi


# script Notifications
osascript -e 'display notification "Erasing" with title "USB Volume"  sound name "default"'

diskutil partitiondisk "$outputfile" 1 GPTFormat JHFS+ USB-RECOVERY 100% 

# script Notifications
osascript -e 'display notification "'"$drivesize"' Erasing Drive '$action' Completed " with title "'"$apptitle"'" subtitle " '"$fname"' "'

response=$(osascript -e 'tell app "System Events" to display dialog "'"$drivesize"' Erasing USB Volume Completed '"$fsize"' " buttons {"Contine ➤ Recovery HD"} default button 1 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'" ')

		
        #####################################################################

Sleep 2
# Select Install macOS
response=$(osascript -e 'tell app "System Events" to display dialog "Select Install macOS to choose your Install macOS High Sierra.app\n\nSelect Cancel for Quit" buttons {"Cancel","Install macOS"} default button 2 with title "'"$apptitle"' '"$version"'" with icon POSIX file "'"$iconfile"'"  ')

action=$(echo $response | cut -d ':' -f2)


# Get image file location
  imagepath=`/usr/bin/osascript << EOT
    tell application "Finder"
        activate
        set imagefilepath to choose file default location "/Applications" with prompt "Select your Install macOS High Sierra.app 
 "
    end tell 
    return (posix path of imagefilepath) 
  EOT`

  # Cancel is user selects Cancel
  if [ ! "$imagepath" ] ; then
    osascript -e 'display notification "Program closing" with title "'"$apptitle"'" subtitle "User cancelled"'
    exit 0
  fi

rsync -a --progress "$imagepath/Contents/SharedSupport/BaseSystem.chunklist" "/tmp/"

rsync -a --progress "$imagepath/Contents/SharedSupport/BaseSystem.dmg" "/tmp/"


rsync -a --progress "./Packages/CloverESPOSXImage.pkg" "/tmp/"

osascript -e 'tell app "System Events" to display dialog "
Please Be patient during the process!" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FinderIcon.icns" buttons {"OK"} default button 1 with title "macOS High Sierra Recovery HD"'
echo " "
echo "
Installer macOS High Sierra Recovery HD! 
Follow all steps.
Be patient! . . . "
echo "  "

if [ -d "${3}/$HOME/Desktop/OSX_Recovery.pkg" ]; then
	rm -rf "${3}/$HOME/Desktop/OSX_Recovery.pkg"
fi

osascript -e 'display notification "Starting" with title "macOS High Sierra Recovery HD"  sound name "default"'
echo "  "
echo "
Downloads macOS High Sierra RecoveryHDUpdate.dmg ⥤ .......  
***********************************************************  "

# Downloads RecoveryHDUpdate.dmg 
curl -L http://supportdownload.apple.com/download.info.apple.com/Apple_Support_Area/Apple_Software_Updates/Mac_OS_X/downloads/041-2768.20111012.cd14A/RecoveryHDUpdate.dmg -o /tmp/RecoveryHDUpdate.dmg
echo "  "
echo "Download macOS High Sierra RecoveryHDUpdate.dmg ⥤ Done! "
echo "***********************************************************  "
# Downloads CreateRecoveryPartition.pkg 
curl -L https://www.dropbox.com/s/v3pykiyxnwsxx0r/CreateRecoveryPartition.pkg.zip?dl=0 -o /tmp/CreateRecoveryPartition.pkg.zip
echo "  "
echo "Download CreateRecoveryPartition.pkg ⥤ Done! "
echo "***********************************************************  "
Sleep 2
# Extract CreateRecoveryPartition.pkg 
ditto -x -k --sequesterRsrc --rsrc /tmp/CreateRecoveryPartition.pkg.zip /tmp/
# Attach the dmg 
hdiutil attach /tmp/RecoveryHDUpdate.dmg -noverify -nobrowse
echo "  " 
echo "Attach macOS High Sierra RecoveryHDUpdate.dmg ⥤ Done! "  
echo "***********************************************************  "
echo "  " 
Sleep 2
# Extract
pkgutil --expand /Volumes/"Mac OS X Lion Recovery HD Update"/RecoveryHDUpdate.pkg /tmp/RecoveryUpdate
# CD
cd /tmp/RecoveryUpdate/RecoveryHDUpdate.pkg/Scripts/Tools/
echo "Extraction Resources ⥤ Done!  "
echo "***********************************************************  "
Sleep 2
# Copying
cp dmtest /tmp/CreateRecoveryPartition.pkg/Contents/Resources/
cp -rp /tmp/BaseSystem.dmg /tmp/CreateRecoveryPartition.pkg/Contents/Resources/
cp -rp /tmp/BaseSystem.chunklist /tmp/CreateRecoveryPartition.pkg/Contents/Resources/
echo "  "
Sleep 2
echo "Copying Resources ⥤ Done!  "
echo "***********************************************************  "
Sleep 2
# Unmount the dmg
hdiutil detach -force /Volumes/"Mac OS X Lion Recovery HD Update"
echo "  "
echo "Unmount dmg ⥤ Done!  "
echo "***********************************************************  "
echo "  "
Sleep 2
# Removing Files
rm -R /tmp/RecoveryUpdate 
rm -R /tmp/RecoveryHDUpdate.dmg
rm -R /tmp/CreateRecoveryPartition.pkg.zip
rm -R /tmp/BaseSystem.dmg
rm -R /tmp/BaseSystem.chunklist
echo "Remove tmp file ⥤ Done! "
echo "***********************************************************  "
echo "  "
Sleep 2
osascript -e 'tell app "System Events" to display dialog "Install CreateRecoveryPartition 
Volumes/ ➤ USB-RECOVERY 
approximate 2 Minutes" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FinderIcon.icns" buttons {"OK"} default button 1 with title "CreateRecoveryPartition"'
echo " "
echo " 
Install CreateRecoveryPartition ➤ Volumes/USB-RECOVERY 
approximate duration 2 Minutes . . . . 
############################## " 
Sleep 2

# run the pkg
osascript -e 'do shell script "installer -allowUntrusted -verboseR -pkg /tmp/CreateRecoveryPartition.pkg -target /Volumes/USB-RECOVERY" with administrator privileges'
echo "  "
echo "  "
osascript -e 'tell app "System Events" to display dialog "Install Clover EFI
Volumes/EFI ➤ USB-RECOVERY 
approximate duration 10 seconds" with icon file "System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:FinderIcon.icns" buttons {"OK"} default button 1 with title "Clover EFI Installer"'
echo " "
echo " 
Install Clover ➤ Volumes/USB-RECOVERY
approximate duration 10 seconds . . . . 
############################### " 


Sleep 1

# run the pkg
osascript -e 'do shell script "installer -allowUntrusted -verboseR -pkg /tmp/CloverESPOSXImage.pkg -target /Volumes/USB-RECOVERY" with administrator privileges'

# shell script Notifications
osascript -e 'display notification "Completed" with title "macOS High Sierra Recovery HD"  sound name "default"'

echo "  "
rm -R /tmp/CreateRecoveryPartition.pkg
rm -R /tmp/CloverESPOSXImage.pkg

echo "
Completed Done! "

