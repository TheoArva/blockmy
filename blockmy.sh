#!/bin/bash

# Exporting variables to Shell required for Camera block/unblock configuration
CamVendorID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 1)
CamProductID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 2)
CamRulesFile=$(grep -RE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/ | cut -d ':' -f 1)

# Exporting variables to Shell required for USB Storage Devices block/unblock configuration
DevName=$(lsblk -o name,mountpoint,tran | grep -E "(usb)" | grep -E "(\bsd[a-zA-Z]+\b)" | awk '{print $1}')
DevNameNo=$(lsblk -o name,mountpoint,tran | grep -E "(\bsd[a-zA-Z]+[0-9]+\b)" | grep -E "(/[a-zA-Z]+/[a-zA-Z0-9\s.-]+/[a-zA-Z0-9\s.-]+)" | awk '{print $1}' | sed 's/^[^a-zA-Z0-9]*//')
CustomBlacklistFilePath="/etc/modprobe.d/custom-blacklist.conf"

## START-of-Camera block/unblock configuration

CameraBlockOn() {
	
	if lsusb | grep -iE "camera|uvc|webcam" &> /dev/null
	then
		if grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\")" $CamRulesFile &> /dev/null
		then
			sudo sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|" "$CamRulesFile" &> /dev/null;
			printf "$CamRulesFile updated successfully...\n";
			sudo udevadm control --reload && sudo udevadm trigger;
			printf "udev daemon reloaded and triggered, successfully...\n";
			printf "Camera blocked, successfully...\n";
		elif grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\")" $CamRulesFile &> /dev/null
		then
			printf "Camera is already blocked...\n";
		elif ! grep -RE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/ &> /dev/null
		then
			printf "ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"\n" | sudo tee /etc/udev/rules.d/99-disable-integrated-webcam.rules &> /dev/null;
			printf "Custom camera rule file '/etc/udev/rules.d/99-disable-integrated-webcam.rules' created, successfully...\n"
			sudo udevadm control --reload && sudo udevadm trigger;
			printf "udev daemon reloaded and triggered, successfully...\n";
			printf "Camera blocked, successfully...\n"
		fi
	else
		printf "No cameras found to block...\n"
		exit 1
	fi
	
}

CameraBlockOff() {

	if lsusb | grep -iE "camera|uvc|webcam" &> /dev/null
	then
		if grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\")" $CamRulesFile &> /dev/null
		then
			sudo sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|" "$CamRulesFile" &> /dev/null;
			printf "$CamRulesFile updated successfully...\n";
			sudo udevadm control --reload && sudo udevadm trigger;
			printf "udev daemon reloaded and triggered, successfully...\n";
			printf "Camera UN-blocked, successfully...\n";
		elif grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\")" $CamRulesFile &> /dev/null
		then
			printf "Camera is already UN-blocked...\n";
		elif ! grep -RE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/&> /dev/null
		then
			printf "No rules blocking the camera found...\n"
		fi
	else
		printf "No cameras found to UN-block...\n"
		exit 1
	fi

}

CameraStatus() {

	if lsusb | grep -iE "camera|uvc|webcam" &> /dev/null
	then
		if grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\")" $CamRulesFile &> /dev/null
		then
			printf "Camera is UN-blocked...\n";
		elif grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\")" $CamRulesFile&> /dev/null
		then
			printf "Camera is blocked...\n";
		elif ! grep -RE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/ &> /dev/null
		then
			printf "No device rules blocking/unblocking the camera found...\n"
		fi
	else
		printf "No cameras found...\n"
		exit 1
	fi

}

## END-of-Camera block/unblock configuration


### START-of-Storage-Devices block/unblock configuration

