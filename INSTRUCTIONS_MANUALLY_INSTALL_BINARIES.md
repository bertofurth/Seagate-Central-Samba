# INSTRUCTIONS_MANUALLY_INSTALL_BINARIES.md
## Summary
This is a guide that describes how to manually replace the old samba
software on a Seagate Central NAS with an updated, modern, cross
compiled version of samba.

Refer to the README.md file for the location of a set of 
pre-compiled binaries that can be used in this process or
refer to the instructions in **INSTRUCTIONS_CROSS_COMPILE.md**
to self generate the binaries.

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

## Prerequisites 
### Disk space on the Seagate Central
About 170MB of disk space on the Seagate Central Data partition will be
required while performing this procedure.

The procedure will result in about 90MB worth of newly installed files
on the Seagate Central Root partition. The Root partition on an
unmodified Seagate Central typically has in the order of 500MB free so
hopefully this small addition of files will not cause any problems.

### ssh access to the Seagate Central.
You'll need ssh access to issue commands on the Seagate Central command 
line. 

If you are especially adept with a soldering iron and have the right 
equipment then you could get serial console access but this quite
difficult and is **not required**. There are some very brief details 
of the connections required at

http://seagate-central.blogspot.com/2014/01/blog-post.html

Archive : https://archive.ph/ONi4l

### su/root access on the Seagate Central.
Make sure that you can establish an ssh session to the Seagate Central
and that you can succesfully issue the **su** command to gain root
priviledges. Note that some later versions of Seagate Central firmware
deliberately disable su access by default.

The alternative procedure detailed in
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md** does not require su access
and will in fact automatically re-enable su access as a result of the
procedure.

### Know how to copy files between your host and the Seagate Central. 
Not only should you know how to transfer files to and from your 
Seagate Central NAS and the build host, ideally you'll know how
to transfer files **even if the samba service is not working**. I 
would suggest that if samba is not working to use FTP or SCP which
should both still work.

## Procedure
### Transfer cross compiled samba binaries to the Seagate Central
You should have a self generated or downloaded archive of the
samba binaries you'd like to install. If you have just completed
cross compiling the samba software you can generate an archive 
with the following commands executed from the base working
directory.

     mv cross seagate-central-samba
     tar -caf seagate-central-samba.tar.gz seagate-central-samba

We must transfer the archive to the Seagate Central. This can be 
copied to the NAS in the same way that other files are normally 
copied to the NAS. 

An alternative method of copying data to the Seagate Central is 
scp. In this example we use the scp command with the "admin" user to
copy the archive to the user's home directory. You will need to
substitute your own username and NAS IP address. After
executing the scp command you'll be prompted for the user's
password.

    scp seagate-central-samba.tar.gz admin@<NAS-ip-address>:

### Extract the archive on the Seagate Central
Establish an ssh session to the seagate central with the same
username who's directory now contains the samba archive.

All the commands after this point are executed on the Seagate
Central and not on the build host.

Change to the directory where the archive has been copied to and
extract it as follows.

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
currently running samba service. 

     /etc/init.d/samba stop

### Backup the original samba software
It is strongly suggested to make backup copies of any binary
executables we are about to overwrite. This way if we need to revert 
back to the old version of software we can do so easily.

We do this here by creating an **old.samba** subdirectory under
/usr/bin and /usr/sbin to store the original versions of the tools.
We then look for any files that have the same names as the new ones
and copy them to these new subdirectories. 

From the base working directory issue the following commands

     mkdir -p /usr/bin/old.samba /usr/sbin/old.samba
     ls usr/sbin | xargs -I{} rsync -a --ignore-existing /usr/sbin/{} /usr/sbin/old.samba/{} 
     ls usr/bin | xargs -I{} rsync -a --ignore-existing /usr/bin/{} /usr/bin/old.samba/{}
     
Ignore the errors in the outputs of the above commands saying "No
such file or directory" because these simply mean that no old
version of a particular new tool was found to backup.

