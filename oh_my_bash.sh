#!/bin/bash
# Installing Oh My Bash
function print_message {
	echo -e "############################################\n# $BOLD$GREEN $1: $RESET\n############################################"
}

function install_message {
	echo -e "############################################\n# $BOLD$BLUE Installing: $1: $RESET\n############################################"
}

install_message "Cloning: Oh My Bash"
sh -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"

print_message "Done"