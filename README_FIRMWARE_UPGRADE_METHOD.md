# README_FIRMWARE_UPGRADE_METHOD.md
## Summary
This is a guide that describes how to generate a custom firmware update
for a Seagate Central NAS. This is primarily done to install a modern,
cross compiled version of the samba file sharing service however there are
other benefits as documented below.

It is partially based on the work at

https://github.com/detain/seagate_central_sudo_firmware

http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html

Refer to the README.md file for the location of a set of pre-compiled binaries
that can be used in this process or refer to the instructions in
**README_CROSS_COMPILE.md** to self generate the binaries.

If you are a user with some Linux experience, or if you have already
made some custom modifications to your Seagate Central's operating system,
then we would strongly suggest that you use the slightly more difficult
but much more flexible and easier to troubleshoot installation method 
described by **README_MANUALLY_INSTALL_BINARIES.md** in this project.

Along with upgrading samba, it is also possible to also upgrade the Seagate
Central Linux kernel and to install other cross compiled software using this 
method. See the **Seagate-Central-Modern-Slot-In-Kernel** and
**Seagate-Central-Utils** projects for details.

https://github.com/bertofurth/Seagate-Central-Modern-Slot-In-Kernel/

https://github.com/bertofurth/Seagate-Central-Utils/

This firmware upgrade can also optionally be used to reset a Seagate Central's
root password in order to regain root access to the system. This might
be useful as Seagate's most recent native firmware updates disable root
access.

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however we believe these
instructions should work for other Seagate Central configurations
and firmware versions. 

## TLDNR
Download a copy of the latest Seagate Central firmware archive from the
Seagate website. This TLDNR assumes the downloaded firmware zip file is
called Seagate-HS-update-201509160008F.zip . Unzip this file to generate a
firmware image file with suffix ".img" as per the following example.

    # Unzip the downloaded Seagate Central Firmware
    unzip Seagate-HS-update-201509160008F.zip
    
Optional : Download or build a cross compiled version of samba 4.x.x for
the Seagate Central. See the **Seagate-Central-Samba** project for 
details. This TLDNR assumes that the samba binaries are stored in the "cross"
subdirectory.
        
Optional : Download or build a new Linux kernel for the Seagate
Central (uImage). See the **Seagate-Central-Modern-Slot-In-Kernel** project
for details. 

Optional : Install other new software into the new software directory
tree. See the **Seagate-Central-Utils** project for details.

Recomended but Optional : Decide on a new root password for the unit.

Create the new Seagate Central firmware image using the "make_seagate_firmware.sh"
script by specifying the Seagate firmware image file (-f), then optionally
the location of cross compiled software (-d), the uImage file (-u) and the new
system root password (-f).

    ./make_seagate_firmware.sh -f ./Seagate-HS-update-201509160008F.img  -d ./cross -u ./uImage -r myrootpassword
    
Upgrade the Seagate Central via the web management interface using the
newly generated image.

## Prerequisites 
### Disk space on the building host
Up to about 1GB of disk space will be required on the building 
host while performing this procedure. The generated firmware image
will be about 120MB in size.

### Time
While the firmware creation process only takes about 1 minute the
upgrade process on the Seagate Central can take as long as 30
minutes depending on how many user files are on the device.

### Required software on build host
The following packages or their equivalents may need to be
installed on the building system.

#### OpenSUSE Tumbleweed - Aug 2021 (zypper add ...)
    unzip
    zip
    squashfs
    
#### Debian 10 - Buster (apt-get install ...)
    unzip
    zip
    squashfs-tools

## Procedure
### Workspace preparation
If not already done, download the files in this project to a 
new directory on your build machine. 

For example, the following **git** command will download the 
files in this project to a new subdirectory called 
Seagate-Central-Samba

    git clone https://github.com/bertofurth/Seagate-Central-Samba
    
Alternately, the following **wget** and **unzip** commands will 
download the files in this project to a new subdirectory called
Seagate-Central-Samba-main

    wget https://github.com/bertofurth/Seagate-Central-Samba/archive/refs/heads/main.zip
    unzip main.zip

