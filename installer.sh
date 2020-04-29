#!/bin/bash

install(){
	echo "Installing to /bin"
	sudo ln -s $PWD/indihome.sh /bin/indihome
}

uninstall(){
	echo "Removing /bin/indihome"
	sudo unlink /bin/indihome
}

case "$1" in
	i | install)
		install
	;;
	u | uninstall)
		uninstall
	;;
	*)
		echo Usage: "$0 [ i | install ] | [u | uninstall ]"
		exit 1
	;;
esac
