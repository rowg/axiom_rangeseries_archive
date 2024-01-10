#!/bin/bash
# AXIOM PERMISSION SETUP SCRIPT
#
# Fix permissions on the Axiom server 
#
#
# temp directory must exist and be empty in the pwd
#
# USEAGE:
# for example with a generic remote site name 'SITE':
# ./axiom_setup.bash SITE
#
# Brian Emery
# March 2023
#


# MAIN FUNCTION 
#-----------------------------------------------------------------------
function do_work {
# DO WORK - run stuff on remote shells
# 
# probably should include a readme file also

rsync -tuvzPr --chmod=ugo=rwx temp/ axiom:"$1"/RadialConfigs/
rsync -tuvzPr --chmod=ugo=rwx temp/ axiom:"$1"/RangeSeries/

# check that it worked
rsync --list-only axiom:"$1"/

}
#-----------------------------------------------------------------------


# DEFINE SITES

# setup script to take command line input (comment out if using loop below)
sites=$1


# CODE BELOW FOR RUNNING LOOP OVER A BUNCH OF SITES
# For example:
#
#sites=(
# "COP1"
# "SCI1"
# "SNI1")

# RUN LOOP

for i in "${sites[@]}"
do
    echo %---------------------------------%
	echo $i	
	do_work $i
done	
	
	
