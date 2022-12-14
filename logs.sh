#!/bin/bash

#Script to gather basic log files
#Either can display or tar & zip them for sharing
#Written by Gareth Pullen (grp43) 13/12/2022

#Define a few Global Variables:
Logging_File=""
BOOTLOG=""
BOOTLINE=""
FILESCREATED=""
DateTime=`date +%F`-`date +%T`

#Check if we're running as root, if not we will need to Sudo certain things
SUDO=''
if [ "$(id -u)" -ne 0 ]; then
	SUDO='sudo'
	root="false"
fi

if [ "$SUDO" = '' ] ; then
	echo "Sudo not set"
else
	echo "Sudo is set"
fi

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
			BOOTLOG=`tail -n +"$BOOTLINE" /var/log/boot.log` &> /dev/null
		else
			BOOTLINE=`sudo grep -n --  ------------ /var/log/boot.log | tail -1 | awk -F: '{print $1}'`
			BOOTLOG=`sudo tail -n +"$BOOTLINE" /var/log/boot.log` &> /dev/null			
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
	#Function to create the various temporary log-files
	#Get Dmesg output
	log-dmesg
	#put it into a file
	echo -e "$Logging_File" > "$FilePathdmesg-$DateTime"
	#Add the file-name to an array for tidyup
	FilesCreated+=("$FilePathdmesg-$DateTime")
	get-bootlog
	echo -e "$BOOTLOG" > "$FilePathBootLog-$DateTime"
	#Add the file-name to an array for tidyup
	FilesCreated+=("$FilePathBiitLog-$DateTime")
}

function zip-logs()
{
	FilePath='/tmp/'
	ZippedName="$DateTime-logs.tar.zip"
	echo -e "\nThis will output to $FilePath$ZippedName"

	#Tidyup
	#Loop through the array of files to delete the temporary ones
	for files in "${FilesCreated[@]}"
	do
		echo $files
		#Tidy up temporary files
		if  [ "$SUDO" = '' ] ; then 
			rm $file
		else
			`sudo rm $file`
		fi
	done
	exit 0
}

### Main Script starts:

#Generate menu & launch functions
PS3="Select what you would like to do (4 quits): "
select option in "zip-logs" "display-errors" "testing" "exit"
do
	case $option in
		zip-logs) zip-logs;;
		display-errors) display-things;;
		testing) make-logs $DateTime;;
		exit) exit 0;;
	esac
done
