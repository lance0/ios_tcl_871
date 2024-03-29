ios_config "service password-encryption"
ios_config "no service config"
ios_config "line con 0" "logging synchronous"
puts -nonewline "Please enter the hostname of this box: "
flush stdout
set hostname [ gets stdin ]
puts -nonewline "Please enter the domain name of this box: "
flush stdout
set domain [ gets stdin ]
ios_config "ip domain name $domain"
ios_config "hostname $hostname"
ios_config "logging buffered 25000"
ios_config "ip cef"
ios_config "no ip domain lookup"
ios_config "no ip http server"
ios_config "aaa new-model"
ios_config "aaa authentication login default local"
puts -nonewline "Please enter the username you would like to configure for this system: "
flush stdout
set username [ gets stdin ]
puts -nonewline "Please enter the password for $username: "
flush stdout
set password [ gets stdin ]
ios_config "username $username privilege 15 password $password"
puts -nonewline "Please enter the enable password: "
flush stdout
set enable [ gets stdin ]
ios_config "enable secret $enable"
puts -nonewline "Please enter the WAN IP address: "
flush stdout
set wan_ip [ gets stdin ]
puts -nonewline "Please enter the WAN netmask: " 
flush stdout
set wan_netmask [ gets stdin ]
ios_config "interface FastEthernet4" "ip address $wan_ip $wan_netmask"
ios_config "interface FastEthernet4" "no shutdown"
puts -nonewline "Please enter the default gateway IP address: "
flush stdout
set def_gw [ gets stdin ]
ios_config "ip route 0.0.0.0 0.0.0.0 $def_gw"
puts -nonewline "Please enter the LAN IP address: "
flush stdout
set lan_ip [ gets stdin ]
puts -nonewline "Please enter the LAN netmask: " 
flush stdout
set lan_netmask [ gets stdin ]
ios_config "interface vlan 1" "shutdown"
ios_config "vlan 55" "name Local"
ios_config "interface vlan 55" "ip address $lan_ip $lan_netmask"
ios_config "interface vlan 55" "no shutdown"
ios_config "interface range FastEthernet 0 - 3" "switchport mode access"
ios_config "interface range FastEthernet 0 - 3" "switchport access vlan 55"
puts "Configuring the DHCP service..."
puts -nonewline "Please enter the DNS Server IP address:"
flush stdout
set dns_ip [ gets stdin ]
puts -nonewline "Please enter the excluded IP address from DHCP assignments - separated by spaces "
flush stdout
set excluded [ gets stdin ]
foreach i $excluded {
        ios_config "ip dhcp excluded-address $i"
}
ios_config "ip dhcp pool DHCP" "network $lan_ip $lan_netmask"
ios_config "ip dhcp pool DHCP" "default-route $lan_ip"
ios_config "ip dhcp pool DHCP" "dns-server $dns_ip"
puts "Configuring NAT ..."
set netmask_oct [split $lan_netmask "."]
foreach j $netmask_oct {
        set wildcard_o [expr {255 - $j}]
        lappend wildcard $wildcard_o
        }
set wildcard_o [split $wildcard " "]
set wildcard_o1 [lindex $wildcard_o 0]
set wildcard_o2 [lindex $wildcard_o 1]
set wildcard_o3 [lindex $wildcard_o 2]
set wildcard_o4 [lindex $wildcard_o 3]
set wildcard_mask "$wildcard_o1.$wildcard_o2.$wildcard_o3.$wildcard_o4"
ios_config "access-list 1 permit $lan_ip $wildcard_mask"
ios_config "ip nat inside source list 1 interface FastEthernet4 overload"
ios_config "interface FastEthernet4" "ip nat outside"
ios_config "interface Vlan 55" "ip nat inside"
puts "Activating SSH ..."
ios_config "line vty 0 4" "transport input ssh"
ios_config "crypto key generate rsa general-keys modulus 1024"
ios_config "ip ssh version 2"
ios_config "ntp server 64.6.144.6"
puts -nonewline {Please enter your timezone [ eg. UTC +2 ]:}
flush stdout
set tzone [ gets stdin ]
ios_config "clock timezone $tzone"
puts "Done...Your box is waiting for some packets!"
