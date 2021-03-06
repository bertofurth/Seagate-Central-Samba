#!/bin/bash
#
# Set this to the name of the cross-answers file.
#
CROSS_ANSWERS=$(basename $(ls -1drv cross-answers* | head -1))

# Below we set "/usr" as the directory for executables
# as opposed to the default of /usr/local because we
# want to overwrite the old samba binaries in /usr/bin
# and /usr/sbin.
#
EXEC_PREFIX=${EXEC_PREFIX:-/usr}
source build-common
source build-functions
check_source_dir "samba"

if [ ! -r $TOP/$CROSS_ANSWERS ]; then
    echo
    echo "Cross answers file not found!"
    echo "This file needs to be present and filled in"
    echo "properly in order to cross compile samba."
    echo
    exit 1
else
    echo "Using cross answers file $CROSS_ANSWERS"
fi

#
# N.B. Samba does not support out of tree builds
# https://wiki.samba.org/index.php/Waf#Out_of_tree_builds
# so we do not change into the normal "OBJ"
# directory. We just stay in the source directory.

if [ ! -x asn1_compile.local ]; then
    echo
    echo No asn1_compile.local binary found in $SRC/$LIB_NAME
    echo Did you run the previous step properly?
fi

if [ ! -x compile_et.local ]; then
    echo
    echo No compile_et.local binary found in $SRC/$LIB_NAME
    echo Did you run the previous step properly?
fi

#
# Configure the build. Some parameters explained.
# prefix : The location on the target device where libraries
#          and other resources will be stored.
# exec-prefix : The location where binary executables will
#               be stored.
# cross-compile : Tell SAMBA that we're cross compiling.
# cross-answers : This file gives the configure stage answers to
#                 questions about the target host that it can't figure
#                 out automatically. This is needed when cross
#                 compiling samba.
# bundled-libraries=!asn1_compile,!compile_et : This relates to an
#                 issue where we need to use locally compiled versions
#                 of these tools rather than versions compiled for
#                 the target.
# enable-fhs : This is necessary when we're using $PREFIX of /usr/local
#              It tells SAMBA to use the standard style of file hierachy.
# with-*dir : Configuration and state file folders set up as per the original
#             Seagate Central SAMBA daemon. This could be left out on a
#             non Seagate Central style system.
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

configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --cross-compile \
	     --cross-answers=$TOP/$CROSS_ANSWERS \
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

cp ./asn1_compile.local `realpath bin/asn1_compile`
if [ $? -ne 0 ]; then
    echo
    echo Unable to copy host asn1_compile tool. Exiting
    exit 0
fi
cp ./compile_et.local `realpath bin/compile_et`
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

#
# Remove the /var/log /var/lock and /var/run directories
# from the cross built tree because they conflict with
# some of the existing directories already on the Seagate
# central.
rm -rf $BUILDHOST_DEST/var/log $BUILDHOST_DEST/var/lock $BUILDHOST_DEST/var/run

finish_it
