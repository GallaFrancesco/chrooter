#!/bin/bash

# exit in case of error
set -e

# configure these
maindir=$(pwd)
chroot_name=gentoo
files=$maindir/files
repo=http://distfiles.gentoo.org/releases/amd64/autobuilds

# don't touch these
stage3=""
portage="portage-latest.tar.xz"
latest=""
root=/tmp/$maindir/$chroot_name
dest=$maindir/$chroot_name

# create chroot directory if missing
if [ ! -d $root ]; then
	echo "============ Creating CHROOT directory ==============="
	mkdir -pv $root
else
	echo "============= Found CHROOT directory ================="
fi
echo ""

# check latest stage3 from repository
echo "==== Dowloading latest Gentoo Stage 3 information ===="
echo "* Fetching from $repo/latest-stage3-amd64.txt"
while read line; do
	if [[ ! ${line:0:1} = "#" ]]; then
		latest=$(echo $line | cut -d" " -f 1)
		stage3=$repo/$latest
		echo "* Found latest Stage3: $stage3"
	fi
done< <(curl $repo/latest-stage3-amd64.txt 2> /dev/null)
echo ""

tarball=$(echo $latest | cut -d"/" -f 2)


# download stage3 if not present
if [ ! -f $tarball ]; then
	echo "=========== Downloading Stage 3 tarball =============="
	wget $stage3 -O $tarball
	echo "=========== Downloading Portage tree =============="
	wget "http://distfiles.gentoo.org/snapshots/$portage" -O "$portage"
	echo ""
else
	echo "============== Found Stage 3 tarball ================="
fi
echo ""

echo "============ Unpacking Stage 3 tarball ==============="
if [ ! "$(ls -A $root)" ]; then # root is empty
	# unpack the tarball
	echo "* Unpacking filesystem into $root"
	echo "* Requires sudo"
	sudo tar xpf $tarball -C $root
	echo "* Unpacking portage tree into $root/usr"
	echo "* Requires sudo"
	sudo tar xpf $portage -C $root/usr
	echo "Done!"
else
	echo "* Skipping since $root is not empty."
fi
echo ""

echo "============= Mounting the filesystem ================"
if [[ -z "$(findmnt | grep -i $chroot_name)" ]]; then
	# mount the filesystems (requires SUDO)
	echo "* Remember to umount when chrooting is over!"
	echo "* Requires sudo"
	sudo mount -v --rbind /dev $root/dev
	sudo mount -v --make-rslave $root/dev
	sudo mount -v -t proc /proc $root/proc
	sudo mount -v --rbind /sys $root/sys
	sudo mount -v --make-rslave $root/sys
	echo "* Setting up networking"
	sudo cp -v /etc/resolv.conf $root/etc/resolv.conf
	echo ""
else
	echo "* Skipping since filesystem is already mounted"
fi

# copy execution scripts to chroot environment
echo "======= Copying setup scripts to the filesystem ======="
echo "* Requires sudo"
sudo cp -rv $files/* $root/
echo ""

# chroot
echo "========== Entering Chroot and setting up ============"
echo "* Requires sudo"
echo ""
sudo chroot $root ./setup.sh

# exited chroot: umount partitions
echo "========== Unmounting Chroot partitions =============="
echo "* Requires sudo"
sudo umount -f $root/proc
sudo umount -R $root/sys
sudo umount -R $root/dev

# copy everything to dest directory once done
echo "========= Finishing up and copying chroot ============"

if [ -d $dest ]; then
	echo "ERROR: $dest already exists"
	exit 1
else
	destball=greatspn-$chroot_name-$(date +%s).tar.gz
	distball=greatspn-$(date +%s).tar.gz
	echo "* Creating tarball in $maindir/$destball"
	echo "* Requires sudo"
	sudo tar -cpzf $destball $root
	echo "* Creating binary distribution in $maindir/$distball"
	echo "* Requires sudo"
	sudo tar -cpzf $distball \
		$root/usr/local/GreatSPN \
		$root/usr/local/lib \
		$root/usr/local/share/applications/pnpro-editor.desktop \
		$root/usr/local/share/mime/application/x-pnpro-editor.xml \
		/usr/local/share/mime/packages/application-x-pnpro-editor.xml
	echo "* Fixing permissions"
	echo "* Requires sudo"
	sudo chown $USER $destball
	sudo chown $USER $distball
	echo "* Computing sha1sum of binary release and saving to $distball-sha1.txt"
	sha1sum $distball > $distball-sha1.txt

fi
echo "Done!"
