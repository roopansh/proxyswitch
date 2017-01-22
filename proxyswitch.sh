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
		ProxyNone
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

	echo "New proxy settings applied."
	echo "ProxySwitch Successful."
}

# set the System proxy
ProxySYS(){
	proxy="$1"
	proxy=$(sed 's/.*@\(.*\)/\1/' <<< "$proxy")
	ProxyPROXY=$(sed 's/\(.*\):.*/\1/' <<< "$proxy")
	ProxyPORT=$(sed 's/.*:\(.*\)/\1/' <<< "$proxy")
	# ProxyUN=$(sed 's/\(.*\):.*@.*:.*/\1/' <<< "$proxy")
	# ProxyPASS=$(sed 's/.*:\(.*\)@.*:.*/\1/' <<< "$proxy")

	# echo $ProxyPROXY $ProxyPORT $ProxyUN $ProxyPASS
	
	sudo gsettings set org.gnome.system.proxy use-same-proxy true
	sudo gsettings set org.gnome.system.proxy mode 'manual'
	sudo gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '::1', '*.iitg.ernet.in', '*.iitg.ac.in', '202.141.*.*', '172.16.*.*']"
	sudo gsettings set org.gnome.system.proxy.http host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.http port "$ProxyPORT"
	# sudo gsettings set org.gnome.system.proxy.http use-authentication true
	# sudo gsettings set org.gnome.system.proxy.http authentication-user '$ProxyUN'
	# sudo gsettings set org.gnome.system.proxy.http authentication-password '$ProxyPASS'
	sudo gsettings set org.gnome.system.proxy.https host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.https port "$ProxyPORT"
	sudo gsettings set org.gnome.system.proxy.ftp host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.ftp port "$ProxyPORT"
	sudo gsettings set org.gnome.system.proxy.socks host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.socks port "$ProxyPORT"
}

# set the apt proxy
ProxyAPT(){
	proxy="$1"
	
	sudo echo -e "Acquire::http::proxy \"http://$proxy/\";\nAcquire::https::proxy \"https://$proxy/\";\nAcquire::ftp::proxy \"ftp://$proxy/\";\nAcquire::socks::proxy \"socks://$proxy/\";" >> /etc/apt/apt.conf
}

# set up the environment variables in the proxy
ProxyENV(){
	proxy="$1"
	
	sudo echo -e "http_proxy=\"http://$proxy/\"\nhttps_proxy=\"https://$proxy/\"\nftp_proxy=\"ftp://$proxy/\"\nsocks_proxy=\"socks://$proxy/\"" >> /etc/environment
}

# exporting the variables in the bashrc file.
ProxyBASHRC(){
	proxy="$1"

	sudo echo -e "## Proxy settings by proxyswitch\nexport http_proxy=\"http://$proxy/\"\nexport https_proxy=\"https://$proxy/\"\nexport socks_proxy=\"socks://$proxy/\"\nexport ftp_proxy=\"ftp://$proxy/\"" >> $HOME/.bashrc

	source $HOME/.bashrc
}

# Set no proxy ... Remove all the previous proxy settings 
ProxyNone(){
	# System Settings Proxy 
	sudo gsettings set org.gnome.system.proxy use-same-proxy true
	sudo gsettings set org.gnome.system.proxy mode 'none'

	# Apt Proxy Configuration
	sudo sed -i.bak '/http::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/https::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/socks::proxy/d' /etc/apt/apt.conf
	sudo sed -i.bak '/ftp::proxy/d' /etc/apt/apt.conf

	# Environment variables set up
	sudo sed -i.bak '/http_proxy/d' /etc/environment
	sudo sed -i.bak '/https_proxy/d' /etc/environment
	sudo sed -i.bak '/ftp_proxy/d' /etc/environment
	sudo sed -i.bak '/socks_proxy/d' /etc/environment

	# exporting in .bashrc file
	sudo sed -i.bak '/proxyswitch/d' $HOME/.bashrc
	sudo sed -i.bak '/http_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/https_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/ftp_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/socks_proxy/d' $HOME/.bashrc

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
