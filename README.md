## Scripts for Archiving HF Radar Data with Axiom Data Science  ##

Tools for pushing CODAR SeaSonde produced oceanographic HF radar data from remote sites to the
Axiom Data Science Archive, located at http://ioos-hfradar.axds.co/pages/inventory/.
Data is synced using `rsync`, which is widely available in Mac and Linux environments.

Reference code that Axiom uses internally to manage the archive is also
available in the `archive_management_scripts` directory. Note that data
providers do __not__ need to run or install the scripts in `archive_management_scripts`!

## Setup ##
#### or, How to set up a SeaConde site computer to push range series data to the archive ####

* Communicate with the range series archive manager at Axiom to determine your sync SSH username
* Download `bootstrap-range-series-archival.sh` from this repository (using a browser, or a
  command line tool like `curl -sL "https://github.com/rowg/axiom_rangeseries_archive/blob/master/bootstrap-range-series-archival.sh" > $HOME/Downloads/bootstrap-range-series-archival.sh`)
* Open a terminal and run the script (as a normal user with read access to the SeaSonde data files, not `root`!)
  using `bash` (example `bash $HOME/Downloads/bootstrap-range-series-archival.sh`)
* Enter your SSH username determined in the first step when prompted
* When the script completes, send the displayed public key to the Axiom range series archive manager (safe to send via email)
* Add the displayed cron job to your crontab (`crontab -e` to open in an editor)

That's it! Your site computer should now be set up to send range series and config data
from the standard CODAR directories to the range series archive at Axiom.

The script creates a directory at `$HOME/range-series-archival` to manage the generated sync script (`range-series-sync.sh`)
and sync logs (`sync.log`). To uninstall, simply delete this directory and remove any associated cron tasks from your crontab.

To manually push a directory to the archive (backfill, etc) you may execute the sync script directly with the
local path as the first argument and the remote path as the second argument.

```
$HOME/range-series-sync.sh /path/to/local/dir Backfill/
```

The `-n` flag can also be used to show the outcome of a sync without actually executing it (dry run).
Note that the `-n` flag must come __before__ the paths in this case or it will be ignored!

```
$HOME/range-series-sync.sh -n /path/to/local/dir Backfill/
```
