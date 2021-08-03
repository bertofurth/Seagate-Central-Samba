# Seagate-Central-Samba
A guide on how to replace the old samba file server software (v3.5.16) 
on the Seagate Central with a new more secure and configurable version of 
samba (v4.14.6) in order to solve problems with Windows 10, Linux and
other modern clients not being able to connect to the Seagate Central.

See INSTRUCTIONS.md for the guide and instructions.

Pre-compiled binaries are available for download at

INSERT URL HERE

### Summary
Many Windows 10, Linux and other modern clients may have difficulty
connecting to the Seagate Central NAS file server. This is because the
file serving "samba" software installed on the Seagate Central uses 
an old version of the SMB file sharing network protocol. This old
version, called SMBv1.0, is much less secure and efficient than
more modern versions. For security reasons, many modern operating
systems will not, by default, allow connections to file servers 
using the SMBv1.0 protocol.

This project seeks to provide a guide to cross-compile and install
a new and replace the old version of samba software (V3.5.16 with
Seagate specific customizations) with a more modern version of 
samba software (v4.14.6) which supports the more secure and efficient
versions of the SMB protocol (V2.1 and above).

See the INSTRUCTIONS.md file in this project for the details.

For anyone who does not have the skill, resources or inclination to execute
these instructions themselves, there is a set of pre-built binaries at

INSERT LINK TO DROP BOX HERE

**NOTE : Performing modifications of this kind on the Seagate Central is 
not without risk. Making the changes suggested in these instructions will 
likely void any warranty and may potentially lead to the device becoming 
unuseable or damaged.**

That being said I've peformed this upgrade on two seperate single bay
Seagate Central systems and they are both working fine. It is also very
simple to roll back the changes should they prove to be inneffective or
have undesirable side effects.

I encourage anyone who is adventurous enough to attempt to this kind
of modification to their Seagate Central to try to understand each step 
before they apply it in order to reduce the chances of accidentally 
rendering their Seagate Central NAS device useless.

Hopefully these instructions can also serve as a template for upgrading
old samba software on other linux based embedded equipment. It should not 
take much tuning of these instructions to be able to apply them to other
similar ARM32 devices running outdated samba software.

Finally, note that the Seagate Central has not received an official 
firmware update since 2015 so the manufacturer will probably not be
providing any resolution of the mentioned issues. That being said,
Seagate is to be commended for making the Seagate Central product 
customizable and open enough for these instructions to work.

### Symptoms of the SMBv1.0 problem
Modern Windows 10 systems with the latest updates can no longer
easily connect to the Seagate Central NAS.

When you click on the icon for a Seagate Central NAS in Windows Explorer,
you may see an error message similar to the following

    Windows cannot access \\NAS-name

    See Details :
    Error code: 0x80070035
    The network path was not found.

If you try to connect to the NAS using a Windows command line tool such
as **net view** an error message similar to the following may be generated

    PS C:\WINDOWS\system32> net view \\10.0.2.199 /ALL
    System error 53 has occurred.

    The network path was not found.

A similar problem can occur for modern Linux based client systems as well.
When trying to mount a Seagate Central NAS drive an error message similar to 
the following may appear

    # mount -t cifs //NAS-X/user1 /mnt/user1 -o user=user1,password=pass1
    mount error: Server abruptly closed the connection.
    This can happen if the server does not support the SMB version you are trying to use.
    The default SMB version recently changed from SMB1 to SMB2.1 and above. Try mounting with vers=1.0.
    mount error(112): Host is down
    Refer to the mount.cifs(8) manual page (e.g. man mount.cifs) and kernel log messages (dmesg)

As mentioned, these problems arise because the Seagate Central's native samba
software allows connections using SMBv1.0 which has a number of known security
vulnerabilities.

The version of samba software on the Seagate Central, v3.5.16, does in theory
suport disabling SMBv1.0 and using only SMBv2.1 however in practise it doesn't 
work well. Versions of samba software v4.x and later are generally considered 
to support SMBv2.1 and higher properly and versions v4.13 and higher
deprecate support for much of SMBv1.0.

### SMBv1.0 Workaround for Windows 10 clients
In Windows 10, you may be able to reconfigure your system to allow connections
to SMB v1.0 file services provided this change has not been administratively
prohibited for security reasons. There are plenty of in depth instructions
and videos on the web showing how to do this (search for : smbv1 windows 10)
however the main steps are summarized here.

Launch the Control Panel applet **Turn Windows features on or off**
(Windows + S, then search for "Turn Windows features on or off" and the applet 
should appear. Alternatively launch Control Panel and find the applet in the
"Programs and Features" tool)

In the "Windows Features" app window that appears expand the **SMB 1.0/CIFS File 
Sharing Support** folder and check the box next to **SMB 1.0/CIFS Client**

Confirm the change by selecting "OK" at the bottom of the window. 

After the changes are made you may be asked to reboot the system to enable
the SMBv1.0 client feature.

