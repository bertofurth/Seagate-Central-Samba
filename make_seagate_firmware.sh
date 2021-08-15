#!/bin/bash
#
# make_seagate_firmware <Seagate-Central-Firmware.img> [Samba-Directory]
#
# Script to create a new firmware image for the Seagate
# Central NAS containing a new version of samba software.
#
# See usage() function below for usage.
#
#
# Heavily based on
# https://github.com/detain/seagate_central_sudo_firmware
# http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html
#


# Set the default root password to a random
# string. If this option is commented out then
# the generated firmware image will NOT enable
# su access on the Seagate Central.
#
DEFAULT_ROOT_PASSWORD=$(cat /dev/urandom | base64 | cut -c1-15 | head -n1)

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

usage()
{
    echo "Usage: $0 <Seagate-Central-Firmware.img> [Samba-Directory]"
    echo 
    echo "Script to create a new firmware image for the Seagate"
    echo "Central NAS containing a new version of samba software."
    echo 
    echo "  Seagate-Central-Firmware.img - "
    echo "    The name of the original Seagate Central firmware"
    echo "    image"
    echo 
    echo "  Samba-Software-Directory -"
    echo "    Optional : The directory containing the cross compiled"
    echo "    samba software for Seagate Central. Expect a directory"
    echo "    structure where important binaries and libraries are "
    echo "    under the usr/ subdirectory."
    echo
    echo "  Other parameters that may be manually modified within the "
    echo "  the $0 script"
    echo 
    echo "  DEFAULT_ROOT_PASSWORD : Enable su access and set the"
    echo "    default root password (default : on)"
    echo 
    echo "  DISABLE_TAPPIN : Remove defunct Tappin software"
    echo "    (default : on)"
    echo    
}   



SEAGATE_FIRMWARE=$1
SAMBA_DIRECTORY=$2

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

if [ -z $SEAGATE_FIRMWARE ]; then
    usage
    exit 1
fi

if [ ! -r $SEAGATE_FIRMWARE ]; then
    echo "Unable to find Seagate firmware $SEAGATE_FIRMWARE"
    exit 1
fi

if ! [ -z $SAMBA_DIRECTORY ]; then
    if [ ! -d $SAMBA_DIRECTORY ]; then	
	echo "Unable to find samba directory $SAMBA_DIRECTORY"
	exit 1  
    fi
    # Sanity check
    if [ ! -r $SAMBA_DIRECTORY/usr/sbin/smbd ]; then
	echo "Unable to find $SAMBA_DIRECTORY/usr/sbin/smbd"
	echo "Are you sure this is a directory that contains"
	echo "cross compiled samba binaries?"
	exit 1
    fi
fi

new_version=$(date +%Y.%m%d.%H%M-S)
new_release_date=$(date +%d-%m-%Y)
SEAGATE_NEW_FIRMWARE=Seagate-Samba-Update-$new_version.img
echo
echo "Creating new firmware image $SEAGATE_NEW_FIRMWARE"
echo "Using base firmware $SEAGATE_FIRMWARE"
if ! [ -z $SAMBA_DIRECTORY ]; then
    echo "Using samba directory $SAMBA_DIRECTORY"
fi
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

rm -rf squashfs-root
unsquashfs -n rfs.squashfs &> log_02_unsquashfs.log
checkerr 0 "unsquashfs" log_02_unsquashfs.log

