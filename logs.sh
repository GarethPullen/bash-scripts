#!/bin/bash

#Script to gather basic log files
#Either can display or tar & zip them for sharing
#Written by Gareth Pullen (grp43) 13/12/2022

#Define a few Global Variables:
Logging_File=""
BOOTLOG=""
BOOTLINE=""
FILESCREATED=""
#Sanitize Time to use "." rather than ":"
DateTime=`date +%F`-`date +%T|tr ':' '.'`

#Check if we're running as root, if not we will need to Sudo certain things
SUDO=''
if [ "$(id -u)" -ne 0 ]; then
	SUDO='sudo'
	root="false"
fi

#DEBUG LINES:
#if [ "$SUDO" = '' ] ; then
#	echo "Sudo not set"
#else
#	echo "Sudo is set"
#fi



#####
# Functions defined here:

function log-dmesg
{
	Logging_File+=`echo -e "********\n DMESG Output: \n********\n "`
	if  [ "$SUDO" = '' ] ; then
		Logging_File+="$(dmesg -T)" &> /dev/null
	else
		Logging_File+="$(sudo dmesg -T)" &> /dev/null
	fi
}

function get-bootlog
{
		if  [ "$SUDO" = '' ] ; then
			BOOTLINE=`grep -n --  ------------ /var/log/boot.log | tail -1 | awk '{print $2,$3,$4,$5}'`
			if [ "$BOOTLINE" = '' ] ; then
				#Only one boot today, so no "------" line - cat the whole file
				BOOTLOG = `cat /var/log/boot.log`
			else
				BOOTLOG=`tail -n +"$BOOTLINE" /var/log/boot.log` &> /dev/null
			fi
		else
			BOOTLINE=`sudo grep -n --  ------------ /var/log/boot.log | tail -1 | awk -F: '{print $1}'`
			if [ "$BOOTLINE" = '' ] ; then
				#Only one boot today, so no "------" line - cat the whole file
				BOOTLOG=`sudo cat /var/log/boot.log`
			else
				BOOTLOG=`sudo tail -n +"$BOOTLINE" /var/log/boot.log` &> /dev/null
			fi
		fi
}

function display-things
{
	echo -e "\nDMESG - search for error\n\n"
	if  [ "$SUDO" = '' ] ; then
		dmesg | grep --color=auto -i -C3 "error" 
	else
		sudo dmesg | grep --color=auto -i -C3 "error"
	fi
	get-bootlog
	echo -e "\n\nBOOT LOG\n\n"
	echo -e "$BOOTLOG"
	
	exit 0
}

function make-logs()
{
	if [ "$1" = '' ] ; then
		#Nothing passed to script.
		FilePath='/tmp/'
	else
		FilePath=$1
	fi
	#Function to create the various temporary log-files
	#Get Dmesg output
	log-dmesg
	#put it into a file
	dmfile="$FilePath""dmesg-$DateTime"
	echo -e "$Logging_File" > "$dmfile"
	#Add the file-name to an array for tidyup
	FilesCreated+=("$dmfile")
	#Get the last boot
	get-bootlog
	#Add it to a file
	blfile="$FilePath""BootLog-$DateTime"
	echo -e "$BOOTLOG" > "$blfile"
	#Add the file-name to an array for tidyup
	FilesCreated+=("$blfile")
	#Change the permissions on the created files:
	for files in "${FilesCreated[@]}"
	do
	if  [ "$SUDO" = '' ] ; then 
			chmod a+rw $files
		else
			`sudo chmod a+rw $files`
		fi
	
	done
}

function zip-logs()
{
	if [ "$1" = '' ] ; then
		#Nothing passed to script.
		FilePath='/tmp/'
	else
		FilePath=$1
	fi
	ZippedName="$DateTime-logs.tar.gz"
	TarName="$DateTime-logs.tar"
	echo -e "\nThis will output to $FilePath$ZippedName"
	#Create the initial Tar file as Empty so we can add to it in the loop
	tar -cf $FilePath$TarName --files-from /dev/null
	#Now get the logs:
	make-logs $FilePath
	
	#Loop through the array of files
	for files in "${FilesCreated[@]}"
	do
		#Tar up each file.
		tar -rf $FilePath$TarName $files &> /dev/null #Suppress messages
		#Tidy up temporary files
		rm $files
	done
	
	#Zip the Tar file
	gzip $FilePath$TarName
	
	#Ensure permissions are all RW for the Zip:
	if  [ "$SUDO" = '' ] ; then 
			chmod a+rw $FilePath$ZippedName
		else
			`sudo chmod a+rw $FilePath$ZippedName`
		fi
	exit 0
}

function set-folder-logs
{
	#Function to ask the user for a folder, set a default if nothing specified.
	#Then calls the "zip-logs" function to actually create & zip them.
	#Loop allows for testing the path exists!
	FolderValid="No"
	while [ "$FolderValid" == "No" ]
	do
		read -p "Enter path to save the zip in (Default: /tmp/): " LogPath
	L	LogPath=${LogPath:-/tmp/}
		#Check if it ends with a "/"
		if [ "${LogPath: -1}" != "/" ] ; then
			LogPath="$LogPath/"
		fi
		#Check the folder exists - if so update the "FolderValid" var
		if [ -d $LogPath ] ; then
			FolderValid="Yes"
		else
			echo "$LogPath is not a valid folder!"
		fi
	done
	zip-logs $LogPath
}

### Main Script starts:

#Generate menu & launch functions
PS3="Select what you would like to do (4 quits): "
select option in "zip-logs" "display-errors" "testing" "exit"
do
	case $option in
		zip-logs) set-folder-logs;;
		display-errors) display-things;;
		testing) make-logs $DateTime;;
		exit) exit 0;;
	esac
done
