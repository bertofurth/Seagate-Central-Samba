#!/bin/bash
source build-samba-common
source build-samba-functions
check_source_dir "acl"
change_into_obj_directory
configure_it --prefix=$DEST --host=$ARCH
did_configure_work
make_it
install_it
finish_it

