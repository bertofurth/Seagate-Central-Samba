# Seagate-Central-Samba
A guide on how to replace the old samba file server software (v3.5.16) 
on the Seagate Central with a new more secure and configurable version of 
samba (v4.14.6) in order to solve problems with Windows 10, Linux and
other modern clients no longer being able to connect to the Seagate
Central using the old and insecure SMBv1.0 protocol.

A set of pre-compiled samba binaries for Seagate Central generated using
the instructions in this project are currently available for download
in the "releases" section of this project at

https://github.com/bertofurth/Seagate-Central-Samba/releases/download/v1.2/seagate-central-samba-4.14.6-21-Jul-2022.tar.gz

Note that there is a related project called 
**Seagate-Central-Slot-In-v5.x-Kernel** that provides a guide on how to
upgrade the Seagate Central Linux kernel after the samba service has been
upgraded. This can be of significant benefit for performance.

https://github.com/bertofurth/Seagate-Central-Slot-In-v5.x-Kernel

There are three sets of instructions included in this project.

### README_CROSS_COMPILE.md 
Cross compile the replacement samba server from scratch.

This is the most difficult and involved option but compiling your own
version of samba is the best way to ensure that you are getting a safe
and untarnished product for your Seagate Central system. 

The process involves running a number of scripts which ideally will
execute seamlessly and without error. Unfortunately there is a 
significant chance that the process may require tweaking to suit
different systems and therefore might require some understanding of
the cross compilation process if anything goes wrong.

### README_MANUALLY_INSTALL_BINARIES.md
These instructions describe how to manually install the samba software
created by the first set of instructions and alter the Seagate Central
configuration accordingly.

This is the method of installation you should probably chose if you
have already installed custom software or modified the settings on the
Seagate Central using the command line rather than the web management
interface. 

### README_FIRMWARE_UPGRADE_METHOD.md
This option involves running an automated script that takes an existing 
official Seagate Central firmware image and the samba binaries generated
in the first set of instructions, or the downloaded pre-compiled
binaries, as it's input. 

The script modifies the supplied Seagate Central firmware image to
include the samba binaries, appropriate configuration, and other
information. The resultant image can be used to upgrade the Seagate 
Central via the web management interface.

The disadvantage of this method is that if you've already made custom
modifications to your Seagate Central, such as manually installing other
cross compiled software or tweaking the configuration using the command
line rather than the web management interface, then this method might
overwrite those changes unless special care is taken.

## Details
Many Windows 10, Linux and other modern clients may have difficulty
connecting to the Seagate Central NAS file server. This is because the
file serving samba v3.5.16 software installed on the Seagate Central uses 
the outdated version 1.0 of the Server Message Block (SMB) network file 
sharing protocol.

SMBv1.0, is much less secure and less efficient than more modern
versions of SMB (such as v2.1 and v3.x). For security reasons, many 
modern operating systems will not, by default, allow connections to 
file servers using the SMBv1.0 protocol. 

The following link is one of many that give some further explanation 
and insight into the many problems with SMBv1.0.

https://stealthbits.com/blog/what-is-smbv1-and-why-you-should-disable-it/

This project seeks to provide a guide to cross-compile and install
a new version of samba software (v4.14.6) which supports the more
secure and efficient versions of the SMB protocol (V2.1 and above)
as well as new samba software features. This new version of samba
does not, by default, support SMBv1.0.

## Warning
**Performing modifications of this kind on the Seagate Central is not 
without risk. Making the changes suggested in these instructions will
likely void any warranty and in rare circumstances may lead to the
device becoming unusable or damaged.**

**Do not use the products of this project in a mission critical system
or in a system that people's health or safety depends on.** 

It is worth noting that during the testing and development of this
procedure I never encountered any problems involving data corruption 
or abrupt loss of connectivity.

In addition, I have never come close to "bricking" any Seagate Central!

The Seagate Central boot loader (u-boot) has a feature where it
automatically reverts to the previous version of firmware if it finds
it is unable to bootup the system after 4 consecutive attempts. This
normally overcomes any kind of cataclysmic software induced failure.

In the absolute worst case where a Seagate Central were rendered totally
inoperable there is always the option of physically opening the Seagate
Central, removing the hard drive and mounting it on a different machine
in order to resurrect it, and if necessary, retrieve any user data. See

Unbrick, Replace or Reset Seagate Central Hard Drive : 
https://github.com/bertofurth/Seagate-Central-Tips/blob/main/Unbrick-Replace-Reset-Hard-Drive.md

Finally, note that the Seagate Central has not received an official 
firmware update since 2015 so the manufacturer will probably not be
providing any resolution of the SMBv1.0 issues. That being said,
Seagate is to be commended for making the Seagate Central product 
customizable and open enough for these instructions to work.

