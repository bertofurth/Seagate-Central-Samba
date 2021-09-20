BERTO : Kind of broken at the moment. Use with caution.

TODO : TLDNR

TODO : TLS  - >    --without-zlib    fix this

TODO :Change to "compile everything" mode. Stop downloading libraries from the SC

TODO : Add a note where new stuff can be added to the firmware

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

## TLDNR
On a build server with an appropriate cross compilation suite installed
run the following commands to download and compile Samba v4.14.6 for
the Seagate Central

    # Download this project to the build host
    git clone https://github.com/bertofurth/Seagate-Central-Samba.git
    cd Seagate-Central-Samba
    
    # Obtain the required source code
    ./download-src-samba.sh
    
    # Build Samba v4.14.6 for Seagate Central
    ./run-all-build-samba.sh
    
    # Remove optional excess components from the software
    ./trim-build.sh
    
    # Create an archive of the software
    mv cross seagate-central-samba-v4.14.6
    tar -caf seagate-central-samba-v4.14.6.tar.gz seagate-central-samba-v4.14.6
    
## Prerequisites 
### Disk space
This procedure will take up to 850MiB of disk  BERTO
space during the build process and will generate up to 85MiB of finished
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
### Source code download and extraction
This procedure was tested using the following versions of software.
Unless otherwise noted these are the latest stable releases at the
time of writing. Hopefully later versions, or at least those with
the same major version numbers, will still work with this guide.

* gmp-6.2.1 - http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz
* nettle-3.7.3 - http://mirrors.kernel.org/gnu/nettle/nettle-3.7.3.tar.gz
* acl-2.3.1 - http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
* libtasn1-4.17.0 - http://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz 
* gnutls-3.6.16 - https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz
* openldap-2.3.39 (Same version as Seagate Central) - https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.3.39.tgz
* samba-4.14.6 - https://www.samba.org/ftp/samba/stable/samba-4.14.6.tar.gz

Download the required source code archives for each component to 
the **src** subdirectory of the base working directory and extract
them using the "tar -xf" command. This can be done automatically for
the versions listed above by running the **download-samba-src.sh**
script.

### Seagate Central libraries and headers TODO: GET RID OF THIS
We need to copy the binary libraries and header files on the Seagate 
Central to the build host so that they can be linked to during the
build process. The build scripts are configured to use the "sc-libs"
subdirectory under the base working directory to hold these files.

There are many methods of copying information from the Seagate Central 
but in this example we use the secure copy program - scp.

First create the required subdirectories under sc-libs. Namely lib,
usr/lib, and usr/includes.

    mkdir -p sc-libs/lib sc-libs/usr/lib sc-libs/usr/include 
    
In this example we use the "admin" user to copy files from the Seagate
Central. You will need to substitute your own username and NAS IP 
address. After executing each scp command you'll be prompted for the 
password for that username on the Seagate Central. Ignore any warning
messages about "not a regular file".

Note that when copying the include files the "-r" option is used to
copy the sub directories as well.

    scp admin@192.0.2.99:/lib/* sc-libs/lib/
    scp admin@192.0.2.99:/usr/lib/* sc-libs/usr/lib
    scp -r admin@192.0.2.99:/usr/include/* sc-libs/usr/include/
   
### Special library and header customizations   
After the libraries and headers are copied over we need to make a 
slight modification to **usr/lib/libc.so** and **usr/lib/libpthread.so**. 
These are text files that contain the names of other libraries to
load but they contain references to the absolute paths /lib and
/usr/lib that will not work in our build environment. Manually edit
these files to remove these paths or run the following commands in the 
sc-libs directory to automatically remove them.

    sed -i.orig -e 's#\(/usr\|/lib/\)##g' sc-libs/usr/lib/libc.so
    sed -i.orig -e 's#\(/usr\|/lib/\)##g' sc-libs/usr/lib/libpthread.so

The original versions of the files will be kept with a .orig suffix.

We also need to rename the **usr/include/md5.h** header file so that
it is not used in the compilation process, otherwise errors related to 
md5 functions will appear when compiling samba.

    mv -f sc-libs/usr/include/md5.h sc-libs/usr/include/md5.h.orig

### Customize the scripts
Change back to the base working directory and edit the variables
at the top of the **build-common** file to suit your build
environment.

These parameters are arranged roughly in order of their likelihood
of needing to be changed. The first two are the most important
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

#### J (Number of CPU threads) 
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

### Optional - Reducing the software size
You can reduce the size of the software that will be installed
on the Seagate Central by deleting or "stripping" components that
aren't normally useful to store on the Seagate Central itself.

#### Optional - Remove static libraries (Strongly recommended)
Many of the build scripts in this project to build both shared and
static libraries. The static libraries are generally only useful while
compiling a static binary on a build host.
 
Since you're unlikely to be performing any compilation on the Seagate
Central itself, we suggest that you remove any static libraries from
the software before it is transferred to the Seagate Central. This can
save a significant amount of disk space.

The following command finds static libraries in the "cross" 
subdirectory and deletes them.

    find cross/ -name "*.a" -exec rm {} \;

An alternative is to keep the static libraries but to "strip" them as
per the information below.

#### Optional - Strip binaries and executables
Binaries and executables generated in this project have debugging
information embedded in them by default. A small amount of space 
(around 20%) can be saved by removing this debugging information 
using the "strip" command. 

The following command searches through the "cross" subdirectory 
and "strips" any appropriate files.

     find cross/ -type f -exec strip {} \;
     
"strip" command error messages saying "file format not recognized" are 
safe to ignore.

#### Optional - Remove documentation
Documentation, which is unlikely to be read on the Seagate Central, can
be deleted to save a small amount of disk space.

    rm -rf cross/usr/local/share/doc
    rm -rf cross/usr/local/share/man
    rm -rf cross/usr/local/share/info
    
#### Optional - Remove multi-language files
If you are happy to keep all command outputs in English, then you can 
delete the files that provide support for other languages.

    rm -rf cross/usr/local/share/locale

#### Optional - Remove header files
Header files, which are only used when compiling software, can be removed
to save a small amount of disk space.

Personally, I prefer to keep these header files in place so that if in
future some other software requiring the shared libraries needs to be 
compiled, the headers are available.  This can make the process of building
software in the future easier.

That being said, it's possible to re-download the relevant library's 
source code again and get the headers that way.

To remove the headers run the following command.

    rm -rf cross/usr/local/include

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

