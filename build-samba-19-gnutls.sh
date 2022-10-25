#!/bin/bash
source build-common
source build-functions
check_source_dir "gnutls"
change_into_obj_directory

# gnutls doesn't like the following .la file
# temporarily rename it.
#
mv $BUILDHOST_DEST/$PREFIX/lib/libidn2.la $BUILDHOST_DEST/$PREFIX/lib/libidn2.la.orig

#
# Where the p11-kit headers are
#
export P11_KIT_CFLAGS=-I$BUILDHOST_DEST/$PREFIX/include/p11-kit-1

# Configure options:
#
# without-tpm : TPM is support for the Trusted Platform
# Module, a hardware module not included in the Seagate
# Central.
#

configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH \
	     --enable-static \
	     --enable-shared \
	     --without-tpm \
	     --enable-openssl-compatibility	     
make_it
install_it
mv $BUILDHOST_DEST/$PREFIX/lib/libidn2.la.orig $BUILDHOST_DEST/$PREFIX/lib/libidn2.la
finish_it

