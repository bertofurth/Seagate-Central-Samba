# Seagate-Central-Samba
Instructions on how to replace the old SAMBA file server software on the
Seagate Central

See INSTRUCTIONS.md for details

### Summary
Many modern Windows 10, Linux and other clients may have difficulty
connecting to the Seagate Central NAS. This is because this NAS device
only supports SMB v1.0, which is less secure than the more modern SMB
verions. SMB is the networking protocol that many NAS devices use to
provide file sharing services.

This project seeks to provide instructions to upgrade the SAMBA software
on the Seagate Central. By installing a more recent version of the SAMBA
software, the Seagate Central SAMBA server can use later versions of
the SMB protocol and will therefore be more easily accessed by modern 
clients.

For anyone who does not have the skill, resources or inclination to execute
these instructions themselves, I provide a set of pre-built binaries at

INSERT LINK TO DROP BOX HERE

**NOTE : Performing modifications of this kind on the Seagate Central is 
not without risk. Making the changes suggested in these instructions will 
likely void any warranty and may potentially lead to the device becoming 
unuseable.**

I encourage anyone who is adventurous enough to attempt to make this kind
of modification to their Seagate Central to try to understand each step 
before they apply it in order to reduce the chances of rendering their NAS
device useless.

Finally, note that the Seagate Central has not received an official 
firmware update since 2015 so the manufacturer will probably not be fixing
this issue of their own accord! That being said, Seagate is to be 
commended for making this product customizable enough for these 
instructions to work.

### The problem this project tries to solve
Many modern Windows 10 systems with the latest updates can no longer easily 
connect to the Seagate Central.

When you click on the icon for a Seagate Central NAS in Windows Explorer 
you'll get an error message similar to 

    Windows cannot access \\NAS-name

    See Details :
    Error code: 0x80070035
    The network path was not found.

This is because the Seagate Central running native firmware uses SMB version 
1.0 which a very old and insecure version of the SMB file sharing protocol. 
By default, modern Windows systems will not connect to such services.

A similar problem can occur for modern Linux based client systems as well.
When trying to mount a Seagate Central NAS drive an error message similar to 
the following may appear

    mount error: Server abruptly closed the connection.
    This can happen if the server does not support the SMB version you are trying to use.
    The default SMB version recently changed from SMB1 to SMB2.1 and above. Try mounting with vers=1.0.
    mount error(112): Host is down
    Refer to the mount.cifs(8) manual page (e.g. man mount.cifs) and kernel log messages (dmesg)

### Workarounds
On a linux client the problem can be rectified by simply adding the "vers=1.0" 
parameter to the existing mount options list as per the helpful error message.

For example on the command line using the mount command

    mount -t cifs //10.0.2.198/user1 /mnt/user1 -o user=user1,password=pass1,vers=1.0

or in the /etc/fstab file

    //NAS-X/Public    /mnt/NAS-X    cifs    credentials=/root/NASX-cred,vers=1.0    0    0

For Windows 10, you may need to manually reconfigure your client Windows 10 
system to allow connections to SMB v1.0 file services. There are plenty of in depth 
instructions on the web however the main steps are summarized here.

Launch the Control Panel applet **Turn Windows features on or off**
(Windows + S, then search for "Turn Windows features on or off" and the applet should appear, 
or Launch Control panel and find the applet in the "Programs and Features" tool)

In the "Windows Features" app window that appears expand the **SMB 1.0/CIFS File 
Sharing Support** folder and check the box next to **SMB 1.0/CIFS Client**

Confirm the change by selecting "OK" at the bottom of the window. 

You may be asked to reboot to enable the feature.

These steps may not work if you have a Windows 10 system client that is
administered by your work or school and they may have administratively prohibited
changing the device's settings to allow it to use less secure SMB v1.0. This was 
true in my case.

This is why I've gone to the effort of putting together the steps for replacing 
the default SAMBA server on the Seagate Central NAS with a new one. I didn't feel 
like I should go out and buy a new file server device when I knew that the one 
I had was perfectly capapble of serving my needs but for the want of a little
tweaking.

### Advantages of the new server

#### SMBv2.0 and later support
SMBv2.0 and later versions of SMB are more secure thatn SMB v1.0. This means that
modern cleints should have noproblems interacting with the file server.

#### Support for new features 
The version of the SAMBA server in these instructions is not crippled in the same
way that the one provided in the original firmware is. This means that the full
array of features in the SAMBA server software may be configured, albeit via the
command line rather than the web interface.

### Disadvantages of the new server
#### Second CPU
In stock Seagate Central firmware, one CPU core is available for normal linux 
processes to make use of and the other is reserved exclusively for the
SAMBA file server.

The original SAMBA software on the Seagate Central has custom modifications that
allow it to make use of this second CPU core. This means that in the unlikely event 
that the Seagate Central is overwhelmed by some other task, the file serving
functionality will not be slowed down.

Unfortunately the version of SAMBA being built using these instructions is based
on the generic SAMBA server software and will NOT make use of this second CPU core.
This is because it does not contain the custom modifications that Seagate added to 
their version of the SAMBA software.

Given that the Seagate Central doesn't normally do anything except serve files, in my
experience this doesn't make much of a practical difference in a home network
environment where at most only a few clients are interacting with the NAS at any
given time.

Note that I have another project in the works that deals with upgrading the Linux 
Kernel on the Seagate Central. This will overcome this CPU sharing problem by making
both CPUs in the Seagate Central available for _all_ processes to make use of.

#### Memory
My tests reveal that the new SAMBA service seems to consume significantly more system 
memory than the original. Most recent versions of SAMBA will generally be quite
memory hungry and so this is not something unique to this project. 

As per the CPU issue, in practical terms this does not seem to significantly impact
system performance. Thanks to the Seagate Central having sufficent swap space there
doesn't appear to be any problems.

![image](https://user-images.githubusercontent.com/53927348/127943946-869ad17f-236d-453d-b49f-11a80b78cb87.png)

