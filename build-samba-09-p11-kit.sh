#!/bin/bash
source build-common
source build-functions
check_source_dir "p11-kit"
change_into_obj_directory

#
# --without-libffi : Disable foreign language functions.
#

configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH \
	     --without-libffi
make_it
install_it
finish_it

