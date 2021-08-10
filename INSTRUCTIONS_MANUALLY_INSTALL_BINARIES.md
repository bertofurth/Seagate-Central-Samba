# INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md
## Summary
This is a guide that describes how to manually replace the old samba
software on a Seagate Central NAS with an updated, modern, cross
compiled version of samba.

Performing the cross compilation build process is covered by 
**INSTRUCTIONS_CROSS_COMPILE.md**

Installation of the cross compiled software using the easier but less
flexible firmware upgrade method is covered by
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations and
firmware versions as long as care is taken to account for any minor
differences.

These instructions should not be followed "blindly". If you have already
made other custom changes to your Seagate Central software via the
command line, such as installing other cross compled software, then
make sure that none of the steps below interfere with those changes.

## Prequisites 
### Disk space on the Seagate Central
About 170MiB of space on the Seagate Central will be required to 
preform this procedure. The procedure will add about 85MiB worth of
newly installed files to the Seagate Central.

### ssh access to the Seagate Central.
You'll need ssh access to issue commands on the Seagate Central command 
line. 

If you are especially adept with a soldering iron and have the right 
equipment then you could get serial console access but this quite difficult 
and is **not required**. There are some very brief details of the 
connections required at

http://seagate-central.blogspot.com/2014/01/blog-post.html
Archive : https://archive.ph/ONi4l

### su/root access on the Seagate Central.
Make sure that you can establish an ssh session to the Seagate Central
and that you can succesfully issue the **su** command to gain root
priviledges.

Some later versions of Seagate Central firmware deliberately disable
su access however there are a number of guides on how to restore su.

Note that the procedure in **INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**
does not require su access and will automatically re-enable su access
as part of the procedure.

The following guide suggests either temporarily reverting back to 
an older firmware version that allows su or creating then upgrading
to a new modified Seagate Central firmware image that re-enables su access.

https://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html
Archive : https://archive.ph/sEoOx

There are is also a useful script available at another project that 
automatically modifies a stock firmware image in such a way that it
upgrading to it will re-allow su access.

https://github.com/detain/seagate_central_sudo_firmware
Archive : https://archive.ph/rg39t

### Know how to copy files between your host and the Seagate Central. 
Not only should you know how to transfer files to and from your 
Seagate Central NAS and the build host, ideally you'll know how
to transfer files **even if the samba service is not working**. I 
would suggest that if samba is not working to use FTP or SCP which
should both still work.

## Procedure
### Transfer cross compiled samba binaries to the Seagate Central
You should have a self generated or downloaded archive of the
samba binaries you'd like to install.

We must transfer the archive to the Seagate Central. In this 
example we use the scp command with the "admin" user. You will 
need to substitute your own username and NAS IP address. After
executing the scp command you'll be prompted for a password
for that username on the Seagate Central.

    scp seagate-central-samba.tar.gz admin@<NAS-ip-address>:

### Extract the archive on the Seagate Central
Establish an ssh session to the seagate central with the same
username who's directory now contains the samba archive.

Change to the directory where the archive has been copied to and
extract the archive

    tar -xvf seagate-central-samba.tar.gz
     
Note, you may get warning messages similar to the following but these
are safe to ignore.

    tar: warning: skipping header 'x'
     
A new directory containing the expanded archive will be created.
We will call this the base directory. Change into this directory.

    cd seagate-central-samba
    
### Login as root or prepend sudo to further commands
The commands after this point in the procedure must be executed with
root priviedges. This can be done by either prepending **sudo** to
each command or by issuing the **su** command and becoming the root
user.

### Turn off the old samba service    
Before upgrading the samba software it is important to stop the
currently running samba software. 

     /etc/init.d/samba stop

### Install the new samba software
Begin by installing required libraries. Note that we are installing
the libraries in a new directory, /usr/local/lib, so that there's no
chance of overwriting any existing libaries on the Seagate Central.

     cp -r usr/local/lib /usr/local/     

You may optionally install the header files. These are only necessary
when compiling code but might be useful to store on the system in
case they are needed in the future.

     cp -r usr/local/include /usr/local/

Next we make backup copies of any binary executables we are about
to overwrite. We do this here by creating an **old.samba**
subdirectory under /usr/bin and /usr/sbin to store the old versions
of the tools. We then look for any files that have the same names
as the new ones and copy them to these new directories. This way if
we need to revert back to the old version of software we can do so
easily. 

     mkdir -p /usr/bin/old.samba /usr/sbin/old.samba
     ls usr/local/sbin | xargs -I{} rsync -a --ignore-existing /usr/sbin/{} /usr/sbin/old.samba/{} 
     ls usr/local/bin | xargs -I{} rsync -a --ignore-existing /usr/bin/{} /usr/bin/old.samba/{}
     
Ignore the errors in the outputs of the above commands saying "No
such file or directory" because these simply mean that no old version of
a particular new tool was found to backup.

Next, copy the new versions of binary executables into place. 

     cp usr/local/sbin/* /usr/sbin/
     cp usr/local/bin/* /usr/bin/
     
Finally perform a sanity check to make sure the smbd binary is
executable by running the following command to check the version of
samba that has been installed.

     smbd -V
 
The command should report the expected new version and not the 
old version (3.5.16).
     
### Customize samba and startup configuration files
The samba configuation file needs to be slightly modfied in order to work
with the new version of samba.

startup script needs to be slightly modified in order to support
the new version of samba. 

GET RID OF MK DIR?????? 

--with-sockets-dir=/var/run




### Test the new software


When the service is started a harmless error message similar to the
following will be generated.

     /etc/init.d/samba: line 138: can't create /proc/cvm_nas/max_jobs_to_process: nonexistent directory
     /etc/init.d/samba: line 138: can't create /proc/cvm_nas/max_jobs_to_submit: nonexistent directory

This message is related to the proprietary CPU sharing scheme that the
original Seagate Central version of samba used. It is not relevant to
the new version of samba which uses the standard linux SMP system to
share cpu resources.

If this cosmetic error message bothers you then you can edit 
/etc/init.d/samba to remove the offending line however if you chose
to revert back to the original version of samba make sure to put this
line back in.


### Optional : Revert to the original samba software
If for some reason the upgrade does not perform to your satisfaction
it is easy to revert back to the original samba software because backups
have been made along the way.

If all the above instructions have been followed then restoring the old
samba service should be accomplished by the following commands issued
as root


     copy it all back
     




install



     
### Troubleshooting
If executing the "smbd -V" command shows an error message similar to

     smbd: error while loading shared libraries: libsamba-util.so.0: cannot open shared object file: No such file or directory

Then it may be that the libraries have not been installed properly.
Check to make sure that /usr/local/lib and /usr/local/lib/samba have
been correctly created and have .so library files present.


/var/log/log.smbd






copying the archive to a user directory


downloaded a pre-compiled version of the samba binaries 
then start at this point.
.

I suggest extracting the archive on your build host rather
than on the Seagate Central itself simply because the process will
be faster using your build device.

If you've compiled the samba binaries then change to the base
directory of the compiled 






Download the files in this project to a new directory on your
build machine. This will be referred to as the base working 
directory going forward.

