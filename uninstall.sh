#!/bin/bash

# Proceed only if root privileges
CheckRoot(){
	if [ $EUID -ne 0 ]; then
		echo "Do you have proper administration rights? (super-user?)"
		echo "Root privileges are required."
		exit
	else
		Uninstall
		return 0
	fi
}

# Uninstall
Uninstall(){
	sudo rm -r $HOME/.proxyswitch
	sudo rm /usr/local/bin/proxyswitch

	echo "Uninstall successfull."
}

CheckRoot