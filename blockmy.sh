#!/bin/bash

# Exporting variables to Shell required for Camera block/unblock configuration
CamVendorID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 1)
CamProductID=$(lsusb | grep -iE "camera|uvc|webcam" | awk '{print $6}' | cut -d ':' -f 2)
CamRulesFile=$(grep -RE "(ATTR{idVendor}==\"$CamVendorID\", ATTR{idProduct}==\"$CamProductID\", ATTR{authorized}=\"[0-9]\")" /etc/udev/rules.d/ | cut -d ':' -f 1)

# Exporting variables to Shell required for USB Storage Devices block/unblock configuration
DevName=$(lsblk -o name,mountpoint,tran | grep -E "(usb)" | grep -E "(\bsd[a-zA-Z]+\b)" | awk '{print $1}')
DevNameNo=$(lsblk -o name,mountpoint,tran | grep -E "(\bsd[a-zA-Z]+[0-9]+\b)" | grep -E "(/[a-zA-Z]+/[a-zA-Z0-9\s.-]+/[a-zA-Z0-9\s.-]+)" | awk '{print $1}' | sed 's/^[^a-zA-Z0-9]*//')

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

MuteInstallConfigs() {

		if grep -iRE "(install\s*uas)" /etc/modprobe.d/ &> /dev/null
		then
			for EachInstUASConfigFile in $(grep -ilRE "(install\suas)" /etc/modprobe.d/ | sort -u)
			do
				sudo sed -i -E 's/(#|\s)*install\s*uas/#install uas/gI' $EachInstUASConfigFile &> /dev/nulll;
				if grep -iE "(#|\s)*(install\s*usb_storage)" $EachInstUASConfigFile &> /dev/null
					then
						sudo sed -i -E 's/(#|\s)*install\s*usb_storage/#install usb_storage/gI' $EachInstUASConfigFile &> /dev/null;
					fi
				printf "One or more 'install uas / install usb_storage' configurations found in $EachInstUASConfigFile...\nAll muted to maintain system stability when using 'blockmy'...\n"
			done
			return 0
		elif grep -iRE "(install\s*usb_storage)" /etc/modprobe.d/ &> /dev/null
		then
			for EachInstUSBConfigFile in $(grep -ilRE "(install\susb_storage)" /etc/modprobe.d/ | sort -u)
			do
				sudo sed -i -E 's/(#|\s)*install\s*usb_storage/#install usb_storage/gI' $EachInstUSBConfigFile &> /dev/null;
					if grep -iE "(#|\s)*(install\s*uas)" $EachInstUSBConfigFile &> /dev/null
					then
						sudo sed -i -E 's/(#|\s)*install\s*uas/#install uas/gI' $EachInstUSBConfigFile &> /dev/null;
					fi
				printf "One or more 'install uas / install usb_storage' configurations found in $EachInstUSBConfigFile...\nAll muted to maintain system stability when using 'blockmy'...\n"
			done
			return 0
		fi

}

MuteRemoveConfigs() {

		if grep -iRE "(remove\s*uas)" /etc/modprobe.d/ &> /dev/null
		then
			for EachRemUASConfigFile in $(grep -ilRE "(remove\s*uas)" /etc/modprobe.d/ | sort -u)
			do
				sudo sed -i -E 's/(#|\s)*remove\s*uas/#remove uas/gI' $EachRemUASConfigFile &> /dev/null;
					if grep -iE "(#|\s)*(remove\s*usb_storage)" $EachRemUASConfigFile &> /dev/null
					then
						sudo sed -i -E 's/(#|\s)*remove\s*usb_storage/#remove usb_storage/gI' $EachRemUASConfigFile &> /dev/null;
					fi
				printf "One or more 'remove uas / remove usb_storage' configurations found in $EachRemUASConfigFile...\nAll muted to maintain system stability when using 'blockmy'...\n"
			done
			return 0
		elif grep -iRE "(remove\s*usb_storage)" /etc/modprobe.d/ &> /dev/null
		then
			for EachRemUSBConfigFile in $(grep -ilRE "(remove\s*usb_storage)" /etc/modprobe.d/ | sort -u)
			do
				sudo sed -i -E 's/(#|\s)*remove\s*usb_storage/#remove usb_storage/gI' $EachRemUSBConfigFile &> /dev/null;
					if grep -iE "(#|\s)*(remove\s*uas)" $EachRemUSBConfigFile &> /dev/null
					then
						sudo sed -i -E 's/(#|\s)*remove\s*uas/#remove uas/gI' $EachRemUSBConfigFile &> /dev/null;
					fi
				printf "One or more 'remove uas / remove usb_storage' configurations found in $EachRemUSBConfigFile...\nAll muted to maintain system stability when using 'blockmy'...\n"
			done
			return 0
		fi

}

