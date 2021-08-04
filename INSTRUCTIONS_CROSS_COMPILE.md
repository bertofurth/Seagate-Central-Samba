# INSTRUCTIONS_CROSS_COMPILE.md
Instructions for cross compiling samba v4.14.6 for the Seagate Central NAS

## Summary
This is a guide that describes how to cross compile replacement samba
software suitable for installation on a Seagate Central NAS device.

Installation of the cross compiled software is covered in another note
entitled

INSTRUCTIONS_SAMBA_INSTALLATION or whatever

These instructions were tested with a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations and
firmware versions.

## Prequisites 

THIS IS ONLY FOR MANUAL INSTALLATION

### Know how to copy files between your build host and the target
### Seagate Central. 
Ideally you'll know how to transfer files between the build host and the
Seagate Central even if the samba service is not working. I would suggest
using FTP or SCP which will both work even if samba is not operational.

### Have ssh access to the Seagate Central.

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

There are is a useful script available at another project that 
automatically modifies a stock firmware image in such a way that it
will re-allow su access 

https://github.com/detain/seagate_central_sudo_firmware
Archive : https://archive.ph/rg39t

BERTO : CREATE A SCRIPT TO DO THIS AUTOMATICALLY

Note that the instructions in this link try to perform the process of 
creating the new firmware image on the Seagate Central itself. It's 
much easier to do it on an external system instead.

### Build host 
As you perform the steps in this guide you will have to make sure that
your build host has appropriate software installed. Below is a list of
packages that I found I needed using OpenSUSE Tumbleweed

BERTO BERTO



Things to install on your building host


Actions

Copy the libraries off the Seagate Central to a directory on your building host



Modify 

./usr/lib/libc.so.orig
./usr/lib/libpthread.so.orig

