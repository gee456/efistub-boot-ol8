#!/bin/bash
#  name: eufi-kernel-update
#  creator: https://github.com/gee456/efistub-boot-ol8
#  purpose:  This script is meant for Hyper-v 2016 with OL 8 nand 9
#            2016 Hyper-v Gen 2 systems have an incompatibility with Grub2 boot loader
#            To fix this we setup direct EUFI boot to the Linux Kernel
#            This script will run durring shutdown and check if the kernel has changed
#            It will then 
#                find the latest kernel
#                copy kernel files to EFI boot volume
#                Update EUFI to boot from this kernel
#            all actions are logged to /var/log/eufi-kernel-update.log
#
#  place script in /usr/local/scripts
#
# installing
#   mkdir -p /usr/local/scripts
#   create /usr/local/scripts/eufi-kernel-update.sh
#   chmod +x /usr/local/scripts/eufi-kernel-update.sh
#   create /etc/systemd/system/eufi-kernel-update.service
#   systemctl daemon-reload
#   systemctl enable eufi-kernel-update.service
#   systemctl start eufi-kernel-update.service
#
# Notes 
#  I was trying to log to syslog as well but the logger comamnd will not write to syslog once the shutdown has started
#   so we log to /var/log/scripts/eufi-kernel-update.log
#
#  Kernel info comand
#   LASTENTRY=$(ls -d /sys/firmware/efi/vars/Boot0* | tail -n 1)
#
#  Where I got the suggestion to EFI-Stub boot
#   https://bugs.launchpad.net/ubuntu/+source/grub2/+bug/1918265
#
# Here is a gret youtube v ideo that explains hos to do it
#   https://www.youtube.com/watch?v=vFP9jv6hiqs
#
# other sites that helped
#   https://wiki.archlinux.org/title/EFISTUB
#   https://www.spinics.net/linux/fedora/fedora-users/msg508335.html
#   https://docs.kernel.org/admin-guide/efi-stub.html
#   https://unix.stackexchange.com/questions/719050/unable-to-boot-linux-kernel-directly-through-efistub 
#   https://wiki.gentoo.org/wiki/Efibootmgr
#   https://linux.die.net/man/8/efibootmgr
#   https://www.linuxbabe.com/command-line/how-to-use-linux-efibootmgr-examples
#   https://www.cyberciti.biz/faq/howto-display-all-installed-linux-kernel-version/
#

# log the start of the script in /var/log/scripts/eufi-kernel-update.log
LOGFILE=/var/log/scripts/eufi-kernel-update.log
if ! [ -d /var/log/scripts ]; then mkdir /var/log/scripts; fi
logit()
{
  now=$(date +%Y%m%d.%H%M%S)
  if [[ -z $1 ]] ; then
    echo "$now Log function called without arguments"
    echo "$now Log function called without arguments" >> $LOGFILE
  fi
  echo "$now $@"
  echo "$now $@" >> $LOGFILE
  # also log to /var/log/messages
  logger "$now $@"
}

logit "eufi-kernel-update: script starting"

if ! [ -d /boot/efi/EFI/custom ]; then 
    logit "eufi-kernel-update: creating folder /boot/efi/EFI/custom"
    mkdir /boot/efi/EFI/custom
fi

kernel=$(rpm -qa kernel |sort | tail -n 1)
kver=${kernel#*-}
logit "eufi-kernel-update: checking for kernel change, current kernel $kver"
if (  efibootmgr | grep 'Oracle Linux EUFI Direct Boot' ); then 
    EFIBOOT=$(efibootmgr -v | grep 'Oracle Linux EUFI Direct Boot')
    if ! ( echo $EFIBOOT | grep $kver ) ; then 
        logit "eufi-kernel-update: cleaning old EUFI entry , kernel changed"
        efibootmgr -b ${EFIBOOT:4:4} -B
        rm -f /boot/efi/EFI/custom/*
        ls /boot/efi/EFI/custom/
    fi
fi

if ! (  efibootmgr | grep 'Oracle Linux EUFI Direct Boot' ); then 
    logit "eufi-kernel-update: creating new EUFI Entry for $kver"
    cp /boot/initramfs-$kver.img /boot/efi/EFI/custom/
    cp /boot/vmlinuz-$kver /boot/efi/EFI/custom/vmlinuz-$kver.efi
    efibootmgr -c -d /dev/sda -p 1 -L "Oracle Linux EUFI Direct Boot" -l "\EFI\custom\vmlinuz-$kver.efi" -u "root=/dev/mapper/ol-root ro crashkernel=auto resume=/dev/mapper/ol-swap rd.lvm.lv=ol/root rd.lvm.lv=ol/swap initrd=\EFI\custom\initramfs-$kver.img"
fi
logit "eufi-kernel-update: done"

