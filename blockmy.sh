#!/bin/bash

# Global variables for Camera block/unblock configuration
CamVendorID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 1)
CamProductID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 2)
CamRulesFile="/etc/udev/rules.d/99-disable-integrated-webcam.rules"

# Global variables for USB Storage Devices block/unblock configuration
DevName=$(lsblk -o name,mountpoint,tran | grep -E "(usb)" | grep -E "\b(sd[a-zA-Z]+)\b" | awk '{print $1}')
DevNameNo=$(lsblk -o name,mountpoint,tran | grep -E "\b(sd[a-zA-Z]+[0-9]+)\b" | grep -E "(/[a-zA-Z]+/[a-zA-Z0-9\s.-]+/[a-zA-Z0-9\s.-]+)" | awk '{print $1}' | sed 's/^[^a-zA-Z0-9]*//')
CustomBlacklistFilePath="/etc/modprobe.d/custom-blacklist.conf"

## START-of-Camera block/unblock configuration

camera_main() {
	
	if lsusb | grep -iE "camera|uvc|webcam" &> /dev/null
	then
		usb_device="detected"
	else
		usb_device="undetected"
	fi

	if grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\")" $CamRulesFile &> /dev/null
	then
		custom_rule="on"
	elif grep -E "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\")" $CamRulesFile &> /dev/null
	then
		custom_rule="off"
	else
		custom_rule="configless"
	fi


	while IFS= read -r file
	do
		sudo sed -i "s|^.*ATTR{idVendor}==\"$CamVendorID\",\s*ATTR{idProduct}==\"$CamProductID\",\s*ATTR{authorized}=\"[0-9]\".*$|#ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|gI" "$file" &> /dev/null;
	done < <( grep -ilE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/*.rules &> /dev/null | sort -u)

}

camera_block_on() {

	camera_main

	case "$usb_device:$custom_rule" in
		detected:on)
			printf "Camera is already blocked.\n"
			;;
		detected:off)
			sudo sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|" "$CamRulesFile" &> /dev/null;
			sudo udevadm control --reload && sudo udevadm trigger
			printf "Camera blocked, successfully.\n"
			;;
		detected:configless)
			printf "ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"\n" | sudo tee /etc/udev/rules.d/99-disable-integrated-webcam.rules &> /dev/null
			sudo udevadm control --reload && sudo udevadm trigger
			printf "Camera blocked successfully.\n"
			;;
		undetected:on|undetected:off|undetected:configless)
			printf "No cameras found to block.\n"
			;;
	esac
	
}

camera_block_off() {

	camera_main

	case "$usb_device:$custom_rule" in
		detected:on)
			sudo sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|" "$CamRulesFile" &> /dev/null;
			sudo udevadm control --reload && sudo udevadm trigger
			printf "Camera unblocked successfully.\n"
			;;
		detected:off|detected:configless)
			printf "Camera is already NOT blocked.\n"
			;;
		undetected:on|undetected:off|undetected:configless)
			printf "No cameras found to block.\n"
			;;
	esac	

}

camera_status() {

	camera_main

	case "$usb_device:$custom_rule" in
		detected:on)
			printf "Camera is blocked.\n"
			;;
		detected:off|detected:configless)
			printf "Camera is NOT blocked.\n"
			;;
		undetected:on|undetected:off|undetected:configless)
			printf "No cameras found.\n"
	esac

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
				if sudo sed -i -E "s/^.*\b$action\s*$module\b.*$/#$action $module/gI" "$file"
				then
					printf "found %s file and muted any $action elements.\nNecessary to maintain system stability with 'blockmy'.\n" "$file"
				fi
			done < <(grep -ilE "^((\s)*$action(\s)*$module)" /etc/modprobe.d/*.conf | sort -u)
		done
	done

}

mute_other_possible_blacklist_usb_rules() {

	local modules=("$@")

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			if sudo sed -i -E "s/^.*\bblacklist\s*$module\b.*$/#blacklist $module/gI" "$file"
			then
				printf "file %s found and muted any blacklist $modules elements.\n"
			fi
		done < <(grep -ilE "^((\s)*blacklist(\s)*$module)" /etc/modprobe.d/*.conf --exclude="$CustomBlacklistFilePath" | sort -u)
	done

}

usb_storage_block_on() {

	local modules=("uas" "usb_storage")

	if [[ -z "$DevName" ]]
	then
		printf "No connected USB storage devices found.\n";
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
			sudo sed -i -E "s/(\s)*(#)+(\s)*blacklist(\s)*$module/blacklist $module/gI" "$file"  
		done < <(grep -ilE "^((\s)*(#)+(\s)*blacklist(\s)*$module)" $CustomBlacklistFilePath)
	done

	if lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		for module in "${modules[@]}"
		do
    			if sudo modprobe -r "$module" &> /dev/null
    			then
        			printf "%s module, unloaded successfully.\n" "$module"
    			elif lsmod | grep -E "\b($module)\b" &> /dev/null
    			then
        			printf "Failed to unload %s module (still in use).\n" "$module"
        			exit 1
    			else
        			printf "%s module was not loaded.\n" "$module"
    			fi
		done
	else
		printf "No running modules found about USB Storage Devices.\nUse --status to check usbstor block status.\n"
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


	mute_install_n_remove_configs "${modules[@]}"
	
	mute_other_possible_blacklist_usb_rules "${modules[@]}"
	

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sudo sed -i -E "s/^.*\bblacklist\s*$module\b.*$/#blacklist $module/gI" "$file"
		done < <(grep -ilE "^((\s)*blacklist(\s)*$module)" $CustomBlacklistFilePath)
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

	
	if grep -E "^((\s)*blacklist(\s)*uas)" /etc/modprobe.d/*.conf &> /dev/null
	then
		module_block="blocked"
	elif grep -E "^((\s)*(#)+(\s)*blacklist(\s)*uas)" /etc/modprobe.d/*.conf &> /dev/null
	then
		module_block="unblocked"
	else
		module_block="configless"
	fi


	case "$module:$module_block" in
		loaded:blocked)
			printf "USB Storage Devices are NOT blocked, but they will be blocked after system reboot.\n"
			;;
		loaded:unblocked|loaded:configless)
			printf "USB Storage Devices are NOT blocked, and they will remain unblocked after system reboot.\n"
			;;
		unloaded:blocked)
			printf "USB Storage devices are blocked, and will remain blocked after system reboot.\n"
			;;
		unloaded:unblocked|unloaded:configless)
			printf "USB Storage devices are blocked, but they will NOT be blocked after system reboot.\n"
			;;
	esac

}

### END-of-USB-Storage-Devices block/unblock configuration

#### START-of-OPTIONS-ARGS

case "$1:$2" in
	"camera:-on")
		camera_block_on
		;;
	"camera:-off")
		camera_block_off
		;;
	"camera:--status")
		camera_status
		;;
	"usbstor:-on")
		usb_storage_block_on
		;;
	"usbstor:-off")
		usb_storage_block_off
		;;
	"usbstor:--status")
		usb_storage_status
		;;
	"--help:"|"-h:")
		printf "Usage: blockmy [DEVICE]... [OPTION]...\n\nBlocks USB Storage and/or Camera\n\nDEVICE:\n \n   camera\n \n   usbstor\n\nOPTION:\n \n  -on\t block DEVICE\n \n  -off\t unblock DEVICE\n \n  --status\t DEVICE's current block status\n \n  -h, --help\t Show this message\n\ne.g.  blockmy camera -on,  blockmy usbstor --status\n\n"
		;;
	*)
		printf "\nIncorrect Syntax...\n\nblockmy -h, --help for info\n\n"
		;;
esac

#### END-of-OPTIONS-ARGS

# Remove all variables exported to Shell before exiting script
unset CamVendorID CamProductID CamRulesFile DevName DevNameNo custom_rule usb_device