if ! [ -z $SAMBA_DIRECTORY ]; then
    new_stage "Insert Samba software"

    # Install samba software 
    cp -r $SAMBA_DIRECTORY/usr/* squashfs-root/usr/ &> log_03_cp_samba.log
    checkerr $? "copy libraries" log_03_cp_samba.log

    new_stage "Generate modified samba configuration"
    #
    # The approach we take is to create an smb.conf file
    # that is only loaded when a non default version of
    # samba is in operation. This way, if the system is
    # reverted to old firmware the original samba config
    # is preserved and will still work with the original
    # version of samba software.
    #

    # Remove no longer supported or needed options
    cp squashfs-root/etc/samba/smb.conf squashfs-root/etc/samba/smb.conf.v4 &> log_04_smb_conf.log
    checkerr $? "smb.conf modification" log_04_smb_conf.log

    sed -i '1i#Copied from smb.conf.v4 at startup\' squashfs-root/etc/samba/smb.conf.v4
    
    sed -i '/auth methods/d' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/encrypt passwords/d' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/null passwords/d' squashfs-root/etc/samba/smb.conf.v4
    
    # There is a poorly formatted line in the default
    # smb.conf file
    #
    # min receivefile size = 1 ## disabled due to SOP receive file bug
    #
    # This doesn't work with samba v4 and needs to be
    # removed. We replace it with
    # 
    # min receivefile size = 16384
    #
    sed -i '/SOP receive file bug/a \        min receivefile size = 16384' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/SOP receive file bug/d' squashfs-root/etc/samba/smb.conf.v4
    
    # Replace and update old appletalk configuration
    sed -i '/netatalk/a \        multicast dns register = yes' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/netatalk/a \        fruit:time machine = yes' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/netatalk/a \        fruit:model = RackMac' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/netatalk/a \        vfs objects = catia fruit streams_xattr' squashfs-root/etc/samba/smb.conf.v4
    sed -i '/netatalk/d' squashfs-root/etc/samba/smb.conf.v4

    # Add a startup script that checks samba version
    # before the main samba startup script is run and
    # loads the new modified samba configuration if
    # required.

    if [ ! -r samba-version-check ]; then
	echo "Unable to find samba-version-check"
	echo "Needed to setup samba configuration"
	exit 1
    fi

    cp samba-version-check squashfs-root/etc/init.d/
    chmod a+x squashfs-root/etc/init.d/samba-version-check
    ln -s ../init.d/samba-version-check squashfs-root/etc/rcS.d/S60samba-version-check

    #
    # Put a message on the About page indicating
    # that we have installed a new version of Samba. We
    # simply overwrite the old English language Tappin
    # message.

    if [ -r squashfs-root/usr/local/include/samba-4.0/samba/version.h ]; then
	SAMBA_VERSION=$(cat squashfs-root/usr/local/include/samba-4.0/samba/version.h | grep SAMBA_VERSION_STRING= | cut -d= -f2)
	sed -i "s#Seagate Remote Access powered by Tappin#Samba ${SAMBA_VERSION} - samba.org#g" squashfs-root/cirrus/application/language/en/cirrus_lang.php
    fi
fi 
  
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
    if [ ! -r set_default_root_pw ]; then
	echo "Unable to find set_default_root_pw"
	echo "Needed to set default root password"
	exit 1
    fi

    sed s#XXXXXXXXXX#$DEFAULT_ROOT_PASSWORD#g set_default_root_pw > set_default_root_pw.modified
    cp set_default_root_pw.modified squashfs-root/etc/init.d/set_default_root_pw
    chmod a+x squashfs-root/etc/init.d/set_default_root_pw
    ln -s ../init.d/set_default_root_pw squashfs-root/etc/rcS.d/S98set_default_root_pw

    chmod 4555 squashfs-root/usr/bin/sudo
    chmod 4555 squashfs-root/usr/bin/su
fi

if [ -n $DISABLE_TAPPIN ]; then
    new_stage "Disable and Remove TappIn service"
    rm -rf squashfs-root/apps/tappin
    find  squashfs-root/etc/ -name *tappinAgent* -exec rm {} +
fi

#
# Generate the small descriptor file associated
# with the firmware update
#
new_md5="$(md5sum rfs.squashfs  | cut -d" " -f1)" 
cp config.ser config.ser.orig
sed -i "/version/c version=${new_version}" config.ser
sed -i "/release_date/c release_date=${new_release_date}" config.ser
sed -i "/rfs/c rfs=${new_md5}" config.ser

#
# Modify the file that identifies the firmware
# version.
sed -i "/version/c version=${new_version}" squashfs-root/etc/config.ser
sed -i "/release_date/c release_date=${new_release_date}" squashfs-root/etc/config.ser


new_stage "Creating new firmware archive"
rm rfs.squashfs
#
# Note that we are using the lowest and
# therefore the fastest form of compression here.
# This is because the Seagate Central is not very
# powerful and will take a long time to decompress
# a heavily compressed file.
#
mksquashfs squashfs-root rfs.squashfs -all-root -noappend -Xcompression-level 1 &> log_05_mksquashfs.log
checkerr $? "mksquashfs squashfs-root" log_05_mksquashfs.log


tar -czvf $SEAGATE_NEW_FIRMWARE rfs.squashfs uImage config.ser &> log_06_tar_firmware.log
checkerr $? "tar up firmware" log_06_tar_firmware.log

#SKIP_CLEANUP=1
if [ -z $SKIP_CLEANUP ]; then
    new_stage "Cleanup"
    rm -rf squashfs-root
    rm -rf uImage config.ser config.ser.orig
    rm -rf rfs.squashfs
    rm -rf set_default_root_pw.modified
fi
echo
echo -e "$GRN Success!! $NOCOLOR"
echo -e "$GRN Created $NOCOLOR $SEAGATE_NEW_FIRMWARE"
if [ -n $DEFAULT_ROOT_PASSWORD ]; then
    echo -e "$GRN Default Root Password :$NOCOLOR $DEFAULT_ROOT_PASSWORD"
    echo $DEFAULT_ROOT_PASSWORD > $SEAGATE_NEW_FIRMWARE.root-password
    echo -e "$GRN Generated text file :$NOCOLOR $SEAGATE_NEW_FIRMWARE.root-password"
fi

