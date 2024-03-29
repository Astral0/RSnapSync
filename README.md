# RSnapSync
RSnapSync is a simple, efficient, and flexible backup tool written in Bash. It leverages rsync and hard links to create incremental snapshots of directories, emulating the functionality of rsnapshot with a focus on simplicity and ease of use.

## Features
Incremental Backups: Saves only the changes since the last snapshot, reducing disk space usage.
Hard Links: Unchanged files between snapshots don't take up additional disk space.
Flexible Scheduling: Supports daily, weekly, and monthly backups.
Simplified Configuration: Easy to set up and configure, making backups hassle-free.

## Requirements
rsync
ssh (for remote backups)
cron (or another scheduler) for automated backups

## Installation
Clone the repository or download the script directly:

```
git clone https://github.com/Astral0/RSnapSync.git
cd RSnapSync
```

Make the script executable:
```
chmod +x rsnap_sync.sh
```

## Configuration
Create and modify a configuration file based on your backup requirements. Start by copying the data0.conf.template file:

```
cp data.conf.template data.conf
```

Edit data.conf to suit your needs:

```
# Number of backups to keep for each type
MAX_BACKUPS_DAILY=5
MAX_BACKUPS_WEEKLY=4
MAX_BACKUPS_MONTHLY=6

# Directory where backups will be stored
BACKUP_DIR="/path/to/backup_directory"

# Remote host (user@hostname) for pulling data, leave empty for local backups
REMOTE_HOST="user@remote_ip"

# Directories to backup
declare -a DIRECTORIES=(
    "/path/to/first_directory"
    "/path/to/second_directory"
    # Add more directories as needed
)
```

## Usage
Run the script with the desired interval (daily, weekly, monthly) and your configuration file:

```
./rsnap_sync.sh data.conf daily
./rsnap_sync.sh data.conf weekly
./rsnap_sync.sh data.conf monthly
```

## Automating Backups with Cron
Automate your backup process by scheduling the script with cron. Use crontab -e to edit the cron jobs and add entries like the following:

```
# Daily backup at 1:00 AM
0 1 * * * /path/to/rsnap_sync.sh /path/to/data.conf daily

# Weekly backup at 2:00 AM on Sundays
0 2 * * 0 /path/to/rsnap_sync.sh /path/to/data.conf weekly

# Monthly backup at 3:00 AM on the first day of each month
0 3 1 * * /path/to/rsnap_sync.sh /path/to/data.conf monthly
```

## License
RSnapSync is released under the GNU General Public License v3.0. See the LICENSE file in the repository for more details.
