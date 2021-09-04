#!/bin/bash

OUTPUT="temp.txt"
LOGS="logs.txt"
# dialog --clear --title "Okno dialogowe Checklist" --backtitle "BASH" --checklist "Twój wybór:" 10 40 3 1 "Pozycja 1" "off" 2 "Pozycja 2" "off" 3 "Pozycja 3" "off" 2> $OUTPUT

VERBOSE=true

if [ ! -f "/usr/bin/dialog" ]; then
    echo "DIALOG NOT FOUND!"
    echo "Installing dialog"
    sleep 2
    sudo apt install dialog
fi

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
34 nemo off \
35 dropbox off \
36 vim off \
37 lxappearance off \
38 xrog off \
39 conky off \
40 discord off \
41 neofetch off \
42 psmisc off \
43 feh off \
44 zsh off \
100 additional off"

declare -A programs
programs[1]="sudo apt install htop -y"
programs[2]="pip3 install bpytop"
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
    echo "alias pfetch='~/Git/pfetch/pfetch'" >> ~/.zshrc
    echo "alias pfetch='~/Git/pfetch/pfetch'" >> ~/.bashrc
}
programs[10]=install_pfetch

install_microsoft_edge(){
    sudo  apt install curl
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
    sudo rm microsoft.gpg
    ## Install
    sudo apt update
    sudo apt install microsoft-edge-dev
}
programs[11]=install_microsoft_edge
# programs[]="sudo apt install flameshot"

install_gnome_tweaks(){
    sudo apt install gnome-tweaks -y
}
programs[12]=install_gnome_tweaks

install_flatpak(){
    sudo apt install flatpak -y
}
prigrams[13]=install_flatpak

install_tilix(){
    sudo apt install tilix -y
    git clone https://github.com/MichaelThessel/tilix-gruvbox.git ~/Git/tilix-gruvbox 
    sudo cp ~/Git/tilix-gruvbox/gruvbox-* /usr/share/tilix/schemes
    rm -rf ~/Git/tilix-gruvbox
}
programs[14]=install_tilix

install_fdupes(){
    sudo apt install fdupes
}
programs[15]=install_fdupes

install_meld(){
    sudo apt install meld -y
}
programs[16]=install_meld

install_unrar(){
    sudo apt install unrar -y
}
programs[17]=install_unrar

install_minicom(){
    sudo apt install minicom -y
}
programs[18]=install_minicom

install_git(){
    sudo apt install git -y
    git config --global user.name "Adam Walkiewicz"
    git config --global user.email "aj.walkiewicz@gmail.com"
}
programs[19]=install_git

install_python3(){
    sudo apt install python3 python3-pip python3-venv -y
}
programs[20]=install_python3

install_peek(){
    sudo apt install peek -y
}
programs[21]=install_peek

install_slack(){
    #to do
    echo "dummy install slack"
}
programs[22]=install_slack

install_ssh(){
    sudo apt install openssh sshpass -y
}
programs[23]=install_ssh

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

install_arduino_cli(){
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
}
programs[27]=install_arduino_cli

install_skype(){
    flatpak install -y skype
}
programs[28]=install_skype

install_zoom(){
    flatpak install -y zoom
}
programs[29]=install_zoom

install_joplin(){
    wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
}
programs[30]=install_joplin

install_cherry_tree(){
    #to do
    echo "dummy install cherry tree"
}
programs[31]=install_cherry_tree

install_fuzzy_finder(){
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
}
programs[32]=install_fuzzy_finder

install_doas(){
    apt install build-essential make bison flex libpam0g-dev -y 
    git clone https://github.com/slicer69/doas.git ~/Git/doas
    cd ~/Git/doas
    make install
    mkdir /usr/local/etc/
    echo "permit nopass $USER as root" > /usr/local/etc/doas.conf
    cd ~/
}
programs[33]=install_doas

install_nemo(){
    sudo apt install nemo -y
}
programs[34]=install_nemo

install_dropbox(){
    cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
    cd -
}
programs[35]=install_dropbox

install_vim(){
    sudo apt install vim -y
    # coping files from github
    cp -r ~/Git/config-files/vim ~/.vim
    cp ~/Git/config-files/dot_files/vimrc ~/.vimrc

    # Install Vundle - plugin manager
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    # To do:
    # Tag bar config - require 
    sudo apt update 
    sudo apt install \
    gcc make \
    pkg-config autoconf automake \
    python3-docutils \
    libseccomp-dev \
    libjansson-dev \
    libyaml-dev \
    libxml2-dev
    git clone https://github.com/universal-ctags/ctags.git ~/Git/ctags
    cd ~/Git/ctags
    ./autogen.sh
    ./configure # defaults to /usr/local
    make
    sudo make install # may require extra privileges depending on where to install
    cd ~/
}
programs[36]=install_vim

install_lxappearance(){
    sudo apt install lxappearance -y
}
programs[37]=install_lxappearance

install_xorg(){
    sudo apt install xorg -y
}
programs[38]=install_xorg

install_conky(){
    sudo apt install conky -y
}
programs[39]=install_conky

install_discord(){
    sudo apt install discord -y
}
programs[40]=install_discord

install_neofetch(){
    sudo apt install neofetch -y
}
programs[41]=install_neofetch

install_psmisc(){
    sudo apt install psmisc -y
}
programs[42]=install_psmisc

install_feh(){
    sudo apt install feh -y
}
programs[43]=install_feh

install_zsh(){
    # https://www.howtoforge.com/tutorial/how-to-setup-zsh-and-oh-my-zsh-on-linux/

    sudo apt install zsh -y

    # Setting ZSH as a default shell for root
    sudo chsh -s /usr/bin/zsh $USER

    echo $SHELL

    # Installing zsh-syntax-highlightning
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # Installing zsh autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    # Installing powerline 10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
}

install_additional(){
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
    gsettings set org.cinnamon.desktop.default-applications.terminal exec tilix
    mkdir -p ~/.gnome2/accels
    touch ~/.gnome2/accels/nemo
    nemo &
    echo '(gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")' >> ~/.gnome2/accels/nemo
}
programs[100]=install_additional

cmd=(dialog --stdout \
        --backtitle "Program Instalator" \
        --separate-output \
        --checklist "Select options:" 30 60 25)
choices=$("${cmd[@]}" ${options})
BUTTON=$?;

if [ "$BUTTON" == 0 ]; then
    clear
    # sudo apt install $choices
    echo "Updating repositories"
    sleep 2
    sudo apt update && sudo apt upgrade -y

    echo "Installing required packages"
    sleep 2
    mkdir -p ~/Git
    sudo apt install git wget flatpak

    echo "Installing packages"
    sleep 2
    len=$(echo $choices | wc -w) 
    step=$(( 100 / $len ))
    progress=$step
    for choice in $choices; do
        ${programs[$choice]} &>> $LOGS
        ( 
            echo $progress
        ) | dialog --title "Installing Packages" --gauge "Please wait..." 10 60 0
        progress=$(( $progress + $step ))
    done

    dialog --title "Installing Completed" --yesno "Installation finished.\nWould you like to reboot your device?" 7 0 && sync; sleep 5; sudo reboot

    # echo "Installation Complete"
fi

if [ "$BUTTON" == 1 ]; then
    clear
	echo "You choose Cancel"
fi
