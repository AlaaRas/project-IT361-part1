# IT361 - System Administration and Maintenance
## Course Project - Part 1 

**Student name:** Alaa Raslan | الاء رسلان

**Student ID:** 443215503

**Section No.:** 5551

**Tested on:** Ubuntu 

---

## About this project

In this part I wrote four shell scripts (bash) that solve small but real
system administration tasks: a backup, a log reader, a process monitor and
a firewall port checker. I tried to use the commands and ideas we studied in
the lectures (shell scripting, process management, system management, user
management and network security), and I wrote comments inside every script
to explain what each part does.

### Files in this folder

| File | What it does |
|------|--------------|
| `1_backup.sh` | Encrypted backup of the main partition, saved in a secure folder |
| `2_user_log.sh` | Saves the login/authentication logs of a user in `ActivitiesLog.txt` |
| `3_top_processes.sh` | Shows the top 5 memory-consuming processes of a user |
| `4_port_checker.sh` | Says if a port is open or closed according to the firewall |
| `README.md` | This file |

### How to get the scripts ready

Every script needs permission to run. In the folder I write:
```
chmod +x *.sh
```

---

## 1. Automated Encrypted Backup (`1_backup.sh`)

**What it does:** It takes a backup of the main partition (`/`), encrypts it
and keeps only the encrypted file in a secure folder. It can also run by
itself every week using cron.

**How it works, step by step:**
1. First the script checks that I am running it as root (with sudo), because
tar needs permission to read all the system files.

2. It checks what I want to back up. If I do not write anything it uses /
(the main partition). I can also write a small folder like /etc to test fast.

3. It makes a secure folder /root/secure_backup and uses chmod 700 on it,
so only root can open it.

4. It reads the password directly from a variable (PASSWORD="MyPassword") defined inside the script.

5. It makes a compressed backup with tar -zcf. It skips folders that are not
real files (/proc, /sys, /dev, /run) and also /tmp, /mnt, /media
and the backup folder itself.

6. It encrypts the tar file with openssl (AES-256) using the password variable.
The name of the backup has the date and time, for example
backup_2026-10-31_02-00-00.tar.gz.enc, so old backups are not replaced.

7. If the encryption worked, it deletes the normal tar file, so there is no
readable copy of the backup on the disk. The encrypted file gets chmod 600.
If something fails, it shows an error and removes the broken files.


**Run it:**
```
sudo ./1_backup.sh          # backs up the main partition /
sudo ./1_backup.sh /etc     # test with a small folder
```

**Weekly schedule with cron :** I open the root crontab with
`sudo crontab -e` and add this line. It means minute 0, hour 2, every day of
the month, every month, day 0 (Sunday), so it runs every Sunday at 2:00 AM:
```
0 2 * * 0 /home/ubuntu/443215503_Part1/1_backup.sh
```
I check that the job is saved with `sudo crontab -l`.

**How to restore a backup:**
```
sudo openssl enc -d -aes-256-cbc -pbkdf2 -in FILE.enc -out backup.tar.gz -pass file:/root/.backup_pass
tar -zxvf backup.tar.gz
```

---

## 2. User Activity Log Extraction (`2_user_log.sh`)

**What it does:** It takes a username and collects all the login and
authentication lines of this user from the system logs. The result is saved
in a file called `ActivitiesLog.txt` in the home directory.

**How it works, step by step:**
1. The username can be written after the script name, for example
   `./2_user_log.sh ubuntu`. If I do not write it, the script asks me for it
   using `read`.
2. It checks that the user is real by searching for the name in `/etc/passwd`
   with `grep`. If the user is not there it shows an error and stops.
3. It gets the home directory of the user from `/etc/passwd` (it is the 6th
   field, so I use `cut`) and creates `ActivitiesLog.txt` there.
4. It writes a title and the date in the file. `>` makes a new file and `>>`
   adds more lines at the end.
5. It adds the lines of the user from `who`, to show if the user is logged in now.
6. Then it searches the authentication log with `grep`. On Ubuntu this file is
   `/var/log/auth.log`. On Red Hat systems it is `/var/log/secure` (this one is
   mentioned in Lecture 10). If neither file exists (newer Ubuntu versions may
   not have them) the script reads the system journal with `journalctl`.
7. I did not search only for the username, because sometimes the computer name
   is the same as the username (like `ubuntu@ubuntu`) and then every line in
   the log would match. So I search for patterns like `for ubuntu`,
   `user ubuntu`, `by ubuntu` and `ubuntu :`, which are the lines about login,
   `sudo` and failed passwords.

**Run it:**
```
./2_user_log.sh ubuntu
cat /home/ubuntu/ActivitiesLog.txt
```
If the log file is not readable I run it with `sudo`.

---

## 3. Top Resource-Consuming Processes (`3_top_processes.sh`)

**What it does:** It takes a username and shows the top 5 processes that use
the most memory for this user.

**How it works, step by step:**
1. The username comes from the command line or from `read`, same as script 2.
2. It checks that the user exists in `/etc/passwd`.
3. It uses `ps -u username` to list only the processes of this user, and
   `-o pid,%mem,rss,comm` to show the process ID, memory percent, memory size
   in KB and the command name.
4. The result goes through a pipe `|` to `sort`, which puts the biggest memory
   percent first, and then to `head -n 5`, which keeps only the first 5 lines.
5. If the user has no running processes, the script says that instead of
   showing an empty result.

**Run it:**
```
./3_top_processes.sh ubuntu
./3_top_processes.sh root
```

---

## 4. Port Status Checker (`4_port_checker.sh`)

**What it does:** It takes a port number and tells if the port is OPEN or
CLOSED in the firewall.

**How it works, step by step:**
1. The port number is given as an argument, for example `sudo ./4_port_checker.sh 22`.
   If I forget it, the script shows how to use it.
2. It checks that the port is only digits (using `case`) and that it is
   between 1 and 65535. Wrong input like `abc` or `99999` shows an error.
3. It checks that I am root (the firewall rules need root) and that
   `iptables` works on the computer. If not, it tells me to install it
   with `sudo apt install iptables`.
4. It lists the firewall rules with `iptables -L -n` and searches for the port
   with `grep`. In this list the port is written as `dpt:22`. I used `\b` in
   the search so port 22 does not match port 2222.
5. If there is a rule for the port: an `ACCEPT` rule means OPEN, and a
   `DROP` or `REJECT` rule means CLOSED.
6. If there is no rule for the port, the default policy of the INPUT chain
   decides: `policy ACCEPT` means OPEN, otherwise CLOSED. I read it from the
   first line of `iptables -L INPUT -n`.

**To test it I made some rules :**
```
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 23 -j DROP
sudo ./4_port_checker.sh 22      # OPEN
sudo ./4_port_checker.sh 23      # CLOSED
sudo ./4_port_checker.sh 80      # depends on the default policy
```

---

## References

1. IT361 lectures, Qassim University, College of Computer: Lecture 5 (Shell Scripting), Lecture 6 (Process and Process Management), Lecture 7 (File Management), Lecture 8 (System Management), Lecture 9 (User Management and Maintenance), Lecture 10 (Network and Security).
2. Shotts, W. (2019). *The Linux Command Line*. No Starch Press.
3. Ward, B. (2021). *How Linux Works* (3rd ed.). No Starch Press.
4. The Linux Documentation Project. http://www.tldp.org/guides.html
5. Linux manual pages (`man`): tar, openssl-enc, crontab, ps, sort, grep, iptables.
6. Anthropic. (2026). *Claude* [Large language model]. https://claude.ai - used for help with orgnizing the README and checking the scripts.
