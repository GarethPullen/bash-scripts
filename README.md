# bash-scripts
A collection of Bash Scripts I've written
# logs.sh
This script offers the user a choice to either view log-files or zip them. If View is chosen, it uses CGrep to search Dmesg for "Error" and pulls the 3 lines either-side of the error. It also shows the boot-log.
If "Zip" is chosen it will collect various logs (Boot log, DMesg, etc.) into the /tmp/ folder, tar & zip them for easy sharing, and then delete the temporary files.
