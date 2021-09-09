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

* OpenSUSE Tumbleweed (Aug 2021) on x86
* OpenSUSE Tumbleweed (Aug 2021) on Raspberry Pi 4B
* Debian 10 (Buster) on x86

The procedure has been tested to work with make v4.3 and v4.2.1 as well
cross compiler gcc versions 11.2.0, 8.5.0 and 5.5.0.

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
The build component takes a total of about 10 minutes to complete on an 
8 core i7 PC. The build takes about 1 hour on a Raspberry Pi 4B.

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
components of your build system may be overwritten.

The only time during this procedure you should be acting as the 
root user on the build system is if you are deliberately installing 
new components on your build system to facilitate the building process. 
See the next pre-requisite for details.

### Required software on build host
As mentioned above, the most important software used by this procedure 
is the cross compiler and associated toolset. This will most likely need
to be manually generated before commencing this procedure as there is
unlikely to be a pre-built cross compiler tool set for Seagate Central
readily available.

There is a guide to generate a cross compilation toolset suitable
for the Seagate Central at the following link.

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
### Workspace preparation
If not already done, download the files in this project to a 
new directory on your build machine. 

For example, the following **git** command will download the 
files in this project to a new subdirectory called 
Seagate-Central-Samba

    git clone https://github.com/bertofurth/Seagate-Central-Samba.git
    
Alternately, the following **wget** and **unzip** commands will 
download the files in this project to a new subdirectory called
Seagate-Central-Samba-main

    wget https://github.com/bertofurth/Seagate-Central-Samba/archive/refs/heads/main.zip
    unzip main.zip

Change into this new subdirectory. This will be referred to as 
the base working directory going forward.

     cd Seagate-Central-Samba

### Source code download and extraction
The next part of the procedure involves gathering the source code 
for each component and installing it into the **src** subdirectory of
the base working directory.

Here we show the versions of software used when generating this guide.
Unless otherwise noted these are the latest stable releases at the
time of writing. Hopefully later versions, or at least those with
the same major version numbers, will still work with this guide.

* gmp-6.2.1
* nettle-3.7.3
* acl-2.3.1
* libtasn1-4.17.0
* gnutls-3.6.16
* openldap-2.3.39 (Should be the same version as Seagate Central)
* samba-4.14.6

Change into the **src** subdirectory of the base working directory
then download the source archives using **wget**, **curl -O** or a 
similar tool as follows. Note that these archives are available from 
a wide variety of sources so if one of the URLs used below does not 
work try to search for another.

    cd src
    wget http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz
    wget http://mirrors.kernel.org/gnu/nettle/nettle-3.7.3.tar.gz
    wget http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
    wget http://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz   
    wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz
    wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz
    wget https://download.samba.org/pub/samba/samba-4.14.6.tar.gz

Extract each file with the **tar -xf** command.

    tar -xf gmp-6.2.1.tar.xz 
    tar -xf nettle-3.7.3.tar.gz  
    tar -xf acl-2.3.1.tar.xz
    tar -xf libtasn1-4.17.0.tar.gz
    tar -xf gnutls-3.6.16.tar.xz
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
password for that username on the Seagate Central. Ignore any warning
messages about "not a regular file".

