#!/bin/bash
#
# make_seagate_firmware <Seagate-HS-update-XXXXX.img>
#                       [-d <Software-Directory>]
#                       [-u <uImage>] [-r [root-password]] 
#
# Script to create a new firmware image for the Seagate
# Central NAS containing cross compiled software and a
# Linux kernel. Special care is taken to accomodate new versions
# of samba.
#
# See usage() function below for usage.
#
#
# Heavily based on
# https://github.com/detain/seagate_central_sudo_firmware
# http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html
#

# ************************************************
# ************************************************
# Nothing below here should normally need to be
# modified.
# ************************************************
# ************************************************


small_usage()
{
    echo "Usage: $0 <-f Seagate-HS-update-XXXXX.img>"
    echo "          [-d <Software-Directory>] "
    echo "          [-u <uImage>] [-r [root-password]] "
}

usage()
{
    small_usage
    echo
    echo "Script to create a new firmware image for the Seagate"
    echo "Central NAS from a stock Seagate supplied image."
    echo 
    echo "  -f Seagate-HS-update-XXXXX.img - "
    echo "    Required : The name of the original Seagate Central "
    echo "    firmware image with a .img suffix. You may have to "
    echo "    first extract it from a zip file."
    echo 
    echo "  -d <Software-Directory> "
    echo "    Optional : The directory containing samba and other"
    echo "    cross compiled software for Seagate Central. The contents"
    echo "    of this directory will be overlaid on top of the native"
    echo "    Seagate Central directory structure."
    echo
    echo "  -u <uImage> "
    echo "    Optional : Specify a uImage Linux kernel image file "
    echo "    that has been compiled for the Seagate Central. This"
    echo "    will be inserted into the firmware and will replace"
    echo "    the native Seagate supplied v2.6.25 uImage kernel in"
    echo "    generated firmware."
    echo
    echo "  -r <root-password>"
    echo "    Optional : After the Seagate Central is upgraded, the"
    echo "    specified value will be set as the root password. This"
    echo "    only occurs once during the first boot after the firmware"
    echo "    upgrade. This is useful because recent firmware"
    echo "    from Seagate disables root access. We strongly suggest"
    echo "    manually changing the root password again after bootup."
    echo
    echo "  Environment variables that may be set to modify "
    echo "  default behavior"
    echo 
    echo "  KEEP_TAPPIN : Do NOT remove defunct Tappin software"
    echo "  KEEP_SEAGATE_MEDIA : Do NOT remove defunct Seagate Media app"
    echo "  NO_USR_LOCAL_PATH : Do NOT add /usr/local/[s]bin to PATH"
    echo "  SKIP_CLEANUP : Do NOT cleanup expanded filesystems after build"
    echo "  SUFFIX : Add a particular suffix to the version number (default "S")"
    echo    
}   


GRN="\e[32m"
RED="\e[31m"
YEL="\e[33m"
NOCOLOR="\e[0m"

while getopts "f:d:u:r: :hHvV" flag
do
    echo Flag $flag argument ${OPTARG}
    case $flag in
	f) SEAGATE_FIRMWARE_FLAG=$flag
	   SEAGATE_FIRMWARE=${OPTARG};;
	d) SAMBA_DIRECTORY_FLAG=$flag
	   SAMBA_DIRECTORY=${OPTARG};;
	u) UIMAGE_FLAG=$flag
	   UIMAGE=${OPTARG};;
	r) ROOT_PW_FLAG=$flag
	   ROOT_PW=${OPTARG};;
	h|H) usage
	   exit 1;;
	v|V|*) small_usage
	   exit 1;;
    esac
done

current_stage="None"
#checkerr() - report error.  4 arguments.
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
    echo -e "$RED Error :$NOCOLOR You must specify a seagate firmware .img file"
    echo "using the -f flag"
    usage
    exit 1
fi

