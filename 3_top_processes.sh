#!/bin/bash
# Script 3: Top 5 memory-consuming processes of a user
# Name: Alaa Raslan   ID: 443215503   Section: 5551
# Course: IT361 System Administration and Maintenance
#
# What this script does: it asks for a username and shows the 5
# processes of this user that use the most memory.
#
# How to run it:   ./3_top_processes.sh ubuntu
#   (or run it without a name and it will ask me to type one)
#
# References: Lecture 6 (ps and top), Lecture 5 (read, if, pipes),
#             Lecture 7 (sort, head), How Linux Works 3rd Edition (Ward, 2021)

# get the username (from the command line or by asking)
if [ "$1" = "" ]; then
    echo "Enter the username:"
    read USER_NAME
else
    USER_NAME=$1
fi

# check that the user is real
if grep "^$USER_NAME:" /etc/passwd > /dev/null
then
    echo "User $USER_NAME found."
else
    echo "Error: user $USER_NAME does not exist"
    exit 1
fi

# ps shows the processes of this user. -o chooses the columns I want:
# the process id, the memory percent, the memory size, and the command name
# then sort puts the biggest memory first (-n = numbers, -r = biggest first,
# -k 2 = use the 2nd column which is %MEM) and head keeps only 5 lines
PROCESSES=`ps -u "$USER_NAME" --no-headers -o pid,%mem,rss,comm | sort -n -r -k 2 | head -n 5`

if [ "$PROCESSES" = "" ]; then
    echo "User $USER_NAME has no running processes."
else
    echo ""
    echo "Top 5 memory-consuming processes for $USER_NAME"
    echo "  PID %MEM   RSS COMMAND     (RSS is the memory size in KB)"
    echo "$PROCESSES"
fi
