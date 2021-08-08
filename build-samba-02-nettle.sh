#!/bin/bash
source build-samba-common
source build-samba-functions
check_source_dir "nettle"
change_into_obj_directory
configure_it --prefix=$DEST --host=$ARCH \
	     --disable-openssl \
	     --disable-documentation
make_it
install_it
finish_it
