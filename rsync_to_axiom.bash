#!/bin/bash
#-----------------------------------------------------------------------#
# RSYNC TO AXIOM - data push from remote sites to Axiom Data Science
#
# Designed to be run on remote site computers from an hourly cron job. This
# script moves Range Series and Configs from the realtime folders (eg
# /Codar/SeaSonde/Data/RangeSeries.
#
# Requires 'axiom' to be defined in .ssh/config
#
# Prior to install, create the remote directories with this:
# rsync -tuvzPr --chmod=ugo=rwx Movies/ axiom:NIC1/RangeSeries/
#
# Test this using this, which should list remote directories:
# rsync --list-only axiom:SITE/
#
#
# Rsync switch explanations:
# -t, --times                 preserve times
# -u, --update                update only (don't overwrite newer files)
# -v, --verbose
# -z, --compress              compress file data
# -P     The  -P  option is equivalent to --partial --progress.
# -E, --extended-attributes   Apple specific option  to  copy  extended
# attributes, resource forks,  and  ACLs.
# -T  --temp-dir=DIR          create temporary files in directory DIR
#
# Brian Emery 24 Oct 2022 from other scripts
#

# get the site name for the remote - force upper case
site_code=$(head -1 /Codar/SeaSonde/Configs/RadialConfigs/Header.txt | awk '{print $2}' | tr '[a-z]' '[A-Z]')


# DEFINE LOCAL LOG FILE
rsync_log=/Codar/SeaSonde/Logs/rsync_to_axiom.log


# Range Files
rsync -tuvzPr --chmod=ugo=rwx --delete /Codar/SeaSonde/Data/RangeSeries/ axiom:"$site_code"/RangeSeries/ >> "$rsync_log" 2>> "$rsync_log"
 
# Config Files
rsync -tuvzPr --chmod=ugo=rwx --delete /Codar/SeaSonde/Configs/RadialConfigs/ axiom:"$site_code"/RadialConfigs/ >> "$rsync_log" 2>> "$rsync_log"
                                                                                                                                                                           
