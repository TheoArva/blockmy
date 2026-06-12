#!/bin/bash

#blockmy (v1.0)
#Copyright (C) 2025 Theodoros Arvanitis (Author)
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/
#Email: theodorosarv@gmail.com

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

camera_main() { #1.Check for existing camera #2.Check for existing camera block/unblock configuration in /etc/udev/rules.d/
	
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
		sed -i "s|^.*ATTR{idVendor}==\"$CamVendorID\",\s*ATTR{idProduct}==\"$CamProductID\",\s*ATTR{authorized}=\"[0-9]\".*$|#ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|gI" "$file" &> /dev/null;
	done < <( grep -ilE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" --exclude="$CamRulesFile" /etc/udev/rules.d/*.rules 2> /dev/null | sort -u)

}

camera_block_on() { #block camera creating/modifying "/etc/udev/rules.d/99-disable-integrated-webcam.rules" file w/ custom rule

	camera_main

	case "$usb_device:$custom_rule" in
		detected:on)
			printf "Camera is already blocked.\n"
			;;
		detected:off)
			sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|" "$CamRulesFile" &> /dev/null;
			udevadm control --reload && udevadm trigger
			printf "Camera blocked, successfully.\n"
			;;
		detected:configless)
			printf "ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"\n" | tee /etc/udev/rules.d/99-disable-integrated-webcam.rules &> /dev/null
			udevadm control --reload && udevadm trigger
			printf "Camera blocked successfully.\n"
			;;
		undetected:on|undetected:off|undetected:configless)
			printf "No cameras found to block.\n"
			;;
	esac
	
}

camera_block_off() { #unblock camera modifying "/etc/udev/rules.d/99-disable-integrated-webcam.rules" file

	camera_main


	case "$usb_device:$custom_rule" in
		detected:on)
			sed -i "s|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"0\"|ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"1\"|" "$CamRulesFile" &> /dev/null;
			udevadm control --reload && udevadm trigger
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

