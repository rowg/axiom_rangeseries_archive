## Scripts for Archiving HF Radar Data with Axiom Data Science  ##

v1.0

Tools for pushing oceanographic HF radar data from remote sites to the
Axiom Data Science Archive. 

HOW TO USE IT

create an entry in ssh config:
```
Host axiom
Hostname data.axds.co
IdentityFile /Users/codar/.ssh/id_axiom
StrictHostKeyChecking accept-new
User hfr_xxxx
```

download it and cd to the unzipped directory

...

add to the site crontab

```
# Push to Axiom Data Sciences Archive
# (this is every hour at 4 minutes after the hour)
4 * * * * /Codar/SeaSonde/Apps/Scripts/rsync_to_axiom.bash

# try to delete lock file once per day just incase
30 23 * * * rm /tmp/axiom-sync.lock
```

TO DO


ACKNOWLEDGMENT


VERSION NOTES

