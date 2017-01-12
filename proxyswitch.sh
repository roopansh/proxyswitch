#!/bin/bash

# Some global variables
source "$HOME/.proxyswitch/proxyDB.txt"
PROXYCOUNT=$PROXYCOUNT
PROXIES=("${PROXIES[@]}")

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
	echo "You have  $PROXYCOUNT  saved proxies."
	echo
	for (( i = 1; i <= $PROXYCOUNT; i++ )); do
		proxy="${PROXIES[$i-1]}"
		# display choice number
		echo -n "$i - "
		# display username
		sed 's/\(.*\):.*@\(.*\)/\2 \1/' <<< "$proxy"
		echo
	done
	read -p "Which proxy you want to use? " ProxyChoice
	# check if in range
	if [[ $ProxyChoice -gt '0' && $ProxyChoice -le $PROXYCOUNT ]]; then
		ProxyChoice=$((ProxyChoice-1))
		# System Settings Proxy 
		ProxySYS $ProxyChoice
		# Apt Proxy Configuration
		ProxyAPT $ProxyChoice
		# Environment variables set up
		ProxyENV $ProxyChoice
		# exporting in .bashrc file
		ProxyBASHRC $ProxyChoice

		echo "ProxySwitch Successful."
	else
		echo "Invalid Proxy Selected."
		echo "ProxySwitch Failed."
	fi

}


# set the System proxy
ProxySYS(){
	proxy="${PROXIES[$1]}"
	proxy=$(sed 's/.*@\(.*\)/\1/' <<< "$proxy")
	ProxyPROXY=$(sed 's/\(.*\):.*/\1/' <<< "$proxy")
	ProxyPORT=$(sed 's/.*:\(.*\)/\1/' <<< "$proxy")
	# echo $ProxyPROXY $ProxyPORT
	sudo gsettings set org.gnome.system.proxy mode 'manual'
	sudo gsettings set org.gnome.system.proxy.http host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.http port "$ProxyPORT"
	sudo gsettings set org.gnome.system.proxy.https host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.https port "$ProxyPORT"
	sudo gsettings set org.gnome.system.proxy.ftp host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.ftp port "$ProxyPORT"
	sudo gsettings set org.gnome.system.proxy.socks host "$ProxyPROXY"
	sudo gsettings set org.gnome.system.proxy.socks port "$ProxyPORT"
}
# set the apt proxy
ProxyAPT(){
	proxy="${PROXIES[$1]}"
	sudo sed -i.bak '/proxy/d' /etc/apt/apt.conf
	sudo echo -e "Acquire::http::proxy \"http://$proxy/\";\nAcquire::https::proxy \"https://$proxy/\";\nAcquire::ftp::proxy \"ftp://$proxy/\";\nAcquire::socks::proxy \"socks://$proxy/\";" >> /etc/apt/apt.conf
}

# set up the environment variables in the proxy
ProxyENV(){
	proxy="${PROXIES[$1]}"
	
	#remove previous proxy
	sudo sed -i.bak '/http_proxy/d' /etc/environment
	sudo sed -i.bak '/https_proxy/d' /etc/environment
	sudo sed -i.bak '/ftp_proxy/d' /etc/environment
	sudo sed -i.bak '/socks_proxy/d' /etc/environment

	sudo echo -e "http_proxy=\"http://$proxy/\"\nhttps_proxy=\"https://$proxy/\"\nftp_proxy=\"ftp://$proxy/\"\nsocks_proxy=\"socks://$proxy/\"" >> /etc/environment

}

# exporting the variables in the bashrc file.
ProxyBASHRC(){
	proxy="${PROXIES[$1]}"

	#remove previous proxy
	sudo sed -i.bak '/proxyswitch/d' $HOME/.bashrc
	sudo sed -i.bak '/http_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/https_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/ftp_proxy/d' $HOME/.bashrc
	sudo sed -i.bak '/socks_proxy/d' $HOME/.bashrc

	sudo echo -e "## Proxy settings by proxyswitch\nexport http_proxy=\"http://$proxy/\"\nexport https_proxy=\"https://$proxy/\"\nexport socks_proxy=\"socks://$proxy/\"\nexport ftp_proxy=\"ftp://$proxy/\"" >> $HOME/.bashrc

	source $HOME/.bashrc
}

CheckRoot