#!/bin/bash

# Some global variables
DATABASE_DIR="$HOME/.proxyswitch"
DATABASE_LOCATION="$HOME/.proxyswitch/proxyDB.txt"
PROXIES=()

# Proceed only if root privileges
CheckRoot(){
	if [ $EUID -ne 0 ]; then
		echo "Do you have proper administration rights? (super-user?)"
		echo "Root privileges are required."
		exit
	else
		SetupProxies
		return 0
	fi
}

# setup the proxy database location
SetupProxies(){
	if [[ ! -d $DATABASE_DIR ]]; then
		sudo mkdir $DATABASE_DIR
		if [[ ! -f $DATABASE_LOCATION ]]; then
			sudo touch $DATABASE_LOCATION
		else
			sudo mv $DATABASE_LOCATION $DATABASE_LOCATION."bkp"
		fi
	fi
	read -p "How many proxies do you wanna save ? " numOfProxies
	echo "PROXYCOUNT="$numOfProxies > $DATABASE_LOCATION
	for (( i = 1; i <= $numOfProxies; i++ )); do
		SaveProxyDetails $i
	done
	echo "PROXIES=(${PROXIES[@]})" >> $DATABASE_LOCATION
	Finalise
}

#set up the proxy details of each proxy
SaveProxyDetails(){
	echo
	echo "Enter Details for proxy #$1"
	read -p "Enter Proxy (e.g. 202.141.80.24) : " proxy
	read -p "Enter Proxy Port (e.g. 3128) : " proxyPort
	read -p "Use proxy Authentication? (Y/N) : " -n 1 response
	echo
	case $response in
		y|Y)
			echo "Enter you proxy Authentication"
			read -p "Enter username : " -r proxyUsername
			read -p "Enter Password : " -r proxyPassword
			ProxyText=$proxyUsername":"$proxyPassword"@"$proxy":"$proxyPort
			;;
		*)	
			ProxyText=$proxy":"$proxyPort
			;;
	esac
	PROXIES+=($ProxyText)
}

# install the script and display final message
Finalise(){
	sudo cp proxyswitch.sh /usr/local/bin/proxyswitch
	sudo chmod 755 /usr/local/bin/proxyswitch
	sudo gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '*.iitg.ernet.in', '*.iitg.ac.in', '202.141.*.*', '172.16.*.*']"
	echo
	echo "ProxySwitch installed successfully."
	echo "Use 'proxyswitch' from terminal to switch proxies."
}

CheckRoot