#!/bin/bash
source build-common
source build-functions
check_source_dir "nettle"
change_into_obj_directory
configure_it --prefix=$PREFIX --exec-prefix=EXEC_PREFIX \
	     --host=$ARCH \
	     --disable-openssl \
	     --disable-documentation
make_it
install_it
finish_it
