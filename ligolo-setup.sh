#/bin/bash
# Author: retr0	
# Date: 2024-12-15
# Description: Setup ligolo	proxy
# Usage: ./ligolo-setup.sh
# Version: 2.0

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

add_link(){
    exp=$(ip -br a | grep lig)
    verify=$(ip link show | grep lig)
    
    num_interfaces=$(echo "$exp" | wc -l)

    if [ "$num_interfaces" -ge 2 ]; then
        clear
        echo -e '\033[31m[x] Cannot add more than 2 ligolo interfaces\n\033[0m'
        return
    fi

    if echo "$verify" | grep -q "ligolo"; then
        clear
        echo -e '\033[31m[x] ligolo/lig interface already exists\n\033[0m'
        
        # Prompt user if they want to create ligolo2
        echo -ne "\033[0;33m[?] Do you want to create ligolo2 instead? (\033[0;32my/n\033[0;33m): \033[0m"
        echo -ne "\033[0;32m"
        read confirmation
        echo -ne "\033[0m"
        
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            # Check if ligolo2 already exists
            if ip -br a | grep -q "ligolo2"; then
                echo -e '\033[31m[x] ligolo2 interface already exists\n\033[0m'
            else
                # Create ligolo2 interface
                sudo ip tuntap add user $USER mode tun ligolo2
                sudo ip link set ligolo2 up
                echo -e '\033[0;32m[+] ligolo2 interface created successfully!\n\033[0m'
                ip -br a | grep lig | xargs -I {} echo -e "\033[0;32m{}\n\033[0m"
            fi
        elif [[ "$confirmation" =~ ^[Nn]$ ]]; then
            echo -e '\033[0;33m[!] Interface creation cancelled by user.\n\033[0m'
        else
            echo -e '\033[0;31m[X] Invalid input. Please enter y/n to confirm.\n\033[0m'
        fi
    elif [ -z "$verify" ]; then
        clear
        # Ask the user if they want to create the ligolo interface
        echo -en "\033[0;34m[?] Do you want to create the ligolo interface? (\033[0;32my/n\033[0;34m): "
        echo -en "\033[0;32m"
        read answer
        echo -ne "\033[0m"

        case $answer in
            [Yy])
                sudo ip tuntap add user $USER mode tun ligolo
                sudo ip link set ligolo up
                echo -ne '\033[0;32m[+] ligolo interface added successfully!\n\033[0m'
                ip -br a | grep lig | xargs -I {} echo -e "\033[0;32m{}\n\033[0m"
                ;;
            [Nn])
                echo -e "\033[0;33m[-] ligolo interface not created.\n\033[0m"
                ;;
            *)
                echo -e "\033[0;31m[X] Invalid response. Please answer with 'y' or 'n'.\n\033[0m"
                ;;
        esac
    fi

}

# Delete a tuntap interface
delete_link(){
    interfaces=$(ip -br a | grep lig | awk '{print $1}')
    if [ -z "$interfaces" ]; then
        echo -e '\033[0;31m[x] ligolo/lig interfaces do not exist\n\033[0m'
        echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
    else
        interface_count=$(echo "$interfaces" | wc -l)
        
        if [ "$interface_count" -eq 1 ]; then
            clear
            echo -e "\033[0;32m[+] Only one interface found: $interfaces\n\033[0m"
        elif [ "$interface_count" -eq 2 ]; then
            clear
            echo -en "\033[0;32m[+] Two interfaces found: \033[0;32m\n"
            for interface in $interfaces; do
              echo -en "\t- $interface\n"
            done
            echo -en "\033[0m"
        fi        
        # Ask the user for confirmation
        echo -ne "\033[0;33m[?] Do you really want to delete the above interface(s)? All will be deleted! (\033[0;32my/n\033[0;33m): \033[0m"
        echo -ne "\033[0;32m"
        read confirmation
        echo -ne "\033[0m"
        
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            for iface in $interfaces; do
                sudo ip link delete $iface 2>/dev/null
            done
            echo -e "\033[0;32m[+] All ligolo interfaces deleted successfully!\n\033[0m"
        elif [[ "$confirmation" =~ ^[Nn]$ ]]; then
            echo -e '\033[0;33m[!] Interface deletion cancelled by user.\n\033[0m'
        else
            echo -e '\033[0;31m[X] Invalid input. Please enter y/n to confirm.\n\033[0m'
        fi
    fi
}

