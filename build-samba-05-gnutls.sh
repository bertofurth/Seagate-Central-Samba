#!/bin/bash
source build-common
source build-functions
check_source_dir "gnutls"
change_into_obj_directory
configure_it --prefix=$DEST --host=$ARCH \
	     --disable-doc \
	     --disable-cxx \
	     --disable-tools \
	     --disable-tests \
	     --enable-static \
	     --enable-shared \
	     --without-zlib \
	     --without-p11-kit \
	     --with-included-unistring \
	     --enable-openssl-compatibility
did_configure_work
make_it
install_it
finish_it

