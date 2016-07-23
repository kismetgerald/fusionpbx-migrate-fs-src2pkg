#!/bin/bash

#Define global variables
fs_path="/usr/local/freeswitch"
fs_pkg_conf_dir="/etc/freeswitch"
fpbx_path="/var/www/fusionpbx"
fpbx_src_path="/usr/src/fusionpbx-install.sh/debian/resources/switch/"
f2b_jail_local="/etc/fail2ban/jail.local"
f2b_jail_conf="/etc/fail2ban/jail.conf"

# Functions
main ()
{
  clear
  echo "${LICENSE}"

  read -p "Shall we proceed? [Y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    detect_os
    switch_check

    # Step 1:
    # First we stop the FreeSWITCH service
    echo "Stopping FreeSWITCH..."
    systemctl stop freeswitch

    # Step 2:
    # Rename existing directories which will prevent the package install
    # We first check if they exist then rename them
    # If they don't exist, then just rename and move on
    echo "Renaming ${fs_pkg_conf_dir} (if it exists) to ${fs_pkg_conf_dir}""_old"
    if [ -d "${fs_pkg_conf_dir}" ]; then 
      mv "${fs_pkg_conf_dir}" "${fs_pkg_conf_dir}"\_old
    fi

    echo "Renaming ${fs_path} to ${fs_path}""_old" 
    mv "${fs_path}" "${fs_path}"\_old

    echo "Checking for the FusionPBX install folder"
    if [ -d "${fpbx_src_path}" ]; then
        echo "FusionPBX install folder found at ${fpbx_src_path}, switching to it."
        cd ${fpbx_src_path} || exit
      else
        echo "FusionPBX install folder was not found, so let's get it."
        cd /usr/src || exit
        git clone https://github.com/fusionpbx/fusionpbx-install.sh.git
        chmod 755 -R /usr/src/fusionpbx-install.sh
        cd /usr/src/fusionpbx-install.sh/debian/resources/switch/ || exit
      fi
    fi

    # Step 3:
    # Install FreeSWITCH
    echo "Ready to install FreeSWITCH"
    sleep 2
    echo "Please make a selection: [1] Official Release [2], Official Release with ALL MODULES, or [3] Master Branch"
    read answer
    if [[ ${answer} == 1 ]]; then 
      ./package-release.sh

    elif [[ ${answer} == 2 ]]; then 
      ./package-all.sh

    elif [[ ${answer} == 3 ]]; then 
      ./package-master-all.sh
    fi

    # Step 4
    # Write the following changes to the db.  These will adjust the switch paths to those used by the package:
    #   COLUMNS --> default_setting_subcategory   default_setting_name    default_setting_value                 default_setting_enabled
    #               base                          dir                     /usr                                  true
    #               bin                           dir                     null                                  true
    #               call_center                   dir                     /etc/freeswitch/autoload_configs      false
    #               conf                          dir                     /etc/freeswitch                       true
    #               db                            dir                     /var/lib/freeswitch/db                true
    #               diaplan                       dir                     /etc/freeswitch/dialplan              false
    #               extensions                    dir                     /etc/freeswitch/directory             false
    #               grammar                       dir                     /usr/share/freeswitch/grammar         true
    #               log                           dir                     /var/log/freeswitch                   true
    #               mod                           dir                     /usr/lib/freeswitch/mod               true
    #               phrases                       dir                     /etc/freeswitch/lang                  false
    #               recordings                    dir                     /var/lib/freeswitch/recordings        true
    #               scripts                       dir                     /usr/share/freeswitch/scripts         true
    #               sip_profiles                  dir                     /etc/freeswitch/sip_profiles          false
    #               sounds                        dir                     /usr/share/freeswitch/sounds          true
    #               storage                       dir                     /var/lib/freeswitch/storage           true
    #               voicemail                     dir                     /var/lib/freeswitch/storage/voicemail true
    echo "Now updating switch paths in FusionPBX's Default Settings ..."
    cd /tmp || exit
    sudo -u postgres -- psql -d fusionpbx -t -c "UPDATE v_default_settings
            SET default_setting_value = v.value,
                default_setting_enabled = v.enabled
            FROM (VALUES
                      ('base',          '/usr',                                        'true' ),
                      ('bin',           '',                                            'true' ),
                      ('call_center',   '/etc/freeswitch/autoload_configs',            'false'),
                      ('conf',          '/etc/freeswitch',                             'true' ),
                      ('db',            '/var/lib/freeswitch/db',                      'true' ),
                      ('dialplan',      '/etc/freeswitch/dialplan',                    'false'),
                      ('extensions',    '/etc/freeswitch/directory',                   'false'),
                      ('grammar',       '/usr/share/freeswitch/grammar',               'true' ),
                      ('log',           '/var/log/freeswitch',                         'true' ),
                      ('mod',           '/usr/lib/freeswitch/mod',                     'true' ),
                      ('phrases',       '/etc/freeswitch/lang',                        'false'),
                      ('recordings',    '/var/lib/freeswitch/recordings',              'true' ),
                      ('scripts',       '/usr/share/freeswitch/scripts',               'true' ),
                      ('sip_profiles',  '/etc/freeswitch/sip_profiles',                'false'),
                      ('sounds',        '/usr/share/freeswitch/sounds',                'true' ),
                      ('storage',       '/var/lib/freeswitch/storage',                 'true' ),
                      ('voicemail',     '/var/lib/freeswitch/storage/voicemail',       'true' )
                  ) AS v(subcategory,value,enabled)
            WHERE v.subcategory = v_default_settings.default_setting_subcategory;"
    echo ""
    echo "Done updating switch path variables in the database ..."
    cd ${fpbx_src_path} || exit


    # Step 5(a) 
    echo "Deleting switch configs pulled down by the package install from /etc/freeswitch ..."
    rm -rf /etc/freeswitch/*
    echo "Done"

    # Step 5(b)
    echo "Restoring switch configs from /usr/local/freeswitch_old/* to /etc/freeswitch ..."
    cp -ar /usr/local/freeswitch_old/conf/* /etc/freeswitch
    echo "Done"

    # Step 5(c)
    echo "Patching the lua.conf.xml file so it points to the new scripts directory ..."
    sed -i 's~base_dir}/scripts~script_dir}~' /etc/freeswitch/autoload_configs/lua.conf.xml
    echo "Done patching the lua.conf.xml file"

    # Step 6
    # Let's fix permissions and restart the various services.
    echo "Fixing permissions and restarting the various services"
    cd "${fpbx_src_path}" || exit
    ./package-permissions.sh
    systemctl daemon-reload
    systemctl try-restart freeswitch
    systemctl daemon-reload
    systemctl restart php5-fpm
    systemctl restart nginx
    echo "Done"

    # Step 7
    # Here we update Fail2Ban to look in /var/log/freeswitch/ for the switch logs
    if [[ -f "${f2b_jail_local}" ]]; then
      echo "Updating log file path in the /etc/fail2ban/jail.local file"
      sed -i 's~usr/local/freeswitch/log/freeswitch.log~var/log/freeswitch/freeswitch.log~' /etc/fail2ban/jail.local
      elif [[ -f "${f2b_jail_conf}" ]]; then
        echo "Updating log file path in the /etc/fail2ban/jail.conf file"
        sed -i 's~usr/local/freeswitch/log/freeswitch.log~var/log/freeswitch/freeswitch.log~' /etc/fail2ban/jail.conf
    fi

    echo "Restarting the Fail2Ban service ..."
    systemctl restart fail2ban
    echo "Done"

    # Step 8
    # Let's wrap-up
    echo "${FINISH}"

    read -p "Reboot the server? [Y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Rebooting server in 10 seconds"
      echo "If you change your mind use Ctrl+C to interrupt the reboot."
      sleep 10
      sudo reboot
    fi
}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "${dist}" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "${dist}" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as ${os}/${dist}."
  echo ""
}

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo "Please consider using the manual approach, if you know what you're doing!"
  echo ""
  echo "Exiting...."
  echo ""
  sleep 5
}

switch_check ()
{
echo "Checking for the existence of FreeSWITCH..."
  if [ -d "${fs_path}" ]
    then
      echo "Excellent!  The FreeSWITCH directory (${fs_path}) was found so let's continue."
      echo ""
    else
      echo "Error: Directory ${fs_path} does not exists."
      echo ""
      echo "The traditional FreeSWITCH path (${fs_path}) was not detected, as such, this script will stop execution."
      echo ""
      sleep 3
      exit 1
  fi
}

LICENSE=$( cat << DELIM
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# "THE UAYOR LICENSE" (Version 1)
#
# This is the Use At Your Own Risk (UAYOR) License.
# I, Kismet Agbasi, wrote this script.  As long as you retain this notice you can do whatever you want with it. This
# script is just my basic attempt to help automate the process of switching FreeSWITCH from source to packages on an
# existing and fully operational FusionBPX server.  I am by no means an expert and this script is not intended to be
# super advanced in anyway.
#
# If you appreciate the rudimentary work and feel you can contribute to making it better in anyway, please consider
# contributing some code via my Github repo.
#
# Author:
#   Kismet Agbasi <kagbasi@digitainc.com>
#
# Contributor(s):
#   <could you some - email me if you're interested>
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# SOME THINGS TO NOTE BEFORE WE PROCEED:
#
# This script will automatically check your system to ensure it is supported and that a source installation
# of FreeSWITCH actually exists.  The traditional path ($fs_path) is used for this check.
# Additionally, there are some files we will need from the FusionPBX installation folders, so if you don't have
# them this script will fetch them for you and place them in ($fpbx_path).
#
# NOTE:  If the FreeSWITCH path is not detected this script will not continue!!!
#
# VERY IMPORTANT:  IF YOU HAVE NOT BACKED UP YOUR SYSTEM, DO SO NOW!!!
#
# I take no responsibility for a failed system as a result of using this script.  If anything should go wrong
# a proper backup should be easy to restore.  If you proceed without taking a backup, YOU ARE FULLY RESPONSIBLE!!!
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
DELIM
)

FINISH=$( cat << DELIM 
# Congratulations, you have just completed an in-place migration of FreeSWITCH
# from a source compilation to a package install.  Some final things to note:
#
# 1.  Log back into FusionPBX and check to make sure ALL modules have started and are running:
#
#     ADVANCED >> Modules
#
# 2.  This is optional, but I chose to reboot the server at this point.  
#     When the server comes back up, login into FusionPBX and check the Sip Status page to make 
#     sure your profiles have restarted.  That’s it, enjoy!
#
# 3.  And to wrap-up, you might consider bringing your system up-to-date via ADVANCED > UPGRADE.  
#     I did run into some issues with the new changes that had been made with MOH, however, all 
#
#     If this is the case for you, follow the instructions provided by a member of the #fusionpbx 
#     IRC channel:  http://pastebin.com/fHw0wDjb 
#
#     If you get this error when placing calls to *9664 to test MOH, then simply restart FreeSWITCH:
#     < [ERR] mod_local_stream.c:814 Unknown source default >
DELIM
)

# BEGIN SCRIPT EXECUTION
getdb
main
echo "Done!"
echo
exit