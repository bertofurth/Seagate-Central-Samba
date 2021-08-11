#!/bin/bash
#
# Don't source build-common here as we want this
# build step to build executables for the host building
# system, not the target Seagate Central.
#
source build-functions
check_source_dir "samba"

#
# N.B. Samba does not support out of tree builds
# https://wiki.samba.org/index.php/Waf#Out_of_tree_builds
# so we cheat by setting OBJ to blank to force the
# build process to use the source directory for the build.
export OBJ=""
change_into_obj_directory
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
# Save the host versions of the tools to the root of
# the source tree.
cp bin/asn1_compile ./asn1_compile.local
cp bin/compile_et ./compile_et.local

echo
echo "****************************************"
echo
echo "Success! Finished building $LIB_NAME host tools ($SECONDS seconds)"
echo
echo "****************************************"
echo
