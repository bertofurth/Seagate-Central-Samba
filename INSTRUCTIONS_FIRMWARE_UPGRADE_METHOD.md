# INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md
## Summary
This is a guide that describes how to generate a firmware update
for a Seagate Central NAS that contains a modern, cross compiled
version of samba.

It is partially based on the work at

https://github.com/detain/seagate_central_sudo_firmware
http://seagatecentralenhancementclub.blogspot.com/2015/11/root-su-recovery-for-seagate-central.html

Performing the cross compilation build process for samba is covered 
by **INSTRUCTIONS_CROSS_COMPILE.md**

If any custom changes have been made to a Seagate Central
unit via the command line, such as manual installation of new 
software or manual configuration changes not done via the web
management interface, then this method may overwrite those changes.

If you have made custom modifications then it might be more
appropriate to use the more difficult but more flexible manual
installation method covered by
**INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md**

The target platform tested was a Seagate Central Single Drive NAS 
running firmware version 2015.0916.0008-F however I believe these
instructions should work for other Seagate Central configurations and
firmware versions. 

## Prequisites 
### Disk space on the building host
Up to about 1GB of disk space will be required on the building 
host while performing this procedure. The generated firmware image
will be about 120MB in size.

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
Download the files in this project to a new directory. This 
will be known as the base working directory.

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
password for the root user if one has not already been set.

The password will be set psuedo randomly each time the
script is run but you can modify this by changing the
DEFAULT_ROOT_PASSWORD parameter.

If you **do not** want to allow su access then edit the
make_seagate_firmware.sh file and comment out the 
DEFAULT_ROOT_PASSWORD setting by placing a # symbol in
front of it as follows

     #DEFAULT_ROOT_PASSWORD=.......

#### TappIn
By default the script will disable and remove the TappIn remote
access service on the Seagate Central. This service has been non 
operational for some time as per the notice on Seagate's webiste.

https://www.seagate.com/au/en/support/kb/seagate-central-tappin-update-007647en/

By disabling the service we are not spending cpu resources on
something that serves no purpose. In addition about 25MB of disk
space is saved.

If you **do not** want to disable the TappIn service then edit the
make_seagate_firmware.sh file and comment out the DISABLE_TAPPIN 
setting by placing a # symbol in front of it as follows

     #DISABLE_TAPPIN=1
     
#### TODO : Add other options?? 
If anyone else has any suggestions about quick settings that could
be optimized using this procedure then please raise an issue and 
we can look into it.

### Run the script
Execute the script as per the following example. The first argument is
the name of the original unmodified Seagate Central firmware image.
The second argument is the name of the directory containing the
cross compiled samba software

     ./make_seagate_firmware.sh ./Seagate-HS-update-201509160008F.img ./cross
     
The script should generate output indicating the status of the process.
Finally it should display the name of the new generated firmware image,
the new randomly generated default root password, and the name of a text
file containing the password.

       Success!!
       Created  Seagate-Samba-Update-2021.0813.1710-S.img
       Default Root Password : XXXXXXXXXXXXXXX
       Generated text file : Seagate-Samba-Update-2021.0814.1348-S.img.root-password
       
### Upgrade the Seagate Central
Login to the target Seagate Central web management page.

Make sure that the newly created firmware image is accesible
from the machine logging into the web management page. If
you built the firmware on a different machine then it will
need to be transfered over.

On the web management page go into "Settings" Tab. Under the
"Advanced" folder select the "Firmware Update" option.

At this point I would suggest disabling the "Update Automatically"
check box as Seagate is no longer providing Automatic Updates.

In the "Install from file" field click on "Choose File". 

Select the newly built firmware image in the dialog box that
appears.


 
 
### Post upgrade
#### ssh into the Seagate Central and change the root password
If the root password has not already been set then it will be
set to the default as generated by the script. For this reason
it is very important to change the root password from the default
to a new one.

Log into the Seagate Central via ssh as a normal user then issue
the su command to gain root prividges. You should be prompted
for a password which should be the one generated by the script.
Next change the root password with the passwd command. Here is
a sample session.

     Seagate-NAS:~$ su
     Password: SeagateCentral-XXXXX-XXXXXXXXX
     Seagate-NAS:/Data/admin# passwd
     Enter new UNIX password: NewPassword123
     Retype new UNIX password: NewPassword123
     passwd: password updated successfully
     
After changing the password the following commands must be run to
ensure that the Seagate Central does not reset the root password
back to the defaults on the next system boot. 

     cp /etc/passwd /usr/config/backupconfig/etc/
     cp /etc/shadow /usr/config/backupconfig/etc/
     
#### Confirm that Samba is working as expected
Check to see if the smbd process is running by running the 
following command. Multiple instances of smbd should be
active.

     ps -w | grep smbd

Also confirm that you can once again transfer files between the
Seagate Central and your clients.

Further test that you are able to disable legacy SMBv1.0 support
on any clients and that you are still able to transfer data to and 
from the Seagate Central.

#### Optional : Reverting firmware
If the new version of firmware or samba is not performing as desired 
then there is always the option of reverting to the previous version.

There is a guide to reverting Seagate Central firmware versions at

http://seagatecentralenhancementclub.blogspot.com/2015/08/revert-to-previous-firmware-on-seagate.html

Archive : https://archive.ph/3eOX0

### Troubleshooting

Check logs