# Add a new route to the existing tuntap interface
add_route(){
    echo -en '\n'
    DEVICES=$(ip -br a | grep lig | awk '{print $1}')
    
    if [ -z "$DEVICES" ]; then
        clear
        echo -e '\033[0;31m[x] ligolo/lig interface does not exist\n\033[0m'
        echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
        menu
    else
        clear
        if [ $(echo "$DEVICES" | wc -l) -gt 1 ]; then
            echo -e '\033[0;33m[+] Multiple ligolo interfaces found:\n\033[0m'
            echo "$DEVICES" | nl  # List interfaces with numbers
            echo -ne '\n\033[0;34m[?] Select the interface to add the route to (enter the number): \033[0m'
            echo -ne "\033[0;32m"
            read interface_choice
            echo -ne "\033[0m"

            if ! [[ "$interface_choice" =~ ^[0-9]+$ ]] || [ "$interface_choice" -lt 1 ] || [ "$interface_choice" -gt $(echo "$DEVICES" | wc -l) ]; then
                echo -e '\033[0;31m[X] Invalid choice! Please select a valid number.\n\033[0m'
                add_route
                return
            fi
            selected_interface=$(echo "$DEVICES" | sed -n "${interface_choice}p")
        else
            selected_interface=$(echo "$DEVICES" | head -n 1)
        fi

        clear
        echo -e "\033[0;32m[+] Adding route to $selected_interface...\033[0m"
        
        while true; do
            echo -ne '\n\033[0;34m[>>] Enter the route here [eg: 0.0.0.0/24] (Press \033[0;32mq/Q\033[0;34m to cancel): \033[0m'
            echo -ne "\033[0;32m"
            read addedroute
            echo -ne "\033[0m"

            if [[ "$addedroute" =~ ^[Qq]$ ]]; then 
                echo -e "\033[0;33m[-] Exiting route input process...\n\033[0m"
                return
            fi

            # Validate the CIDR format
            if validate_cidr "$addedroute"; then
                echo -ne '\033[0;34m[?] Do you want to add this route: [\033[0;32m'"$addedroute"'\033[0;34m]? (\033[0;32my/n\033[0;34m): \033[0m'
                echo -ne "\033[0;32m"
                read confirmation
                echo -ne "\033[0m"

                if [[ "$confirmation" =~ ^[Yy]$ ]]; then
                    output=$(sudo ip route add "$addedroute" dev "$selected_interface" 2>&1)

                    if [[ $? -eq 0 ]]; then
                        echo -e "\033[0;32m\n[+] Success: Route added successfully!\n\n\033[0;34m[*] Here is the newly added route: \033[0m"
                        ip route | grep "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m\n"
                    else
                        echo -e "\033[0;31m[x] Error adding route: $output\033[0m"
                    fi
                    break
                else
                    echo -e "\033[0;33m[-] Route addition cancelled by user.\n\033[0m"
                fi
            else
                echo -en '\033[31m\n[X] Invalid CIDR notation. Please enter a valid IP in the format 0.0.0.0/24.\n\033[0m'
            fi
        done
    fi
}

