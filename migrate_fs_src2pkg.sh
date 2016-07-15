#!/bin/bash

#Define global variables
fs_path="/usr/local/freeswitch"
fpbx_path="/var/www/fusionpbx"

# Functions
main ()
{
  echo "$LICENSE"

  read -p "Shall we proceed? [Y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    detect_os
    switch_check
    #echo "Operating System detected is =====>>>> $os/$dist"
    #echo "Existing FreeSWITCH detected at =====>>>> $fs_path"
    echo "FusionPBX is assumed to be at =====>>>> $fpbx_path"
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

        if [ -z "$dist" ]; then
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

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist."
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
  if [ -d "$fs_path" ]
    then
      echo "Excellent!  The FreeSWITCH directory ($fs_path) was found so let's continue."
      echo ""
      detect_os
    else
      echo "Error: Directory $fs_path does not exists."
      echo ""
      echo "The traditional FreeSWITCH path ($fs_path) was not detected, as such, this script will stop execution."
      echo ""
      sleep 5
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

# BEGIN SCRIPT EXECUTION
main
exit 1