#!/bin/sh

GIB_IN_BYTES="1073741824"

# #check if sshpass is installed
# if ! [ -x "$(command -v sshpass)" ]; then
#   echo "sshpass is not installed"
#   exit 1
# fi

# # check if the emulated-entrypoint.sh file exists
# if [ ! -e emulated-entrypoint.sh ]; then
#   echo "No emulated-entrypoint.sh detected!"
#   exit 1
# fi
# chmod +x emulated-entrypoint.sh



# check if the filesystem image exists
target="${1:-pi1}"
image_path="/sdcard/filesystem.img"
zip_path="/filesystem.zip"

if [ ! -e $image_path ]; then
  echo "No filesystem detected at ${image_path}!"
  if [ -e $zip_path ]; then
      echo "Extracting fresh filesystem..."
      unzip $zip_path
      mv -- *.img $image_path
  else
    exit 1
  fi
fi

# splitip () {
#     local IFS
#     IFS=.
#     set -- $*
#     echo "$@"
# }
# Get the IP address of the host machine
# host_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1 | cut -d. -f1-3)
# echo $host_ip
# # Split the IP address into its octets
# # x=$(splitip $host_ip)
# # set -- $x
# # i1=$1
# # i2=$2
# # i3=$3
# # i4=$4

# # echo "Host IP: $x"
# # echo "i1: $i1"
# # echo "i2: $i2"
# # echo "i3: $i3"
# # echo "i4: $i4"
# # dhcp_start="$i1.$i2.$i3.$i4"
# # dns_ip="$i1.$i2.$i3.3"
# # Calculate the starting IP address for the guest machine
# guest_start_ip="$host_ip.15"

# # Calculate the IP address of the virtual nameserver
# dns_ip="$host_ip.3"
nameserver=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
search2=$(grep search /etc/resolv.conf | awk '{print $2}')
search3=$(grep search /etc/resolv.conf | awk '{print $3}')
search4=$(grep search /etc/resolv.conf | awk '{print $4}')


qemu-img info $image_path
image_size_in_bytes=$(qemu-img info --output json $image_path | grep "virtual-size" | awk '{print $2}' | sed 's/,//')
if [[ "$(($image_size_in_bytes % ($GIB_IN_BYTES * 2)))" != "0" ]]; then
  new_size_in_gib=$((($image_size_in_bytes / ($GIB_IN_BYTES * 2) + 1) * 2))
  echo "Rounding image size up to ${new_size_in_gib}GiB so it's a multiple of 2GiB..."
  qemu-img resize $image_path "${new_size_in_gib}G"
fi

if [ "${target}" = "pi1" ]; then
  emulator=qemu-system-arm
  kernel="/root/qemu-rpi-kernel/kernel-qemu-4.19.50-buster"
  dtb="/root/qemu-rpi-kernel/versatile-pb.dtb"
  machine=versatilepb
  memory=256m
  root=/dev/sda2
  nic="-net nic --net user,dnssearch=$search2,dnssearch=$search3,dnssearch=$search4,dns="$nameserver",hostfwd=tcp::5022-:22"
elif [ "${target}" = "pi2" ]; then
  emulator=qemu-system-arm
  machine=raspi2b
  memory=1024m
  kernel_pattern=kernel7.img
  dtb_pattern=bcm2709-rpi-2-b.dtb
  append="dwc_otg.fiq_fsm_enable=0"
  nic="-netdev user,id=net0,dnssearch=$search2,dnssearch=$search3,dnssearch=$search4,dns="$nameserver",hostfwd=tcp::5022-:22 -device usb-net,netdev=net0"
elif [ "${target}" = "pi3" ]; then
  emulator=qemu-system-aarch64
  machine=raspi3b
  memory=1024m
  kernel_pattern=kernel8.img
  dtb_pattern=bcm2710-rpi-3-b-plus.dtb
  append="dwc_otg.fiq_fsm_enable=0"
  nic="-netdev user,id=net0,dnssearch=$search2,dnssearch=$search3,dnssearch=$search4,dns="$nameserver",hostfwd=tcp::5022-:22 -device usb-net,netdev=net0"
else
  echo "Target ${target} not supported"
  echo "Supported targets: pi1 pi2 pi3"
  exit 2
fi

if [ "${kernel_pattern}" ] && [ "${dtb_pattern}" ]; then
  fat_path="/fat.img"
  echo "Extracting partitions"
  fdisk -l ${image_path} \
    | awk "/^[^ ]*1/{print \"dd if=${image_path} of=${fat_path} bs=512 skip=\"\$4\" count=\"\$6}" \
    | sh

  echo "Extracting boot filesystem"
  fat_folder="/fat"
  mkdir -p "${fat_folder}"
  fatcat -x "${fat_folder}" "${fat_path}"

  root=/dev/mmcblk0p2

  echo "Searching for kernel='${kernel_pattern}'"
  kernel=$(find "${fat_folder}" -name "${kernel_pattern}")

  echo "Searching for dtb='${dtb_pattern}'"
  dtb=$(find "${fat_folder}" -name "${dtb_pattern}")
fi

if [ "${kernel}" = "" ] || [ "${dtb}" = "" ]; then
  echo "Missing kernel='${kernel}' or dtb='${dtb}'"
  exit 2
fi

echo "Booting QEMU machine \"${machine}\" with kernel=${kernel} dtb=${dtb} and demonizing"


${emulator} \
  --machine "${machine}" \
  --cpu arm1176 \
  --m "${memory}" \
  --drive "format=raw,file=${image_path}" \
  ${nic} \
  --dtb "${dtb}" \
  --kernel "${kernel}" \
  --append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=${root} rootwait panic=1 ${append}" \
  --no-reboot \
  --display none \
  --serial mon:stdio 
  

  # -virtfs local,path=/sdcard,mount_tag=sdcard,security_model=none \
  #bind the /etc/hosts file to the emulated machine
  #bind the /etc/resolv.conf file to the emulated machine
  #bind the emulated-entrypoint.sh file to the emulated machine
  #make the emulated machine run the emulated-entrypoint.sh file
  # --serial none \
  # --serial mon:stdio

echo "Waiting for QEMU machine to boot..."

  # --bind /etc/hosts \
  # --bind /etc/resolv.conf \ # add a bind mount to the emulated-entrypoint.sh file
  # --bind emulated-entrypoint.sh # and make the machine run the emulated-entrypoint.sh file
  # --run emulated-entrypoint.sh &

# # busy wait till the docker container is up
# while ! nc -z localhost 5022; do
#   #print the nohup.out file to the console
#   echo "Waiting for QEMU machine to boot..."
# done

# # BUSY WAITING FOR THE QEMU MACHINE TO BOOT
# echo "Waiting for QEMU machine to boot..."
# while ! nc -z localhost 5022; do
#   sleep 0.1 # wait for 1/10 of the second before check again
# done

# # copy the /etc/hosts file and /etc/resolv.conf file to the qemu machine
# /usr/bin/local/sshpass -p "raspberry" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P 5022 /etc/hosts /etc/resolv.conf pi@localhost:/home/pi

# # run the emulated-entrypoint.sh file inside the qemu machine
# /usr/bin/local/sshpass -p "raspberry" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 5022 pi@localhost "bash -s" < emulated-entrypoint.sh $SERVER_IP_ADDRESS

