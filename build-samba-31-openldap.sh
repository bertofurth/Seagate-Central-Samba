#!/bin/bash
source build-common
source build-functions
check_source_dir "openldap"
change_into_obj_directory

# openldap doesn't like the following .la file
# temporarily rename it.
#
mv $BUILDHOST_DEST/$PREFIX/lib/libgnutls.la $BUILDHOST_DEST/$PREFIX/lib/libgnutls.la.orig

configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH \
	     --with-yielding_select=no 

# Cross compiling openLDAP gives error
#
# undefined reference to `lutil_memcmp'
#
# Adding configure option "ac_cv_func_memcmp_working=yes"
# should fix this but it doesn't.
#
# The only solutions I can find are similar to
# the one below where we forcibly stop
# NEED_MEMCMP_REPLACEMENT from being defined.
#
sed -i '/NEED_MEMCMP_REPLACEMENT/d' $OBJ/$LIB_NAME/include/portable.h
if [ $? -ne 0 ]; then
    echo
    echo Failed modifying $OBJ/$LIB_NAME/include/portable.h with sed
    exit -1
fi
make_it
install_it

mv $BUILDHOST_DEST/$PREFIX/lib/libgnutls.la.orig $BUILDHOST_DEST/$PREFIX/lib/libgnutls.la

finish_it
