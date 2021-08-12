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

The build environments tested were using the cross compilation suite
based on gcc versions 11.2.0 and  
These instructions should not be followed "blindly". If you have already
made other custom changes to your Seagate Central software via the
command line, such as installing other cross compled software, then
make sure that none of the steps below interfere with those changes.

## Prequisites 
### Disk space on the Seagate Central
About 170MiB of disk space on the Seagate Central will be required
to perform this procedure. The procedure will add about 90MiB worth of
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

Note that the alternative procedure detailed in
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md** does not require su access
and will in fact automatically re-enable su access as part of the
procedure.

Some later versions of Seagate Central firmware deliberately disable
su access however there are a number of guides on how to restore su.

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

We must transfer the archive to the Seagate Central. This can be 
copied to the NAS in the same way that other files are normally 
copied to the NAS. 

An alternative method of copying data to the Seagate Central is scp.
In this example we use the scp command with the "admin" user to
copy the archive to the user's home directory. You will need to
substitute your own username and NAS IP address. After
executing the scp command you'll be prompted for the user's
password.

    scp seagate-central-samba.tar.gz admin@<NAS-ip-address>:

### Extract the archive on the Seagate Central
Establish an ssh session to the seagate central with the same
username who's directory now contains the samba archive.

Change to the directory where the archive has been copied to and
extract it.

    tar -xvf seagate-central-samba.tar.gz
     
Note, you may get warning messages similar to the following but these
are safe to ignore.

    tar: warning: skipping header 'x'
     
A new directory containing the expanded archive will be created.
We will call this the base working directory. Change into this
directory.

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

The archive contains other files including man pages and other
documentation, however the Seagate Central does not natively support
these therefore there is probably no need to install these files.
     
### Customize samba configuration files
The main samba configuation file /etc/samba/smb.conf needs to be
modfied in order to work with modern versions of samba.

First make a backup of the original file just in case you wish to
revert to the original version of samba.

    cp /etc/samba/smb.conf /etc/samba/smb.conf.old
    
Next, edit the configuration file and remove or comment out with a #
the following lines of configuration which is no longer needed.

     . . .
     # auth methods = guest, sam_ignoredomain
     . . .

Also comment out or delete this line which enables apple talk style
connection

     . . .
     # vfs object = netatalk
     . . .
     
and with the up to date appletalk configuration equivalents as follows.
    
     . . .
     vfs objects = catia fruit streams_xattr
     fruit:model = RackMac
     fruit:time machine = yes
     multicast dns register = yes
     . . .
     
The new configuration needs to be saved and then copied to a special
folder that stores backups of the system configuration. If this step
is not completed then any changes made to the smb.conf file will be 
overwritten each time the system boots up. (See the 
/etc/init.d/firmware-init-1bay startup script for details.)

     cp /etc/samba/smb.conf /usr/config/backupconfig/etc/samba/smb.conf

At this point you can take the opportunity to enable other samba
features that are available in samba 4. See the following link for
details on other samba parameters that can be configured

https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html

### Test the newly installed server
At this point the server should be fully installed and can be 
reactivated with the following command

     /etc/init.d/samba start

Check to see if the smbd process is running by running the 
following command. Multiple instances of smbd should be
active.

     ps -w | grep smbd

Also confirm that you can once again transfer files between the
Seagate Central and your clients.

Further test that you are able to disable legacy SMBv1.0 support
on any clients and that you are still able to transfer data to and 
from the Seagate Central.

### Optional : Revert back to the old samba software
If the new version of samba is not performing as desired then there
is always the option of reinstating the original version.

If the procedure above has been followed then the following sequence
of commands issued with root priviledges will restore the original
samba software.

     /etc/init.d/samba stop
     cp /etc/samba/smb.conf.old /etc/samba/smb.conf
     cp /etc/samba/smb.conf /usr/config/backupconfig/etc/samba/smb.conf
     cp /usr/sbin/old.samba/* /usr/sbin/
     cp /usr/bin/old.samba/* /usr/bin/
     /etc/init.d/samba start

### Troubleshooting
If executing the "smbd -V" command shows an error message similar to

     smbd: error while loading shared libraries: libsamba-util.so.0: cannot open shared object file: No such file or directory

Then it may be that the libraries have not been installed properly.
Check to make sure that /usr/local/lib and /usr/local/lib/samba have
been correctly created and have .so library files present.

If the samba services do not start after bootup or after manually 
starting the service then check the logs in

     /var/log/log.smbd
     /var/log/log.nmbd
     
 Note that the following log message may appear in the smbd log
 
      Address family not supported by protocol
      
 This is merely an indication that the samba service is trying to use
 IPv6 however the native linux kernel on a Seagate Central does not
 support IPv6. These messages can be ignored.

 