mute_install_n_remove_configs() {

	local actions=("install" "remove")
	local modules=("$@")

	for action in "${actions[@]}"
	do
		for module in "${modules[@]}"
		do
			while IFS= read -r file
			do
				if sudo sed -i -E "s/(\s)*$action\s*$module/#$action $module/gI" "$file"
				then
					printf "%s found and muted.\n" "$file"
					printf "%s found and muted.\nNecessary to maintain system stability with 'blockmy'.\n" "$file"
				fi
			done < <(grep -ilE "^(\s*$action\s*$module\s*)" /etc/modprobe.d/*.conf | sort -u)
		done
	done

}

mute_other_possible_blacklist_usb_rules() {

	local modules=("$@")

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sudo sed -i -E "s/(\s)*blacklist\s*$module/#blacklist $module/gI" "$file"
		done < <(grep -ilE "^(\s*blacklist\s*$module\s*)" /etc/modprobe.d/*.conf --exclude="$CustomBlacklistFilePath" | sort -u)
	done

}

usb_storage_block_on() {

	local modules=("uas" "usb_storage")

	if [[ -z "$DevName" ]]
	then
		printf "No USB storage devices found. Nothing to do.\n";
	else
		while IFS= read -r file
		do
			if sudo umount /dev/$file
			then
				printf "Unmounted %s successfully.\n" "$file"
			else
				printf "Problem unmounting USB storage device %s.\nExiting...\n" "$file";
				exit 1
			fi
		done <<< "$DevNameNo"
			while IFS= read -r file
			do
				if udisksctl power-off -b /dev/$file
				then
					printf "Powered off USB storage device %s successfully.\n" "$file"
				else
					printf "Problem powering off USB storage device %s.\nExiting...\n" "$file";
					exit 1
				fi
			done <<< "$DevNameNo"
	fi

	mute_install_n_remove_configs "${modules[@]}"

	if [[ ! -e $CustomBlacklistFilePath ]] && [[ ! -s $CustomBlacklistFilePath ]]
	then
		printf "#Block my USB Storage Devices\nblacklist uas\nblacklist usb_storage\n" | sudo tee -a $CustomBlacklistFilePath &> /dev/null
	fi

	mute_other_possible_blacklist_usb_rules "${modules[@]}"

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sudo sed -i -E "s/(#)+(\s)*blacklist\s*$module\s*/blacklist $module/gI" "$file"
		done < <(grep -ilE "(blacklist\s*$module)" $CustomBlacklistFilePath)
	done

	if lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		for module in "${modules[@]}"
		do
    			if sudo modprobe -r "$module" &> /dev/null
    			then
        			printf "%s unloaded successfully.\n" "$module"
    			elif lsmod | grep -E "\b($module)\b" &> /dev/null
    			then
        			printf "Failed to unload %s (still in use).\n" "$module"
        			exit 1
    			else
        			printf "%s was not loaded.\n" "$module"
    			fi
		done
	else
		printf "No kernel modules found running about USB Storage devices.\n"
	fi
}

usb_storage_block_off() {

	local modules=("uas" "usb_storage")

	if ! lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		for module in uas usb_storage
		do
    			if sudo modprobe "$module" &> /dev/null
    			then
        			printf "%s loaded successfully.\n" "$module"
    			elif ! lsmod | grep -E "\b($module)\b" &> /dev/null
    			then
        			printf "Failed to load %s.\n" "$module"
        			exit 1
    			else
        			printf "%s was already loaded.\n" "$module"
    			fi
		done
	else
		printf "Modules about USB Storage devices already running.\n"
	fi

	mute_other_possible_blacklist_usb_rules "${modules[@]}"

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sudo sed -i -E "s/(\s)*(#)+(\s)*blacklist\s*$module\s*/#blacklist $module/gI" "$file"
		done < <(grep -ilE "((#)+\s*blacklist\s*$module)" $CustomBlacklistFilePath)
	done

}

usb_storage_status() {

local module

local module_block

	if lsmod | grep -E "\b(uas)\b" &> /dev/null
	then
  module="loaded"
 elif ! lsmod | grep -E "\b(uas)\b" &> /dev/null
 then
  module="unloaded"
 fi

	if grep -E "^((\s)*(#)+(\s)*blacklist(\s)*uas(\s)*)$" /etc/modprobe.d/*.conf &> /dev/null
	 then
		 module_block="unblocked"
 elif grep -E "^((\s)*blacklist(\s)*uas(\s)*)$" /etc/modprobe.d/*.conf &> /dev/null
 then
  module_block="blocked"
 else
  module_block="configless"
 fi

case "$module:$module_block" in
 loaded:blocked)
  printf "test1"
  ;;
 loaded:unblocked|loaded:configless)
  printf "test2"
  ;;
 unloaded:blocked)
  printf "test3"
  ;;
 unloaded:unblocked|unloaded:configless)
  print "test4"
  ;;
esac

		elif grep -E "^(blacklist\suas)$" $BlacklistFile &> /dev/null
		then
			printf "USB Storage devices are UN-blocked, but will NOT persist among boot times...\n"
		elif grep -RE "(\buas\b)" /etc/modprobe.d/ &> /dev/null
		then
			printf "USB Storage devices are UN-blocked, and will remain among boot times...\n"
		fi
	elif ! lsmod | grep -E "(\buas\b)" &> /dev/null
	then
		if grep -E "^(blacklist\suas)$" $BlacklistFile &> /dev/null
		then
			printf "USB Storage devices are blocked, and will remain among boot times...\n"
		elif grep -E "^(#blacklist\suas)$" $BlacklistFile &> /dev/null
		then
			printf "USB Storage devices are blocked, but will NOT persist among boot times...\n"
		elif grep -RE "(\buas\b)" /etc/modprobe.d/ &> /dev/null
		then
			printf "USB Storage devices are blocked, and will remain among boot times...\n"
		fi
	fi

}

### END-of-USB-Storage-Devices block/unblock configuration

#### START-of-OPTIONS-ARGS

if [[ $1 = "camera" ]] && [[ $2 = "-on" ]]
then
	CameraBlockOn
elif [[ $1 = "camera" ]] && [[ $2 = "-off" ]]
then
	CameraBlockOff
elif [[ $1 = "camera" ]] && [[ $2 = "--status" ]]
then
	CameraStatus
elif [[ $1 = "usbstor" ]] && [[ $2 = "-on" ]]
then
	usb_storage_block_ON
elif [[ $1 = "usbstor" ]] && [[ $2 = "-off" ]]
then
	usb_storage_block_off	
elif [[ $1 = "usbstor" ]] && [[ $2 = "--status" ]]
then
	usb_storage_status
elif [[ $1 =~ ^"--help"$ ]] || [[ $1 =~ ^"-h"$ ]]
then
	printf "Usage: blokmy [DEVICE]... [OPTION]...\n\nBlocks USB Storage and/or Camera\n\nDEVICE:\n \n   camera\n \n   usbstor\n\nOPTION:\n \n  -on\t block DEVICE\n \n  -off\t unblock DEVICE\n \n  --status\t DEVICE's current block status\n \n  -h, --help\t Show this message\n\ne.g.  blokmy camera -on,  blockmy usbstor --status\n\n"
else
	printf "\nIncorrect Syntax...\n\nblockmy -h, --help for info\n\n"
fi

#### END-of-OPTIONS-ARGS

# Remove all variables exported to Shell before exiting script
unset CamVendorID;
unset CamProductID;
unset CamRulesID;
unset DevName;
unset DevNameNo;


#!/bin/bash

CustomBlacklistFilePath="/etc/modprobe.d/custom-blacklist.conf"

# Function to mute specific module lines in modprobe config
MuteModuleConfigs() {
    local module=$1
    local action=$2  # install/remove/blacklist

    while IFS= read -r file; do
        if sudo sed -i -E "s/(#|\s)*$action\s*$module/#$action $module/gI" "$file"; then
            printf "%s lines in %s muted\n" "$action $module" "$file"
        fi
    done < <(grep -ilRE "($action\s*$module)" /etc/modprobe.d/)
}

# Function to mute all occurrences of uas and usb_storage except custom blacklist
MuteAllOtherBlacklists() {
    local modules=("uas" "usb_storage")
    for module in "${modules[@]}"; do
        while IFS= read -r file; do
            # Skip custom blacklist
            [[ "$file" == "$CustomBlacklistFilePath" ]] && continue
            if sudo sed -i -E "s/(#|\s)*blacklist\s*$module/#blacklist $module/gI" "$file"; then
                printf "blacklist %s muted in %s\n" "$module" "$file"
            fi
        done < <(grep -ilRE "(blacklist\s*$module)" /etc/modprobe.d/)
    done
}

# Update initramfs if needed
UpdateInitramfs() {
    if command -v update-initramfs &> /dev/null; then
        sudo update-initramfs -u
        printf "initramfs updated. A reboot may be required.\n"
    fi
}

# Ensure custom blacklist file exists and contains correct lines
EnsureCustomBlacklist() {
    local modules=("uas" "usb_storage")
    if [[ ! -e "$CustomBlacklistFilePath" || ! -s "$CustomBlacklistFilePath" ]]; then
        printf "# Block my USB-StorageDevices\n" | sudo tee "$CustomBlacklistFilePath" > /dev/null
    fi

    for module in "${modules[@]}"; do
        if ! grep -qE "^\s*blacklist\s*$module\s*$" "$CustomBlacklistFilePath"; then
            printf "blacklist %s\n" "$module" | sudo tee -a "$CustomBlacklistFilePath" > /dev/null
            printf "%s module added to custom blacklist\n" "$module"
        fi
    done
}

# === Main Execution ===

# Mute install/remove lines
#for action in install remove; do
#    for module in uas usb_storage; do
#        MuteModuleConfigs "$module" "$action"
#	done
#done

# Mute other blacklist lines
#MuteAllOtherBlacklists

# Update initramfs
#UpdateInitramfs

# Ensure custom blacklist file has correct content
#EnsureCustomBlacklist

#printf "Script completed. All uas & usb_storage configurations processed.\n"