if [ ! -r $SEAGATE_FIRMWARE ]; then
    echo -e "$RED Error : Unable to find Seagate firmware $SEAGATE_FIRMWARE $NOCOLOR"
    echo
    exit 1
fi  

if [[ -n $SAMBA_DIRECTORY_FLAG ]]; then
   if [[ -z $SAMBA_DIRECTORY ]]; then
      echo -e "$RED Error :$NOCOLOR No software directory specified after -$SAMBA_DIRECTORY_FLAG"
      echo
      small_usage
      exit 1
   fi
   if [[ ! -d $SAMBA_DIRECTORY ]]; then	
      echo -e "$RED Error :$NOCOLOR Unable to find software directory $SAMBA_DIRECTORY"
      echo
      exit 1  
   fi
   # Sanity check
   if [ ! -d $SAMBA_DIRECTORY/usr/ ]; then
      echo -e "$RED Warning : $NOCOLOR Unable to find $SAMBA_DIRECTORY/usr/"
      echo "Are you sure this is a directory that contains"
      echo "cross compiled binaries? Continuing anyway...."
      echo
   fi
fi

if [[ -n $UIMAGE_FLAG ]]; then
   if [[ -z $UIMAGE ]]; then
      echo -e "$RED Error :$NOCOLOR No uImage file specified -$UIMAGE_FLAG"
      echo
      small_usage
      exit 1
   fi
   if [[ ! -r $UIMAGE ]]; then
    echo -e "$RED Error :$NOCOLOR Unable to find uImage file $UIMAGE"
    echo
    exit 1
   fi
   
fi

SUFFIX=${SUFFIX-S}
new_version=$(date +%Y.%m%d.%H%M%S-$SUFFIX)
new_release_date=$(date +%d-%m-%Y)
BASE=temp-$new_version
SEAGATE_NEW_FIRMWARE=Seagate-Central-Update-$new_version.img
echo
echo "Creating new firmware image $SEAGATE_NEW_FIRMWARE"
echo "Using original firmware $SEAGATE_FIRMWARE"
if [[ -n $SAMBA_DIRECTORY ]]; then
    echo "Using cross compiled software directory $SAMBA_DIRECTORY"
fi
if [[ -n $UIMAGE ]]; then
    echo "Using uImage file $UIMAGE as Linux kernel"
fi
if [[ -n $ROOT_PW ]]; then
    echo "Setting root password on first boot to $ROOT_PW"
else
    echo "NOT resetting root password."
fi
echo "Using temporary build directory $BASE"
echo   

# You could change the script to use a random password as follows
#ROOT_PW=$(cat /dev/urandom | base64 | cut -c1-15 | head -n1)

# Printing free space on the device because this process takes up
# so much disk space.
df -h .


new_stage "Extract Seagate Firmware"
#
# Note that although the Seagate firmware typically
# has extention .img it is in fact a gzipped tar archive.
#
rm -rf $BASE
mkdir $BASE &> log_01_extract_firmware.log
checkerr $? "Create temporary directory" log_01_extract_firmware.log
tar -C $BASE/ -zxpf $SEAGATE_FIRMWARE &>> log_01_extract_firmware.log
checkerr $? "untar Seagate Firmware" log_01_extract_firmware.log

unsquashfs -d $BASE/squashfs-root -n $BASE/rfs.squashfs  &> log_02_unsquashfs.log

checkerr 0 "unsquashfs" log_02_unsquashfs.log

