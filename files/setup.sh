#!/bin/bash

set -e

echo "[CHROOT] Starting setup script for Gentoo."
echo "---> this script is run as root from inside the chroot jail."
echo ""
echo "[CHROOT] Syncing portage tree"
emerge --sync
echo "[CHROOT] Updating packages if needed"
emerge --update --newuse --with-bdeps=y --deep --keep-going @world

echo "[CHROOT] Installing layman"
if [[ $(emerge -p --quiet layman 2>/dev/null | grep -i layman | grep -i ebuild | cut -d" " -f4) != "R" ]]; then
	emerge layman
else
	echo "[CHROOT] Skipping since layman is already installed"
fi

echo "[CHROOT] Adding 'greatspn-overlay' and syncing"
if [[ -z $(layman -l | grep -i greatspn-overlay) ]]; then
	layman -k -o https://raw.githubusercontent.com/GallaFrancesco/greatspn-overlay/master/greatspn-overlay.xml -f -a greatspn-overlay
	layman-updater -R
else
	echo "[CHROOT] greatspn-overlay already present, syncing"
	layman -s greatspn-overlay
fi

echo "[CHROOT] Installing GreatSPN"
emerge greatspn

echo "[CHROOT] Cleaning up"
if [[ $(emerge -p --quiet gentoolkit 2>/dev/null | grep -i gentoolkit | grep -i ebuild | cut -d" " -f4) != "R" ]]; then
	emerge gentoolkit
fi

emerge --deep --depclean --with-bdeps=y
eclean --deep distfiles
eclean --deep packages
rm -rf /usr/portage/distfiles/*
