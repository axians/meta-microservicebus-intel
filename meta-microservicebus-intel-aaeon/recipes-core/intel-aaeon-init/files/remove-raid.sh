#!/bin/sh
# Helper script to remove raid
systemctl stop docker
systemctl stop microservicebus-node
systemctl stop intel-aaeon-init
umount /data
mdadm --stop /dev/md0
mdadm --zero-superblock /dev/sda3 /dev/sdb3
rm /etc/mdadm.conf