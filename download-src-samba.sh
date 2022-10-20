#!/bin/sh

# Run this script to download and extract the versions
# of source code this project was tested with. Unless
# otherwise noted these are the latest stable versions
# available at the time of writing.

# Based on gcc's download_prerequisites script

gmp='http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz'
nettle='http://mirrors.kernel.org/gnu/nettle/nettle-3.8.tar.gz'
attr='http://download.savannah.gnu.org/releases/attr/attr-2.5.1.tar.xz'
acl='http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz'
zlib='https://zlib.net/fossils/zlib-1.2.13.tar.gz'
libunistring='http://mirrors.kernel.org/gnu/libunistring/libunistring-1.0.tar.xz'
libidn2='http://mirrors.kernel.org/gnu/libidn/libidn2-2.3.3.tar.gz'
libtasn1='http://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.18.0.tar.gz'
p11kit='https://github.com/p11-glue/p11-kit/releases/download/0.24.1/p11-kit-0.24.1.tar.xz'
gnutls='https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.6.tar.xz'
openldap='https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.3.tgz'
libtirpc='https://downloads.sourceforge.net/project/libtirpc/libtirpc/1.3.2/libtirpc-1.3.2.tar.bz2'
LinuxPAM='https://github.com/linux-pam/linux-pam/releases/download/v1.5.2/Linux-PAM-1.5.2.tar.xz'
samba='https://www.samba.org/ftp/samba/stable/samba-4.14.14.tar.gz'
krb5='https://kerberos.org/dist/krb5/1.20/krb5-1.20.tar.gz'

echo_archives() {
    echo "${gmp}"
    echo "${nettle}"
    echo "${attr}"
    echo "${acl}"
    echo "${zlib}"
    echo "${libunistring}"
    echo "${libidn2}"
    echo "${libtasn1}"
    echo "${p11kit}"
    echo "${gnutls}"
    echo "${openldap}"
    echo "${libtirpc}"
    echo "${LinuxPAM}"
    echo "${samba}"
    echo "${krb5}"
}

die() {
    echo "error: $@" >&2
    exit 1
}

mkdir -p src
cd src

if type wget > /dev/null ; then
    fetch='wget --backups=1'
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