USBStorageBlockON() {

	if lsblk -o name,mountpoint,tran | grep -E "(\bsd[a-zA-Z]+[0-9]+\b)" | grep -E "(/[a-zA-Z]+/[a-zA-Z0-9\s.-]+/[a-zA-Z0-9\s.-]+)" | awk '{print $1}' | sed 's/^[^a-zA-Z0-9]*//' &> /dev/null
	then
		for devNo in $DevNameNo
		do
			if sudo umount /dev/$devNo
			then
				printf "Unmounted USB storage device $devNo, successfully...\n"
			else
				printf "There was a problem when unmounting the USB storage devices...\nExiting...\n";
				exit 1
			fi
		done
	else
		printf "No mounted USB Storage devices found...\n"
	fi

	if lsblk -o name,mountpoint,tran | grep -E "(usb)" | grep -E "(\bsd[a-zA-Z]+\b)" | awk '{print $1}' &> /dev/null
	then
		for dev in $DevName
		do
			if udisksctl power-off -b /dev/$dev
			then
				printf "Powered off USB storage device $dev, successfully...\n"
			else
				printf "There was problem when powering off the USB storage devices...\nExiting...\n";
				exit 1
			fi
		done
	else
		printf "No powered-on USB Storage devices found...\n"
	fi

	if lsmod | grep -E "\b(uas|usb_storage)\b" &> /dev/null
	then
		sudo modprobe -r usb_storage &> /dev/null;
		sudo modprobe -r uas &> /dev/null;
		printf "USB Storage blocked, successfully...\n";
	else
		printf "No kernel modules found running about USB Storage devices...\n"
	fi

	MuteInstallConfigs
	MuteRemoveConfigs

	if grep -iRE "(blacklist\s*uas)" /etc/modprobe.d/ &> /dev/null
	then
		for EachUASConfigFile in $(grep -ilRE "(blacklist\s*uas)" /etc/modprobe.d/ | sort -u)
		do
			sudo sed -i -E 's/(#|\s)*blacklist\s*uas/#blacklist uas/gI' $EachUASConfigFile &> /dev/null;
				if grep -iE "(#|\s)*(blacklist\s*usb_storage)" $EachUASConfigFile &> /dev/null
				then
					sudo sed -i -E 's/(#|\s)*blacklist\s*usb_storage/#blacklist usb_storage/gI' $EachUASConfigFile &> /dev/null;
				else
					printf "blacklist usb_storage\n" | sudo tee -a $EachUASConfigFile &> /dev/null
				fi
			printf "$EachUASConfigFile updated successfully...\n"
		done
		printf "USB Storage devices will remain blocked among boot times...\n";
		return 0
	elif grep -iRE "(blacklist\s*usb_storage)" /etc/modprobe.d/ &> /dev/null
	then
		for EachUSBConfigFile in $(grep -ilRE "(blacklist\s*usb_storage)" /etc/modprobe.d/ | sort -u)
		do
			sudo sed -i -E 's/(#|\s)*blacklist\s*usb_storage/#blacklist usb_storage/gI' $EachUSBConfigFile &> /dev/null;
				if grep -iE "(#|\s)*(blacklist\s*uas)" $EachUSBConfigFile &> /dev/null
				then
					sudo sed -i -E 's/(#|\s)*blacklist\s*uas/#blacklist uas/gI' $EachUSBConfigFile &> /dev/null;
				else
					printf "blacklist uas\n" | sudo tee -a $EachUSBConfigFile &> /dev/null
				fi
			printf "$EachUSBConfigFile updated successfully...\n"
		done
		printf "USB Storage devices will remain blocked among boot times...\n";
	fi
	
	printf "# Block my USB-StorageDevices\nblacklist uas\nblacklist usb_storage\n" | sudo tee /etc/modprobe.d/custom-blacklist.conf &> /dev/null;
	printf "/etc/modprobe.d/custom-blacklist.conf file created, successfully...\nUSB Storage devices will remain blocked among boot times...\n"

}

USBStorageBlockOff() {

	if ! lsmod | grep -E "(\buas\b)|(\busb_storage\b)" &> /dev/null
	then
		sudo modprobe usb_storage &> /dev/null;
		sudo modprobe uas &> /dev/null
		printf "USB Storage UN-blocked, successfully...\n";
	else
		printf "Kernel modules found running about USB Storage devices...\n"
	fi

	if grep -iRE "\b(uas|usb_storage)\b" /etc/modprobe.d/ &> /dev/null
	then
		if grep -iE "(#|\s)*(blacklist\s+uas)+" $BlacklistFile &> /dev/null
		then
			sudo sed -i -E 's/(#|\s)*blacklist(#|\s)*uas/#blacklist uas/gI' $BlacklistFile &> /dev/null;
				if grep -iE "(#|\s)*(blacklist\s+usb_storage)+" $BlacklistFile &> /dev/null
				then
					sudo sed -i -E 's/(#|\s)*blacklist(#|\s)*usb_storage/#blacklist usb_storage/gI' $BlacklistFile &> /dev/null
				else
					printf "# Block my USB-StorageDevices\n#blacklist usb_storage" | sudo tee -a $BlacklistFile &> /dev/null
				fi
			printf "$BlacklistFile updated successfully...\nUSB Storage devices will remain UN-blocked among boot times...\n";
			return 0
		elif grep -iE "(#|\s)*(blacklist\s+usb_storage)+" $BlacklistFile &> /dev/null
		then
			sudo sed -i -E 's/(#|\s)*blacklist(#|\s)*usb_storage/#blacklist usb_storage/gI' $BlacklistFile &> /dev/null
				if grep -iE "(#|\s)*(blacklist\s+uas)+" $BlacklistFile &> /dev/null
				then
					sudo sed -i -E 's/(#|\s)*blacklist(#|\s)*uas/#blacklist uas/gI' $BlacklistFile &> /dev/null
				else
					printf "# Block my USB-StorageDevices\nblacklist uas" | sudo tee -a $BlacklistFile &> /dev/null;
					return 0
				fi
		fi
	else
		printf "No USB Storage device configuration files found about blocking/unblocking them...\n"

	fi

}

USBStorageStatus() {

	if lsmod | grep -E "(\buas\b)" &> /dev/null
	then
		if grep -E "^(#blacklist\suas)$" $BlacklistFile &> /dev/null
		then
			printf "USB Storage devices are UN-blocked, and will remain among boot times...\n"
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
	USBStorageBlockON
elif [[ $1 = "usbstor" ]] && [[ $2 = "-off" ]]
then
	USBStorageBlockOff	
elif [[ $1 = "usbstor" ]] && [[ $2 = "--status" ]]
then
	USBStorageStatus
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
