#!/bin/bash
source build-common
source build-functions
check_source_dir "acl"
change_into_obj_directory
configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX \
	     --sbindir=$EXEC_PREFIX \
	     --host=$ARCH
make_it
install_it
finish_it