delete_route() {
    echo -en '\n'
    DEVICES=$(ip -br a | grep lig | awk '{print $1}')

    if [ -z "$DEVICES" ]; then
        clear
        echo -e '\033[0;31m[x] ligolo/lig interface does not exist\n\033[0m'
        echo -e "\033[38;5;214m[-] Make sure you have created a new tuntap interface first.\n\033[0m"
        menu
    else
        clear
        if [ $(echo "$DEVICES" | wc -l) -gt 1 ]; then
            echo -e '\033[0;33m[+] Multiple ligolo interfaces found:\n\033[0m'
            echo "$DEVICES" | nl  # List interfaces with numbers
            echo -ne '\n\033[0;34m[?] Select the interface to delete the route from (enter the number): \033[0m'
            echo -ne "\033[0;32m"
            read interface_choice
            echo -ne "\033[0m"

            if ! [[ "$interface_choice" =~ ^[0-9]+$ ]] || [ "$interface_choice" -lt 1 ] || [ "$interface_choice" -gt $(echo "$DEVICES" | wc -l) ]; then
                echo -e '\033[0;31m[X] Invalid choice! Please select a valid number.\n\033[0m'
                delete_route
                return
            fi
            selected_interface=$(echo "$DEVICES" | sed -n "${interface_choice}p")
        else
            selected_interface=$(echo "$DEVICES" | head -n 1)
        fi
        clear
        echo -e "\033[0;32m[+] Deleting route from $selected_interface...\033[0m"

        routes=$(ip route show dev "$selected_interface")

        if [ -z "$routes" ]; then
            echo -e "\033[0;33m\n[-] No routes found for the interface $selected_interface.\n\033[0m"
            return
        fi

        echo "$routes" | nl
        echo -ne '\033[0;34m[>>] Enter the number of the route to delete (or type \033[0;32mq \033[0;34mor \033[0;32mQ\033[0;34m to cancel): \033[0m'
        echo -ne "\033[0;32m"
        read route_choice
        echo -ne "\033[0m"

        if [[ "$route_choice" =~ ^[Qq]$ ]]; then
            echo -e "\033[0;33m[-] Exiting route deletion process...\033[0m"
            return
        fi

        if ! [[ "$route_choice" =~ ^[0-9]+$ ]] || [ "$route_choice" -lt 1 ] || [ "$route_choice" -gt $(echo "$routes" | wc -l) ]; then
            echo -e '\033[0;31m[X] Invalid choice! Please select a valid route number.\n\033[0m'
            delete_route
            return
        fi

        route_to_delete=$(echo "$routes" | sed -n "${route_choice}p")
        route_cidr=$(echo "$route_to_delete" | awk '{print $1}')

        # Delete the route using the CIDR only
        if [ -n "$route_cidr" ]; then
            echo -ne "\n\033[0;34m[?] Do you want to delete this route: \033[0;32m$route_cidr\033[0;34m? (\033[0;32my/n\033[0;34m): \033[0m"
            echo -ne "\033[0;32m"
            read confirmation
            echo -ne "\033[0m"

            if [[ "$confirmation" =~ ^[Yy]$ ]]; then
                sudo ip route del "$route_cidr"

                if [ $? -eq 0 ]; then
                    echo -e "\033[0;32m\n[+] Success: Route deleted successfully!\n\033[0m"
                    ip route show dev "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m"
                else
                    echo -e "\033[0;31m[x] Error deleting route: $route_cidr\n\033[0m"
                fi
            else
                echo -e "\033[0;33m[-] Route deletion cancelled by user.\n\033[0m"
            fi
        else
            echo -e "\033[0;31m[X] Invalid route format, missing CIDR.\n\033[0m"
            delete_route
        fi
    fi
}

# show information about the existing ligolo interfaces
get_info(){
    interfaces=$(ip -br a | grep lig | awk '{print $1}')
    
    if [ -z "$interfaces" ]; then
        echo -e '\033[0;31m[x] ligolo/lig interface does not exist\n\033[0m'
        echo -e "\033[38;5;214m[-] Can't get the information. Please create a new tuntap interface first.\n\033[0m"
    else
        num_interfaces=$(echo "$interfaces" | wc -l)

        if [ "$num_interfaces" -gt 1 ]; then
            echo -e '\033[0;33m[*] Multiple ligolo interfaces found:\n\033[0m'
            echo "$interfaces" | nl  # List interfaces with numbers
            echo -ne '\n\033[0;34m[?] Select the interface to get information about (enter the number): \033[0m'
            echo -ne "\033[0;32m"
            read interface_choice
            echo -ne "\033[0m"

            # Check if the input is a valid number
            if ! [[ "$interface_choice" =~ ^[0-9]+$ ]] || [ "$interface_choice" -lt 1 ] || [ "$interface_choice" -gt "$num_interfaces" ]; then
                echo -e '\033[0;31m[X] Invalid choice! Please select a valid number.\n\033[0m'
                get_info
                return
            fi
            
            selected_interface=$(echo "$interfaces" | sed -n "${interface_choice}p")
            echo -e "\033[0;34m\n[*] Interface $selected_interface Information:\n\033[0m"
            ifconfig "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m"
            
            routes=$(ip route show dev "$selected_interface")
            if [ -n "$routes" ]; then
                echo -e "\033[0;34m\n[*] Routes for $selected_interface:\n\033[0m"
                ip route show dev "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m\n"
            else
                echo -e "\n\033[0;33m[-] No routes found for $selected_interface.\n\033[0m"
            fi
        else
            selected_interface=$(echo "$interfaces" | head -n 1)
            echo -e "\033[0;34m\n[*] Interface $selected_interface Information:\n\033[0m"
            ifconfig "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m"

            routes=$(ip route show dev "$selected_interface")
            if [ -n "$routes" ]; then
                echo -e "\033[0;34m\n[*] Routes for $selected_interface:\n\033[0m"
                ip route show dev "$selected_interface" | xargs -I {} echo -e "\033[0;32m{}\033[0m\n"
            else
                echo -e "\n\033[0;33m[-] No routes found for $selected_interface.\n\033[0m"
            fi
        fi
    fi
    menu
}

