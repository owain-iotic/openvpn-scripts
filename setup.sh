#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then echo 'Please run as root.' >&2; exit 1; fi


if [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE

    echo "detected: $OS $VER"

    apt-get update -y 
    apt-get install -y openvpn

    cd update-systemd-resolved
    make 
    systemctl enable systemd-resolved.service
    systemctl start systemd-resolved.service
    mv /etc/openvpn/update-resolv-conf /etc/openvpn/update-resolv-conf.owain
    ln -s /etc/openvpn/scripts/update-systemd-resolved /etc/openvpn/update-resolv-conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    backup_name=$(date +'%Y-%m-%d-%H%M%S')
    echo "backup nsswitch.conf"

    cp /etc/nsswitch.conf "/etc/nsswitch.conf.bak-$backup_name"

    echo "update nsswitch.conf"
    sed 's/hosts:/#hosts:/g' "/etc/nsswitch.conf.bak-$backup_name" > /etc/nsswitch.conf
    echo "# Use /etc/resolv.conf first, then fall back to systemd-resolved" >> /etc/nsswitch.conf
    echo "hosts: files dns resolve myhostname" >> /etc/nsswitch.conf 
    echo "# Use systemd-resolved first, then fall back to /etc/resolv.conf" >> /etc/nsswitch.conf 
    echo "# hosts: files resolve dns myhostname" >> /etc/nsswitch.conf 
    echo "# Don't use /etc/resolv.conf at all" >> /etc/nsswitch.conf 
    echo "# hosts: files resolve myhostname" >> /etc/nsswitch.conf 


elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
    echo "debian detected: $OS $VER not done the work on this yet..." && exit 1 
elif [ -f /etc/SuSe-release ]; then
    echo "suse detected: $OS $VER not done the work on this yet..." && exit 1
elif [ -f /etc/redhat-release ]; then
    echo "rh detected: $OS $VER not done the work on this yet..." && exit 1 
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
    echo "fb detected: $OS $VER not done the work on this yet..." && exit 1 
fi


exit 0 





