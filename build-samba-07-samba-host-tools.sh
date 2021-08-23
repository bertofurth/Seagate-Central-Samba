#!/bin/bash
#
# This build script differs from the others as
# we want this build step to build executables
# for the host building system, not the target Seagate Central.
#
# In this script we are building local versions
# of the "asn1_compile" and "compile_et" tools
# which are needed to compile the complete
# project.
#
# N.B. Don't "source build-common" here

source build-functions
check_source_dir "samba"

#
# N.B. Samba does not support out of tree builds
# https://wiki.samba.org/index.php/Waf#Out_of_tree_builds
# so we do not change into the normal "OBJ"
# directory. We just stay in the source directory.

configure_it --without-systemd \
	     --disable-python --without-ad-dc \
	     --with-shared-modules='!vfs_snapper' \
	     --without-pam \
	     --without-libarchive \
	     --without-json \
	     --without-acl-support \
	     --without-ldap \
	     --without-ads
make asn1_compile
if [ $? -ne 0 ]; then
    echo
    echo make host asn1_compile tool for $LIB_NAME failed. Exiting
    exit -1
fi
make compile_et
if [ $? -ne 0 ]; then
    echo
    echo make host compile_et tool for $LIB_NAME failed. Exiting
    exit -1
fi
#
# Save copies of the host versions of the tools to the
# root of the source tree. These will be used in the next
# build step where we compile samba for the target.
cp bin/asn1_compile ./asn1_compile.local
cp bin/compile_et ./compile_et.local

echo
echo "****************************************"
echo
echo "Success! Finished building $LIB_NAME host tools ($SECONDS seconds)"
echo
echo "****************************************"
echo
