# RSnapSync
RSnapSync is a simple, efficient, and flexible backup tool written in Bash. It leverages rsync and hard links to create incremental snapshots of directories, emulating the functionality of rsnapshot with a focus on simplicity and ease of use.

Features
Incremental Backups: Saves only the changes since the last snapshot, reducing disk space usage.
Hard Links: Unchanged files between snapshots don't take up additional disk space.
Flexible Scheduling: Supports daily, weekly, and monthly backups.
Simplified Configuration: Easy to set up and configure, making backups hassle-free.
Requirements
rsync
ssh (for remote backups)
cron (or another scheduler) for automated backups
Installation
Clone the repository or download the script directly:

sh
Copy code
git clone https://github.com/yourusername/RSnapSync.git
cd RSnapSync
Make the script executable:

sh
Copy code
chmod +x rsnap_sync.sh
Configuration
Create and modify a configuration file based on your backup requirements. Start by copying the data0.conf.template file:

sh
Copy code
cp data0.conf.template data0.conf
Edit data0.conf to suit your needs:

bash
Copy code
# Number of backups to keep for each type
MAX_BACKUPS_DAILY=5
MAX_BACKUPS_WEEKLY=4
MAX_BACKUPS_MONTHLY=6

# Directory where backups will be stored
BACKUP_DIR="/volume1/BACKUP/data0"

# Remote host (user@hostname) for pulling data, leave empty for local backups
REMOTE_HOST="service_backup@data0"

# Directories to backup
declare -a DIRECTORIES=(
    "/raid/PROJETS2"
    "/raid/DEVELOPMENT"
)
Usage
Run the script with the desired interval (daily, weekly, monthly) and your configuration file:

sh
Copy code
./rsnap_sync.sh data0.conf daily
./rsnap_sync.sh data0.conf weekly
./rsnap_sync.sh data0.conf monthly
Automating Backups with Cron
Automate your backup process by scheduling the script with cron. Use crontab -e to edit the cron jobs and add entries like the following:

cron
Copy code
# Daily backup at 1:00 AM
0 1 * * * /path/to/rsnap_sync.sh /path/to/data0.conf daily

# Weekly backup at 2:00 AM on Sundays
0 2 * * 0 /path/to/rsnap_sync.sh /path/to/data0.conf weekly

# Monthly backup at 3:00 AM on the first day of each month
0 3 1 * * /path/to/rsnap_sync.sh /path/to/data0.conf monthly
License
RSnapSync is released under the GNU General Public License v3.0. See the LICENSE file in the repository for more details.
