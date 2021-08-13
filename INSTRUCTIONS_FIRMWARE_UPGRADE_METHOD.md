# INSTRUCTIONS_FIRMWARE_UPGRADE_METHOD.md
## Summary
This is a guide that describes how to generate a firmware update
for a Seagate Central NAS that contains a modern, cross compiled
version of samba.

It is partially based on the work at

https://github.com/detain/seagate_central_sudo_firmware

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
About BERTO MB of disk space will be required on the building 
host to perform this procedure. The generated firmware image
will be about XXXX MB in size.

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
directory will be known as the base workspace.

### Obtain Seagate Central Firmware
As of the writing of this document Seagate Central firmware can be
downloaded from the Seagate website by going to the following URL
and entering your Seagate Central's serial number.

https://www.seagate.com/au/en/support/external-hard-drives/network-storage/seagate-central/#downloads

The serial number can be found on the bottom of your Seagate
Central's case, via the web management interface on the
"Settings -> Setup -> About" page, or via the ssh command line by
issing the "serialno.sh" command.

The serial number should be in a format similar to "NA6SXXXX".

The latest firmware file available as of the writing of this document
is Seagate-HS-update-201509160008F.zip

Copy this file to the base work directory and unzip it as
follows to extract a .img file 

     unzip Seagate-HS-update-201509160008F.zip

There should now be a .img file in the base working directory.
This is the firmware image that will be used in the coming steps.

### Obtain Samba software archive
Obtain an archived copy of the cross compiled samba software you wish
to install on your Seagate Central. The archive should one generated
as per the instructions in the INSTRUCTIONS_CROSS_COMPILE.md .

There is a pre-compiled version of this currently available at

BERTO

This procedure assumes that the directory structure in the archive
is as per the default instructions in INSTRUCTIONS_CROSS_COMPILE.md . 
Specifically the binaries and associated files should all be in
the usr/local/ subdirectory of the extracted archive.

There is no need to extract the archive at this point. This will
be done by the script executed below.

### OPTIONAL : Tweak the make_seagate_firmware.sh script
#### su access
By default the script will make sure that su access is enabled 
on the upgraded Seagate Central. It will also set a default
password for the root user if one has not already been set.

The password will be set psuedo randomly each time the
script is run but you can modify this by changing the
DEFAULT_ROOT_PASSWORD parameter.

If you do not want to allow su access then comment out the
DEFAULT_ROOT_PASSWORD setting as follows

     #DEFAULT_ROOT_PASSWORD=.......

Refer to the make_seagate_firmware.sh script to see what the
modify
the DEFAULT_ROOT_PASSWORD parameter near the top of the script.
BERTO Useful to make sure this is enabled so you have complete
administrative control of the system.

This upgrade will reset the root password to the value specified
in the file which by default is seagatecentralFDSFDSSFD

#### Disable TappIn
BERTO It doesn't work anymore so why not turn it off?

#### TODO : Add other options?? 

### Run the script

script-name <Seagate-firmware-name.img> <samba-archive-name.tar.gz>



It will be named sdfsdfdsf-date-time

### Upgrade the Seagate Central
Copy the 
 
 
### After
Change the root password as per the other procedure. Will need to 
copy stuff to the backup as well.




### Reverting firmware




