#!/bin/bash
# Script 1: Automated encrypted backup
# Name: Alaa Raslan   ID: 443215503   Section: 5551
# Course: IT361 System Administration and Maintenance
#
# What this script does:
#   1. makes a tar.gz backup of the main partition (/)
#   2. encrypts the backup with openssl before keeping it
#   3. saves the encrypted file in a secure folder that only root can open
#
# How to run it:    sudo ./1_backup.sh
# To test it fast:  sudo ./1_backup.sh /etc     (backs up only /etc)
#
# To run it every week I use cron (Lecture 8). I open the root crontab
# with "sudo crontab -e" and add this line (every Sunday at 2:00 AM):
#   0 2 * * 0 /home/ubuntu/443215503_Part1/1_backup.sh
#
# References: Lecture 8 (Backup & Restore and Cron), Lecture 5 (Shell scripting),
#             The Linux Command Line (Shotts, 2019)

# tar must read all the files in the system, so only root can run this
if [ "`whoami`" != "root" ]; then
    echo "Error: please run this script with sudo"
    exit 1
fi

# what to back up. If I do not write a folder, it uses / (the main partition)
if [ "$1" = "" ]; then
    SOURCE="/"
else
    SOURCE="$1"
fi

if [ ! -d "$SOURCE" ]; then
    echo "Error: $SOURCE is not a folder"
    exit 1
fi

# my settings
BACKUP_DIR="/root/secure_backup"     # the secure folder
PASS_FILE="/root/.backup_pass"       # the file that has the password
DATE=`date +%Y-%m-%d_%H-%M-%S`       # date and time in the file name, so old backups stay
TAR_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"
ENC_FILE="$TAR_FILE.enc"

# make the secure folder. chmod 700 means only the owner (root) can enter it
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# the password is saved in a file so it is not written inside the script.
# I create this file one time before running the script:
#   echo "MyPassword" | sudo tee /root/.backup_pass
#   sudo chmod 600 /root/.backup_pass
if [ ! -f "$PASS_FILE" ]; then
    echo "Error: the password file $PASS_FILE does not exist."
    echo "Create it first (see the comments in this script)."
    exit 1
fi

echo "Starting the backup of $SOURCE ..."

# step 1: make the tar file. I skip folders that are not real files
# (/proc, /sys, /dev, /run) and the folder where I save the backup
tar -zcf "$TAR_FILE" --exclude=/proc --exclude=/sys --exclude=/dev \
    --exclude=/run --exclude=/tmp --exclude=/mnt --exclude=/media \
    --exclude="$BACKUP_DIR" "$SOURCE" 2> /dev/null

# step 2: encrypt the tar file (AES-256), the password comes from the file
if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TAR_FILE" -out "$ENC_FILE" -pass file:"$PASS_FILE"
then
    # step 3: delete the normal tar file so only the encrypted one stays
    rm -f "$TAR_FILE"
    chmod 600 "$ENC_FILE"
    echo "Backup finished. Encrypted file: $ENC_FILE"
else
    echo "Error: the encryption failed"
    rm -f "$TAR_FILE" "$ENC_FILE"
    exit 1
fi

# To restore a backup later:
#   sudo openssl enc -d -aes-256-cbc -pbkdf2 -in FILE.enc -out backup.tar.gz -pass file:/root/.backup_pass
#   tar -zxvf backup.tar.gz
