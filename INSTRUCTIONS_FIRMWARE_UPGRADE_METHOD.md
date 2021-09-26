# INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md
## Summary
This is a guide that describes how to generate a firmware update
for a Seagate Central NAS that contains a modern, cross compiled
version of samba.

It is partially based on the work at

https://github.com/detain/seagate_central_sudo_firmware

http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html

Refer to the README.md file for the location of a set of 
pre-compiled binaries that can be used in this process or
refer to the instructions in **README_CROSS_COMPILE.md**
to self generate the binaries.

If any custom changes have been made to a Seagate Central
unit via the command line, such as manual installation of new 
software or manual configuration changes not done via the web
management interface, then this method may overwrite those 
changes. Configuration changes made via the normal Seagate
Central web management interface will not be affected.

If you have made extensive custom modifications via the CLI then
it might be more appropriate to use the more difficult but more
flexible manual installation method covered by
**README_FIRMWARE_UPGRADE_METHOD.md**

Note that it is possible to also upgrade the Seagate Central
Linux kernel and to install other cross compiled software using
this method. See the **Seagate-Central-Slot-In-v5.x-Kernel**
and **Seagate-Central-Utils** projects for details.

https://github.com/bertofurth/Seagate-Central-Slot-In-v5.x-Kernel/

https://github.com/bertofurth/Seagate-Central-Utils/

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations
and firmware versions. 

## TLDNR
Make sure you have already built or downloaded a cross compiled 
copy of samba for the Seagate Central. This TLDNR assumes that it
is stored in the "cross" subdirectory.

Download a copy of the latest Seagate Central firmware from the Seagate 
website. This TLDNR assumes the downloaded firmware zip file is called
Seagate-HS-update-201509160008F.zip 

    # Unzip the downloaded Seagate Central Firmware
    unzip Seagate-HS-update-201509160008F.zip
    
Optional : Install a new Linux kernel (uImage) into the new software
directory tree. (See **Seagate-Central-Slot-In-v5.x-Kernel** project)
 
    mkdir -p ./cross/boot
    cp my-kernel/uImage ./cross/boot/uImage
    
