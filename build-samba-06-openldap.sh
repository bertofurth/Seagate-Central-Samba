#!/bin/bash
source build-samba-common
source build-samba-functions
check_source_dir "openldap"
#
# Copy ldap header files available in the source code
# to the target directory
#
cp $LIB_NAME/include/lber.h \
   $LIB_NAME/include/ldap.h \
   $LIB_NAME/include/ldap_cdefs.h \
   $LIB_NAME/include/ldap_schema.h \
   $LIB_NAME/include/ldap_utf8.h \
   $LIB_NAME/include/slapi-plugin.h  \
   $BUILDHOST_DEST/$DEST/include
if [ $? -ne 0 ]; then
    echo
    echo Copying source based header files for $LIB_NAME failed. Exiting
    exit 0
fi

change_into_obj_directory
configure_it --prefix=$DEST --host=$ARCH \
	     --with-yielding_select=no \
	     --disable-slapd \
	     --disable-syncprov \
	     --disable-backends \
	     --disable-overlays
#
# Note that we only need the include headers from
# this openldap library, not the binaries. The binaries
# are already installed on the Seagate Central. Therefore
# we only need to make depend
#
make depend
if [ $? -ne 0 ]; then
    echo
    echo make depend for $LIB_NAME failed. Exiting
    exit -1
fi
cp include/lber_types.h \
   include/ldap_config.h \
   include/ldap_features.h \
   $BUILDHOST_DEST/$DEST/include
if [ $? -ne 0 ]; then
    echo
    echo Copying generated header files for $LIB_NAME failed. Exiting
    exit 0
fi

#
# We also need to create the following links within
# the set of Seagate Central libraries so that
# samba can use the standard ldap library names for
# linking. If this step is not done then we'll get
# errors during samba compilation related to ldap_*
# objects
#
# This is necessary because some of the library names
# used on the Seagate Central are not in a standard
# format.

ln -s /usr/lib/libldap-2.3.so.0 $BUILDHOST_DEST/$DEST/lib/libldap.so
ln -s libldap-2.3.so.0 $SEAGATE_LIBS_BASE/usr/lib/libldap.so
ln -s /usr/lib/liblber-2.3.so.0 $BUILDHOST_DEST/$DEST/lib/liblber.so
ln -s liblber-2.3.so.0 $SEAGATE_LIBS_BASE/usr/lib/liblber.so

finish_it
