#!/bin/bash

# Source the Proxy Database
source "$HOME/.proxyswitch/proxyDB.txt"

# Proceed only if root privileges
CheckRoot(){
	if [ $EUID -ne 0 ]; then
		echo "Do you have proper administration rights? (super-user?)"
		echo "Root privileges are required."
		exit
	else
		ProxyChoice
		return 0
	fi
}

# ask user which proxy he wants to use
ProxyChoice(){
	clear
	echo "You have  $PROXYCOUNT  saved proxies."
	echo

	echo "0 > USE NO PROXY"
	echo

	for (( i = 1; i <= $PROXYCOUNT; i++ )); do
		proxy="${PROXIES[$i-1]}"
	
		# display choice number
		echo -n "$i > "
	
		# display proxy:port and username
		sed 's/\(.*\):.*@\(.*\)/\2  \1/' <<< "$proxy"
		echo
	done

	echo "$i > SOME OTHER PROXY"
	echo

	read -p "Chose any one option : " ProxyChoice
	
	# check if in range
	if [[ $ProxyChoice -gt '0' && $ProxyChoice -le $PROXYCOUNT ]]; then
		# ProxyChoice=$((ProxyChoice-1))
		# Read the proxy details from the database
		proxy="${PROXIES[$ProxyChoice-1]}"
		# Set that proxy
		SetProxy $proxy
	elif [[ $ProxyChoice == $(($PROXYCOUNT + 1)) ]]; then
		# Set a new Proxy
		NewProxy
	elif [[ $ProxyChoice == '0' ]]; then
		# No Proxy
		ProxyNone 'none'
	else
		echo "Invalid Proxy Selected."
		echo "ProxySwitch Failed."
	fi
}

# Calls functions to set proxy in different fields
SetProxy(){
	# Remove all the previous Proxy Settings
	ProxyNone

	# System Settings Proxy 
	ProxySYS $1
	# Apt Proxy Configuration
	ProxyAPT $1
	# Environment variables set up
	ProxyENV $1
	# exporting in .bashrc file
	ProxyBASHRC $1

	source $HOME/.bashrc
	
	echo "New proxy settings applied."
	echo "ProxySwitch Successful."
}

# set the System proxy
ProxySYS(){
	proxy="$1"
	proxy=$(sed 's/.*@\(.*\)/\1/' <<< "$proxy")
	ProxyPROXY=$(sed 's/\(.*\):.*/\1/' <<< "$proxy")
	ProxyPORT=$(sed 's/.*:\(.*\)/\1/' <<< "$proxy")

	sudo gsettings set org.gnome.system.proxy mode 'manual';
	sudo gsettings set org.gnome.system.proxy.http host $ProxyPROXY;
	sudo gsettings set org.gnome.system.proxy.http port $ProxyPORT;
	sudo gsettings set org.gnome.system.proxy.https host $ProxyPROXY
	sudo gsettings set org.gnome.system.proxy.https port $ProxyPORT
	sudo gsettings set org.gnome.system.proxy.ftp host $ProxyPROXY
	sudo gsettings set org.gnome.system.proxy.ftp port $ProxyPORT
	sudo gsettings set org.gnome.system.proxy.socks host $ProxyPROXY
	sudo gsettings set org.gnome.system.proxy.socks port $ProxyPORT
	sudo gsettings set org.gnome.system.proxy.all host $ProxyPROXY
	sudo gsettings set org.gnome.system.proxy.all port $ProxyPORT
}

# set the apt proxy
ProxyAPT(){
	proxy="$1"
	
	sudo echo -e "Acquire::http::proxy \"http://$proxy/\";\nAcquire::https::proxy \"https://$proxy/\";\nAcquire::ftp::proxy \"ftp://$proxy/\";\nAcquire::socks::proxy \"socks://$proxy/\";\nAcquire::all::proxy \"https://$proxy/\";" >> /etc/apt/apt.conf
}

# set up the environment variables in the proxy
ProxyENV(){
	proxy="$1"
	
	sudo echo -e "http_proxy=\"http://$proxy/\"\nhttps_proxy=\"https://$proxy/\"\nftp_proxy=\"ftp://$proxy/\"\nsocks_proxy=\"socks://$proxy/\"\nall_proxy=\"https://$proxy/\"" >> /etc/environment

	export http_proxy="http://$proxy/"
	export https_proxy="https://$proxy/"
	export socks_proxy="socks://$proxy/"
	export ftp_proxy="ftp://$proxy/"
	export all_proxy="https://$proxy/"
}

# exporting the variables in the bashrc file.
ProxyBASHRC(){
	proxy="$1"

	sudo echo -e "## Proxy settings by proxyswitch\nexport http_proxy=\"http://$proxy/\"\nexport https_proxy=\"https://$proxy/\"\nexport socks_proxy=\"socks://$proxy/\"\nexport ftp_proxy=\"ftp://$proxy/\"\nexport all_proxy=\"https://$proxy/\"" >> $HOME/.bashrc
}

# Set no proxy ... Remove all the previous proxy settings 
ProxyNone(){
	# System Settings Proxy
	if [[ $1 == 'none' ]]; then
		sudo gsettings set org.gnome.system.proxy mode 'none'
	fi

	# Apt Proxy Configuration
	sudo sed -i.bak '/http::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/https::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/socks::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/ftp::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/all::proxy/d' /etc/apt/apt.conf
	

	# Environment variables set up
	sudo sed -i.bak '/http_proxy/d' /etc/environment
	sudo sed -i.bak '/https_proxy/d' /etc/environment
	sudo sed -i.bak '/ftp_proxy/d' /etc/environment
	sudo sed -i.bak '/socks_proxy/d' /etc/environment
	sudo sed -i.bak '/all_proxy/d' /etc/environment

	# exporting in .bashrc file
	sudo sed -i.bak '/proxyswitch/d' $HOME/.bashrc
	sudo sed -i.bak '/http_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/https_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/ftp_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/socks_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/all_proxy/d' $HOME/.bashrc

	echo "All previous proxy settings removed."
}

# Set a new proxy not saved in the database 
NewProxy(){
	echo
	echo "Enter Details for proxy : "
	read -p "Proxy (e.g. 202.141.80.24) : " proxy
	read -p "Proxy Port (e.g. 3128) : " proxyPort
	read -p "Use proxy Authentication? (Y/N) : " -n 1 response
	echo
	case $response in
		y|Y)
			echo "Enter you proxy Authentication"
			read -p "Enter Username : " -r proxyUsername
			read -p "Enter Password : " -r proxyPassword
			Proxy=$proxyUsername":"$proxyPassword"@"$proxy":"$proxyPort
			;;
		*)	
			Proxy=$proxy":"$proxyPort
			;;
	esac

	SetProxy $Proxy
}

CheckRoot
