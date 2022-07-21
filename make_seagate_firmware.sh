#!/bin/bash
#
# make_seagate_firmware <Seagate-HS-update-XXXXX.img> [Software-Directory]
#
# Script to create a new firmware image for the Seagate
# Central NAS containing a version of samba and other
# cross compiled software.
#
# See usage() function below for usage.
#
#
# Heavily based on
# https://github.com/detain/seagate_central_sudo_firmware
# http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html
#


# Set the default root password to a random
# string. Feel free to change this to a
# fixed string if you prefer.
#

DEFAULT_ROOT_PASSWORD=$(cat /dev/urandom | base64 | cut -c1-15 | head -n1)

#DEFAULT_ROOT_PASSWORD=MyPassword

# ************************************************
# ************************************************
# Nothing below here should normally need to be
# modified.
# ************************************************
# ************************************************

usage()
{
    echo "Usage: $0 <Seagate-HS-update-XXXXX.img> [Software-Directory]"
    echo 
    echo "Script to create a new firmware image for the Seagate"
    echo "Central NAS containing a new version of samba and other"
    echo "cross compiled software."
    echo 
    echo "  Seagate-HS-update-XXXXX.img - "
    echo "    The name of the original Seagate Central firmware"
    echo "    image. Make sure this is a .img file"
    echo 
    echo "  Software-Directory -"
    echo "    Optional : The directory containing samba and other"
    echo "    cross compiled software for Seagate Central. The contents"
    echo "    of this directory will be overlaid on top of the native"
    echo "    Seagate Central directory structure."
    echo
    echo "  Environment variables that may be set to modify "
    echo "  default behavior"
    echo 
    echo "  NO_ENABLE_ROOT : Do NOT enable su/root access"
    echo "  FORCE_PW_CHANGE : Force a one time root password change on upgrade"
    echo "  KEEP_TAPPIN : Do NOT remove defunct Tappin software"
    echo "  KEEP_SEAGATE_MEDIA : Do NOT remove defunct Seagate Media app"
    echo "  NO_USR_LOCAL_PATH : Do NOT add /usr/local/bin to PATH"
    echo "  SKIP_CLEANUP : Do NOT cleanup expanded filesystems after build"
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
    echo
    usage
    exit 1
fi

if ! [ -z $SAMBA_DIRECTORY ]; then
    if [ ! -d $SAMBA_DIRECTORY ]; then	
	echo "Unable to find samba directory $SAMBA_DIRECTORY"
	echo
	usage
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
SEAGATE_NEW_FIRMWARE=Seagate-Central-Update-$new_version.img
echo
echo "Creating new firmware image $SEAGATE_NEW_FIRMWARE"
echo "Using base firmware $SEAGATE_FIRMWARE"
if ! [ -z $SAMBA_DIRECTORY ]; then
    echo "Using samba directory $SAMBA_DIRECTORY"
fi
if [[ -z $NO_ENABLE_ROOT ]]; then
    echo "Enabling su access with default root password $DEFAULT_ROOT_PASSWORD"
    if [[ -n $FORCE_PW_CHANGE ]]; then
	echo "Forcing root password change on reboot. FORCE_PW_CHANGE is set"
    fi
else
    echo "WARNING : NOT Enabling su access. NO_ENABLE_ROOT is set"
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

    # Optional : Save a backup copy of the original samba
    # software.
    #
    # mkdir -p squashfs-root/usr/bin/old.samba squashfs-root/usr/sbin/old.samba
    # ls $SAMBA_DIRECTORY/usr/sbin | xargs -I{} rsync -a --ignore-existing squashfs-root/usr/sbin/{} squashfs-root/usr/sbin/old.samba/{}
    # ls $SAMBA_DIRECTORY/usr/bin | xargs -I{} rsync -a --ignore-existing squashfs-root/usr/bin/{} squashfs-root/usr/bin/old.samba/{}
    #

    
    # Install samba software 
    cp -f -r $SAMBA_DIRECTORY/* squashfs-root/ &> log_03_cp_samba.log
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
  
if [[ -z $NO_ENABLE_ROOT ]]; then
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
    if [[ -n $FORCE_PW_CHANGE ]]; then
	sed s#^FORCE_PW_CHANGE=0#FORCE_PW_CHANGE=1# -i set_default_root_pw.modified
    fi
    
    cp set_default_root_pw.modified squashfs-root/etc/init.d/set_default_root_pw
    chmod a+x squashfs-root/etc/init.d/set_default_root_pw
    ln -s ../init.d/set_default_root_pw squashfs-root/etc/rcS.d/S98set_default_root_pw

    chmod 4555 squashfs-root/usr/bin/sudo
    chmod 4555 squashfs-root/usr/bin/su
fi

# By default we disable the defunct TappIn service. 
#
# See https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/
#
if [[ -z $KEEP_TAPPIN ]]; then
    new_stage "Disable and Remove TappIn service"
    rm -rf squashfs-root/apps/tappin
    find  squashfs-root/etc/ -name *tappinAgent* -exec rm {} +
    sed -i "s#Remote access allows you to access your files anywhere in the world using a web browser. To use, you can download apps for iPhone, iPad, Android, Kindle Fire, and Windows Phone.#The Seagate Central remote access service is defunct. It can not be activated in this version of firmware.#g" squashfs-root/cirrus/application/language/en/cirrus_lang.php
fi

# By default we disable the defunct Segate media service. 
# Note that this is NOT the twonky media server
#
# See https://www.seagate.com/support/downloads/seagate-media/
#
if [[ -z $KEEP_SEAGATE_MEDIA ]]; then
    new_stage "Disable and Remove Seagate Media app service"
    rm -rf squashfs-root/media_server
    find  squashfs-root/etc/ -name *media_server* -exec rm {} +
    sed -i "s#The Seagate Media app allows you to access your media anywhere in the world. Download the Seagate Media app for iPhone, iPad, Android, and Kindle Fire from your mobile device’s app store.#The Seagate Media app is now defunct. This service cannot be activated in this version of Seagate Central firmware#g" squashfs-root/cirrus/application/language/en/cirrus_lang.php
fi


# In order to support newly installed cross compiled
# software we add /usr/local/bin and /usr/local/sbin to
# the default PATH
#
if [[ -z $NO_USR_LOCAL_PATH ]]; then
    new_stage "Add /usr/local/ to default PATH"
    sed -i '/^ENV_SUPATH/c \ENV_SUPATH      PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' squashfs-root/etc/login.defs
    sed -i '/^ENV_PATH/c \ENV_PATH        PATH=/usr/local/bin:/bin:/usr/bin' squashfs-root/etc/login.defs
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
# least CPU intenstive form of compression here.
# This is because the Seagate Central is not very
# powerful and will take a long time to decompress
# a heavily compressed file.
#
mksquashfs squashfs-root rfs.squashfs -all-root -noappend -Xcompression-level 1 &> log_05_mksquashfs.log
checkerr $? "mksquashfs squashfs-root" log_05_mksquashfs.log


tar -czvf $SEAGATE_NEW_FIRMWARE rfs.squashfs uImage config.ser &> log_06_tar_firmware.log
checkerr $? "tar up firmware" log_06_tar_firmware.log

if [[ -z $SKIP_CLEANUP ]]; then
    new_stage "Cleanup"
    rm -rf squashfs-root
    rm -rf uImage config.ser config.ser.orig
    rm -rf rfs.squashfs
    rm -rf set_default_root_pw.modified
fi
echo
echo -e "$GRN Success!! $NOCOLOR"
echo -e "$GRN Created $NOCOLOR $SEAGATE_NEW_FIRMWARE"
if [[ -z $NO_ENABLE_ROOT ]]; then
    echo -e "$GRN Default Root Password :$NOCOLOR $DEFAULT_ROOT_PASSWORD"
    echo $DEFAULT_ROOT_PASSWORD > $SEAGATE_NEW_FIRMWARE.root-password
    echo -e "$GRN Generated text file :$NOCOLOR $SEAGATE_NEW_FIRMWARE.root-password"
fi

