#!/bin/bash
# PROPAGATION SCRIPT
#
# Copy keys, etc to remote sites
#
# Brian Emery 10 Jan 2024 from other scripts

#-----------------------------------------------------------------------
# Define the main function that copies the script to remote sites
function do_work {

# COPY NEW AXIOM SCRIPT
scp rsync_to_axiom.bash "$1":/Codar/SeaSonde/Apps/Scripts/

# set file permissions
ssh "$1" chmod 777 /Codar/SeaSonde/Apps/Scripts/rsync_to_axiom.bash

}
#-----------------------------------------------------------------------

# DEFINE SITE IP ALIASES
# define a list of site IP addresses or DNS aliases to loop over

# For example
sites=("mgs1.dnsalias.com"
       "nic1.dnsalias.com"
       "sci1.dnsalias.com")


# RUN LOOP

for i in "${sites[@]}"
do
    echo %---------------------------------%
        echo $i
        do_work $i
done



