# HF Radar Archive Management

Bash script (run at the archive/Axiom) to organizing incoming HF radar files from site operators.
Leverages rsync and inotifywait.

## SITE OPERATORS DO NOT NEED TO RUN OR INSTALL THIS SCRIPT ##

In non-watching mode, all detected range series files are processed
(copied to the target archive date directory if they don't already exist),
and then Configs/RadialConfigs files are snapshotted if there are differences
from the previous snapshot (using rsync's `--link-dir` argument, which uses
hard links to present states of the directory through time without duplicating
disk space usage).

The source directory to process is provided as the only argument. Note
that the source directory is expected to contain a subdirectory
per site (e.g. `./COP1/RangeSeries` etc).

Flags:

* `-a`: target archive directory root for all archived data
  (i.e. not including operator or site subdirectories)
* `-n`: Dry run, output messages but do not actually process data
* `-o`: Operator name (e.g. `UCSB`)
* `-r`: In process mode, wait x seconds between scans
* `-w`: Watch source directory for new range series files and process them

Non-watch mode, process all ranges series and configs found:

```bash
./hf-radar-archive-manager.sh -o UCSB -a /path/to/archive
  /path/to/incoming/data
```

Usually you want to run this every x seconds to pick up config changes (supply `-r` flag)

```bash
./hf-radar-archiver.sh -o UCSB -a /media/data/hfradar/archive
  -r 900 /media/data/rssh/hfr_ucsb
```

Watch mode, monitor source directory for new or updated range series files (`*.rs`).
Note that config files are not processed in watch mode.

```bash
./hf-radar-archive-manager.sh -o UCSB -a /path/to/archive
  -w /path/to/incoming/data
```

## Requirements

* inotify-tools
* rsync
