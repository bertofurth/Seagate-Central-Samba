# INSTRUCTIONS_CROSS_COMPILE.md
Instructions for cross compiling samba v4.14.6 for the Seagate Central NAS

## Summary
This is a guide that describes how to cross compile replacement samba
software suitable for installation on a Seagate Central NAS device.

Installation of the cross compiled software is covered in both

INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md

and

INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md

in this directory.

These instructions were tested with a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations and
firmware versions.

## Prequisites 

THIS IS ONLY FOR MANUAL INSTALLATION

### Know how to copy files between your build host and the Seagate Central. 
Ideally you'll know how to transfer files between the build host and the
Seagate Central **even if the samba service is not working**. I would suggest
that if samba is not working to use FTP or SCP which should both still work.

### Have ssh access to the Seagate Central.
You'll need to issue commands on the Seagate Central command line. 

If you are especially adept with a soldering iron and have the right 
equipment then you could get serial console access but this quite difficult 
and is **not required**. There are some very brief details of the 
connections required at

http://seagate-central.blogspot.com/2014/01/blog-post.html
Archive : https://archive.ph/ONi4l

### Have su/root access to the Seagate Central.
Make sure that you can establish an ssh session to the Seagate Central
and that you can succesfully issue the **su** command to gain root
priviledges.

Some later versions of Seagate Central firmware deliberately disable
su access however there are a number of guides on how to restore su
access on the Seagate Central. The following guide suggests either 
temporarily reverting back to an older firmware version that allows
su or creating then "upgrading" to a new modified Seagate Central 
firmware image that re-enables su access.

https://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html
Archive : https://archive.ph/sEoOx

Note that the instructions in the above link try to perform the process 
of creating the new firmware image on the Seagate Central itself. It's 
much easier to do it on an external system instead.

There are is also a useful script available at another project that 
automatically modifies a stock firmware image in such a way that it
upgrading to it will re-allow su access.

https://github.com/detain/seagate_central_sudo_firmware
Archive : https://archive.ph/rg39t

BERTO : CREATE A SCRIPT TO DO THIS AUTOMATICALLY

### Do not perform this procedure as the root user
Some of the libraries being used in this procedure have flaws
that cause the "make install" component of the build process
try to overwrite parts of the building system's library
directories regardless of how they are configured.

For this reason it is **imperative** that you are not performing
this procedure as root.

The only time during this procedure you should be acting as the 
root user on the build system is if you are deliberately installing 
new components on your build system to facilitate the building process. 
See the next pre-requisite for details.

### Build host 
As you perform the steps in this guide you will have to make sure that
your build host has appropriate software installed. You may encounter
error messages during the process complaining about missing commands 
or tools. Hopefully it won't be too onerous to figure out how to work
your package management system in order to install them.

OpenSUSE Tumbleweed


Debian 
BERTO BERTO



Things to install on your building host


Actions

Copy the libraries off the Seagate Central to a directory on your building host

Download the libraries  (script)

Run the scripts to compile the libraries

Should end up with a directory containing the binaries.


Modify 

./usr/lib/libc.so.orig
./usr/lib/libpthread.so.orig




Compile libraries in the following order as later libraries may require 
resources from earlier ones.

Here we show the versions used when generating this guide. I've used the 
latest versions available as of the writing of this guide so it may be
that you can use other even more recent versions. In some cases I found that
an older specific version needs to be used in which case I've made a note.

gmp-6.2.1  
https://gmplib.org/download/gmp/gmp-6.2.1.tar.lz

nettle-3.3   (N.B. Couldn't get later versions working)
https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz

acl-2.3.1
http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz

libtasn1-4.17.0
https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz

gnutls-3.4.17 (v3.4.x is the version referred to in samba documentation)
https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.17.tar.xz

openldap-2.3.39 (Must be the same as version on Seagate Central)
https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz

Note that all we need from this particular version of OpenLDAP is the header
include files. The binary library is already present on the Seagate Central and
we don't want to overwrite it. 


samba-4.14.6
https://download.samba.org/pub/samba/samba-4.14.6.tar.gz












