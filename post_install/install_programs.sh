#!/bin/bash
OUTPUT="temp.txt"

# dialog --clear --title "Okno dialogowe Checklist" --backtitle "BASH" --checklist "Twój wybór:" 10 40 3 1 "Pozycja 1" "off" 2 "Pozycja 2" "off" 3 "Pozycja 3" "off" 2> $OUTPUT

options="1 htop off \
2 bpytop off \
3 nmap off \
4 flameshot off \
5 tree off \
6 pv off \
7 unzip off \
8 synaptic off \
9 ranger off \
10 pfetch off \
11 microsoft_edge off \
12 gnome_tweaks off \
13 flatpak off \
14 tilix off \
15 fdupes off \
16 meld off \
17 unrar off \
18 minicom off \
19 git off \
20 python3 off \
21 peek off \
22 slack off \
23 sshpass off \
24 tftp off \
25 nfs off \
26 sublime_text off \
27 arduino-cli off \
28 skype off \
29 zoom off \
30 joplin off \
31 cherry-tree off \
32 fuzzy--finder off \
33 doas off \
34 nemo off"

declare -A programs
programs[1]="sudo apt install htop -y"
programs[2]="pip3 install bpytop -y"
programs[3]="sudo apt install nmap -y"
programs[4]="sudo apt install flameshot -y"
programs[5]="sudo apt install tree -y"
programs[6]="sudo apt install pv -y"
programs[7]="sudo apt install unzip -y"
programs[8]="sudo apt install synaptic -y"
programs[9]="sudo apt install ranger -y"

install_pfetch(){
    mkdir -p ~/Git/pfetch
    git clone https://github.com/dylanaraps/pfetch.git ~/Git/pfetch
}
programs[10]=install_pfetch

install_microsoft_edge(){
    doas --  apt install curl
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    doas -- install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    doas -- sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
    doas -- rm microsoft.gpg
    ## Install
    doas -- apt update
    doas -- apt install microsoft-edge-dev
}
programs[11]=install_microsoft_edge
# programs[]="sudo apt install flameshot"

install_tftp(){
    tftpd-hpa tftp-hpa -y
}
programs[24]=install_tftp

install_nfs(){
    sudo apt install nfs-kernel-server nfs-common -y
}
programs[25]=install_nfs

install_sublime_text(){
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    sudo apt-get install apt-transport-https
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    sudo apt-get update
    sudo apt-get install sublime-text
}
programs[26]=install_sublime_text

cmd=(dialog --stdout \
        --backtitle "Program Instalator" \
        --separate-output \
        # --no-items \
        # --checklist "Select options:" 40 80 35)
        --checklist "Select options:" 30 60 25)
choices=$("${cmd[@]}" ${options})
BUTTON=$?;

if [ "$BUTTON" == 0 ]; then
    clear
	echo "Installing packages"
    # sudo apt install $choices
    for choice in $choices; do
        ${programs[$choice]}
    done
    echo "Installation Complete"
fi

if [ "$BUTTON" == 1 ]; then
    clear
	echo "You choose Cancel"
fi

# echo $choices
