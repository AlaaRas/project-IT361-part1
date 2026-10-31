#!/bin/bash
# Script 2: User activity log extraction
# Name: Alaa Raslan   ID: 443215503   Section: 5551
# Course: IT361 System Administration and Maintenance
#
# What this script does: it asks for a username, then takes all the
# login / authentication lines of this user from the system logs and
# saves them in a file called ActivitiesLog.txt in the home directory.
#
# How to run it:   ./2_user_log.sh ubuntu
#   (or run it without a name and it will ask me to type one)
#
# References: Lecture 5 (read, if, redirection), Lecture 7 (grep, cut),
#             Lecture 9 (/etc/passwd), Lecture 10 (syslog and /var/log),
#             The Linux Command Line (Shotts, 2019)

# get the username. If I wrote it after the script name use it,
# if not, ask for it with read
if [ "$1" = "" ]; then
    echo "Enter the username:"
    read USER_NAME
else
    USER_NAME=$1
fi

# check that the user is real. Every user has a line in /etc/passwd
if grep "^$USER_NAME:" /etc/passwd > /dev/null
then
    echo "User $USER_NAME found."
else
    echo "Error: user $USER_NAME does not exist"
    exit 1
fi

# find the home directory of the user (it is the 6th field in /etc/passwd)
HOME_DIR=`grep "^$USER_NAME:" /etc/passwd | cut -d ':' -f 6`
if [ ! -d "$HOME_DIR" ]; then
    HOME_DIR=$HOME      # if the user has no home folder, use my home
fi
OUTPUT="$HOME_DIR/ActivitiesLog.txt"

# these are the words that show a line is about this user (login, sudo, ...)
# I did not search only for the name because the computer name can be the
# same as the username and then every line would match
PATTERN="for $USER_NAME\|user $USER_NAME\|by $USER_NAME\|$USER_NAME :"

# > makes a new file, >> adds to the end of the file
echo "Login and authentication logs for user: $USER_NAME" > "$OUTPUT"
echo "Date: `date`" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# part 1: is the user logged in now?
echo "---- Users logged in now (who) ----" >> "$OUTPUT"
who | grep "^$USER_NAME " >> "$OUTPUT"

# part 2: the lines from the authentication log
echo "" >> "$OUTPUT"
echo "---- Authentication log lines ----" >> "$OUTPUT"
if [ -f /var/log/auth.log ]; then
    # Ubuntu / Debian
    grep "$PATTERN" /var/log/auth.log >> "$OUTPUT"
elif [ -f /var/log/secure ]; then
    # Red Hat / CentOS (this one is in Lecture 10)
    grep "$PATTERN" /var/log/secure >> "$OUTPUT"
else
    # new Ubuntu versions may not have the log files, they keep the logs
    # in the journal, so I read it with journalctl
    journalctl 2> /dev/null | grep "$PATTERN" >> "$OUTPUT"
fi

echo "Done. The logs are saved in $OUTPUT"
