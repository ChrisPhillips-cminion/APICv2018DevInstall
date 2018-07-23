sudo losetup -D
sudo umount /tmp/tmpfs  --force
sudo rm -rf /tmp/tmpfs || true
# Create mountpoint for tmpfs
mkdir /tmp/tmpfs
# Mount tmpfs there
mount -t tmpfs none /tmp/tmpfs
# Create empty file of 600MB 
# (it creates 599MB hole, so it does not 
#  consume more memory than needed)
dd if=/dev/zero of=/tmp/tmpfs/img.bin bs=1M seek=1599 count=1
# Partition the image file
#cfdisk /tmp/tmpfs/img.bin 
# Create loop block device of it (-P makes kernel look for partitions)
losetup -P /dev/loop0 /tmp/tmpfs/img.bin 
# Now it's your turn:
#   mount loop0p1 and loop0p2 and copy whatever you want and unmount it
pwd
sudo sfdisk /dev/loop0 < $(pwd)/yaml/loop0.layout
sudo mkfs.ext4 /dev/loop0p1