Change into this new subdirectory. This will be referred to as 
the base working directory going forward.

     cd Seagate-Central-Samba

### Obtain Seagate Central firmware
As of the writing of this document a Seagate Central firmware zip
file can be downloaded from the Seagate website by going to the
following URL and entering your Seagate Central's serial number.

https://apps1.seagate.com/downloads/request.html

The serial number can be found on the bottom of your Seagate
Central's case, via the web management interface on the
"Settings -> Setup -> About" page, or via the ssh command line by
issuing the "serialno.sh" command.

The serial number should be in a format similar to "NA6SG99A" which
is a made up example of a valid Seagate Central serial number.

The latest firmware zip file available as of the writing of this 
document is Seagate-HS-update-201509160008F.zip

Copy this file to the base working directory on the build host 
and unzip it as per the following example.

    # unzip Seagate-HS-update-201509160008F.zip
    Archive:  Seagate-HS-update-201509160008F.zip  
      inflating: ReadMe.pdf
      inflating: Seagate-HS-update-201509160008F.img
  
There should now be a .img file in the base working directory.
This is the original Segate Central firmware image that will be
used as a basis to create a new firmware image in the coming steps.

Note: Some users have reported that the download only works when
connecting to the seagate website from a US based IP address.

Note: If Seagate ever stop supplying firmware downloads then there is 
a ".img" format firmware file stored in partition 5, the "Config" parititon,
on the Seagate Central hard drive. This is accessible in the 
/usr/config/firmware directory on the Seagate Central.

### Optional : Obtain cross compiled samba software
If you wish to include an upgraded samba server in the newly
generated firmware then make sure that there is a subdirectory
under the base working directory containing the cross compiled
samba software. This will be called **cross** if the procedure 
in README_CROSS_COMPILE.md has been followed.

If you have instead downloaded a pre-compiled archive of the
samba software then copy it to the base working directory and
extract it as per the following example.

     tar -xf seagate-central-samba.tar.gz
     
Take note of the extracted directory name as this will be used
later in the procedure.

### Optional (Advanced) : Add other cross compiled software
This is an "Advanced" option and should only be used if you
have a very solid understanding of this procedure, the
Seagate Central upgrade process and exactly what's happening
at each stage.

Other software besides samba can be cross compiled for the Seagate
Central as per the **Seagate-Central-Utils** project at

https://github.com/bertofurth/Seagate-Central-Utils/

If you build software using that project, then the generated
software can be copied into the same directory tree as the
samba software seen above and embedded in the new firmware 
at the same time as samba. 

All you have to do is make sure that the new software is 
copied into the correct sub directories of the software
directory. These directories are generally as follows (this
is not an exhaustive list)

usr/local/bin : Binary executables
usr/local/lib : Library files
usr/local/sbin : Service binary executables

Some cross compiled software also require that configuration and
startup files be installed in the following directories

etc : Configuration files
etc/init.d : Startup scripts
etc/rcX.d : Startup script links

### Optional : Add a new Linux kernel
If you have downloaded or built a new "uImage" style Linux kernel 
for the Seagate Central as per the **Seagate-Central-Modern-Slot-In-Kernel**
project at

https://github.com/bertofurth/Seagate-Central-Modern-Slot-In-Kernel

then this can be inserted into the new firmware as well.

Simply take a note of the location of the new "uImage" so that it can
be specified later. It might be prudent to copy it to the working
directory.
   
