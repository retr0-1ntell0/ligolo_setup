#/bin/bash
# Author: retr0	
# Date: 2023-05-01
# Description: Setup ligolo	proxy
# Usage: ./ligolo-setup.sh
# Version: 1.0

# retrieve the existing tuntap interface
exp=$(ip -br a | grep 'lig*')

# Add a new tuntap interface
add_link(){
	if [[ $exp == *"lig"* ]]; then
		echo 'ligolo/lig interface already exists'
	else
		sudo ip tuntap add user $USER mode tun ligolo
		sudo ip link set ligolo up
		echo -n -e 'ligolo/lig interface created successfully! \n'
		ip -br a | grep 'lig*'
		echo -e -n '\n\n'
	fi
}

# Delete a tuntap interface
delete_link(){
	if [[ $exp != *"lig"* ]]; then
		echo 'ligolo/lig interface does not exists'
	else
		sudo ip link delete ligolo
		echo -n -e 'ligolo/lig interface deleted successfully! \n'
		ip -br a | grep 'lig*'
		echo -e -n '\n\n'
	fi
}

# menu function
menu(){
	echo -n -e 'What do you want to do ?\n\n1. For a new tuntap interface: \n2. To delete a tuntap interface: \n'
	read -p 'Select an option: ' option

	case $option in
	1) add_link;;
	2) delete_link;;
	*) 
		echo 'Invalid option. Please select a valid option.'
		menu
		return
		;;
	esac
}

# Main function
menu

