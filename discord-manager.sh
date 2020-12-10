#!/bin/bash

#1 - Setup vars. 
    #Get download url for latest version
    #Get filename and version number from url
    #Set Dialoog command
    #Check if Powercord (https://powercord.dev) is installed
    #Get current DIR
#2
    #Checks if Discord is installed. If it isn't asks user if it should be. Creates folders, downloads and extracts Discord to install location, moves .desktop to /usr/share/applications.
#3
    #Functionally the same as #2 but folders aren't created and .desktop file isn't moved.
#4
    #Checks if Powercord is installed. If it is, ask user if it should auto replug. Proceeds to cd to user provided Powercord install dir, plugs powercord, and returns to original directory.

#1
URL=$(curl -L --head https://discord.com/api/download/canary\?platform\=linux\&format\=tar.gz 2>/dev/null | grep location: | tail -n1 | cut -d' ' -f2 | tr -d '\r')
FILENAME=$(basename "$URL")
CURRENTVERSION=$(cat /usr/share/discord-canary/version.txt)
NEWVERSION=$(echo "$FILENAME" | grep -Po '(?<=0.0.)[^.]+')
if command -v kdialog &> /dev/null ;then
    DIALOG=kdialog
elif command -v zenity &> /dev/null ;then
    DIALOG=zenity
else
    DIALOG=dialog
fi

if cat /usr/share/discord-canary/resources/app/index.js | grep powercord ;then
    POWERCORD=1
fi

OGPWD=$(pwd)

#2
if [ ! -d "/usr/share/discord-canary/" ] ;then
    if ! "$DIALOG" --title "Discord Canary Manager" --yesno "Discord Canary is not installed\nInstall it now?" 20 60; then exit ; fi
    PASSWD=$("$DIALOG" --title "Discord Canary Manager" --password "Password required to continue" 20 60)
	echo "$PASSWD" | sudo -S mkdir -p /usr/share/discord-canary
	echo "$PASSWD" | sudo -S chmod 777 /usr/share/discord-canary
	wget -c "$URL" -P /tmp/
	if [ $? -eq 8 ] ; then
        "$DIALOG" --title "Discord Canary Manager" --error "Download failed"
        exit
    fi
	tar -C /usr/share/discord-canary/ -xzf "/tmp/$FILENAME" --strip 1
	echo "$PASSWD" | sudo -S mv /usr/share/discord-canary/discord-canary.desktop /usr/share/applications/
	echo "$NEWVERSION" > /usr/share/discord-canary/version.txt
	rm "/tmp/$FILENAME"
	"$DIALOG" --title "Discord Canary Manager" --msgbox "Discord Canary successfully installed!" 20 60
#3
elif  [ "$NEWVERSION" -gt "$CURRENTVERSION" ] ;then
    if ! "$DIALOG" --title "Discord Canary Manager" --yesno "New Discord Canary Update ($NEWVERSION)!\nInstall it now?" 20 60; then exit ; fi
    wget -c "$URL" -P /tmp/
	tar -xzf "/tmp/$FILENAME" -C /usr/share/discord-canary/ --overwrite --strip 1
	rm /usr/share/discord-canary/discord-canary.desktop
	echo "$NEWVERSION" > /usr/share/discord-canary/version.txt
	rm "/tmp/$FILENAME"
#4
	if [ "$POWERCORD" -eq 1 ] ;then
        if ! "$DIALOG" --title "Discord Canary Manager" --yesno "Powercord installation detected! Replug Powercord?" 20 60; then exit ; fi
        PCPATH=$("$DIALOG" --title "Discord Canary Manager" --inputbox "Enter the path to your Powercord installation" "/home/rose/git/powercord")
        cd "$PCPATH"
        PASSWD=$("$DIALOG" --title "Discord Canary Manager" --password "Password required to continue" 20 60)
        echo "$PASSWD" | sudo -S npm run unplug
        echo "$PASSWD" | sudo -S npm run plug
        cd "$OGPWD"
    fi
	"$DIALOG" --title "Discord Canary Manager" --msgbox "Discord Canary successfully updated!" 20 60
else
    "$DIALOG" --title "Discord Canary Manager" --msgbox "Discord Canary up to date." 20 60
fi
exit
