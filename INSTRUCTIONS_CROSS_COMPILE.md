# INSTRUCTIONS_CROSS_COMPILE.md
## Summary
This is a guide that describes how to cross compile replacement samba
software suitable for installation on a Seagate Central NAS device.

Manual installation of the cross compiled software is covered by
**INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md**

Installation of the cross compiled software using the easier but less
flexible firmware upgrade method is covered by
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**

This procedure has been tested to work on the following building
platforms

* OpenSUSE Tumbleweed (Aug 2021) on x86  gcc-11.2.0 make-4.3
* OpenSUSE Tumbleweed (Aug 2021) on Raspberry Pi 4B  gcc-11.2.0 make-4.3
* Debian 10 (Buster) on x86  gcc-11.2.0 make-4.2.1

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations and
firmware versions.

## Prerequisites 
### Disk space
This procedure will take up to a maximum of just under 850MiB of disk
space during the build process and will generate about 85MiB of finished
product. 

### Time
The build takes a total of about 8 minutes to complete on an 
8 core i7 PC. The build takes about 50 minutes on a Raspberry Pi 4B.

### A cross compilation suite on a build host
You can follow the instructions at

https://github.com/bertofurth/Seagate-Central-Toolchain

to generate a cross compilation toolset that will generate binaries,
headers and other data suitable for the Seagate Central.

Note that an alternative approach would be to install gcc and other
build tools on the Seagate Central itself and perform the build process 
on the Seagate Central, however the Seagate Central is an order
of magnitude slower than most modern PCs. This would mean that compiling
something like this project on a Seagate Central could take hours to 
complete.

### Know how to copy files between your host and the Seagate Central. 
Not only should you know how to transfer files to and from your Seagate
Central NAS and the build host, ideally you'll know how to transfer files 
**even if the samba service is not working**. I would suggest
that if samba is not working to use FTP or SCP which should both still work.

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
The most important software used by this procedure is the
cross compiler and associated toolset. This will most likely need to
be manually generated before commencing this procedure as there is
unlikely to be a pre-built cross compiler tool set for Seagate Central
readily available.

There is a guide to generate a cross compilation toolset suitable
for the Seagate Central at the link below.

https://github.com/bertofurth/Seagate-Central-Toolchain

It is suggested to build the latest versions of gcc and binutils
available.

The following packages or their equivalents may also need to be
installed on the building system.

#### OpenSUSE Tumbleweed - Aug 2021 (zypper add ...)
    zypper install -t pattern devel_basis
    gcc-c++
    libgnutls-devel
    perl
    perl-Parse-Yapp
    rpcgen
    
#### Debian 10 - Buster (apt-get install ...)
    build-essential 
    libgnutls28-dev
    libparse-yapp-perl
    m4
    pkg-config
    python3-distutils
    zlib1g-dev
    flex

## Procedure
### Source code download and extraction
Download the files in this project to a new directory on your
build machine. This will be referred to as the base working 
directory going forward.

The next part of the procedure involves gathering the source code 
for each component and installing it into the working base directory.

Here we show the versions of software used when generating this guide.
Unless otherwise noted these are the latest stable releases at the
time of writing.

* gmp-6.2.1
* nettle-3.3 (Unable to get later versions working)
* acl-2.3.1
* libtasn1-4.17.0
* gntls-3.4.17 (3.4.x is currently recommended by samba documentation)
* openldap-2.3.39 (Must be the same version as Seagate Central)
* samba-4.14.6

Download these using **wget**, **curl -O** or a similar tool as follows.
Note that these source archives are available from a wide variety of 
sources so if one of the URLs used below does not work try to search 
for another.

    wget http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz
    wget http://mirrors.kernel.org/gnu/nettle/nettle-3.3.tar.gz
    wget http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
    wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz
    wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.17.tar.xz
    wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz
    wget https://download.samba.org/pub/samba/samba-4.14.6.tar.gz

Extract each file with the **tar -xf** command.

    tar -xf gmp-6.2.1.tar.xz
    tar -xf nettle-3.3.tar.gz
    tar -xf acl-2.3.1.tar.xz
    tar -xf libtasn1-4.17.0.tar.gz
    tar -xf gnutls-3.4.17.tar.xz
    tar -xf openldap-2.3.39.tgz
    tar -xf samba-4.14.6.tar.gz

### Seagate Central libraries and headers
We need to copy the binary libraries and header files on the Seagate 
Central to the build host so that they can be linked to during the
build process.

There are many methods of copying information from the Seagate Central 
but in this example we use the secure copy program - scp.

First change into the sc-libs subdirectory from the base working 
directory and create the required lib, usr/lib, and usr/include 
sub directories.

    mkdir -p sc-libs
    cd sc-libs
    mkdir -p lib usr/lib usr/include 
    
