# INSTRUCTIONS_CROSS_COMPILE.md
## Summary
This is a guide that describes how to cross compile replacement samba
software suitable for installation on a Seagate Central NAS device.

Manual installation of the cross compiled software is covered by
**INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md**

Installation of the cross compiled software using the easier but less
flexible firmware upgrade method is covered by
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**

Cross compiling samba is difficult and there are many articles and posts
that detail the trouble people have had with this process. Hopefully by
following this guide you will avoid most of those problems.

## TLDNR
On a build server with the "arm-sc-linux-gnueabi-" cross compilation 
suite installed, run the following commands to download and compile 
Samba v4.14.6 for the Seagate Central

    # Download this project to the build host
    git clone https://github.com/bertofurth/Seagate-Central-Samba.git
    cd Seagate-Central-Samba
    
    # Obtain the required source code
    ./download-src-samba.sh
    
    # Build Samba v4.14.6 for Seagate Central
    ./run-all-build-samba.sh
    
    # Remove optional excess components from the software
    ./trim-build.sh
    
    # Optional : Create an archive of the software
    mv cross seagate-central-samba-v4.14.6
    tar -caf seagate-central-samba-v4.14.6.tar.gz seagate-central-samba-v4.14.6
    
Proceed to the instructions in either
**INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md** or
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md** to install the newly
built software on the Seagate Central.
    
## Tested platforms
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
This procedure will take up to 1.1GB of disk space during the build
process and will generate approximately 85MiB of finished product. 

### Time
The build component takes a total of about 25 minutes to complete on an 
8 core i7 PC. The build takes about 2 hours on a Raspberry Pi 4B.

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
Download the required source code archives for each component to 
the **src** subdirectory of the base working directory and extract
them using the "tar -xf" command. This can be done automatically for
the versions listed below by running the **download-samba-src.sh**
script.

     ./download-samba-src.sh
     
This procedure was tested using the following versions of software.
Unless otherwise noted these are the latest stable releases at the
time of writing. Hopefully later versions, or at least those with
the same major version numbers, will still work with this guide.

* gmp-6.2.1 - http://mirrors.kernel.org/gnu/gmp/gmp-6.2.1.tar.xz
* nettle-3.7.3 - http://mirrors.kernel.org/gnu/nettle/nettle-3.7.3.tar.gz
* attr-2.4.48 - http://download.savannah.gnu.org/releases/attr/attr-2.4.48.tar.gz
* acl-2.3.1 - http://download.savannah.gnu.org/releases/acl/acl-2.3.1.tar.xz
* zlib-1.2.11 - https://zlib.net/zlib-1.2.11.tar.xz
* libunistring-0.9.10 - http://mirrors.kernel.org/gnu/libunistring/libunistring-0.9.10.tar.xz
* libidn2-2.3.1 - http://mirrors.kernel.org/gnu/libidn/libidn2-2.3.1.tar.gz
* libtasn1-4.17.0 - http://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.17.0.tar.gz 
* p11-kit-0.24.0 - https://github.com/p11-glue/p11-kit/releases/download/0.24.0/p11-kit-0.24.0.tar.xz
* gnutls-3.6.16 - https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.16.tar.xz
* openldap-2.5.7 - https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.5.7.tgz
* libtirpc-1.3.2 - https://downloads.sourceforge.net/project/libtirpc/libtirpc/1.3.2/libtirpc-1.3.2.tar.bz2
* Linux-PAM-1.5.2 - https://github.com/linux-pam/linux-pam/releases/download/v1.5.2/Linux-PAM-1.5.2.tar.xz'
* samba-4.14.6 - https://www.samba.org/ftp/samba/stable/samba-4.14.6.tar.gz
* krb5-1.19.2 - https://kerberos.org/dist/krb5/1.19/krb5-1.19.2.tar.gz

### Customize the build scripts
You may need to edit the variables at the top of the **build-common**
file in your project directory to suit your build environment.

Listed below are the two important parameters to get right. 

There are some other parameters and environment variables that can
be set and modified. See details in the text of the script itself.

#### CROSS_COMPILE (Important)
This parameter sets the prefix name of the cross compiling toolkit.
This will likely be something like "arm-XXX-linux-gnueabi-" . If 
using the tools generated by the Seagate-Central-Toolkit project
this prefix will be "arm-sc-linux-gnueabi-". Normally this parameter
will have a dash (-) at the end.

    CROSS_COMPILE=arm-sc-linux-gnueabi-
    
#### CROSS, TOOLS and SYSROOT (Important)
The location of the root of the cross compiling tool suite on the 
compiling host (CROSS), the location of the cross compiling 
binary executables such as arm-XXX-linux-gnueabi-gcc (TOOLS), and
the location of the compiler's platform specific libraries and
header files (SYSROOT).

