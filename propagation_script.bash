#!/bin/bash
# PROPAGATION SCRIPT
#
# Copy keys, etc to remote sites. Note that after the
# keys are installed, you'll have to manually answer
# yes to the authorized keys question
#
# Brian Emery 10 Jan 2024 from other scripts

#-----------------------------------------------------------------------
# Define the main function that copies the script to remote sites
function do_work {

# COPY NEW AXIOM SCRIPT
scp rsync_to_axiom.bash "$1":/Codar/SeaSonde/Apps/Scripts/

# set file permissions
ssh "$1" chmod 777 /Codar/SeaSonde/Apps/Scripts/rsync_to_axiom.bash

# copy config file
scp config "$1":~/.ssh/

# copy site private key
scp id_axiom "$1":~/.ssh/

# set file permissions
ssh "$1" chmod 600 /Users/codar/.ssh/id_axiom

# ADD RSYNC TO CRONTAB
# use with caution!
ssh "$1" 'crontab -l > ~/old_crontab'
ssh "$1" 'cp ~/old_crontab ~/new_crontab'
ssh "$1" 'echo "4 * * * * /Codar/SeaSonde/Apps/Scripts/rsync_to_axiom.bash" >> ~/new_crontab'
ssh "$1" 'echo "30 23 * * * rm /tmp/axiom-sync.lock" >> ~/new_crontab'
ssh "$1" 'crontab ~/new_crontab'


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