if ! [[ -z $SAMBA_DIRECTORY ]]; then
    new_stage "Insert cross compiled software"
  
    # Optional : Save a backup copy of any native software that is
    # going to be overwritten. That way, if things go really wrong
    # then these old binaries can still be accessed. This will make
    # the image much bigger.
    #
    # mkdir -p squashfs-root/usr/old/sbin squashfs-root/usr/old/bin
    # ls $SAMBA_DIRECTORY/usr/sbin | xargs -I{} rsync -a --ignore-existing $BASE/squashfs-root/usr/sbin/{} $BASE/squashfs-root/usr/old/sbin/{}
    # ls $SAMBA_DIRECTORY/usr/bin | xargs -I{} rsync -a --ignore-existing $BASE/squashfs-root/usr/bin/{} $BASE/squashfs-root/usr/old/bin/{}
    #

    
    # Install cross compiled software 
    cp -f -r $SAMBA_DIRECTORY/* $BASE/squashfs-root/ &> log_03_cp_samba.log
    checkerr $? "copy data" log_03_cp_samba.log


    if [[ -r $SAMBA_DIRECTORY/usr/sbin/smbd ]]; then
	echo -e "$GRN Found SAMBA binaries.$NOCOLOR"
	new_stage "Generate modified samba configuration"
	#
	# The approach we take is to create an smb.conf file
	# that is only loaded when a non default version of
	# samba is in operation. This way, if the system is
	# reverted to old firmware the original samba config
	# is preserved and will still work with the original
	# version of samba software.
	#
	
	# Remove no longer supported or needed smb.conf options
	cp $BASE/squashfs-root/etc/samba/smb.conf $BASE/squashfs-root/etc/samba/smb.conf.v4 &> log_04_smb_conf.log
	checkerr $? "smb.conf modification part 1" log_04_smb_conf.log
	cp $BASE/squashfs-root/etc/samba/smb.conf $BASE/squashfs-root/etc/samba/smb.conf.v3 &>> log_04_smb_conf.log
	checkerr $? "smb.conf modification part 2" log_04_smb_conf.log

	sed -i '1i#Copied from smb.conf.v4 at startup' $BASE/squashfs-root/etc/samba/smb.conf.v4
    
	sed -i '/auth methods/d' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/encrypt passwords/d' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/null passwords/d' $BASE/squashfs-root/etc/samba/smb.conf.v4
    
	# There is a poorly formatted line in the default
	# smb.conf file
    	#
	# min receivefile size = 1 ## disabled due to SOP receive file bug
    	#
	# This doesnt work with samba v4 and needs to be
	# removed. We replace it with
	# 
	# min receivefile size = 16384
    	# strict allocate = yes
    
	sed -i '/SOP receive file bug/a \        min receivefile size = 16384' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/SOP receive file bug/a \        strict allocate = yes' $BASE/squashfs-root/etc/samba/smb.conf.v4	
	sed -i '/SOP receive file bug/d' $BASE/squashfs-root/etc/samba/smb.conf.v4
    
	# Replace and update old appletalk configuration
	sed -i '/netatalk/a \        multicast dns register = yes' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/netatalk/a \        fruit:time machine = yes' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/netatalk/a \        fruit:model = RackMac' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/netatalk/a \        vfs objects = catia fruit streams_xattr' $BASE/squashfs-root/etc/samba/smb.conf.v4
	sed -i '/netatalk/d' $BASE/squashfs-root/etc/samba/smb.conf.v4
	
	# Add a startup script that checks samba version
	# before the main samba startup script is run and
	# loads the new modified samba configuration if
	# required.

	if [[ ! -r samba-version-check ]]; then
	    echo -e "$RED Error :$NOCOLOR Unable to find samba-version-check"
	    echo "Needed to setup samba configuration"
	    exit 1
	fi

	cp samba-version-check $BASE/squashfs-root/etc/init.d/
	chmod a+x $BASE/squashfs-root/etc/init.d/samba-version-check
	ln -s ../init.d/samba-version-check $BASE/squashfs-root/etc/rcS.d/S60samba-version-check

	#
	# Put a message on the About page indicating
	# that we have installed a new version of Samba. We
	# simply overwrite the old English language Tappin
	# message.

	if [[ -r $BASE/squashfs-root/usr/local/include/samba-4.0/samba/version.h ]]; then
	    SAMBA_VERSION=$(cat $BASE/squashfs-root/usr/local/include/samba-4.0/samba/version.h | grep SAMBA_VERSION_STRING= | cut -d= -f2)
	    sed -i "s#Seagate Remote Access powered by Tappin#Samba ${SAMBA_VERSION} - samba.org#g" $BASE/squashfs-root/cirrus/application/language/en/cirrus_lang.php
	fi
    fi
fi  

if [[ -n $UIMAGE ]]; then
    new_stage "Copy uImage to firmware"
    cp $UIMAGE $BASE/uImage &> log_05_copy_uImage.log
    checkerr $? "Copy uImage to firmware" log_05_copy_uImage.log
fi

if [[ -n $ROOT_PW ]]; then
    new_stage "Enable su access"
    #
    # Enable root ssh (some people dont like this but I cant see a problem)
    #
    if [ "$(grep "^PermitRootLogin yes" $BASE/squashfs-root/etc/ssh/sshd_config)" = "" ]; then
	sed s#"^PermitRootLogin without-password"#"PermitRootLogin yes"#g -i $BASE/squashfs-root/etc/ssh/sshd_config
    fi;
    if [ "$(grep "\"users,nogroup,wheel" $BASE/squashfs-root/usr/sbin/ba-upgrade-finish)" = "" ]; then
	sed s#"\"users,nogroup"#"\"users,nogroup,wheel"#g -i $BASE/squashfs-root/usr/bin/usergroupmgr.sh;
    fi;
    if [ "$(grep "usermod -a -G users,wheel" $BASE/squashfs-root/usr/sbin/ba-upgrade-finish)" = "" ]; then
	sed s#"usermod -a -G nogroup"#"usermod -a -G users,wheel,nogroup"#g -i $BASE/squashfs-root/usr/sbin/ba-upgrade-finish;
    fi;

    #
    # Make sure the root password change scripts are
    # available to copy into the firmware.
    #
    if [ ! -r change-root-pw.sh ]; then
	echo -e "$RED Error :$NOCOLOR Unable to find change-root-pw.sh script"
	echo "Needed to set root password"
	exit 1
    fi

    if [ ! -r disable-change-root-pw.sh ]; then
	echo -e "$RED Error :$NOCOLOR Unable to find disable-change-root-pw.sh script"
	echo "Needed to set root password"
	exit 1
    fi
    sed s#XXXXX#$ROOT_PW#g change-root-pw.sh > $BASE/change-root-pw.sh.modified
    
    cp $BASE/change-root-pw.sh.modified $BASE/squashfs-root/etc/init.d/change-root-pw.sh
    cp disable-change-root-pw.sh $BASE/squashfs-root/etc/init.d/disable-change-root-pw.sh
    chmod a+x $BASE/squashfs-root/etc/init.d/change-root-pw.sh
    chmod a+x $BASE/squashfs-root/etc/init.d/disable-change-root-pw.sh
    ln -s ../init.d/change-root-pw.sh $BASE/squashfs-root/etc/rcS.d/S90change-root-pw.sh
    ln -s ../init.d/disable-change-root-pw.sh $BASE/squashfs-root/etc/rcS.d/S91disable-change-root-pw.sh

    #
    # Make sure su and sudo are executable. In some versions
    # of firmware Seagate have turned off the x attribute!
    
    chmod 4555 $BASE/squashfs-root/usr/bin/sudo
    chmod 4555 $BASE/squashfs-root/usr/bin/su
fi

# By default we disable the defunct TappIn service. 
#
# See https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/
#
if [[ -z $KEEP_TAPPIN ]]; then
    new_stage "Disable and Remove TappIn service"
    rm -rf $BASE/squashfs-root/apps/tappin
    find  $BASE/squashfs-root/etc/ -name *tappinAgent* -exec rm {} +
    sed -i "s#Remote access allows you to access your files anywhere in the world using a web browser. To use, you can download apps for iPhone, iPad, Android, Kindle Fire, and Windows Phone.#The Seagate Central remote access service is defunct. It can not be activated in this version of firmware.#g" $BASE/squashfs-root/cirrus/application/language/en/cirrus_lang.php
fi

# By default we disable the defunct Segate media service. 
# Note that this is NOT the twonky DLNA media server
#
# See https://www.seagate.com/support/downloads/seagate-media/
#
if [[ -z $KEEP_SEAGATE_MEDIA ]]; then
    new_stage "Disable and Remove Seagate Media app service"
    rm -rf $BASE/squashfs-root/media_server
    find  $BASE/squashfs-root/etc/ -name *media_server* -exec rm {} +
    sed -i "s#The Seagate Media app allows you to access your media anywhere in the world. Download the Seagate Media app for iPhone, iPad, Android, and Kindle Fire from your mobile device’s app store.#The Seagate Media app is now defunct. This service cannot be activated in this version of Seagate Central firmware#g" $BASE/squashfs-root/cirrus/application/language/en/cirrus_lang.php
fi


# In order to support newly installed cross compiled
# software we add /usr/local/bin and /usr/local/sbin to
# the default PATH
#
if [[ -z $NO_USR_LOCAL_PATH ]]; then
    new_stage "Add /usr/local/[s]bin to default PATH"
    sed -i '/^ENV_SUPATH/c \ENV_SUPATH      PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' $BASE/squashfs-root/etc/login.defs
    sed -i '/^ENV_PATH/c \ENV_PATH        PATH=/usr/local/bin:/bin:/usr/bin' $BASE/squashfs-root/etc/login.defs
fi

#
# Generate the small descriptor file associated
# with the firmware update
#
new_md5="$(md5sum $BASE/rfs.squashfs  | cut -d" " -f1)" 
cp $BASE/config.ser $BASE/config.ser.orig
sed -i "/version/c version=${new_version}" $BASE/config.ser
sed -i "/release_date/c release_date=${new_release_date}" $BASE/config.ser
sed -i "/rfs/c rfs=${new_md5}" $BASE/config.ser

#
# Modify the file that identifies the firmware
# version.
sed -i "/version/c version=${new_version}" $BASE/squashfs-root/etc/config.ser
sed -i "/release_date/c release_date=${new_release_date}" $BASE/squashfs-root/etc/config.ser


new_stage "Creating new firmware archive"

# First we delete the old archive.
rm $BASE/rfs.squashfs >& log_06_mksquashfs.log
checkerr $? "Delete old archive" log_06_mksquashfs.log
#
# Note that we are using the lowest and
# least CPU intenstive form of compression here.
# This is because the Seagate Central is not very
# powerful and will take a long time to decompress
# a heavily compressed file.
#
mksquashfs $BASE/squashfs-root $BASE/rfs.squashfs -all-root -noappend -Xcompression-level 1 &>> log_06_mksquashfs.log
checkerr $? "mksquashfs squashfs-root" log_06_mksquashfs.log


tar -C $BASE -czvf $SEAGATE_NEW_FIRMWARE rfs.squashfs uImage config.ser &> log_07_tar_firmware.log
checkerr $? "tar up firmware" log_07_tar_firmware.log

if [[ -z $SKIP_CLEANUP ]]; then
    new_stage "Cleanup"
    rm -rf $BASE
#    rm -rf squashfs-root
#    rm -rf uImage config.ser config.ser.orig
#    rm -rf rfs.squashfs
#    rm -rf set_default_root_pw.modified
fi
echo
echo -e "$GRN Success!! $NOCOLOR"
echo -e "$GRN Created $NOCOLOR $SEAGATE_NEW_FIRMWARE"
if [[ -n $ROOT_PW ]]; then
    echo -e "$GRN Root Password :$NOCOLOR $ROOT_PW"
    echo $ROOT_PW > $SEAGATE_NEW_FIRMWARE.root-password.txt
    echo -e "$GRN Generated text file :$NOCOLOR $SEAGATE_NEW_FIRMWARE.root-password.txt"
fi

