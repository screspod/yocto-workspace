echo "Starting Company A/B boot"

setenv BOOT_ORDER "B A"

virtio scan

if test -z "${BOOT_ORDER}"; then
   setenv BOOT_ORDER "A B"
fi

for slot in ${BOOT_ORDER}; do
   if test "${slot}" = "A"; then
         setenv bootpart 1
         setenv rootpart 3
   fi

   if test "${slot}" = "B"; then
         setenv bootpart 2
         setenv rootpart 4
   fi

   load virtio 0:${bootpart} ${kernel_addr_r} Image

   if test $? -eq 0; then
      setenv bootargs root=/dev/vda${rootpart} rootwait rootfstype=ext4 console=ttyAMA0,115200 rauc.slot=${slot}
      booti ${kernel_addr_r} - ${fdt_addr}
   fi

   echo "Failed to load kernel from slot ${slot}"

done

echo "No bootable slot found"
reset