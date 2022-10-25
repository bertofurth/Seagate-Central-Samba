#!/bin/bash
source build-common
source build-functions
check_source_dir "libtirpc"
change_into_obj_directory

#
# Rebuilding libtirpc with krb5 support
# by NOT specifying --disable-gssapi
#
# Specify the location of the locally built
# krb-config script
#
export KRB5_CONFIG=$BUILDHOST_DEST/$EXEC_PREFIX/bin/krb5-config 

configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH  \
	     --enable-static \
	     --disable-gssapi
make_it
install_it
finish_it
