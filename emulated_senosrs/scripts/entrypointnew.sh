#!/bin/sh

GIB_IN_BYTES="1073741824"

# check if the emulated-entrypoint.sh file exists
if [ ! -e emulated-entrypoint.sh ]; then
  echo "No emulated-entrypoint.sh detected!"
  exit 1
fi
chmod +x emulated-entrypoint.sh

# ask the user for the target ip address
echo "Enter the IP address of the MQTT broker: "
read IP

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
  nic="--net nic --net user,hostfwd=tcp::5022-:22"
elif [ "${target}" = "pi2" ]; then
  emulator=qemu-system-arm
  machine=raspi2b
  memory=1024m
  kernel_pattern=kernel7.img
  dtb_pattern=bcm2709-rpi-2-b.dtb
  append="dwc_otg.fiq_fsm_enable=0"
  nic="-netdev user,id=net0,hostfwd=tcp::5022-:22 -device usb-net,netdev=net0"
elif [ "${target}" = "pi3" ]; then
  emulator=qemu-system-aarch64
  machine=raspi3b
  memory=1024m
  kernel_pattern=kernel8.img
  dtb_pattern=bcm2710-rpi-3-b-plus.dtb
  append="dwc_otg.fiq_fsm_enable=0"
  nic="-netdev user,id=net0,hostfwd=tcp::5022-:22 -device usb-net,netdev=net0"
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

echo "testing where qemu is"
echo "Booting QEMU machine \"${machine}\" with kernel=${kernel} dtb=${dtb}"

# run the emulator and use the emulated-entrypoint.sh file to run the emulated sensors with the IP address of the MQTT broker
# as an argument 

$emulator -machine ${machine} -m ${memory} -kernel ${kernel} -dtb ${dtb} -append "${append}" -hda ${image_path} -hdb ${image_path} ${nic} -no-reboot -no-shutdown -serial mon:stdio -display none -net nic -net user,hostfwd=tcp::5022-:22 &
sleep 10
sshpass -p 'raspberry' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pi@localhost -p 5022 "./emulated-entrypoint.sh ${IP}"
 

