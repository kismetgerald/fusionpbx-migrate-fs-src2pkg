#!/bin/bash

#Define global variables
fs_path="/usr/local/freeswitch"
fpbx_path="/var/www/fusionpbx"

LICENSE=$( cat << DELIM
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
+                                                                                                                       +
+ "THE UAYOR LICENSE" (Version 1)                                                                                       +
+                                                                                                                       +
+ This is the Use At Your Own Risk (UAYOR) License.                                                                     +
+ I, Kismet Agbasi, wrote this script.  As long as you retain this notice you can do whatever you want with it. This    +
+ script is just my basic attempt to help automate the process of switching FreeSWITCH from source to packages on an    +
+ existing and fully operational FusionBPX server.  I am by no means an expert and this script is not intended to be    +
+ super advanced in anyway.                                                                                             +
+                                                                                                                       +
+ If you appreciate the rudimentary work and feel you can contribute to making it better in anyway, please consider     +
+ contributing some code via my Github repo.                                                                            +
+                                                                                                                       +
+ Author:                                                                                                               +
+   Kismet Agbasi <kagbasi@digitainc.com>                                                                               +
+                                                                                                                       +
+ Contributor(s):                                                                                                       +
+   <could you some - email me if you're interested>                                                                    +
+                                                                                                                       +
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
+                                                                                                                       +
+ SOME THINGS TO NOTE BEFORE WE PROCEED:                                                                                +
+                                                                                                                       +
+ This script will automatically check your system to ensure it is supported and that a source installation             +
+ of FreeSWITCH actually exists.  The traditional path ($fs_path) is used for this check.  Additionally, there          +
+ are some files we will need from the FusionPBX installation folders, so if you don't have them this script will       +
+ fetch them for you and place them in ($fpbx_path).                                                                    +
+                                                                                                                       +
+ NOTE:  If the FreeSWITCH path is not detected this script will not continue!!!                                        +
+                                                                                                                       +
+ VERY IMPORTANT:  IF YOU HAVE NOT BACKED UP YOUR SYSTEM, DO SO NOW!!!                                                  +
+                                                                                                                       +
+ I take no responsibility for a failed system as a result of using this script.  If anything should go wrong           +
+ a proper backup should be easy to restore.  If you proceed without taking a backup, YOU ARE FULLY RESPONSIBLE!!!      +
+                                                                                                                       +
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
DELIM
)

echo "$LICENSE"

read -p "Shall we proceed? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Operating System detected is =====>>>> $os/$dist"
  echo "Existing FreeSWITCH detected at =====>>>> $fs_path"
  echo "FusionPBX detected at =====>>>> $fpbx_path"
  
fi
exit 1

# Functions
unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo
  echo "You can override the OS detection by setting os= and dist= prior to running this script."
  echo "You can find a list of supported OSes and distributions on our website: https://packagecloud.io/docs#os_distro_version"
  echo
  echo "For example, to force Ubuntu Trusty: os=ubuntu dist=trusty ./script.sh"
  echo
  echo "Please email support@packagecloud.io and let us know if you run into any issues."
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
}

main ()
{
  detect_os
  switch_check

  # Need to first run apt-get update so that apt-transport-https can be
  # installed
  echo -n "Operating System detected is =====>>>> $os/$dist"
  echo -n "Existing FreeSWITCH detected at =====>>>> $fs_path"
  
}