#!/bin/sh

# this file should be here: /usr/lib/cgi-bin/store_wifi_parameters.sh

############################################################
# GENERAZIONE FILE REVERSE_FATSCGI_PARAMS
# USATO DA NGINX PER RI-CARICARE GLI STESSI DATI SU WEBPAGE
############################################################
export DHCP="${DHCP/on/checked}"

cat <<EOT > /etc/nginx/reverse_fastcgi_params
# DO NOT EDIT, THIS FILE IS AUTOGENERATED!
set \$internetenabled "true";
set \$ssid "$SSID";
set \$pass "$PASS";
set \$dhcp "$DHCP";
set \$ipaddress "$IPADDRESS";
set \$netmask "$NETMASK";
set \$gateway "$GATEWAY";
set \$dns "$DNS";
EOT

/etc/init.d/nginx reload

############################################################
# APPLICAZIONE DATI WIFI SU OS LINUX
############################################################
update_wpa_supp() {
    local filename="$1"
    cat <<EOT > $filename
ctrl_interface=/var/run/wpa_supplicant
ap_scan=1
network={
   ssid="$SSID"
EOT

    if [[ "${#PASS}" -gt 3 ]]; then
	echo "   psk=\"$PASS\"" >> $filename
    else
	echo "   key_mgmt=NONE" >> $filename
    fi
    echo "}" >> $filename
}

update_wpa_supp "/etc/wpa_supplicant.conf"

update_start_script() {

    local filename="$1"
    cat <<EOT > $filename
#!/bin/sh
case "\$1" in
        start)
                modprobe wilc-sdio
		sh /home/root/Start_Connection.sh
                ;;
        stop)
                ifconfig wlan0 down
		modprobe -r wilc-sdio
                ;;
esac
exit 0
EOT
    chmod 755 $filename
    ln -sf $filename /etc/rc5.d/
}

if [ -n "$SSID" ]; then
update_start_script "/etc/init.d/S85start_wlan"
fi

############################################################
# APPLICAZIONE DATI ETHERNET SU OS LINUX
############################################################
update_interfaces() {
    local filename="$1"
    cat <<EOT > $filename
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)
 
# The loopback interface
auto lo
iface lo inet loopback
EOT

if [ -n "$SSID" ]; then
    cat <<EOT >> $filename
# Wireless interfaces
iface wlan0 inet dhcp
	wireless_mode managed
	wireless_essid any
	wpa-driver wext
	wpa-conf /etc/wpa_supplicant.conf

EOT
fi

##     cat <<EOT >> $filename
## iface atml0 inet dhcp
## 
## EOT

    if [[ "$DHCP" == "checked" ]]; then
    cat <<EOT >> $filename
# Wired or wireless interfaces
auto eth0
iface eth0 inet dhcp
# iface eth1 inet dhcp

EOT
    else
       if [ -n "$IPADDRESS" ]; then
    cat <<EOT >> $filename
# Wired or wireless interfaces
auto eth0
iface eth0 inet static
	address $IPADDRESS
	netmask $NETMASK
	# network 192.168.7.0
	gateway $GATEWAY

EOT
       fi
    fi

    cat <<EOT >> $filename
# Ethernet/RNDIS gadget (g_ether)
# ... or on host side, usbnet and random hwaddr
iface usb0 inet static
	address 192.168.7.2
	netmask 255.255.255.0
	network 192.168.7.0
	gateway 192.168.7.1

# Bluetooth networking
iface bnep0 inet dhcp

EOT
}

update_interfaces "/etc/network/interfaces"

update_dns() {
    local filename="$1"
    cat <<EOT > $filename
domain rgm5.it
nameserver $DNS
EOT
}

update_dns "/etc/resolv.conf"

############################################################
# GENERAZIONE RESPONSE DEBUG
############################################################
echo "HTTP/1.0 200 OK"
echo "Content-type: text/plain"
echo ""

echo "****************** /etc/nginx/reverse_fastcgi_params ********************"
cat /etc/nginx/reverse_fastcgi_params

echo ""
echo "****************** /etc/wpa_supplicant.conf ********************"
cat /etc/wpa_supplicant.conf

echo ""
echo "****************** /etc/init.d/S85start_wlan ********************"
cat /etc/init.d/S85start_wlan

echo ""
echo "****************** /etc/network/interfaces ********************"
cat /etc/network/interfaces

echo ""
echo "****************** /etc/resolv.conf ********************"
cat /etc/resolv.conf

echo ""
echo "OK"

###########################################################

ln -sf /home/root/Start_STA.sh /home/root/Start_Connection.sh

###########################################################
# method1: apply changes on the fly
if [ -v APPLY_NETWORK_CONFIGURATION ]; then
   if [ -n "$SSID" ]; then
      # sh /home/root/Start_Provision.sh # START ACCESS POINT wilc1000_SoftAP
      /etc/init.d/S85start_wlan start
   fi

   # APPLY NETWORK CHANGES
   /etc/init.d/networking restart

   sh /home/root/Start_Connection.sh 
else
   #method2 reboot
   reboot
fi

