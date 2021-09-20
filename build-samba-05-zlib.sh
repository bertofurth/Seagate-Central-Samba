#!/bin/bash
source build-common
source build-functions
check_source_dir "zlib"
change_into_obj_directory
configure_it --prefix=$PREFIX \
	     --eprefix=$EXEC_PREFIX
make_it
install_it
finish_it