Optional : Install other new software into the new software directory
tree. (See **Seagate-Central-Utils** project)

    cp -r my-util/cross/* ./cross/
    
Create the new Seagate Central firmware image

    ./make_seagate_firmware.sh ./Seagate-HS-update-201509160008F.img ./cross
    
Take note of the new randomly generated default root password which
will be applied if there is no root password already set.

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

    git clone https://github.com/bertofurth/Seagate-Central-Samba.git
    
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

https://www.seagate.com/au/en/support/external-hard-drives/network-storage/seagate-central/#downloads

The serial number can be found on the bottom of your Seagate
Central's case, via the web management interface on the
"Settings -> Setup -> About" page, or via the ssh command line by
issuing the "serialno.sh" command.

The serial number should be in a format similar to "NA6SXXXX".

The latest firmware zip file available as of the writing of this 
document is Seagate-HS-update-201509160008F.zip

Copy this file to the base working directory on the build host 
and unzip it as follows.

     unzip Seagate-HS-update-201509160008F.zip

There should now be a .img file in the base working directory.
This is the firmware image that will be used in the coming steps.

Note : If Seagate ever stop supplying firmware downloads then it
would be possible to generate a new firmware image based on the
contents of a working Seagate Central. That, however, is beyond
the scope of this project.

### Obtain cross compiled samba software
Make sure that there is a subdirectory under the base working 
directory containing the cross compiled samba software. This
will be called **cross** if the procedure in
INSTRUCTIONS_CROSS_COMPILE.md has been followed.

If you have instead downloaded a pre-compiled archive of the
samba software then copy it to the base working directory and
extract it as per the following example.

     tar -xf seagate-central-samba.tar.gz
     
Take note of the extracted directory name as this will be used
later in the procedure.

### Optional : Add a new Linux kernel
If you have built a new Linux kernel for the Seagate Central
as per the **Seagate-Central-Slot-In-v5.x-Kernel** project at

https://github.com/bertofurth/Seagate-Central-Slot-In-v5.x-Kernel

then you can insert this new kernel into the new software
directory tree as follows

    mkdir -p cross/boot
    cp uImage cross/boot/uImage
    
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
copied into the correct sub directories which are generally
as follows (this is not an exhaustive list)

usr/local/bin : Binary executables
usr/local/lib : Library files
usr/local/sbin : Service binary executables

Some of the projects also require that configuration and
startup files be installed in the following directories

etc : Configuration files
etc/init.d : Startup scripts
etc/rcX.d : Startup script links
     
### Run the make_seagate_firmware.sh script
The **make_seagate_firmware.sh** script takes an existing
Seagate Central firmware image, overlays the contents of the
specified sofware directory and then packages up a new
firmware image that can be installed using the normal
Seagate Central Web Management interface.

Execute the **make_seagate_firmware.sh** script as per the following
example. The first argument is the name of the original unmodified 
Seagate Central firmware image. The second argument is the name of
the directory containing the cross compiled samba software. 

     ./make_seagate_firmware.sh ./Seagate-HS-update-201509160008F.img ./cross
     
The script should generate output indicating the status of the process.
Finally it should display the name of the newly generated firmware image,
the new randomly generated default root password, and the name of a text
file containing the password.

       Success!!
       Created  Seagate-Samba-Update-2021.0808.0605-S.img
       Default Root Password : XxXxXxXxXxXxX
       Generated text file : Seagate-Samba-Update-2021.0808.0605-S.img.root-password

In addition to generating a new firmware image, the script also
does the following things.

#### Re-enable su / root access
By default the script will make sure that su access is enabled 
on the upgraded Seagate Central. It will also set a default
password for the root user that is applied if one is **not**
already set.

The password will be set randomly each time the script is run
but you can modify this by changing the DEFAULT_ROOT_PASSWORD 
parameter within the script.

If you do NOT want to re-enable su / root access on the Seagate
Central then set the NO_ENABLE_ROOT enviroment variable to any 
value. For example

     NO_ENABLE_ROOT=1 ./make_seagate_firmware.sh .......

#### Remove the defunct TappIn service
By default the script will disable and remove the TappIn remote
access service on the Seagate Central. This service has been non 
operational for some time as per the notice on Seagate's website.

https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/

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
Login to the target Seagate Central web management page.

Make sure that the newly created firmware image is locally
accessible from the machine logging into the web management page. 

On the web management page go into "Settings" Tab. Under the
"Advanced" folder select the "Firmware Update" option.

At this point I would suggest making sure that the 
"Update Automatically" check box is deselected as Seagate is
no longer providing automatic updates.

In the "Install from file" field click on "Choose File". 

A file selection dialog box should appear where you can select
the newly built firmware image.

Once the firmware upgrade image has been chosen click on the
"Install" button.

A dialog box will appear saying

     Your Seagate Central must be on for the duration 
     of the update. This can take from 5 to 10 minutes.
     Do you want to continue?

Click on OK
 
A display entitled "Update progress" showing a progress meter should
appear.

After about few minutes the progress meter seems to pause for a
significant amount of time at 86%.

I believe at this point the upgrade process is trying to catalogue
user data files so if you have a lot of user data files stored on
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
If the root password **has not already been set** then it will be
set to the default as generated by the script. For this reason
it is very important to change the root password from the default
to a new one.

Log into the Seagate Central via ssh as a normal user then issue
the **su** command to gain root privileges. You should be prompted
for a password which should be the one generated by the script.
Next change the root password with the **passwd** command. Here is
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
     
Note that this needs to be done at anytime when the root
password is changed on the Seagate Central.

#### Confirm that samba is working as expected
First, perform a sanity check to make sure the new samba binaries
are installed and executable by running the following command to
check the version of samba that is active.

    testparm -V

The command should report the expected new version (v4.x.x) and 
not the old version (3.5.16).

Next, check to see if the smbd process is running by executing the 
following command. Multiple instances of smbd should be active.

     ps -w | grep smbd

Also confirm that you can once again transfer files between the
Seagate Central and your clients.

Further test that you are able to disable legacy SMBv1.0 support
on any clients and that you are still able to transfer data to and 
from the Seagate Central.

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



