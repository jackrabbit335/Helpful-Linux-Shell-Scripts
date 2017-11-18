#!/bin/bash

#This refreshes systemd in case of failed or changed units
sudo systemctl daemon-reload

#This will try to ensure you have a strong network connection
for c in computer;
do 
	ping -c4 google.com 
	if [ $? -eq 0 ]
	then 
		echo "Connection successful"
	else
		interface=$(ip -o -4 route show to default | awk '{print $5}')
		sudo dhclient -v -r && sudo dhclient
		sudo systemctl stop NetworkManager.service
		sudo systemctl disable NetworkManager.service
		sudo systemctl enable NetworkManager.service
		sudo systemctl start NetworkManager.service
		sudo ip link set $interface up #Refer to networkconfig.log
	fi
done 

#This will reload the firewall to ensure it's enabled
sudo ufw reload

#This will clean the cache
sudo rm -r .cache/*
sudo rm -r .thumbnails/*
sudo rm -r ~/.local/share/Trash
sudo rm -r ~/.nv/*
sudo rm -r ~/.local/share/recently-used.xbel
sudo rm -r /tmp/* 
find ~/Downloads/* -type f -mtime +1 -exec rm {} \; #Deletes contents older than one day
history -c && history -w

#This could clean your Video folder and Picture folder based on a set time
TRASHCAN=~/.local/share/Trash/
find ~/Video/* -mtime +30 -exec mv {} $TRASHCAN \; #throws away month old content
find ~/Pictures/* -mtime +30 -exec mv {} $TRASHCAN \;#The times can be changed

#Sometimes it's good to check for and remove broken symlinks
find -xtype l -delete

#clean some unneccessary files leftover by applications in home directory
find $HOME -type f -name "*~" -print -exec rm {} \;

#Optionally, you can remove old backups to make room for new ones
find /Backups/* -mtime +30 -exec rm {} \;
 
#This helps get rid of old archived log entries
sudo journalctl --vacuum-size=25M

#This will remove orphan packages from pacman 
sudo pacman -Rsn --noconfirm $(pacman -Qqdt)

#Optional This will remove the pamac cached applications and older versions
sudo pacman -Sc --noconfirm

#This will ensure you are up to date and running fastest mirrors 
sudo pacman-mirrors -g
sudo pacman -Syyu --noconfirm
sudo pacman-optimize && sync

#This refreshes index cache
sudo updatedb && sudo mandb 

#update the grub 
sudo grub-mkconfig -o /boot/grub/grub.cfg

#This runs a disk checkup and attempts to fix filesystem
sudo touch /forcefsck 

#This will create a backup of your system
echo "Would you like to make a backup? (Y/n)"
read answer
if [[ $answer == Y ]];
then 
	sudo rsync -aAXv --exclude=dev --exclude=proc --exclude=Backups --exclude=Music --exclude=sys --exclude=tmp --exclude=run --exclude=mnt --exclude=media --exclude=lost+found / /Backups
else 
	echo "It is a good idea to create a backup after such changes, maybe later."
fi

#Optional and prolly not needed
sudo e4defrag / -c > fragmentation.log

#This will reboot the system
sudo systemctl reboot