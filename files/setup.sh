#!/bin/bash

set -e

echo "[CHROOT] Starting setup script for Gentoo."
echo "---> this script is run as root from inside the chroot jail."
echo ""
echo "[CHROOT] Syncing portage tree"
emerge --sync

echo "[CHROOT] Installing layman"
emerge layman

echo "[CHROOT] Adding 'greatspn-overlay' and syncing"
layman -k -o https://raw.githubusercontent.com/GallaFrancesco/greatspn-overlay/master/greatspn-overlay.xml -f -a greatspn-overlay
layman-updater -R

echo "[CHROOT] Installing GreatSPN"
emerge greatspn

echo "[CHROOT] Cleaning up"
emerge gentoolkit
emerge --deep --depclean --with-bdeps=y
eclean --deep distfiles
eclean --deep packages