### Install the new samba software
The structure of files in the extracted archive should be such that
we can simply copy everything under the usr subdirectory straight
to the /usr directory of the Seagate Central.

Issue the following command from the base working directory

     cp -r usr/* /usr/
     
Finally perform a sanity check to make sure the new binaries are
executable by running the following command to check the version of
samba that has been installed.

     testparm -V
 
The command should report the expected new version (v4.x.x) and 
not the old version (3.5.16).

Note that the archive may contain man pages and other documentation
that are not used on the Seagate Central. If desired these files can
be removed from the /usr/local/doc , /usr/local/info and
/usr/local/man subdirectories. 

### Customize samba configuration files
The main samba configuation file /etc/samba/smb.conf needs to be
modfied in order to work with modern versions of samba.

First make a backup of the original file just in case you wish to
revert to the original version of samba.

    cp /etc/samba/smb.conf /etc/samba/smb.conf.old
    
Next, edit the /etc/samba/smb.conf file with vi or nano and remove
or comment out with a # the following configuration lines which
are no longer supported in samba v4.

     . . .
     # min receivefile size = 1 ## disabled due to SOP receive file bug
     . . .
     # auth methods = guest, sam_ignoredomain
     # encrypt passwords = yes
     . . .
     # null passwords = yes
     . . .
     # vfs object = netatalk
     . . .
     
Replace these lines with the following. Make sure these lines
are after the "[global]" directive and before the "include"
directive at the end of the file

     . . .
     min receivefile size = 16384
     vfs objects = catia fruit streams_xattr
     fruit:model = RackMac
     fruit:time machine = yes
     multicast dns register = yes
     . . .

At this point you can take the opportunity to enable other samba
features that are available in samba 4. See the following link for
details on other samba parameters that can be configured.

https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html

The new configuration needs to be saved and then copied to a special
folder that stores backups of the system configuration. If this step
is not completed then any changes made to the smb.conf file will be 
overwritten each time the system boots up. (See the 
/etc/init.d/firmware-init-1bay startup script for details.)

     cp /etc/samba/smb.conf /usr/config/backupconfig/etc/samba/smb.conf

### Test the newly installed server
At this point the server should be fully installed. Run the 
**testparm** command to check that the new samba configuration
is correct and compatible with the new version of samba.

     testparm

The server may be reactivated with the following command

     /etc/init.d/samba start

Check to see if the smbd process is running by using the 
following command. Multiple instances of smbd should be
active.

     ps -w | grep smbd

After waiting a minute or two confirm that you can once again
transfer files between the Seagate Central and your clients.

If appropriate, further test that you are able to disable legacy 
SMBv1.0 support on any clients and that you are still able to
transfer data to and from the Seagate Central.

Finally test that the new software and configuration survive a
reboot of the Seagate Central. The best way to do this is either
via the Web management interface or with the CLI command

     reboot
 
Rebooting the Seagate Central by disconnecting the power is
not normally recommended.

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
After the upgrade it may take a few minutes for the changes to the
NAS configuration to propagate and be recognized throughout your local
network. 

If any individual clients are having difficulty connecting to the NAS 
after the upgrade then consider rebooting them or forcing them to
disconnect then reauthenticate to the Seagate Central NAS. 

If executing the "testparm -V" command on the Seagate Central shows an
error message similar to

     testparm: error while loading shared libraries: libsamba-util.so.0: cannot open shared object file: No such file or directory

then it may be that the libraries have not been installed properly.
Check to make sure that /usr/local/lib and /usr/local/lib/samba have
been correctly created and have .so library files present.

If the samba services do not start after bootup or after manually 
starting the service then check the logs in

     /var/log/log.smbd
     /var/log/log.nmbd
     
Note that the following log message may appear in the 
/var/log/log.smbd log
 
      Address family not supported by protocol
      
This is merely a warning that the samba service is trying to use 
IPv6 however the native linux kernel on a Seagate Central does not 
support IPv6. These messages can be ignored.

Check the syslog at

     /var/log/syslog

This will show error and messages associated with system startup and
for any other serious conditions that occur.
