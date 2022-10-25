#!/bin/bash
source build-common
source build-functions
check_source_dir "libtirpc"
change_into_obj_directory

# We first build libtirpc without krb5.
#
# Samba needs libtirpc but samba doesn't work well
# with externally built kerberos / krb5.
#
# For this reason we first build libtirpc without krb5
# by specifying "--disable-gssapi"
#
# After samba is built we build krb5 and rebuild
# libtirpc with krb5 included.
#
configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH  \
	     --enable-static \
	     --disable-gssapi
make_it
install_it
finish_it