## Symptoms of the SMBv1.0 problem
Modern Windows 10 systems with the latest updates can no longer
easily connect to the Seagate Central NAS.

When you click on the icon for a Seagate Central NAS in Windows Explorer,
you may see an error message similar to the following

    Windows cannot access \\NAS-name

    See Details :
    Error code: 0x80070035
    The network path was not found.

If you try to probe the status of the NAS using a Windows command line tool
such as **net view** an error message similar to the following may be generated

    PS C:\WINDOWS\system32> net view \\10.0.2.199
    System error 53 has occurred.

    The network path was not found.

When trying to mount a Seagate Central NAS drive using a modern version of
Linux or other Unix based operating system an error message similar to the
following may appear

    # mount -t cifs //NAS-X/user1 /mnt/user1 -o user=user1,password=pass1
    mount error: Server abruptly closed the connection.
    This can happen if the server does not support the SMB version you are trying to use.
    The default SMB version recently changed from SMB1 to SMB2.1 and above. Try mounting with vers=1.0.
    mount error(112): Host is down
    Refer to the mount.cifs(8) manual page (e.g. man mount.cifs) and kernel log messages (dmesg)

This problem arises because modern versions of the cifs tools, which allow
linux systems to connect to samba NAS devices, do not by default use the SMBv1.0
protocol.

The version of samba software on the Seagate Central, v3.5.16, does in theory 
support manually disabling SMBv1.0 and using only SMBv2.1 however in practise 
it doesn't work well. Versions of samba software v4.x and later are generally 
considered to support SMBv2.1 and higher properly. Samba versions v4.13 and 
higher deprecate support for much of SMBv1.0.

## SMBv1.0 Workaround for Windows 10 clients
In Windows 10, you may be able to reconfigure your system to allow connections
to SMB v1.0 file services. There are plenty of in depth instructions and 
videos on the web showing how to do this (search for : smbv1 windows 10)
however the main steps are summarized here.

Launch the Control Panel applet **Turn Windows features on or off**

This applet can be launched by pressing Windows Key + S to invoke the
Windows Search dialog, then searching for "Turn Windows features on or off". 
The applet should appear in the search results and can be launched from 
there.

In the "Windows Features" app window that appears expand the **SMB 1.0/CIFS 
File Sharing Support** folder and check the box next to **SMB 1.0/CIFS 
Client**

Confirm the change by selecting "OK" at the bottom of the window. 

After the changes are made you may be asked to reboot the system to enable
the SMBv1.0 client feature.

Be aware that in some cases an IT department administered Windows 10 system 
will be administratively prohibited from changing this setting because of
the security issues associated with SMBv1.0.

## SMBv1.0 Workaround for Linux clients
On a linux or other unix client the problem can be rectified by simply
adding the "vers=1.0" parameter to the existing mount options list as per
the helpful error message shown when attempting to mount the NAS volume.

For example on the command line using the mount command

    mount -t cifs //NAS-X/user1 /mnt/NAS-X-user1 -o user=user1,password=pass1,vers=1.0

or in the /etc/fstab file

    //NAS-X/user1    /mnt/NAS-X-user1    cifs    user=user1,password=pass1,vers=1.0    0    0

## Advantages of installing the new samba server
### Modern Windows 10 and Linux will connect properly
As per the notes above, by upgrading to an SMBv2 and later capable file 
server the Seagate Central will be able to serve modern security 
conscious operating systems without the need for any security compromising 
workarounds on the client systems.

### Enhanced security and performance
SMBv1.0 has multiple security issues that make it vulnerable to various 
forms of attack. Additionally later versions of SMB introduce more
efficient messaging mechanisms and stronger builtin data integrity 
checking. Some tests show that SMBv3.0 can be many times faster
than SMBv1.0 in some circumstances because of increased efficiency.

### Support for new features 
The samba server created using these instructions is not crippled in 
the same way that the one provided in the original firmware is. This
means that the full array of features available in samba server software 
may be configured, albeit via the command line and configuration file 
rather than the web interface.

### Performance : TODO
TEST A FRESH OUT OF THE BOX UNIT RUNNING OLD SAMBA vs A NEW ONE

## Disadvantages of installing the new samba server
### Second CPU (fixed by Seagate-Central-Slot-In-v5.x-Kernel)
The Seagate Central is based on a Cavium CNS3420 CPU which has 2 CPU 
cores. In stock Seagate Central firmware, the first CPU core is available
for normal linux processes and the second is reserved exclusively for the 
samba file server. In other words, the second CPU cannot be used by any 
"normal" linux processes. In Seagate Central software this scheme is
referred to as the "Cavium SMP Offloading Procession" (SOP), or in
general terms "Asymmetric Multi Processing" (AMP).