In this example we use the "admin" user to copy files from the Seagate
Central. You will need to substitute your own username and NAS IP 
address. After executing each scp command you'll be prompted for the 
password for that username on the Seagate Central. 

Note that when copying the include files the "-r" option is used to
copy the sub directories as well.

    scp admin@<NAS-ip-address>:/lib/* ./lib/
    scp admin@<NAS-ip-address>:/usr/lib/* ./usr/lib
    scp -r admin@<NAS-ip-address>:/usr/include/* usr/include/
   
### Special library and header customizations   
After the libraries and headers are copied over we need to make a 
slight modification to **usr/lib/libc.so** and **usr/lib/libpthread.so**. 
These files are text files that contain the names of other libraries 
but they contain references to the absolute paths /lib and /usr/lib
that will not work in our build environment. Manually edit these
files to remove these paths or run the following commands in the 
sc-libs directory to automatically remove them.

    sed -i.orig -e 's#\(/usr\|/lib/\)##g' usr/lib/libc.so
    sed -i.orig -e 's#\(/usr\|/lib/\)##g' usr/lib/libpthread.so

The original versions of the files will be kept with a .orig suffix.

We also need to rename the **usr/include/md5.h** header file so that
it is not used in the compilation process, otherwise errors related to 
md5 functions will appear when compiling samba.

    mv -f usr/include/md5.h usr/include/md5.h.orig

### Customize the scripts
Change back to the base working directory and edit the variables
at the top of the **build-common** file to suit your build
environment.

    #
    # Set the prefix name of the cross compiling toolkit. This
    # will likely be something like arm-XXX-linux-gnueabi-
    # Normally this will have a dash at the end.
    #
    export CROSS_COMPILE=arm-sc-linux-gnueabi-
    
    #
    # The location of the root of the cross compiling tool suite
    # on the compiling host (CROSS), and the location of the
    # binaries (TOOLS).
    #
    # Make sure to use an absolute path and not the ~ or . symbols.
    #
    CROSS=$HOME/Seagate-Central-Toolchain/cross
    TOOLS=$CROSS/tools/bin
    
    #
    # Set the number of threads to use when compiling.
    #
    # Generally set equal to or less than the number of CPU
    # cores on the building machine. Set to 1 when
    # troubleshooting.
    #
    J=6

If you decide to build a significantly different version of 
samba than the one used in this guide (v4.4.16) then then you may need 
to alter the included cross-answers file which has a name similar to

**samba-X.X.X-cross-answers-seagate-central.txt**

This file contains information that allows samba to be cross
compiled for the arm platform. If you create a new cross-answers
file you will need to modify the main samba build script
**build-samba-08-samba.sh** to point at the new cross answers file.

For more details about the samba cross-answers file see 

https://wiki.samba.org/index.php/Waf#Using_--cross-answers 

### Run the build scripts in order
The build scripts are named in the numerical order that they need to be
executed. 

    ./build-samba-01-gmp.sh
    ./build-samba-02-nettle.sh
    ./build-samba-03-acl.sh
    ./build-samba-04-libtasn1.sh
    ./build-samba-05-gnutls.sh
    ./build-samba-06-openldap.sh
    ./build-samba-07-samba-host-tools.sh
    ./build-samba-08-samba.sh

My suggestion is to not blindly execute all the scripts at once or from 
another script unless you're confident that the build will work. You need
to check to ensure that each script reports success as per the example
below before executing the next script.

    ****************************************
    
    Success! Finished installing gmp-6.2.1 to /home/user/Seagate-Central-Samba/cross
    
    ****************************************

### Create an archive of the finished product
The finished product is now in the **cross** subdirectory. I would suggest
renaming that directory to something meaningful and then creating an archive
of the directory. For example

     mv cross seagate-central-samba
     tar -caf seagate-central-samba.tar.gz seagate-central-samba
     
### Troubleshooting
The vast majority of problems will be due to

 * A needed build system component has not been installed.
 * The "Special library and header customizations" step was skipped.
 * A previous build step was not completed successfully.
 * Weird issues with the samba in-tree build system.

If you encounter problems compiling the samba component then make sure
to always have a clean source tree at the start of each build. This 
means deleting the samba source directory and then re-expanding the 
samba tar archive to generate a fresh samba source directory.

It's worth mentioning that some of the libraries, especially gnutls,
will generate a very large volume of warning messages during 
compilation. These are nothing to worry about as long as the success 
message is printed at the end of each script.

The "configure" stages of the build are where things will most likely
go wrong. In this case it is useful to view the configure log which 
will be located at obj/<src-dir>/config.log or for samba 
<samba-src-dir>/bin/config.log

Cross compiling samba is difficult and there are a lot of articles
and posts that detail the trouble people have had with this process. 
Hopefully by following this guide you will avoid most of those 
problems.

