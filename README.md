# efistub-boot-ol8
Scripts for changing EL8 or 9 variants to stub boot

This script will update the EUFI listing with the current kernel if the kernel changes. Every time server is restarted this script will check to see if kernel was updated. If it was it changes the EUFI to boot off this new kernel.

The way systemd executes shutdown leaves syslog unavialble 
so the logger command doesn't work must log to 
log file /var/log/scripts/ax-eufi-kernel-update.log

# installing
```
   mkdir -p /usr/local/scripts  
   create /usr/local/scripts/eufi-kernel-update.sh  
   chmod +x /usr/local/scripts/eufi-kernel-update.sh  
   create /etc/systemd/system/eufi-kernel-update.service  
   systemctl daemon-reload  
   systemctl enable eufi-kernel-update.service  
   systemctl start eufi-kernel-update.service  
```
