#!/bin/bash

# exit in case of error
set -e

maindir=$(pwd)
files=$maindir/files
repo=http://distfiles.gentoo.org/releases/amd64/autobuilds
stage3=""
portage="portage-latest.tar.xz"
latest=""
root=/tmp/$maindir/gentoo
dest=$maindir/gentoo

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
echo "---> Fetching from $repo/latest-stage3-amd64.txt"
while read line; do
	if [[ ! ${line:0:1} = "#" ]]; then
		latest=$(echo $line | cut -d" " -f 1)
		stage3=$repo/$latest
		echo "---> Found latest Stage3: $stage3"
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
	echo "---> Unpacking filesystem into $root"
	echo "---> Requires sudo"
	sudo tar xpf $tarball -C $root
	echo "---> Unpacking portage tree into $root/usr"
	echo "---> Requires sudo"
	sudo tar xpf $portage -C $root/usr
	echo "Done!"
else
	echo "---> Skipping since $root is not empty."
fi
echo ""

if [ -z $(findmnt | grep -i $root) ]; then
	# mount the filesystems (requires SUDO)
	echo "============= Mounting the filesystem ================"
	echo "---> Remember to umount when chrooting is over!" 
	echo "---> Requires sudo"
	sudo mount -v --rbind /dev $root/dev
	sudo mount -v --make-rslave $root/dev
	sudo mount -v -t proc /proc $root/proc
	sudo mount -v --rbind /sys $root/sys
	sudo mount -v --make-rslave $root/sys
	echo "---> Setting up networking"
	sudo cp -v /etc/resolv.conf $root/etc/resolv.conf
	echo ""
fi

# copy execution scripts to chroot environment
echo "======= Copying setup scripts to the filesystem ======="
echo "---> Requires sudo"
sudo cp -v $files/setup.sh $root/
sudo cp -v $files/make.conf $root/etc/portage/make.conf
sudo cp -v $files/package.accept_keywords $root/etc/portage/
sudo cp -v $files/use_greatspn $root/etc/portage/package.use/
echo ""

# chroot
echo "========== Entering Chroot and setting up ============"
echo "---> Requires sudo"
echo ""
sudo chroot $root ./setup.sh

# exited chroot: umount partitions
echo "========== Unmounting Chroot partitions =============="
echo "---> Requires sudo"
sudo umount -f $root/proc
sudo umount -R $root/sys
sudo umount -R $root/dev

# copy everything to dest directory once done
echo "========= Finishing up and copying chroot ============"
echo "---> Copying to $dest"
if [ -d $dest]; then
	echo "ERROR: $dest already exists"
	exit 1
else
	cp -rv $root $dest
fi
echo "Done!"
