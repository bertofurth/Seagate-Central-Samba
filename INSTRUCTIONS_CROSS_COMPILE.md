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
### A cross compilation suite on a build host
You can follow the instructions at

https://github.com/bertofurth/Seagate-Central-Toolchain

to generate a cross compilation suite that will generate binaries
suitable for the Seagate Central.

Note that an alternative approach would be to install gcc and other
build tools on the Seagate Central itself and perform the process on
the Seagate Central however the Seagate Central is an order of magnitude
slower than most modern PCs. It would mean that compiling something like 
this project on a Seagate Central could take many hours to complete.

### Know how to copy files between your build host and the Seagate Central. 
Not only should you know how to transfer files to and from your Seagate
Central NAS and the build host, ideally you'll know how to transfer files 
**even if the samba service is not working**. I would suggest
that if samba is not working to use FTP or SCP which should both still work.

### Have ssh access to the Seagate Central.
You'll need ssh access to issue commands on the Seagate Central command 
line. 

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
su or creating then upgrading to a new modified Seagate Central 
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

### Do not perform this procedure as the root user on the build machine
Some versions of the libraries being used in this procedure have flaws
that may cause the "make install" component of the build process try to 
overwrite parts of the building system's library directories.

For this reason it is **imperative** that you are not performing
this procedure as root on the build machine otherwise important 
components of your build system machine may be overwritten.

The only time during this procedure you should be acting as the 
root user on the build system is if you are deliberately installing 
new components on your build system to facilitate the building process. 
See the next pre-requisite for details.

### Required software on build host
As you perform the steps in this guide you will have to make sure that
your build host has appropriate software packages installed. I found that
I had to install the following packages and their preequisites on a basic
system to get the build working.

#### OpenSUSE Tumbleweed (Aug 2021)
zypper install -t pattern devel_basis
gcc-c++
lzip
libgnutls-devel
perl
perl-Parse-Yapp
rpcgen



BERTO THERES MORE

#### Debian 10 (Buster)
build-essential
BERTO THERES MORE


## Procedure
### Source code download and extraction
Download the files in this project to a new directory on your
build machine. This will be referred to as the base working 
directory going forward.

The next part of the procedure involves gathering the source code 
for each component and installing it into the working base directory.

Here we show the versions of software used when generating this guide. 
Download these using **wget**, **curl -O** or a similar tool. I've 
used the latest versions of these libraries available as of the writing 
of this guide unless a specific older version needs to be used in which 
case I've made a note.

* gmp-6.2.1  
https://gmplib.org/download/gmp/gmp-6.2.1.tar.lz

* nettle-3.3  (Couldn't get later versions working)     
https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz

* acl-2.3.1     
http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz

* libtasn1-4.17.0       
https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz

* gnutls-3.4.17  (v3.4.x is the version referred to in samba documentation)   
https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.17.tar.xz

* openldap-2.3.39  (Must be the same as version on Seagate Central)     
https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz

* samba-4.14.6     
https://download.samba.org/pub/samba/samba-4.14.6.tar.gz

Extract each file with the **tar -xf** command.

Here is an example of the commands used to download and extract these
source code archives

    wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.lz
    tar -xf gmp-6.2.1.tar.lz
    wget https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz
    tar -xf nettle-3.3.tar.gz
    wget http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
    tar -xf acl-2.3.1.tar.xz
    wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz
    tar -xf libtasn1-4.17.0.tar.gz
    wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.17.tar.xz
    tar -xf gnutls-3.4.17.tar.xz
    wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz
    tar -xf openldap-2.3.39.tgz
    wget https://download.samba.org/pub/samba/samba-4.14.6.tar.gz
    tar -xf samba-4.14.6.tar.gz

### Seagate Central libraries and headers
We need to copy the binary libraries and header files on the Seagate Central
to the build host so that they can be linked against during the build process.

There are many methods of copying information from the Seagate Central but 
in this example we use the secure copy program - scp.

First change into the sc-libs from the build workspace root and create
the required lib, usr/lib, and usr/include sub directories.

    mkdir -p sc-libs
    cd sc-libs
    mkdir -p lib usr/lib usr/include 
    
Copy over the binaries from the Seagate Central /lib directoryusing the
name of a valid user on your Segate Central. In these examples we use the
"admin" user. Note that after execution of this command you'll be prompted 
for the user's password.

    scp admin@NAS-1.lan:/lib/* ./lib/
   
Next copy over the libraries in the /usr/lib directory

    scp admin@NAS-1.lan:/usr/lib/* ./usr/lib

Finally copy over the header include files. Note the -r parameter in scp to
copy subdirectories as well.
    
    scp -r admin@NAS-1.lan:/usr/include/* usr/include/
   
### Special library and header customizations   
After the libraries and headers are copied over we need to make a slight
modification to **usr/lib/libc.so** and **usr/lib/libpthread.so**. These
files contain the names of other libraries but they contain absolute
paths that will not work in our build environment. To remove these
absolute paths run the following commands in the sc-libs directory.

    sed -i.orig -e 's/\(\/lib\/\|\/usr\/lib\/\)//g' usr/lib/libc.so
    sed -i.orig -e 's/\(\/lib\/\|\/usr\/lib\/\)//g' usr/lib/libpthread.so

The original versions of the files will be kept with a .orig suffix.

We also need to rename the **usr/include/md5.h** header file so that it is
not used in the compilation process.

    mv -f usr/include/md5.h usr/include/md5.h.orig

### Customize the scripts
Change back to the base working directory and edit the ....
BERTO Edit build-samba-common to setup parameters


### Run the build scripts in order
The build scripts are named in the numerical order that they need to be
executed.

Here is the current order.

    ./build-samba-01-gmp.sh
    ./build-samba-02-nettle.sh
    ./build-samba-03-acl.sh
    ./build-samba-04-libtasn1.sh
    ./build-samba-05-gnutls.sh
    ./build-samba-06-openldap.sh
    ./build-samba-07-samba-host-tools.sh
    ./build-samba-08-samba.sh

My suggestion is to not blindly execute all the scripts. You need to check 
to ensure that each script reports success before executing the next script.

Assuming everything works correctly the scripts will take about 


PC 5 mins for first 7 components Another 5 for the last samba build



#### tar and copy over 

There are two methods of copying files from the Seagate Central



Gather the source code for samba and the component libraries. 

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

* gmp-6.2.1  
https://gmplib.org/download/gmp/gmp-6.2.1.tar.lz

* nettle-3.3  (Couldn't get later versions working)     
https://ftp.gnu.org/gnu/nettle/nettle-3.3.tar.gz

* acl-2.3.1     
http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz

* libtasn1-4.17.0       
https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz

* gnutls-3.4.17  (v3.4.x is the version referred to in samba documentation)   
https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.17.tar.xz

* openldap-2.3.39  (Must be the same as version on Seagate Central)     
https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz

* samba-4.14.6     
https://download.samba.org/pub/samba/samba-4.14.6.tar.gz





### Troubleshooting

The vast majority of problems will be due to

 * A needed build system component has not been installed.
 * The "Special library and header customizations" step was skipped.
 * Weird issues with the samba in-tree build system

If you encounter problems compiling the samba component then make sure to 
always have a clean source tree at the start of each build. This means
deleting the samba source directory and then re-expanding the samba tar 
archive to generate a fresh new samba source directory.

Cross compiling samba is difficult and there are a lot of articles and posts
that detail the trouble people have had with this process so hopefully by 
following this guide you will avoid most of those problems.

