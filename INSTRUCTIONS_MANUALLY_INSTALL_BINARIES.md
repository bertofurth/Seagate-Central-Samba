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

## Prequisites 
### Disk space on the Seagate Central
About 170MiB of space on the Seagate Central will be required to 
preform this procedure. The procedure will add about 85MiB worth of
newly installed files to the Seagate Central.

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
If you've manually compiled the samba binaries then generate a 
compressed archive of your work as follows where "cross" is the base
directory of the work.

     tar -caf seagate-central-samba-4.14.6.tar.gz cross

If you'd prefer to download pre-compiled binaries then refer to the
README.md file for the location of a compressed archive.

Transfer the archive to the Seagate Central. In this example we
copy the I would suggest
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

