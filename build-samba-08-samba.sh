#!/bin/bash
#
# Set this to the name of the cross-answers file.
#
CROSS_ANSWERS=samba-4.14.6-cross-answers-seagate-central.txt

source build-common
source build-functions
check_source_dir "samba"

if [ ! -r $CROSS_ANSWERS ]; then
    echo
    echo "Cross answers file $CROSS_ANSWERS not accessible."
    echo "This file needs to be present and filled in"
    echo "properly in order to cross compile samba."
    echo
else
    echo "Cross answers file $CROSS_ANSWERS found!"
fi

if [ -r $SEAGATE_LIBS_BASE/usr/include/md5.h ]; then 
    echo
    echo $SEAGATE_LIBS_BASE/usr/include/md5.h
    echo may cause compilation to fail when compiling
    echo source4/heimdal/lib/hcrypto/evp-hcrypto.c
    echo
    echo This file is going to be renamed to md5.h.orig.
    echo
    mv -f $SEAGATE_LIBS_BASE/usr/include/md5.h $SEAGATE_LIBS_BASE/usr/include/md5.h.orig
else
    echo "$SEAGATE_LIBS_BASE/usr/include/md5.h does not exist. Good!"
fi

#
# N.B. Samba does not support out of tree builds
# https://wiki.samba.org/index.php/Waf#Out_of_tree_builds
# so we cheat by setting OBJ to blank to force the
# build process to use the source directory for the build.
export OBJ=""
change_into_obj_directory

if [ ! -x asn1_compile.local ]; then
    echo
    echo No asn1_compile.local binary found in $LIB_NAME
    echo Did you run the previous step properly?
fi

if [ ! -x compile_et.local ]; then
    echo
    echo No compile_et.local binary found in $LIB_NAME
    echo Did you run the previous step properly?
fi


#
# Configure the build. Some parameters explained.
# prefix : The location on the target device where the binaries
#          will be stored.
# cross-compile : Tell SAMBA that we're cross compiling.
# cross-answers : This file gives the configure stage answers to
#                 questions about the target host that it can't figure
#                 out automatically. This is needed when cross
#                 compiling samba.
# bundled-libraries=!asn1_compile,!compile_et : This relates to an
#                 issue where we need to use locally compiled versions
#                 of these tools rather than versions compiled for
#                 the target.
# enable-fhs : This is necessary when we're using $DEST of /usr/local
#              It tells SAMBA to use the standard style of file hierachy.
# *dir : Configuration and state file folders set up as per the original
#        Seagate Central SAMBA daemon. This could be left out on a
#        non Seagate Central style system.
#
# The options following are just customizations disabling functionality
# that I don't think is necessary and that makes it easier to cross compile
# SAMBA. If you're really keen you can go ahead and find the libraries required
# to re-enable these features and have them work. For example, it may be
# that you want your Seagate Central to be a Domain Controller in which case
# you'll have to remove the "--disable_python --without-ad-dc" flags and
# make sure you have all the extra libraries required to suit that. This
# is functionality beyond what's offered on the Seagate Central natively.
#

configure_it --prefix=$DEST --cross-compile \
	     --cross-answers=../$CROSS_ANSWERS \
	     --bundled-libraries=!asn1_compile,!compile_et \
	     --enable-fhs --sysconfdir=/etc --localstatedir=/var \
	     --with-configdir=/etc/samba --with-logfilebase=/var/log \
	     --with-lockdir=/var/lock --with-statedir=/var/lock \
	     --with-cachedir=/var/lock \
	     --with-piddir=/var/run \
	     --with-privatedir=/etc/samba/private \
	     --with-sockets-dir=/var/run \
	     --without-systemd \
	     --disable-python --without-ad-dc \
	     --without-json \
	     --without-libarchive \
	     --with-shared-modules='!vfs_snapper' \
	     --without-gpgme \
	     --without-regedit

#
# Compile the cross-compiled versions of the asn1_compile and
# compile_et tools then overwrite them with the host versions
#
# This is a necessary workaround to overcome a problem where
# cross compiling SAMBA can lead to errors similar to
# "Cannot execute binary file" appearing during the build process.
#
make asn1_compile
if [ $? -ne 0 ]; then
    echo
    echo make target asn1_compile tool for $LIB_NAME failed. Exiting
    exit 0
fi

make compile_et
if [ $? -ne 0 ]; then
    echo
    echo make target compile_et tool for $LIB_NAME failed. Exiting
    exit 0
fi

cp ./asn1_compile.local bin/default/source4/heimdal_build/asn1_compile
if [ $? -ne 0 ]; then
    echo
    echo Unable to copy host asn1_compile tool. Exiting
    exit 0
fi
cp ./compile_et.local bin/default/source4/heimdal_build/compile_et
if [ $? -ne 0 ]; then
    echo
    echo Unable to copy host compile_et tool. Exiting
    exit 0
fi

#
# These settings are required to take advantage of the
# host executable asn1_compile and compile_et tools built
# in the previous step.
#
export USING_SYSTEM_ASN1_COMPILE=1
export ASN1_COMPILE=./asn1_compile
export USING_SYSTEM_COMPILE_ET=1
export COMPILE_ET=./compile_et

make_it
install_it
finish_it
