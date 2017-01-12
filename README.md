# proxyswitch

Are you fed up of changing all the proxy settings individually in 
		
	- Settings Menu

	- Environment Variables

	- Apt Configuration


Use **proxyswitch** to switch proxies in linux with ease.

# How To Install

	git clone https://github.com/roopansh/proxyswitch

	cd proxyswitch

	bash install.sh


Then enter the number of proxies you want to save and their details.

Save the proxies that you commonly use and have to switch between frequently.

**NOTE : In your ~/.bashrc file, DON'T export any proxy environment variables.**

# How To Use

Use the following command from anywhere in the terminal


	proxyswitch


It'll display you saved proxies and you can chose from them.

# How To Uninstall

	bash uninstall.sh


# Up Coming

- Add new proxy settings while using the script itself and no need to save it in advance.

- Add new proxies to the database instead of creating the new database everytime you install it. Currently, on installing again, the previous database of proxies will be deleted and replaced by the new proxies you enter that time.



## About the project author

#### Roopansh Bansal

B.Tech undergraduate (Computer Science & Engineering)

IIT Guwahati

India


roopansh.bansal@gmail.com

www.linkedin.com/in/roopansh
