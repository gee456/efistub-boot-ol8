# efistub-boot-ol8
Scripts for changing EL8 r 9 to stub boot

This script will update the EUFI listing with the current kernel if the kernel changes

The way systemd executes shutdown leaves syslog unavialble 
so the logger command doesn't work must log to 
log file /var/log/scripts/ax-eufi-kernel-update.log