start_proxy(){
    exp=$(which ligolo-proxy 2>/dev/null | head -n 1)
    
    DEVICES=$(ip -br a | grep lig | awk '{print $1}')
    
    if [ -z "$DEVICES" ]; then
        echo -e '\033[0;31m[X] ligolo/lig interface does not exist.\n\033[0m'
        echo -e "\033[38;5;214m[X] Can't start the proxy. Please create a new tuntap interface first.\n\033[0m"
        menu
        return
    fi
    
    if [ "$(echo "$DEVICES" | wc -l)" -gt 1 ]; then
        echo -e "\033[0;34m[?] Multiple ligolo interfaces found.\n[>>] Please select the interface to start the proxy on (or type \033[0;32m3\033[0;34m to quit):\033[0m"
        select selected_interface in $DEVICES "Quit"; do
            if [[ "$selected_interface" == "Quit" ]]; then
                echo -e "\n\033[0;33m[-] Exiting proxy setup...\033[0m\n"
                menu
                return
            elif [[ -n "$selected_interface" ]]; then
                break
            else
                echo -e '\n\033[0;31m[X] Invalid selection. Please select a valid interface or \033[0;32m"type 3"\033[0;31m to exit.\n\033[0m\n'
            fi
        done
    else
        selected_interface="$DEVICES"
    fi
    
    # Check if routes are present for the selected interface
    routes=$(ip route | grep "$selected_interface")
    
    if [ -z "$routes" ]; then
        echo -e "\033[0;31m[X] No routes found on the selected \033[0;32m$selected_interface\033[0;31m interface!\n\033[0m"
        echo -e "\033[38;5;214m[-] Please add a route to the interface before starting the proxy.\n\033[0m"
        menu
        return
    fi

    # If the ligolo-proxy binary is found, proceed to start it
    if [ -z "$exp" ]; then
        echo -e '\033[0;31m[X] ligolo-proxy binary not found!\n\033[0m'
        echo -e "\033[38;5;214m[X] Please install ligolo-proxy first.\n\033[0m"
        menu
        return
    else
        echo -e '\n\033[0;32m[+] ligolo-proxy binary found!\n\033[0m'
        echo -e "\033[0;32m[+] Starting ligolo-proxy...\n\033[0m"
        $exp -selfcert
    fi
}

quit(){
    echo -en '\033[0;34m[?] Do you really want to Quit ? (\033[0;32my/n\033[0;34m): \033[0m'
    echo -en "\033[0;32m"
    read confirmation
    echo -en "\033[0m"

    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        echo -e '\n\033[0;33m[+] Exiting...See ya! \033[0m'
        # Check if ligolo-selfcerts exists before cleaning
        if [ -d "$(pwd)/ligolo-selfcerts" ]; then
            echo -e "\033[38;5;214m\n[*] Cleaning up...[*]\n\033[0m"
            rm -vrf $(pwd)/ligolo-selfcerts    
            echo -e "\033[32m\n[*] Selfcerts cleaned up successfully! [*]\n\033[0m"
        fi
        exit
    else
        echo -e '\n\033[0;33m[!] Exit cancelled by user.\n\033[0m'
    fi
}

Banner(){
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
}

# menu function
menu(){
	while true; do
		echo -e '\033[0;34mWhat do you want to do ?\n\n\t\033[0;32m[1] \033[0;34mAdd a new tuntap interface: \n\t\033[0;32m[2] \033[0;34mDelete a tuntap interface: \n\t\033[0;32m[3] \033[0;34mAdd a new route: \n\t\033[0;32m[4] \033[0;34mDelete a route: \n\t\033[0;32m[5] \033[0;34mStart ligolo-proxy: \n\033[0m'
		echo -e '\033[0;34mPress \033[0;32m[i or I]\033[0;34m to verify the `ligolo` interface\nPress \033[0;32m[c or C]\033[0;34m to clear the screen\nPress \033[0;32m[q or Q]\033[0;34m to quit and Ctrl+C to stop the script\033[0m\n'
		echo -ne '\033[0;34mSelect an option: \033[0m'
        echo -ne "\033[0;32m"
		read option
        echo -ne "\033[0m"

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
			delete_route
            menu
			;;
		5) 
            clear
			start_proxy
            clear
            echo -e "\033[0;32m[+] ligolo-proxy exited successfully!\n\033[0m"
            ;;
        [cC])
            clear
            Banner
            menu
            ;;  
		[iI]) 
            clear
			echo -e '\033[0;34m\n[+] Interface information:\n    ----------------------\033[0m'
			get_info
			menu
			return
			;;
		[qQ]) 
            clear
            quit
            ;;
		*) 
			echo -e '\033[31m\n[X] Invalid option. Please select a valid one.\n\033[0m'
			continue
			;;
		esac
	done
}

# Main function
clear
Banner
menu