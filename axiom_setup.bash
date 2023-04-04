#!/bin/bash
# AXIOM SETUP SCRIPT
#
# Copy keys, etc to remote sites
#i
#
# temp directory must exist and be empty in the pwd
#
# USEAGE:
# for example:
# ./key_installer.bash mgs1.dnsalias.com
#
# Copyright (C) 2012 Brian Emery
#
#  		20 July 2012
#
# Copy this from local to stokes where it should be run:
# rsync -avr /projects/hf_sites/ stokes:/home/codar/scripts/hf_sites/
#
# NOTE
# ssh-copy-id -i id_rsa_hfsites.pub codar@mgs1.dnsalias.com
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


# DEFINE SITE IP ALIASES

# set sites to loop over as command line input
sites=$1


# CODE BELOW FOR RUNNING LOOP OVER ALL SITES

# DONE THIS ITERATION
#sites=(
# "COP1"
# "PTM1"
# "SSD1"
# "RFG1"
# "MGS1"
# "NIC1"
# "SCI1"
# "SNI1")

# RUN LOOP

for i in "${sites[@]}"
do
    echo %---------------------------------%
	echo $i	
	do_work $i
done	
	
	