Note that when copying the include files the "-r" option is used to
copy the sub directories as well.

    scp admin@192.168.1.99:/lib/* ./lib/
    scp admin@192.168.1.99:/usr/lib/* ./usr/lib
    scp -r admin@192.168.1.99:/usr/include/* usr/include/
   
### Special library and header customizations   
After the libraries and headers are copied over we need to make a 
slight modification to **usr/lib/libc.so** and **usr/lib/libpthread.so**. 
These are text files that contain the names of other libraries to
load but they contain references to the absolute paths /lib and
/usr/lib that will not work in our build environment. Manually edit
these files to remove these paths or run the following commands in the 
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

These parameters are arranged roughly in order of their likelihood
of needing to be changed. The first three are the most important
to get right.

#### CROSS_COMPILE (Important)
This parameter sets the prefix name of the cross compiling toolkit.
This will likely be something like "arm-XXX-linux-gnueabi-" . 
Normally this will have a dash (-) at the end.

    CROSS_COMPILE=arm-sc-linux-gnueabi-
    
#### CROSS and TOOLS (Important)
The location of the root of the cross compiling tool suite on the 
compiling host (CROSS), and the location of the cross compiling 
binary executables such as gcc (TOOLS).

Make sure to use an absolute path and not the ~ or . symbols.

    CROSS=$HOME/Seagate-Central-Toolchain/cross
    TOOLS=$CROSS/tools/bin

#### J (Number of CPU threads) (Important)
Set the number of threads to use when compiling. Generally set 
equal to or less than the number of CPU cores on the building machine. 
Set to 1 when troubleshooting.
    
    J=6

#### BUILDHOST_DEST (Unlikely to need changing)
The directory on the compiling host where binaries and other 
generated files will be temporarily installed before being copied 
to the Seagate Central.

This is different to PREFIX and EXEC_PREFIX (see below) which is where 
the generated files need to be located on the Seagate Central itself.

     BUILDHOST_DEST=$(pwd)/cross

#### PREFIX, EXEC_PREFIX (Unlikely to need changing)
The directories where the libraries (PREFIX) and executables
(EXEC_PREFIX) will be installed on the target device (i.e. on
the Seagate Central). This should probably be left as /usr/local 
and /usr.

Note that is NOT the place where the resultant binaries and libraries 
will be temporarily copied to on the compiling host (see 
BUILDHOST_DEST).

     PREFIX=/usr/local
     
     EXEC_PREFIX=/usr

#### SEAGATE_LIBS_BASE (Unlikely to need changing)
Specify a directory containing the native library files as copied
from the Seagate Central. If this directory is changed then make
sure the step that downloads libraries from the Seagate Central
to the build host is modified accordingly.

     SEAGATE_LIBS_BASE=$(pwd)/sc-libs

### Samba cross answers file 
If you decide to build a significantly different version of 
samba than the one used in this guide then then you may need 
to alter the included cross-answers file which has a name similar to

**cross-answers-seagate-central-samba-X.X.X.txt**

This file contains information that allows samba to be cross
compiled for the arm platform. If you create a new cross-answers
file you will need to modify the main samba build script
**build-samba-08-samba.sh** to point at the new cross answers file.

For more details about the samba cross-answers file see 

https://wiki.samba.org/index.php/Waf#Using_--cross-answers 

### Run the build scripts in order
The build scripts are named in the numerical order that they need to be
executed. On the first run we suggest executing them individually to make
sure each one works.

    ./build-samba-01-gmp.sh
    ./build-samba-02-nettle.sh
    ./build-samba-03-acl.sh
    ./build-samba-04-libtasn1.sh
    ./build-samba-05-gnutls.sh
    ./build-samba-06-openldap.sh
    ./build-samba-07-samba-host-tools.sh
    ./build-samba-08-samba.sh

There is a script called **run_all_build.sh** that will execute all 
the individual build scripts in order however this is only recommended
once you are confident that the build will run without issue.

### Optional : Create an archive of the finished product
The finished product is now in the **cross** subdirectory (or whatever
BULILDHOST_DEST is set to). If this data needs to be transferred to 
the Seagate Central as part of the manual installation procedure then
rename that directory to a descriptive name and then create an archive.
For example

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
may generate a very large volume of warning messages during 
compilation. Particularly 

    warning: 'ASN1_TYPE' macro is deprecated, use 'asn1_node' instead.
    
These are nothing to worry about as long as the success 
message is printed at the end of each script.

The "configure" stages of the build are where things will most likely
go wrong. In this case it is useful to view the configure log which 
will be located at obj/component-X.Y.Z/config.log or 
src/samba-4.X.Y/bin/config.log

Cross compiling samba is difficult and there are a lot of articles
and posts that detail the trouble people have had with this process. 
Hopefully by following this guide you will avoid most of those 
problems.

