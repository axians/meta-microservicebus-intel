#!/bin/sh
#
# Init AAEON
# 
# Create home dir on data partition if missing and set owner
# Create RAUC data dir
# Setup Edge config 
# Set hostname
# Add iptables 
#
#***********************************************************************

# Get script name
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# Dynamic settings, replaced with values from Yocto variables
MSB_HOME_DIR_PATH="@MSB_HOME_DIR_PATH@"
MSB_NODE_USER="@MSB_NODE_USER@"
MSB_NODE_GROUP="@MSB_NODE_GROUP@"
RAUC_VAR_DIR="@RAUC_VAR_DIR@"
IOTEDGE="@IOTEDGE@"

RESULT=0

# Check if RAID is setup 
if [ ! -d /dev/md0 ]; then
  echo "Setting up RAID 1"
  # Create /data directory if it does ot exist
  if [ ! -d /data ]; then
    echo "Creating /data"
    mkdir /data
  fi

  # Check if sda3 or sdb3 has been RAID'ed
  SDA3_RAID=$(mdadm -E /dev/sda3 | grep "Raid Level" | awk '{print $4}')
  SDB3_RAID=$(mdadm -E /dev/sdb3 | grep "Raid Level" | awk '{print $4}')
  WORKINGDEVICES=$(mdadm -D /dev/md0 | grep 'Working Devices' | awk '{print $4}')
  WORKINGDEVICES=$(echo $(mdadm -D /dev/md0 | grep 'Working Devices' ) |awk '{print length}')
  DATA_IS_MOUNTED=$(echo $(df | grep /data ) |awk '{print length}')

  if [ "$WORKINGDEVICES" == 2 ] && [ "$DATA_IS_MOUNTED" -gt 0]; then
    echo "Partition has already been RAIDED. All good"
  elif [ "$SDA3_RAID" == "raid1" ] || [ "$SDB3_RAID" == "raid1" ]; then
    
    echo "Partition has already been RAIDED. Assebling RAID"
    
    FSTAB_RAID=$(echo $(cat /etc/fstab | grep /dev/md0 ) |awk '{print length}')
    if [ "$FSTAB_RAID" == 0 ]; then 
      echo "...Updating /etc/fstab"
      echo "/dev/md0 /data ext4 nofail 0 0" >> /etc/fstab 
    fi

    MDADM_RAID=$(echo $(cat /etc/mdadm.conf | grep "$(mdadm --detail --scan)" ) |awk '{print length}')
    if [ "$MDADM_RAID" == 0 ]; then
      echo "...Updating /etc/mdadm.conf "
      mdadm --detail --scan >> /etc/mdadm.conf 
      mount -a
    fi
    
  else
    echo "Partition has never been RAIDED. CREATING RAID"
    yes | mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda3 /dev/sdb3
    mdadm --wait /dev/md0
    yes | mkfs.ext4 /dev/md0
    mdadm --detail --scan >> /etc/mdadm.conf
    echo "/dev/md0 /data ext4 nofail 0 0" >> /etc/fstab
    mount -a
  fi

  echo "RAID 1 setup complete"
fi

# Check if home dir is created
if [ -d ${MSB_HOME_DIR_PATH} ]; then
   echo "HOME dir exists, setting permissions" 
   # Set permissions on home dir to msb user
   chown -R ${MSB_NODE_USER}:${MSB_NODE_GROUP} ${MSB_HOME_DIR_PATH}
   echo "HOME dir ready" 
   systemd-notify --ready
   # Copy .bashrc file to home 
  cp /etc/skel/.bashrc ${MSB_HOME_DIR_PATH}/ 2>&1 > /dev/null
else
   # Create home dir/path if missing and set permissions
   echo "HOME dir does not exists, creating..." 
   mkdir -p ${MSB_HOME_DIR_PATH}
   echo "...setting permissions"
   chown -R ${MSB_NODE_USER}:${MSB_NODE_GROUP} ${MSB_HOME_DIR_PATH}
   if [ $? -ne 0 ]; then
     echo "Error: Failed to create ${MSB_HOME_DIR_PATH}"
     systemd-notify --status="Error: Failed to create ${MSB_HOME_DIR_PATH}"
     RESULT=3
   else
     echo "HOME dir ready"
     systemd-notify --status="Home dir ready"
     systemd-notify --ready
    # Copy .bashrc file to home 
    cp /etc/skel/.bashrc ${MSB_HOME_DIR_PATH}/ 2>&1 > /dev/null 
  fi  
fi

# Check if rauc dir is created
if [ -d ${RAUC_VAR_DIR} ]; then
  echo "RAUC dir ready"
else
  echo "RAUC dir does not exists, creating..."
  # Create rauc dir if missing
  mkdir -p ${RAUC_VAR_DIR}
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create ${RAUC_VAR_DIR}"
  else
    echo "Created ${RAUC_VAR_DIR}"
  fi
fi

if [ "${IOTEDGE}" = "TRUE" ]; then
    echo "Copy IoT Edge config if IOTEDGE == TRUE and config file not exists " ${IOTEDGE}

    echo "Node is running IoT Edge" | systemd-cat -p info -t "${me}"
    if [ ! -d /data/home/iotedge ]; then
      echo "Copying config.yaml to /data" | systemd-cat -p info -t "${me}"

      mkdir /data/home/iotedge
      chown iotedge:iotedge /var/lib/iotedge
      chown iotedge:iotedge /var/log/iotedge
      chown iotedge:iotedge /data/home/iotedge
      
      cp /etc/iotedge/config.yaml /data/home/iotedge/config.yaml
      chown iotedge:iotedge /data/home/iotedge/config.yaml

      if [ $? -eq 0 ]; then
        echo "Successfully copied config.yaml. Setting permissions" | systemd-cat -p info -t "${me}"
	chmod g+rw /data/home/iotedge/config.yaml
        chown iotedge:iotedge /data/home/iotedge/config.yaml
      else
        echo "Error, failed to copy config.yaml tp /data/home/iotedge" | systemd-cat -p warning -t "${me}"
      fi
    fi

    if [ ! -d /data/lib/docker ]; then
      echo "Create docker directory" | systemd-cat -p info -t "${me}"

      mkdir -p /data/lib/docker
      
      if [ $? -eq 0 ]; then
        echo "Successfully created docker directory" | systemd-cat -p info -t "${me}"
      else
        echo "Error, failed creating docker directory" | systemd-cat -p warning -t "${me}"
      fi
    fi
fi

# Set hostname to serial number doesn't work on AAEON :(
#/usr/sbin/dmidecode -s chassis-serial-number > /etc/hostname

# Set iptables and alert rules
sudo iptables -N SSHATTACK
sudo iptables -A SSHATTACK -j LOG --log-prefix "Possible SSH attack! " --log-level 7;
sudo iptables -A SSHATTACK -j DROP;
sudo iptables -A INPUT -i eth0 -p tcp -m state --dport 22 --state NEW -m recent --set;
sudo iptables -A INPUT -i eth0 -p tcp -m state --dport 22 --state NEW -m recent --update --seconds 120 --hitcount 4 -j SSHATTACK;

exit $RESULT




