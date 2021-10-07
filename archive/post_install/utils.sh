#!/bin/bash
GREEN="\033[1;32m"
BLUE="\033[1;34m"
BOLD="\033[1m"
RESET="\033[0m"

function print_message {
	echo -e "$BOLD$GREEN $1: $RESET\n"
}

function install_message {
	echo -e "$BOLD$BLUE Installing: $1: $RESET\n"
}
