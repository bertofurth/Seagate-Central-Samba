#!/bin/bash
source build-common
source build-functions
check_source_dir "krb5"

# I'm not able to get the built version of
# kerberos working the samba. This script
# will seccessfully cross compile kerberos 
# however the result can't be used by
# samba itself.
#
# We leave it here for your reference because
# the process was a little unusual.
#

# krb5 source code is in the "src" subdirectory
# of the extracted directory rather than in the
# base extracted directory. This is unusual.
#
export LIB_NAME=$LIB_NAME/src


change_into_obj_directory

#
# krb5 needs these set for cross compiling otherwise you
# get "cannot test for xxxxx while cross compiling"
# errors.
# https://github.com/cockroachdb/cockroach/issues/38841
#
# 
export krb5_cv_attr_constructor_destructor=yes
export ac_cv_func_regcomp=yes
export ac_cv_printf_positional=yes



configure_it --prefix=$PREFIX \
	     --bindir=$EXEC_PREFIX/bin \
	     --sbindir=$EXEC_PREFIX/sbin \
	     --host=$ARCH

# It seems that the "krb5_cv_attr_constructor_destructor=yes"
# workaround doesn't always work so we manually set the
# appropriate define.
#
sed -i '/#undef DESTRUCTOR_ATTR_WORKS/c #define DESTRUCTOR_ATTR_WORKS 1' include/autoconf.h

make_it
install_it
finish_it