camera_status() { #check camera block/unblock status

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

mute_install_n_remove_configs() { #comment out any existing install/remove uas/usb_storage configuration interfering

	local actions=("install" "remove")
	local modules=("$@")
	local check_InstallRemove_status=false


	for action in "${actions[@]}"
	do
		for module in "${modules[@]}"
		do
			while IFS= read -r file
			do
				if sed -i -E "s/^.*\b$action\s*$module\b.*$/#$action $module/gI" "$file"
				then
					printf "found %s file and muted any $action elements.Necessary to maintain system stability with 'blockmy'.\n" "$file"
					check_InstallRemove_status=true
				fi
			done < <(grep -ilE "^((\s)*$action(\s)*$module)" /etc/modprobe.d/*.conf | sort -u)
		done
	done


	if [[ $check_InstallRemove_status == true ]]
	then
		if which update-initramfs
		then
			update-initramfs -u
			printf "initramfs was updated to allow changes take effect.\nA system reboot may be required.\n"
		fi
	fi

}

mute_other_possible_blacklist_usb_rules() { #comment out any existing blacklist uas/usb_storage *.conf files interfering

	local modules=("$@")

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			if sed -i -E "s/^.*\bblacklist\s*$module\b.*$/#blacklist $module/gI" "$file"
			then
				printf "file %s found and muted any blacklist $module elements.\n" "$file"
			fi
		done < <(grep -ilE "^((\s)*blacklist(\s)*$module)" /etc/modprobe.d/*.conf --exclude="$CustomBlacklistFilePath" | sort -u)
	done

}

usb_storage_block_on() { #1. unmount connected ext storage #2. power it/them off #3. unload uas/usb_storage modules #4.create "/etc/modprobe.d/blacklist.conf" w/ custom block rules #4. mask gvfs & usbmuxd services for mobile phones

  

	local modules=("uas" "usb_storage")
	local gvfs_services=("gvfs-afc-volume-monitor.service" "gvfs-mtp-volume-monitor.service" "gvfs-gphoto2-volume-monitor.service")
	local system_services=("usbmuxd.service")
	local gvfs_processes=("gvfs-afc-volume-monitor" "gvfs-mtp-volume-monitor" "gvfs-gphoto2-volume-monitor" "gvfsd-afc" "gvfsd-mtp" "gvfsd-gphoto2")
	local check_block_status=false


	if [[ -z "$DevNameNo" ]]
	then
		check_block_status=false
	else
		while IFS= read -r file
		do
			if umount /dev/$file
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


	if [[ ! -e $CustomBlacklistFilePath ]] || [[ ! -s $CustomBlacklistFilePath ]]
	then
		printf "#Block my USB Storage Devices\nblacklist uas\nblacklist usb_storage\n" | tee -a $CustomBlacklistFilePath &> /dev/null
	fi


	mute_other_possible_blacklist_usb_rules "${modules[@]}"


	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sed -i -E "s/(\s)*(#)+(\s)*blacklist(\s)*$module/blacklist $module/gI" "$file"  
		done < <(grep -ilE "^((\s)*(#)+(\s)*blacklist(\s)*$module)" $CustomBlacklistFilePath)
	done


	for service in "${gvfs_services[@]}"
	do
		if systemctl --global mask "$service" &> /dev/null
		then
			printf "%s globally masked successfully.\n" "$service"
		else
			printf "Failed to globally mask %s.\n" "$service"
			exit 1
		fi
	done


	for service in "${system_services[@]}"
	do
		if systemctl mask --now "$service" &> /dev/null
		then
			printf "%s masked successfully.\n" "$service"
		else
			printf "Failed to mask %s.\n" "$service"
			exit 1
		fi
	done


	systemctl daemon-reload &> /dev/null

	if [[ -n "$SUDO_USER" ]]
	then
		runuser -u "$SUDO_USER" -- env XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" systemctl --user daemon-reload &> /dev/null
	fi

	for process in "${gvfs_processes[@]}"
	do
		if pgrep -f "$process" &> /dev/null
		then
			pkill -f "$process" &> /dev/null
			printf "%s process terminated successfully.\n" "$process"
		fi
	done


	if lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		for module in "${modules[@]}"
		do
    			if modprobe -r "$module" &> /dev/null
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
		check_block_status=true
	fi

	
	if [[ $check_block_status == true ]]
	then
		printf "USB Storage Devices are already blocked.\n"
	else
		printf "USB Storage Devices blocked successfully.\n"
	fi

}

usb_storage_block_off() { #1.load uas/usb_storage modules #2.modify "/etc/custom-blacklist.conf" file #3.unmask gvfs & usbmuxd services for mobile phones



	local modules=("uas" "usb_storage")
	local gvfs_services=("gvfs-afc-volume-monitor.service" "gvfs-mtp-volume-monitor.service" "gvfs-gphoto2-volume-monitor.service")
	local system_services=("usbmuxd.service")
	local check_unblock_status=false


	if ! lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		for module in uas usb_storage
		do
    			if modprobe "$module" &> /dev/null
    			then
        			printf "%s module loaded successfully.\n" "$module"
    			elif ! lsmod | grep -E "\b($module)\b" &> /dev/null
    			then
        			printf "Failed to load %s module.\n" "$module"
        			exit 1
    			else
        			printf "%s module was already loaded.\n" "$module"
    			fi
		done
	else
		check_unblock_status=true
	fi


	mute_install_n_remove_configs "${modules[@]}"
	
	mute_other_possible_blacklist_usb_rules "${modules[@]}"
	

	for module in "${modules[@]}"
	do
		while IFS= read -r file
		do
			sed -i -E "s/^.*\bblacklist\s*$module\b.*$/#blacklist $module/gI" "$file"
		done < <(grep -ilE "^((\s)*blacklist(\s)*$module)" $CustomBlacklistFilePath)
	done


	for service in "${gvfs_services[@]}"
	do
		if systemctl --global unmask "$service" &> /dev/null
		then
			printf "%s globally unmasked successfully.\n" "$service"
		else
			printf "Failed to globally unmask %s.\n" "$service"
			exit 1
		fi
	done


	for service in "${system_services[@]}"
	do
		if systemctl unmask "$service" &> /dev/null
		then
			printf "%s unmasked successfully.\n" "$service"
		else
			printf "Failed to unmask %s.\n" "$service"
			exit 1
		fi
	done


	systemctl daemon-reload &> /dev/null

	if [[ -n "$SUDO_USER" ]]
	then
		runuser -u "$SUDO_USER" -- env XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" systemctl --user daemon-reload &> /dev/null
	fi

	if [[ $check_unblock_status == true ]]
	then
		printf "USB Storage Devices are already unblocked.\n"
	else	
		printf "USB Storage Devices unblocked successfully.\n"
	fi

}

usb_storage_status() { #1.check for modules status #2.check for "/etc/modprobe.d/custom-blacklist.conf" file's content #3.check for gvfs & usbmuxd services for mobile phones

	local module
	local module_block
	local modules=("uas" "usb_storage")
	local gvfs_services=("gvfs-afc-volume-monitor.service" "gvfs-mtp-volume-monitor.service" "gvfs-gphoto2-volume-monitor.service")
	local system_services=("usbmuxd.service")
	local gvfs_block
	local system_service_block
	local check_module_status=true
	local check_module_block_status=true
	local check_module_unblock_status=false
	local check_gvfs_status=true
	local check_system_service_status=true

	for item in "${modules[@]}"
	do
		if lsmod | grep -E "\b($item)\b" &> /dev/null
		then
			check_module_status=false
			break
		fi
	done


	if [[ $check_module_status == true ]]
	then
 		module="unloaded"
	else
 		module="loaded"
	fi

	
	for item in "${modules[@]}"
	do
		if grep -E "^((\s)*blacklist(\s)*$item)" /etc/modprobe.d/*.conf &> /dev/null
		then
			check_module_block_status=true
		elif grep -E "^((\s)*(#)+(\s)*blacklist(\s)*$item)" /etc/modprobe.d/*.conf &> /dev/null
		then
			check_module_block_status=false
			check_module_unblock_status=true
			break
		else
			check_module_block_status=false
			break
		fi
	done

	if [[ $check_module_block_status == true ]]
	then
		module_block="blocked"
	elif [[ $check_module_unblock_status == true ]]
	then
		module_block="unblocked"
	else
		module_block="configless"
	fi

	for service in "${gvfs_services[@]}"
	do
		if [[ "$(systemctl --global is-enabled "$service" 2> /dev/null)" == "masked" ]]
		then
			check_gvfs_status=true
		else
			check_gvfs_status=false
			break
		fi
	done


	if [[ $check_gvfs_status == true ]]
	then
		gvfs_block="blocked"
	else
		gvfs_block="unblocked"
	fi


	for service in "${system_services[@]}"
	do
		if [[ "$(systemctl is-enabled "$service" 2> /dev/null)" == "masked" ]]
		then
			check_system_service_status=true
		else
			check_system_service_status=false
			break
		fi
	done


	if [[ $check_system_service_status == true ]]
	then
		system_service_block="blocked"
	else
		system_service_block="unblocked"
	fi


	case "$module:$module_block" in
		loaded:blocked)
			printf "USB Storage Devices are NOT blocked, but they will be blocked after system reboot.\n"
			;;
		loaded:unblocked|loaded:configless|unloaded:unblocked|unloaded:configless)
			printf "USB Storage Devices are NOT blocked, and they will remain unblocked after system reboot.\n"
			;;
		unloaded:blocked)
			printf "USB Storage devices are blocked, and will remain blocked after system reboot.\n"
			;;
	esac


	case "$gvfs_block:$system_service_block" in
		blocked:blocked)
			printf "Phone Storage Devices are blocked, and will remain blocked after user login.\n"
			;;
		blocked:unblocked)
			printf "Android Phone Storage Devices are blocked, but iOS Phone Storage Devices are NOT fully blocked.\n"
			;;
		unblocked:blocked)
			printf "Android Phone Storage Devices are NOT blocked, but iOS Phone Storage Devices are partially blocked.\n"
			;;
		unblocked:unblocked)
			printf "Phone Storage Devices are NOT blocked, and will remain unblocked after user login.\n"
			;;
	esac

}

### END-of-USB-Storage-Devices block/unblock configuration

#### START-of-ARGS-OPTIONS

#finalizing x2 ARGS = camera, usbstor AND x5 OPTIONS = -on, -off, --status, -h, --help

[ "$EUID" -ne 0 ] && printf "Run with sudo.\n" && exit 1

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
		printf "Usage: %s [DEVICE]... [OPTION]...\n\nBlocks USB Storage and/or Camera\n\nDEVICE:\n \n   camera\n \n   usbstor\n\nOPTION:\n \n  -on\t block DEVICE\n \n  -off\t unblock DEVICE\n \n  --status\t DEVICE's current block status\n \n  -h, --help\t Show this message\n\ne.g.  %s camera -on,  %s usbstor --status\n\n" "$(basename "$0")" "$(basename "$0")" "$(basename "$0")"
		;;
	*)
		printf "\nIncorrect Syntax...\n\n%s -h, --help for info\n\n" "$(basename "$0")"
		;;
esac

#### END-of-ARGS-OPTIONS

# Remove all global variables exported to Shell before exiting script
unset CamVendorID CamProductID CamRulesFile DevName DevNameNo custom_rule usb_device