These steps may not work if you have a Windows 10 system that is administered by
a third party, such as your work or school, and they may have administratively
prohibited changing the device's settings to allow it to use less secure SMB 
v1.0.

### SMBv1.0 Workaround for Linux clients
On a linux client the problem can be rectified by simply adding the "vers=1.0" 
parameter to the existing mount options list as per the helpful error message
shown when attempting to mount the NAS volume.

For example on the command line using the mount command

    mount -t cifs //NAS-X/user1 /mnt/NAS-X-user1 -o user=user1,password=pass1,vers=1.0

or in the /etc/fstab file

    //NAS-X/user1    /mnt/NAS-X-user1    cifs    usr=user1,password=pass1,vers=1.0    0    0




### Workaround that involes minor modification of the Seagate Central
It is possible to alter the configuration of the samba v3.5.16 software running on
the Seagate Central so that it no longer accepts SMBv1.0 connections. This will
allow Windows 10 clients to be able to connect to the NAS however only SMBv2.1
is supported in samba v3.5.16. While this version of SMB is more secure than 
SMBv1.0 it still has flaws that are fixed in later versions.

In addition this workaround will not help linux clients to connect.



is still not completely 

This means that linux

server that are unable to connect and are not able to be reconfigured
to connect using SMB
https://wiki.samba.org/index.php/Samba3/SMB2#Introduction

### Advantages of installing the new samba server

#### Modern Windows 10 and Linux will connect properly
As per the notes above by upgrading to an SMBv2 and later capable file server the
Seagate Central will still be able to serve modern security conscious operating
systems.

#### Enhanced security and performance
SMBv1.0 has multiple security issues that make it vulnerable to various forms of
attack. Additionally later versions of SMB introduce more efficient messaging 
mechanisms and the option for stronger forms of data encryption.

#### Support for new features 
The samba server created using these instructions is not crippled in the same
way that the one provided in the original firmware is. This means that the full
array of features availabe in samba server software may be configured, albeit via 
the command line and configuration file rather than the web interface.

### Disadvantages of installing the new samba server

#### Second CPU
The Seagate Central is based on a Cortex CNS3420 CPU which has 2 CPU cores.
In stock Seagate Central firmware, one CPU core is available for normal linux 
processes and the other is reserved exclusively for the samba file server. In
other words, the second CPU cannot be used by other processed. Linux acts as if
it only has one CPU core available.

The original samba software on the Seagate Central has custom modifications that
allow it to make use of this second CPU core. This means that in the unlikely event 
that the Seagate Central is overwhelmed by some other task, the file serving
functionality will not be slowed down.

Unfortunately, standard samba software does not make use of this second CPU core.

Given that the Seagate Central doesn't normally do anything except serve files, in my
experience this doesn't make much of a practical difference in a home network
environment where at most only a few clients are interacting with the NAS at any
given time.

Note that I have another project in the works that deals with upgrading the Linux 
Kernel on the Seagate Central. This will overcome this CPU sharing problem by making
both CPUs in the Seagate Central available for _all_ linux processes to make use of.

#### Memory
My tests reveal that the new SAMBA service seems to consume significantly more system 
memory than the original. Most recent versions of SAMBA will generally be quite
memory hungry so this is not something unique to this project. 

As per the CPU issue, in practical terms this does not seem to significantly impact
system performance. This is thanks to the Seagate Central having sufficent swap space
to cater for any temporary excessive memry usage.


### Motivation for this project
My work supplied laptop currently runs Windows 10. After one particular work
mandated system update I was no longer able to connect to my Seagate Central NAS
via the normal Windows Explorer file management tool.

My work IT department administratively disabled the ability to configure the
above mentioned workaround allowing Windows 10 to use SMBv1.0. This was presumably
done for valid security reasons, however I imagine that a significant portion of
Windows users suffered the same kind of inconvinience that I did.

I was still able to temporarily perform file transfers via FTP, which the Seagate
Central supports, however this was less convinient than I was used to.

After doing some research I was able to put together this guide to modifying the
offending component of the Seagate Central, namely the outdate samba software. I 
realise that this information is probably years too late to be of real help however
I am uploading this information in conjunction with some other related projects
centered on the Seagate Central which have taken me a long time to develop.

Another motivation was that I didn't feel like I should have to go out and 
purchase a new file server device when I knew that the Seagate Central hardware
was perfectly capable of serving my needs. I have a philosphical opposition to
the modern culture of buying new gadets every few years to replace ones that are
still adequate for the job they perform. It is both environmentally and financially
wasteful.

While one might be inclined to blame the NAS manufacturer, Seagate, and say that
they should still be providing support and updates for a device that is only
about 7 years old, to their credit they have provided enough information and GPL
source code to make the Seagate Central relatively modifyable and serviceable by
third parties. For this reason I am grateful to Seagate and if someone from the
company is reading this note then I would be thrilled for them to take this work
and make it the basis for an official update for the Seagate Central product.
Naturally all the guidelines of the GPLv2 would need to be adhered to.
