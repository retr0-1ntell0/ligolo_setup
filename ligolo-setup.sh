#/bin/bash
# Author: retr0	
# Date: 2024-11-18
# Description: Setup ligolo	proxy
# Usage: ./ligolo-setup.sh
# Version: 1.1

DEVICE=$(ip -br a | grep lig | awk '{print $1}')

# Function to validate CIDR notation
validate_cidr() {
    local cidr=$1
    # Regular expression to match valid CIDR notation (e.g., 192.168.1.1/24)
    if [[ $cidr =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}\/([12]?[0-9]|3[0-2])$ ]]; then
		return 0
    else
		return 1
	fi
}

# Add a new tuntap interface
add_link(){
	# retrieve the existing tuntap interface
	exp=$(ip -br a | grep lig)
	verify=$(ip link show | grep lig)
	#created=$(sudo ip tuntap add user $USER mode tun ligolo 2>&1)
	#if [[ $exp == *"lig"* ]]; then
	if echo "$verify" | grep -q "ligolo"; then
		echo -e '\033[31m[x] ligolo/lig interface already exists\n\033[0m'
	#elif echo "$created" | grep -q "Device or resource busy"; then
	#	echo -e '\033[31m[-] ligolo/lig already created!\n\033[0m'
	elif [ -z "$verify" ]; then
		sudo ip tuntap add user $USER mode tun ligolo
		sudo ip link set ligolo up 
		echo -ne '\033[0;32m[+] ligolo/lig interface created successfully!\n\033[0m'
		ip -br a | grep lig | xargs -I {} echo -e "\033[0;32m{}\n\033[0m"
	fi
}

# Delete a tuntap interface
delete_link(){
	expression=$(ip link show $DEVICE | awk '{print $2}')
	if [ -z "$expression" ]; then
		echo -e '\033[0;31m[x] ligolo/lig does not exists\n\033[0m'
		echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
	elif echo "$expression" | grep -q "ligolo"; then
		sudo ip link delete $DEVICE 2>/dev/null
		ip link show | grep lig
		echo -e '\033[0;32m[+] ligolo/lig interface deleted successfully! \n\033[0m'
	else
		echo -e '\033[0;31m[x] Device not found!\n\033[0m'
		echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
	fi
}

# Add a new route to the existing tuntap interface
add_route(){
	echo -en '\n'
	DEV=$(ip -br a | grep lig | awk '{print $1}')
	if [ -z "$DEV" ]; then
		echo -e '\033[0;31m[x] ligolo/lig interface does not exists\n\033[0m'
		echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
		menu
	else
		while true; do
			echo -ne '\033[0;34mEnter the route here [eg: 0.0.0.0/24]: \033[0m' 
			read addedroute

			if validate_cidr "$addedroute"; then
				output=$(sudo ip route add $addedroute dev $DEVICE 2>&1)
				break
			else
				echo -en '\033[31m\n[x] Invalid CIDR notation. Please enter a valid IP in the format 0.0.0.0/24.\n\033[0m'
			fi
		done

		if echo "$output" | grep -q "RTNETLINK answers: File exists"; then 
			echo -ne "\033[0;31m\n[x] Error: Route already exists!\nHere is the existing route => $(ip route | grep lig)\n\033[0m"
		elif echo "$output" | grep -q "Cannot find device"; then
			echo -ne "\033[31m\n[x] Error: Device does not exist!\n\033[0m"
			echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
		else
			echo -e "\033[0;32m\n[+] Success: Route added successfully!\nHere is the newly added route: \033[0m"
			ip route | grep $DEVICE | xargs -I {} echo -e "\033[0;32m{}\033[0m"
		fi
	fi
}

get_info(){
	# retrieve the existing tuntap interface
	exp=$(ip -br a | grep lig | awk '{print $1}')
	if echo "$exp" | grep -q "ligolo"; then
		echo -e '\033[0;32m\n\033[0;38;5;214m[+] Ligolo interface information:\n\033[0m'
		ip -br a | grep lig | xargs -I {} echo -e "\033[0;32m{}\n\033[0m"
		echo -e '\n\033[0;32m\n\033[0;38;5;214m[+] Ligolo routes:\n\033[0m'
		ip route | grep $exp | xargs -I {} echo -e "\033[0;32m{}\033[0m"
		echo -e '\n\033[0;32m\n\033[0;38;5;214m[+] Ligolo ARP table:\n\033[0m'
		ip neigh | grep $exp | xargs -I {} echo -e "\033[0;32m{}\033[0m"
	elif [ -z "$exp" ]; then
		echo -e '\033[0;31m[x] ligolo/lig interface does not exists\n\033[0m'
		echo -e "\033[38;5;214m[-] Can't get the information. Please create a new tuntap interface first.\n\033[0m"
	else
		echo -e '\033[0;31m[x] ligolo/lig interface does not exists\n\033[0m'
		echo -e "\033[38;5;214m[-] Can't get the information. Please create a new tuntap interface first.\n\033[0m"
	fi
	menu
}