The original samba software on the Seagate Central has custom 
modifications that allow it to make use of the second CPU core operating
in AMP mode. This means that in the unlikely event that the first Seagate
Central CPU is overwhelmed by some non file-sharing task, the file 
serving functionality will not be slowed down as it will be using the
second CPU.

Unfortunately, normal samba software as used by this installation guide 
does not make use of AMP mode. This is because AMP is rarely implemented
in modern linux systems. Most modern linux systems use "Symmetrical 
Multi Processing" (SMP) which allows **all** processes to make use of
**any** CPU.

Given that the Seagate Central doesn't normally do anything except serve 
files, in my judgement this disadvantage won't make much of a practical
difference in the moderate usage environment of a home or small business 
where a Seagate Central would typically be deployed. The only minor 
exception I've encountered is just after bootup when the Seagate Central
spends a few minutes cataloging the data files stored on the unit.
During this brief time the CPU load can be quite high and file serving 
performance can slightly suffer.

Note that there is another project called Seagate-Central-Slot-In-v5.x-Kernel
located at

https://github.com/bertofurth/Seagate-Central-Slot-In-v5.x-Kernel/ 

which shows instructions for compiling and installing an upgraded SMP
capable Linux Kernel on the Seagate Central. This will overcome the second
CPU problem by making **both** CPUs in the Seagate Central available for
**all** linux processes. That is, SMP (Symmetrical Multi Processing) 
will be implemented in this updated Linux Kernel. 

If this new upgraded linux kernel is installed and running then the new
version of samba can take advantage of both the SMP based CPU cores on the
system and then, in theory, the new samba software will be able to 
perform even better than the original Seagate AMP based samba software.

### Memory
My tests reveal that the updated samba v4.14.6 software seems to consume 
significantly more system memory than the original v3.5.16. Most recent 
versions of samba will generally be quite memory hungry so this is not 
something unique to this project. 

As per the CPU issue, in practical terms this does not seem to 
significantly impact system performance. This is thanks to the Seagate 
Central having sufficient swap space to cater for any temporary excessive 
memory usage.

### No support for very old clients that depend on SMBv1.0
Very old client operating systems, such as Windows XP, Windows 95 or Windows 
2000 either only support SMBv1.0 or do not properly support SMBv2.1. If the 
new samba server is installed on the Seagate Central then these types of 
very old clients may not be able to connect to the Seagate Central using
the SMB protocol. (They'll still be able to use FTP/SCP etc)

This may also apply to very old network connected systems such as 
televisions or DVD players that make use of the Seagate Central to access 
media files, although most of these kinds of devices use the DLNA
media sharing protocol which is unaffected by this upgrade.

SMBv2.1 client support was introduced for Windows 7 in 2007 and for
Linux v3.7 in 2012 so most clients from after these dates should be fine. 

## Motivation for this project
My work supplied laptop currently runs Windows 10. After one particular IT
department mandated system update I was no longer able to connect to my 
Seagate Central NAS via the normal Windows Explorer file management tool. 
This was because SMBv1.0 client capability was turned off in my laptop by 
the update.

My work IT department administratively disabled the option to re-enable 
SMBv1.0. This was presumably done for valid security reasons, however it meant 
that I had no easy way of accessing my home Seagate Central file server.

I was still able to temporarily perform file transfers via FTP and SCP, 
which the Seagate Central natively supports, however this was a less
convenient option than I was used to.

After doing some research I was able to put together this guide to modifying 
the offending component of the Seagate Central, namely the outdated samba 
software. I realise that this information is probably years too late to be of
real help however I am uploading this information in conjunction with some
other related projects centred on the Seagate Central which have taken me a
long time to develop.

Another motivation was that I didn't feel like I should have to go out and 
purchase a new file server device when I know that the Seagate Central 
hardware is perfectly capable of serving my needs. I have a philosophical
opposition to the modern culture of buying new gadgets every few years to 
replace ones that are still adequate for the job they perform. It is both
environmentally and financially wasteful.

While one might be inclined to blame the NAS manufacturer, Seagate, and say 
that they should still be providing support and updates for a device that is 
only about 7 years old, to their credit they have provided enough information 
and GPL source code to make the Seagate Central relatively modifiable and 
serviceable by third parties. For this reason I am grateful to Seagate and if 
someone from the company is reading this note then I would be thrilled for them 
to take this work and use it as the basis for an official update for the Seagate 
Central product.

Hopefully these instructions can serve as a template for upgrading
old samba software on other Linux based embedded equipment. It should not 
take much tuning of these instructions to be able to apply them to other
similar ARM based devices running outdated samba software.

Finally I learned a great deal about Linux, samba and cross-compilation 
while writing this guide. Please read these instructions with the 
understanding that I am still in the process of learning. I trust that
this project will help others to learn as well.
