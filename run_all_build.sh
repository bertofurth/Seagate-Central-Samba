#!/bin/bash
#
# Run all the samba cross compiling scripts in order.
#
# Only run this if you're confident that the
# scripts will work. Run them individually on
# the first attempt.
#
checkerr()
{
    if [ $? -ne 0 ]; then
	echo "Failure. Aborting "
	exit 1
    fi
}

./build-samba-01-gmp.sh
checkerr
./build-samba-02-nettle.sh
checkerr
./build-samba-03-acl.sh
checkerr
./build-samba-04-libtasn1.sh
checkerr
./build-samba-05-gnutls.sh
checkerr
./build-samba-06-openldap.sh
checkerr
./build-samba-07-samba-host-tools.sh
checkerr
./build-samba-08-samba.sh
checkerr
