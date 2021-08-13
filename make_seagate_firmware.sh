#!/bin/bash
#
# make_seagate_firmware <Seagate-Central-Firmware.img> <Samba-Software-Archive.tar.gz>
#
# Script to create a new firmware image for the Seagate
# Central NAS containing a new version of samba software.
#
# Heavily based on
# https://github.com/detain/seagate_central_sudo_firmware
#


# Set the default root password. If this option is
# commented out then the generated firmware image will
# NOT enable su access on the Seagate Central.
#
DEFAULT_ROOT_PASSWORD=SeagateCentral-$RANDOM-$(date +%N)

# Disable the defunct TappIn service. If this option
# is commented out then the TappIn service will NOT
# be disabled.
#
# See https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/
#
DISABLE_TAPPIN=1

# ************************************************
# ************************************************
# Nothing below here should normally need to be
# modified.
# ************************************************
# ************************************************

SEAGATE_FIRMWARE=$1
SAMBA_ARCHIVE=$2

GRN="\e[32m"
RED="\e[31m"
YEL="\e[33m"
NOCOLOR="\e[0m"
current_stage="None"
#report error.  4 arguments.
# $1-retval (0 means success) $2-name  $3-log file
checkerr()
{
    if [ $1 -ne 0 ]; then
	echo -e "$RED  Failure: $2 $NOCOLOR $(date +%T) Check $3"
	tail $3
	exit 1
    else
	echo -e "$GRN  Success: $2 $NOCOLOR $(date +%T) See $3"
    fi
}

new_stage()
{
    current_stage=$1
    echo -e "$GRN $current_stage$NOCOLOR : $(date +%T)"
}

usage()
{
    echo "Usage: $0 <Seagate-Central-Firmware.img> <Samba-Software-Archive.tar.gz>"
    echo 
    echo "Script to create a new firmware image for the Seagate"
    echo "Central NAS containing a new version of samba software."
    echo
    echo "  Seagate-Central-Firmware.img - Name of a firmware image "
    echo "      for a Seagate Central NAS"
    echo 
    echo "  Samba-Software-Archive.tar.gz - Name of a samba software"
    echo "      archive specially compiled for the Seagate Central."
    echo
    echo "Other parameters may need to be modified in the script."
    echo  
}

if [ -z $SAMBA_ARCHIVE ]; then
    usage
    exit 1
fi

if [ ! -r $SEAGATE_FIRMWARE ]; then
    echo "Unable to find Seagate firmware $SEAGATE_FIRMWARE"
    exit 1
fi

if [ ! -r $SAMBA_ARCHIVE ]; then
    echo "Unable to find samba archive $2"
    exit 1
fi

SAMBA_DIRECTORY=`tar -tzf $SAMBA_ARCHIVE | head -1 | cut -f1 -d"/"`
if [ -z $SAMBA_DIRECTORY ]; then
   echo "Unable to determine the directory the"
   echo "archive $SAMBA_ARCHIVE will extract to."
   echo "Check that the samba archive has the"
   echo "proper structure."
   exit 1
fi

new_version=$(date +%Y.%m%d.%H%M-S)
new_release_date=$(date +%d-%m-%Y)
SEAGATE_NEW_FIRMWARE=Seagate-Samba-Update-$new_version.img
echo
echo "Creating new firmware image $SEAGATE_NEW_FIRMWARE"
echo "Using base firmware $SEAGATE_FIRMWARE"
echo "Using samba archive $SAMBA_ARCHIVE"
if [ -n $DEFAULT_ROOT_PASSWORD ]; then
   echo "Enabling su access with default root password $DEFAULT_ROOT_PASSWORD"
fi
echo   

# Printing free space on the device because this process takes up
# so much disk space.
df -h .


new_stage "Extract Seagate Firmware"
#
# Note that although the Seagate firmware typically
# has extention .img it is in fact a gzipped tar archive.
#
tar -zxpf $SEAGATE_FIRMWARE &> log_01_extract_firmware.log
checkerr $? "untar Seagate Firmware" log_01_extract_firmware.log

unsquashfs rfs.squashfs &> log_02_unsquashfs.log
checkerr $? "unsquashfs" log_02_unsquashfs.log

new_stage "Extract Samba archive"
tar -xf $SAMBA_ARCHIVE &> log_03_extract_samba_archive.log
checkerr $? "tar -xf" log_03_extract_samba_archive.log

new_stage "Insert Samba software"

# Install libraries
cp -r $SAMBA_DIRECTORY/usr/local/lib squashfs-root/usr/local/

