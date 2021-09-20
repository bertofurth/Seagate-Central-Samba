#!/bin/bash
source build-common
source build-functions
check_source_dir "Linux-PAM"
change_into_obj_directory

# disable-nis : nis is not needed and requires
# extra libraries to build.
#
# includedir=$PREFIX/include/security : For some
# reason Linux-PAM won't put include files in
# the expected place (include/security) if the
# PREFIX isn't /usr
#
configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH  \
	     --enable-static \
	     --includedir=$PREFIX/include/security \
	     --disable-nis

make_it
install_it
finish_it
