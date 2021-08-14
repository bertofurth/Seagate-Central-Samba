#!/bin/bash
source build-common
source build-functions
check_source_dir "gmp"
change_into_obj_directory
configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH
make_it
install_it
finish_it