# Install executables
cp $SAMBA_DIRECTORY/usr/local/sbin/* squashfs-root/usr/sbin/
cp $SAMBA_DIRECTORY/usr/local/bin/* squashfs-root/usr/bin/

# Install headers (this is optional)
cp -r $SAMBA_DIRECTORY/usr/local/include squashfs-root/usr/local/

new_stage "Generate modified samba configuration"
#
# The approach we take is to create an smb.conf file
# that is only loaded when a non default version of
# samba is in operation. This way, if the system is
# reverted to old firmware the original samba config
# is preserved and will still work.
#

#
# Remove no longer supported or needed options
cp squashfs-root/etc/samba/smb.conf squashfs-root/etc/samba/smb.conf.v4
sed -i '/min receivefile size/d' squashfs-root/etc/samba/smb.conf.v4
sed -i '/auth methods/d' squashfs-root/etc/samba/smb.conf.v4

# Replace and update old appletalk configuration
sed -i '/netatalk/a multicast dns register = yes' squashfs-root/etc/samba/smb.conf.v4
sed -i '/netatalk/a fruit:time machine = yes' squashfs-root/etc/samba/smb.conf.v4
sed -i '/netatalk/a fruit:model = RackMac' squashfs-root/etc/samba/smb.conf.v4
sed -i '/netatalk/a vfs objects = catia fruit streams_xattr' squashfs-root/etc/samba/smb.conf.v4
sed -i '/netatalk/d' squashfs-root/etc/samba/smb.conf.v4

# Add a startup script that checks samba version
# before the main samba startup script is run

if [ ! -r samba-version-check ]; then
    echo "Unable to find samba-version-check"
    echo "Needed to setup samba configuration"
    exit 1
fi
cp samba-version-check squashfs-root/etc/init.d/
chmod a+x squashfs-root/etc/init.d/samba-version-check
ln -s ../init.d/samba-version-check squashfs-root/etc/rcS.d/S60samba-version-check
   
if [ -n $DEFAULT_ROOT_PASSWORD ]; then
   new_stage "Enable su access"
   if [ "$(grep "^PermitRootLogin yes" squashfs-root/etc/ssh/sshd_config)" = "" ]; then
       sed s#"^PermitRootLogin without-password"#"PermitRootLogin yes"#g -i squashfs-root/etc/ssh/sshd_config
   fi;
   if [ "$(grep "\"users,nogroup,wheel" squashfs-root/usr/sbin/ba-upgrade-finish)" = "" ]; then
       sed s#"\"users,nogroup"#"\"users,nogroup,wheel"#g -i squashfs-root/usr/bin/usergroupmgr.sh;
   fi;
   if [ "$(grep "usermod -a -G users,wheel" squashfs-root/usr/sbin/ba-upgrade-finish)" = "" ]; then
       sed s#"usermod -a -G nogroup"#"usermod -a -G users,wheel,nogroup"#g -i squashfs-root/usr/sbin/ba-upgrade-finish;
   fi;
   if [ ! -r finish.append ]; then
       echo "Unable to find finish.append"
       echo "Needed to set default root password"
       exit 1
   fi
   sed s#XXXXXXXXXX#$DEFAULT_ROOT_PASSWORD#g finish.append > finish.append.modified
   if [ "$(grep "finish.append" squashfs-root/etc/init.d/finish)" = "" ]; then
       cat finish.append.modified >> squashfs-root/etc/init.d/finish
   fi
   chmod 4555 squashfs-root/usr/bin/sudo
   chmod 4555 squashfs-root/usr/bin/su
fi

if [ -n $DISABLE_TAPPIN ]; then
    new_stage "Disable and Remove TappIn service"
    rm -rf squashfs-root/apps/tappin
    find  squashfs-root/etc/ -name *tappinAgent* -exec rm {} +
fi


new_stage "Creating new firmware archive"
rm rfs.squashfs
#
# Note that we are using the least compressing and
# therefore the fastest form of compression here.
# This is because the Seagate Central is not very
# powerful and will take a long time to decompress
# a heavily compressed file.
#
mksquashfs squashfs-root rfs.squashfs -all-root -noappend -Xcompression-level 1 &> log_04_mksquashfs.log
checkerr $? "mksquashfs squashfs-root" log_04_mksquashfs.log
new_md5="$(md5sum rfs.squashfs  | cut -d" " -f1)" 
cp config.ser config.ser.orig
sed -i "/version/c version=${new_version}" config.ser
sed -i "/release_date/c release_date=${new_release_date}" config.ser
sed -i "/rfs/c rfs=${new_md5}" config.ser

tar -czvf $SEAGATE_NEW_FIRMWARE rfs.squashfs uImage config.ser &> log_05_tar_firmware.log
checkerr $? "tar up firmware" log_05_tar_firmware.log

#SKIP_CLEANUP=1
if [ -z $SKIP_CLEANUP ]; then
    new_stage "Cleanup"
    rm -rf $SAMBA_DIRECTORY
    rm -rf squashfs-root
    rm -rf uImage config.ser config.ser.orig
    rm -rf rfs.squashfs
    rm -rf finish.append.modified
fi
echo
echo -e "$GRN Success!! $NOCOLOR"
echo -e "$GRN Created $NOCOLOR $SEAGATE_NEW_FIRMWARE"
if [ -n $DEFAULT_ROOT_PASSWORD ]; then
    echo -e "$GRN Default Root Password :$NOCOLOR $DEFAULT_ROOT_PASSWORD"
fi

