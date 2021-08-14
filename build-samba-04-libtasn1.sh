#!/bin/bash
source build-common
source build-functions
check_source_dir "libtasn1"
change_into_obj_directory
configure_it --prefix=$PREFIX --exec-prefix=$EXEC_PREFIX \
	     --host=$ARCH \
	     --disable-doc \
	     --enable-cross-guesses=conservative
make_it
install_it
finish_it

