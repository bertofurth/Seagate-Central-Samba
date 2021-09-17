#!/bin/sh

# Run this script to download and extract the versions
# of source code this project was tested with. Unless
# otherwise noted these are the latest stable versions
# available at the time of writing.

# Based on gcc's download_prerequisites script

gmp='http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz'
nettle='http://mirrors.kernel.org/gnu/nettle/nettle-3.7.3.tar.gz'
acl='http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz'
libtasn1='http://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz '
gnutls='https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz'
openldap='https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz'
samba='https://www.samba.org/ftp/samba/stable/samba-4.14.6.tar.gz'

echo_archives() {
    echo "${gmp}"
    echo "${nettle}"
    echo "${acl}"
    echo "${libtasn1}"
    echo "${gnutls}"
    echo "${openldap}"
    echo "${samba}"

}

die() {
    echo "error: $@" >&2
    exit 1
}

mkdir -p src
cd src

if type wget > /dev/null ; then
    fetch='wget'
else
    if type curl > /dev/null; then
	fetch='curl -LO'
    else
	die "Unable to find wget or curl"
    fi    
fi


for ar in $(echo_archives)
do
	${fetch} "${ar}"    \
		 || die "Cannot download $ar"
        tar -xf "$(basename ${ar})" \
		 || die "Cannot extract $(basename ${ar})"
done
unset ar