If any kernel modules have been compiled to go with the new
kernel then they need to be copied into the new software tree. For 
example

    mkdir -p cross/lib/modules
    cp -r my-kernel/cross-mod/lib/modules/* cross/lib/modules/
        
### Run the make_seagate_firmware.sh script
The **make_seagate_firmware.sh** script takes an existing Seagate Central
firmware image and creates a new one that can be used to upgrade the Seagate
Central using the normal Seagate Central Web Management interface.

The **make_seagate_firmware.sh** script has the following flags.

#### -f original-firmware-image.img  (Required)
This is the only compulsory/required option. With this flag we specify the
name of the original Seagate Central firmware image file that will be used
as the basis to create a new firmware image. This will probably be something
like "-f ./Seagate-HS-update-201509160008F.img". Warning : Do not specify a 
".zip" file as downloaded from Seagate here. You must first unzip the ".zip"
file to produce the needed ".img" file.

#### -d Software-directory (Optional)
This optional flag specifies the directory containing samba and/or other cross
compiled software for Seagate Central. The contents of this directory will
be overlaid on top of the native Seagate Central directory structure inside
the firmware.
    
#### -u uImage (Optional)
This optional flag specifies a uImage style Linux kernel image file that has
been compiled for the Seagate Central. This will be inserted into the firmware
and will replace the native Seagate supplied v2.6.25 uImage kernel in generated
firmware.

#### -r Root-Password (Recommended but Optional)
If this optional flag is configured then the root password on the Seagate Central
will be set to the value specified. This only occurs once during the very first
bootup after the firmware upgrade. This is useful because recent firmware from
Seagate disables root access on the Seagate Central. We strongly suggest manually 
changing the root password again after bootup.

Some example invocations are as follows

### Example 1 - Upgrade the samba server and change the root password
This example creates a firmware image that upgrades samba to the pre-compiled version
in the newly downloaded "seagate-central-samba-4.14.6-21-Jul-2022" directory and sets
the root password to "seagate9977". 

    ./make_seagate_firmware.sh -f ./Seagate-HS-update-201509160008F.img -d ./seagate-central-samba-4.14.6-21-Jul-2022 -r seagate9977

### Example 2 - Change root password only
This example generates a firmware image that is virtually the same as native Seagate
firmware (no new samba or kernel), but resets the root password to "superman321"

    ./make_seagate_firmware.sh -f ./Seagate-HS-update-201509160008F.img -r superman321
    
### Example 3 - Upgrade samba, root password and Linux Kernel
Create a new firmware image that contains the cross compiled samba software in the
"cross" directory, as well as a downloaded precompiled Linux kernel called
"uImage.v5.16.20-sc", and a root password of "mypassword123"

    ./make_seagate_firmware.sh -f ./Seagate-HS-update-201509160008F.img -d ./cross -u ./uImage.v5.16.20-sc -r mypassword123

The script should generate output indicating the status of the process.

If any fatal errors occur the script should stop and point to a log file
that will hopefully provide some troubleshooting data about the error that has
occured.

Finally, the script should display the name of the newly generated firmware image,
the new randomly generated default root password, and the name of a text
file containing the password. Here is an example of the script being executed with
all the flags and completing succesfully.

    $ ./make_seagate_firmware.sh -f ./Seagate-HS-update-201509160008F.img -d ./seagate-central-samba-4.14.6-21-Jul-2022 -u ./uImage.v5.16.20-sc -r MyNewPassword123
    Flag f argument ./Seagate-HS-update-201509160008F.img
    Flag d argument ./seagate-central-samba-4.14.6-21-Jul-2022
    Flag u argument ./uImage.v5.16.20-sc
    Flag r argument MyNewPassword123
    
    Creating new firmware image Seagate-Central-Update-2022.0819.164318-S.img
    Using original firmware ./Seagate-HS-update-201509160008F.img
    Using cross compiled software directory ./seagate-central-samba-4.14.6-21-Jul-2022
    Using uImage file ./uImage.v5.16.20-sc as Linux kernel
    Setting root password on first boot to MyNewPassword123
    Using temporary build directory temp-2022.0819.164318-S
    
    Filesystem      Size  Used Avail Use% Mounted on
    tmpfs           1.9G  604M  1.3G  32% /tmp
     Extract Seagate Firmware : 16:43:18
      Success: Create temporary directory  16:43:18 See log_01_extract_firmware.log
      Success: untar Seagate Firmware  16:43:20 See log_01_extract_firmware.log
      Success: unsquashfs  16:43:22 See log_02_unsquashfs.log
     Insert cross compiled software : 16:43:22
      Success: copy data  16:43:23 See log_03_cp_samba.log
     Found SAMBA binaries.
     Generate modified samba configuration : 16:43:23
      Success: smb.conf modification part 1  16:43:23 See log_04_smb_conf.log
      Success: smb.conf modification part 2  16:43:23 See log_04_smb_conf.log
     Copy uImage to firmware : 16:43:23
      Success: Copy uImage to firmware  16:43:23 See log_05_copy_uImage.log
     Enable su access : 16:43:23
     Disable and Remove TappIn service : 16:43:23
     Disable and Remove Seagate Media app service : 16:43:23
     Add /usr/local/[s]bin to default PATH : 16:43:23
     Creating new firmware archive : 16:43:24
      Success: Delete old archive  16:43:24 See log_06_mksquashfs.log
      Success: mksquashfs squashfs-root  16:43:29 See log_06_mksquashfs.log
      Success: tar up firmware  16:43:39 See log_07_tar_firmware.log
     Cleanup : 16:43:39
    
     Success!!
     Created  Seagate-Central-Update-2022.0819.164318-S.img
     Root Password : MyNewPassword123
     Generated text file : Seagate-Central-Update-2022.0819.164318-S.img.root-password.txt
 
In addition to generating a new firmware image, the script also does the 
following things.

#### Remove the defunct Seagate Media app service
By default the script will disable and remove the proprietary Seagate
Media app service on the Seagate Central. Note that this is not the
same as the Twonky DLNA media service which remains unaffected by
this firmware upgrade.

The proprietary Seagate Media app service has been non 
operational for some time as per the notice on Seagate's website.

https://www.seagate.com/support/downloads/seagate-media/

By disabling this service we stop the Seagate Central from spending
cpu and memory resources on something that serves no purpose. 
     
If you do NOT want to disable the Seagate Media app service then set
the KEEP_SEAGATE_MEDIA environment variable to any value.

#### Remove the defunct TappIn service
By default the script will disable and remove the TappIn remote
access service on the Seagate Central. This service has been non 
operational for some time as per the notice on Seagate's website.

https://www.seagate.com/support/kb/seagate-central-tappin-update-007647en/

By disabling the service we stop the Seagate Central from spending
cpu and memory resources on something that serves no purpose. In
addition about 25MB of disk space is saved by removing it.

If you do NOT want to disable the Tappin service then set
the KEEP_TAPPIN environment variable to any value.

#### Add /usr/local/bin and /usr/local/sbin to PATH
If any other new cross compiled software besides samba is added
to the new software directory then the system default PATH needs 
to be updated to include the /usr/local/bin and /usr/local/sbin
directories. 

If you do NOT want to add these directories to the default PATH
then set the NO_USR_LOCAL_PATH environment variable to any
value.

### Upgrade the Seagate Central
Login to the target Seagate Central web management page as an admin
user. (Normal users are not able to perform a system upgrade.)

Make sure that the newly created firmware image is locally accessible 
from the machine you are using to log into the web management page. 

On the web management page go into "Settings" Tab. Under the "Advanced" 
folder select the "Firmware Update" option.

At this point I would suggest making sure that the "Update Automatically"
check box is deselected as Seagate is no longer providing automatic 
firmware updates.

In the "Install from file" field click on "Choose File". 

A file selection dialog box should appear where you can select the newly 
built firmware image. 

Once the firmware upgrade image has been chosen click on the
"Install" button.

A dialog box will appear saying

     Your Seagate Central must be on for the duration 
     of the update. This can take from 5 to 10 minutes.
     Do you want to continue?

Click on OK
 
A display entitled "Update progress" showing a progress meter should
appear.

After about few minutes the progress meter may seem to pause for a
significant amount of time at 86%.

I believe at this point the upgrade process is trying to catalogue
user data files, so if you have a lot of user data files stored on
the Seagate Central then this might influence the time it takes to 
upgrade. In my case it took about 15 minutes to get past the 86% 
point.

Once the upgrade is complete a new page should appear displaying 
the message
 
    Rebooting in progress
    The device is rebooting after completing system updates and 
    changes. Wait until the page refreshes and the Seagate Central 
    application appears.

Hopefully the unit will quickly reboot and you are able to access
the web management page again.

Don't panic if you go to the "Home" page and see that the
pie chart indicates that there's no user data. It can take up to
24 hours after an upgrade for the Seagate Central to properly take
stock of the user data and update it's internal statistics. 

If you navigate to the Settings tab then look at the
Setup -> About page then you should see a new version number
in the "Firmware version" field reflecting the new firmware just
applied.

Furthermore for English language users the "Technology Partners"
section should contain a new note indicating the new version of
samba software the unit is running.

### Post upgrade
#### ssh into the Seagate Central and change the root password
If you chose to setup the firmware to force the root password to change
then I would strongly suggest changing it again at this point.

Login to the Seagate Central via ssh as any user. Issue the "su" command
to become the root user and enter the password you selected during the
firmware generation process.

Next, change the root password with the **passwd** command. Here is
a sample session.

     Seagate-NAS:~$ su
     Password: xxxxxxxxxxxxxxx
     Seagate-NAS:/Data/admin# passwd
     Enter new UNIX password: NewPassword123
     Retype new UNIX password: NewPassword123
     passwd: password updated successfully
     
After changing the root password the following commands must be
run to ensure that the Seagate Central does not reset the root
password back to the defaults on the next system boot. 

     cp /etc/passwd /usr/config/backupconfig/etc/
     cp /etc/shadow /usr/config/backupconfig/etc/
     
Note that these "cp" commands need to be run at any future time when the root
password is changed. This is unique to the Seagate Central and is not generally
required on other Linux systems.

#### Confirm that samba is working as expected
IF you have upgraded the samba software on the unit, perform a
sanity check to make sure the new samba binaries are installed 
and executable by running the following command to check the
version of samba that is active.

    testparm -V

The command should report the expected new version (v4.x.x) and 
not the old version (3.5.16).

Next, check to see if the smbd process is running by executing the 
following command. Multiple instances of smbd should be active.

     ps -w | grep smbd

Also confirm that you can once again transfer files between the
Seagate Central and your clients.

Once you have confirmed that the samba service is working you may optionally
disable legacy SMBv1.0 support on any clients that you using to access the
Seagate Central.

#### Optional : Reverting firmware
If the new version of firmware or samba is not performing as 
desired then there is always the option of reverting to the previous 
version.

There is a simple guide to reverting to the previously running version
of Seagate Central firmware at

http://seagatecentralenhancementclub.blogspot.com/2015/08/revert-to-previous-firmware-on-seagate.html

Archive : https://archive.ph/3eOX0

### Troubleshooting 
#### Client connection problems
After the upgrade it may take a few minutes for the changes to the
NAS configuration to propagate and be recognized throughout your
local network.

If any individual clients are having difficulty connecting to the
NAS after the upgrade then consider rebooting them or forcing them
to disconnect then reauthenticate to the Seagate Central NAS.

#### Check samba logs (/var/log/smbd.log)
These logs on the Seagate Central will show error messages
associated with the samba service and will be useful if the service
is not starting.

#### Check the syslog (/var/log/syslog)   
The syslog will show log messages and errors associated with the
system startup process and for other serious events.

#### Check samba parameters (testparm)
The testparm command checks the samba configuration file to make
sure that all the settings are compatible with the current version 
of samba. Here is an example of the expected output for a working
system.

    root@NAS-X:~# testparm
    Load smb config files from /etc/samba/smb.conf
    Loaded services file OK.
    Weak crypto is allowed

    Server role: ROLE_STANDALONE



