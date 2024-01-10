## Scripts for Archiving HF Radar Data with Axiom Data Science  ##

v1.0

Tools for pushing oceanographic HF radar data from remote sites to the
Axiom Data Science Archive, along with code that Axiom uses to manage the 
archive. 

OVERVIEW

The script ```rsync_to_axiom.bash``` is designed to work on SeaSonde sites
without modifications. In order to do this it uses the site code which it 
retrieves from the Header.txt file, and inserts that into the rsync destination
directory (on Axiom's server). 


HOW TO USE THIS CODE TO PUSH RNG FILES TO AXIOM

Here's a quick 'how to' to use this code on a SeaSonde site.

0) Create an ssh key and give the public key to Axiom. (In the instructions
   below, the key name is 'id_axiom'. Use the name of your key on your site).
   
1) create an entry in ssh config file ```~/.ssh/config```
```
Host axiom
Hostname data.axds.co
IdentityFile /Users/codar/.ssh/id_axiom
StrictHostKeyChecking accept-new
User hfr_xxxx
```

2) download the bash file
   Download the ```rsync_to_axiom.bash``` file, eg from:
   https://github.com/rowg/axiom_rangeseries_archive/blob/master/rsync_to_axiom.bash

   Put this in the site folder ```/Codar/SeaSonde/Apps/Scripts/```

3) Add the script to the site crontab
   Here's an example entry:

```
# Push to Axiom Data Sciences Archive
# (this is every hour at 4 minutes after the hour)
4 * * * * /Codar/SeaSonde/Apps/Scripts/rsync_to_axiom.bash

# try to delete lock file once per day just in case
30 23 * * * rm /tmp/axiom-sync.lock
```

NOTES

1) The folder ```archive_management_scripts``` contains code used by Axiom 
on their servers for managing the RNG archive. If you are a HF radar
operator you can safely ignore this folder and the code in it!

2) CODAR officially suggests not using crontab, and instead using ```launchd```

ACKNOWLEDGMENT

VERSION NOTES