start_proxy(){
	# retrieve the installed ligolo-proxy binary
	exp=$(which ligolo-proxy 2>/dev/null)
	DEV=$(ip -br a | grep lig | awk '{print $1}')
	if [ -z "$DEV" ]; then
		echo -e '\033[0;31m[x] ligolo/lig interface does not exists\n\033[0m'
		echo -e "\033[38;5;214m[x] Can't start the proxy. Please create a new tuntap interface first.\n\033[0m"
		menu
	else
		if [ -z "$exp" ]; then
			echo -e '\033[0;31m[x] ligolo-proxy binary not found!\n\033[0m'
			echo -e "\033[38;5;214m[x] Please install ligolo-proxy first.\n\033[0m"
			menu
		else
			echo -e '\033[0;32m[+] ligolo-proxy binary found!\n\033[0m'
			echo -e "\033[0;32m[+] Starting ligolo-proxy...\n\033[0m"
			$exp -selfcert
		fi
	fi
}

# menu function
menu(){
	echo -e '\033[0;34mWhat do you want to do ?\n\n1. Add a new tuntap interface: \n2. Delete a tuntap interface: \n3. Add a new route: \n4. Start ligolo-proxy: \n\033[0m'
	echo -e '\033[0;34mPress i or I to verify the `ligolo` interface\nPress q or Q to quit and Ctrl+C to stop the script\033[0m\n'
	echo -ne '\033[0;34mSelect an option: \033[0m'
	read option

	case $option in
	1) 
		add_link
		menu
		;;
	2) 
		delete_link
		menu
		;;
	3) 
		add_route
		menu
		;;

	4) 
		start_proxy;;

	[iI]) 
		echo -e '\033[0;32m\n[+] Interface information:\n    ----------------------\n\033[0m'
		get_info
		menu
		return
		;;
	[qQ]) 
		echo -e '\033[38;5;214m\n[***] Exiting...See ya! [***]\n\033[0m'
		echo -e "\033[38;5;214m\n[*] Cleaning up...[*]\n\033[0m"
		rm -vrf $(pwd)/ligolo-selfcerts    # clean up the self-signed certificates
		exit;;
	*) 
		echo -e '\033[31m\n[x] Invalid option. Please select a valid option.\n\033[0m'
		return
		;;
	esac
}

# Main function
clear
# Banner
echo -e '\033[0;34m
$$\      $$\                  $$\                $$$$$$\           $$\    $$\   $$\          
$$ |     \__|                 $$ |              $$  __$$\          $$ |   $$ |  $$ |         
$$ |     $$\ $$$$$$\  $$$$$$\ $$ |$$$$$$\       $$ /  \__|$$$$$$\$$$$$$\  $$ |  $$ |$$$$$$\  
$$ |     $$ $$  __$$\$$  __$$\$$ $$  __$$\$$$$$$\$$$$$$\ $$  __$$\_$$  _| $$ |  $$ $$  __$$\ 
$$ |     $$ $$ /  $$ $$ /  $$ $$ $$ /  $$ \______\____$$\$$$$$$$$ |$$ |   $$ |  $$ $$ /  $$ |
$$ |     $$ $$ |  $$ $$ |  $$ $$ $$ |  $$ |     $$\   $$ $$   ____|$$ |$$\$$ |  $$ $$ |  $$ |
$$$$$$$$\$$ \$$$$$$$ \$$$$$$  $$ \$$$$$$  |     \$$$$$$  \$$$$$$$\ \$$$$  \$$$$$$  $$$$$$$  |
\________\__|\____$$ |\______/\__|\______/       \______/ \_______| \____/ \______/$$  ____/ 
            $$\   $$ |                                                             $$ |      
            \$$$$$$  |                                                             $$ |      
             \______/                                                              \__|      
\n\033[0m'
menu

