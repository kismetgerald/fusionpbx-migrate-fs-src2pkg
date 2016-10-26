#Migrate FreeSWITCH from Source to Package Install
---
This is a small script written to help automate the process of migrating the underlying FreeSWITCH application from source to packages on an existing and fully operational FusionPBX server, thus preserving all functionality and settings.  

Before you follow this readme, please understand that I am a novice in the Linux world so if you see an opportunity to improve on this process, please feel free to fork this repo and make changes.  All I ask is that you communicate such improvements back to me via pull requests, email, or to the #fusionpbx or #freeswitch IRC channels so as to help the community benefit from them.

##**Prerequisites:**##
---
Before you begin, make sure the following is true about your environment:
* OS:  Debian Linux v8 (Jessie) x64
* FusionPBX is installed and functioning well (i.e., you can login and make changes to your settings and they take effect).
* You have a source-compiled installation of FreeSWITCH (i.e., the folder /usr/local/freeswitch is present on your system and Advanced > Default Settings > Switch in the FusionPBX Gui shows the switch paths in the folder identified above).
* The folder /etc/freeswitch is NOT present in your system (if it is, you’ll need to delete or move it, as the installation will not overwrite that folder).

##**Summary Results:**##
---
If all goes well, your installation of FusionPBX will be unaffected (i.e., any customizations you’ve made will survive), but you will now be able to easily upgrade FreeSWITCH with APT (using apt-get upgrade and/or apt-get dist-upgrade).

An added benefit is that installing modules will be much easier – as simple as “apt-get install freeswitch-mod-shout” for example.  It’ll get installed, configured, and enabled for you.

##**Okay, some housekeeping:**##
If you are as cautious as I am, and this server is a VPS – **TAKE A SNAPSHOT NOW!!!**
If it is not a VPS, then you may want to opt for move (_wherever a delete is specified_).  In case anything goes wrong, simply go back and move the folders back to where they were.  I would recommend a suffix like “_old”.


#**Usage:**#
To use this script, simply choose one of the following approaches..

##**Automatic Approach**##
---
Open the Command-Line Interface (CLI) and run the following commands
    git clone https://github.com/kismetgerald/fusionpbx-migrate-fs-src2pkg.git
    cd fusionpbx-migrate-fs-src2pkg/
    chmod +x migrate_fs_src2pkg.sh
    ./migrate_fs_src2pkg.sh

##**Manual Approach**##
---
If you're the more hands-on type and want to get your hands dirty with the CLI, then this option is best for you.  Simply reference [these PDF instructions](https://github.com/kismetgerald/fusionpbx-migrate-fs-src2pkg/blob/master/Instructions.pdf).