Make sure to use an absolute path and not the ~ or . symbols.

    CROSS=$HOME/Seagate-Central-Toolchain/cross
    TOOLS=$CROSS/tools/bin
    SYSROOT=$CROSS/sysroot

### Samba cross answers file 
If you decide to build a significantly different version of 
samba than the one used in this guide then then you may need 
to alter the included cross-answers file which has a name similar to

**cross-answers-seagate-central-samba-X.X.X.txt**

This file contains information that allows samba to be cross
compiled for the arm platform. The build script for samba
will automatically use the latest version of cross-answers
found in the build directory.

For more details about the samba cross-answers file see 

https://wiki.samba.org/index.php/Waf#Using_--cross-answers 

### Run the build scripts in order
The build scripts are named in the numerical order that they need to be
executed. On the first run we suggest executing them individually to make
sure each one works.

    ./build-samba-01-gmp.sh
    ./build-samba-02-nettle.sh
    ./build-samba-03-attr.sh
    ./build-samba-04-acl.sh
    ./build-samba-05-zlib.sh
    ./build-samba-06-libunistring.sh
    ./build-samba-07-libidn2.sh
    ./build-samba-08-libtasn1.sh
    ./build-samba-09-p11-kit.sh
    ./build-samba-10-gnutls.sh
    ./build-samba-11-openldap.sh
    ./build-samba-12-libtirpc-no-krb5.sh
    ./build-samba-13-Linux-PAM.sh
    ./build-samba-14-samba-host-tools.sh
    ./build-samba-15-samba.sh
    ./build-samba-16-krb5.sh
    ./build-samba-17-libtirpc-with-krb5.sh

There is a script called **run-all-build-samba.sh** that will execute all 
the individual build scripts in order however this is only recommended
once you are confident that the build will run without issue. 

### Optional - Reduce the software size
You can reduce the size of the software that will be installed
on the Seagate Central by deleting or "stripping" components that
aren't normally useful to store on the Seagate Central itself.

All the steps in this section can be executed by running the 
included script called **trim-build-samba.sh**.

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

#### Optional - Strip binaries and executables
Binaries and executables generated in this project have debugging
information embedded in them by default. A small amount of space 
(around 20%) can be saved by removing this debugging information 
using the "strip" command. 

The following example searches through the "cross" subdirectory 
and "strips" any appropriate files.

     find cross/ -type f -exec strip {} \;
     
"strip" command error messages saying "file format not recognized" are 
safe to ignore.

### Optional : Create an archive of the finished product
The finished product is now in the **cross** subdirectory. If this 
data needs to be transferred to the Seagate Central as part of the
manual installation procedure then rename that directory to a
descriptive name and then create an archive. For example

     mv cross seagate-central-samba
     tar -caf seagate-central-samba.tar.gz seagate-central-samba
     
### Troubleshooting
Here are some steps that should be taken when troubleshooting issues
while cross compiling software for the Seagate Central. Note that
logs for each stage are automatically stored in the **log** 
subdirectory of the base working directory.

### Configure logs
If the configure stage of a build is failing, then verbose configure
logs are generally stored in a file called "config.log" underneath
the "obj/component-name" sub directory or the src/samba-X.X.X directory
for samba.

Search for configure logs by running the following command from the
base working directory.

     find -name config.log

### More verbose build logs
The output of the "make" part of the build scripts can be made more
verbose and detailed by adding some options to the build commands.
For example, to restrict a build to one thread and to produce more
verbose output, specify the "-j1 V=1" parameters as follows.

     ./build-samba-01-library1.sh -j1 V=1 
     
"-d" may be added in order to troubleshoot issues with "make" itself 
as opposed to the compilation part of the process. Note that "-d" 
generates a very large amount of logs.

### Make sure required build tools are installed
If the compilation process complains about a tool not being installed
or a command not being found then it may be necessary to install that
utility on your build host.

Use your build host's software management tools to search for the
appropriate packages that need installing. For example

OpenSuse : zypper search tool-name
Debian : apt search tool-name

### Problems building the samba component 
Building samba itself is unique in that it must use "in tree" 
building, which means that objects and compilation outputs are placed
in the source tree of samba itself. 

If you encounter problems compiling the samba component then make sure
to always have a clean source tree at the start of each build. This 
means deleting the samba source directory and then re-expanding the 
samba tar archive to generate a fresh samba source directory.

     cd src
     rm -rf samba-X.X.X
     tar -xf samba-X.X.X.tar.gz

### Warning messages
It's worth mentioning that some of the libraries, especially gnutls,
may generate a very large volume of warning messages during 
compilation. Particularly 

    warning: 'ASN1_TYPE' macro is deprecated, use 'asn1_node' instead.
    
These are nothing to worry about as long as the success 
message is printed at the end of each script.


