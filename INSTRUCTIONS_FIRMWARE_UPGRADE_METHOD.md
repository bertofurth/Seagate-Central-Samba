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
refer to the instructions in **INSTRUCTIONS_CROSS_COMPILE.md**
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
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations
and firmware versions. 

## Prequisites 
### Disk space on the building host
Up to about 1GB of disk space will be required on the building 
host while performing this procedure. The generated firmware image
will be about 120MB in size.

### Time
While the fimware creation process only takes about 1 minute the
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
Download the files in this project to a new directory on the
building host. This will be known as the base working directory.

### Obtain Seagate Central Firmware
As of the writing of this document a Seagate Central firmware zip
file can be downloaded from the Seagate website by going to the
following URL and entering your Seagate Central's serial number.

https://www.seagate.com/au/en/support/external-hard-drives/network-storage/seagate-central/#downloads

The serial number can be found on the bottom of your Seagate
Central's case, via the web management interface on the
"Settings -> Setup -> About" page, or via the ssh command line by
issing the "serialno.sh" command.

The serial number should be in a format similar to "NA6SXXXX".

The latest firmware zip file available as of the writing of this 
document is Seagate-HS-update-201509160008F.zip

Copy this file to the base working directory and unzip it as
follows.

     unzip Seagate-HS-update-201509160008F.zip

There should now be a .img file in the base working directory.
This is the firmware image that will be used in the coming steps.

Note : If Seagate ever stop supplying firmware downloads then it
would be possible to generate a new fimrware image based on the
contents of a working Seagate Central. That, however, is beyond
the scope of this project.

### Obtain cross compiled samba software
Make sure that there is a subdirectory under the base working 
directory containing the cross compiled samba software.

The procedure assumes that the directory structure of the
samba software directory is as per the default instructions in
INSTRUCTIONS_CROSS_COMPILE.md . Specifically the binaries and
associated files should all be in the usr/local/ subdirectory.

If you have downloaded a pre-compiled archive then copy it to
the base working directory and extract it as per the following
example.

     tar -xf seagate-central-samba.tar.gz
     
### OPTIONAL : Tweak the make_seagate_firmware.sh script
#### su access
By default the script will make sure that su access is enabled 
on the upgraded Seagate Central. It will also set a default
password for the root user that is applied if one is **not**
already set.

The password will be set psuedo randomly each time the
script is run but you can modify this by changing the
DEFAULT_ROOT_PASSWORD parameter within the script.

If you **do not** want to allow su access then edit the
make_seagate_firmware.sh file and comment out the 
DEFAULT_ROOT_PASSWORD setting by placing a # symbol in
front of it as follows

     #DEFAULT_ROOT_PASSWORD=.......

#### TappIn
By default the script will disable and remove the TappIn remote
access service on the Seagate Central. This service has been non 
operational for some time as per the notice on Seagate's website.

https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/

By disabling the service we are not spending cpu resources on
something that serves no purpose. In addition about 25MB of disk
space is saved by removing it.

If you **do not** want to remove the TappIn service then edit the
make_seagate_firmware.sh file and comment out the DISABLE_TAPPIN 
setting by placing a # symbol in front of it as follows

     #DISABLE_TAPPIN=1
     
Note that the Tappin icon will still appear in the Seagate Central
web management interface but it will not be able to be activated.
     
#### TODO : Add other options?? 
If anyone else has any suggestions about quick settings on the 
Seagate Central that could be modified and optimized using this
procedure then please raise an issue and we can look into it.

### Run the script
Execute the **make_seagate_firmware.sh** script as per the following
example. The first argument is the name of the original unmodified 
Seagate Central firmware image. The second argument is the name of
the directory containing the cross compiled samba software. 

     ./make_seagate_firmware.sh ./Seagate-HS-update-201509160008F.img ./seagate-central-samba
     
The script should generate output indicating the status of the process.
Finally it should display the name of the new generated firmware image,
the new randomly generated default root password, and the name of a text
file containing the password.

       Success!!
       Created  Seagate-Samba-Update-2021.0813.1710-S.img
       Default Root Password : XxXxXxXxXxXxX
       Generated text file : Seagate-Samba-Update-2021.0814.1348-S.img.root-password
       
### Upgrade the Seagate Central
Login to the target Seagate Central web management page.

Make sure that the newly created firmware image is accesible
locally from the machine logging into the web management page. 

On the web management page go into "Settings" Tab. Under the
"Advanced" folder select the "Firmware Update" option.

At this point I would suggest making sure that the 
"Update Automatically" check box in deselected as Seagate is
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
 
A display entited "Update progress" showing a progress meter should
appear.

After about 3 minutes the progress meter seems to pause at 86%.

I believe at this point the upgrade process is trying to catalog
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
Settings -> About page then you should see a new version number
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
the su command to gain root prividges. You should be prompted
for a password which should be the one generated by the script.
Next change the root password with the passwd command. Here is
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

#### Confirm that Samba is working as expected
Check to see if the smbd process is running by executing the 
following command. Multiple instances of smbd should be
active.

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
#### Check samba logs (/var/log/smbd.log)
These logs will show error messages associated with the samba service
and will be useful if the service is not starting.

#### Check startup logs (dmesg)    
The **dmesg** command will show errors associated with the system startup
process in general.

#### Check samba parameters (testparm)
The testparm command checks the samba configuration file to make sure
that all the settings are compatible with the current version of
samba.

    root@NAS-X:~# testparm
    Load smb config files from /etc/samba/smb.conf
    Loaded services file OK.
    Weak crypto is allowed

    Server role: ROLE_STANDALONE



