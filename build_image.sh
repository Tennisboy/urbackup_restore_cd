#!/bin/bash

set -e

./create_splash.sh
cd image_root

# Step 1: Clean up any previous live build data
lb clean

# Step 2: Create the package list to include openssh-server
mkdir -p config/package-lists
echo "openssh-server" > config/package-lists/my-packages.list.chroot

# Step 3: Create a hook to enable and start SSH at boot
mkdir -p config/hooks/live
cat <<'EOF' > config/hooks/live/0300-enable-ssh.hook.chroot
#!/bin/bash
# Enable the ssh service
systemctl enable ssh
# Set username and password
echo "ROOT_USERNAME:PASSWORD" | chpasswd
# Allow root login and password authentication (adjust sshd_config to permit root login)
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
EOF
chmod +x config/hooks/live/0300-enable-ssh.hook.chroot

# Step 4: Configure the build process with the required parameters
lb config --apt apt --apt-recommends false --tasksel none --apt-indices false \
          --distribution bookworm --memtest none \
          --mirror-binary http://ftp.uni-stuttgart.de/debian/ \
          --mirror-bootstrap http://ftp.uni-stuttgart.de/debian/ \
          --architectures amd64 \
          --mirror-chroot http://ftp.uni-stuttgart.de/debian/ \
          --linux-flavours "amd64" --debian-installer false \
          --firmware-binary true --system live --compression xz \
          --bootappend-live "boot=live components username=urbackup" \
          --iso-application "UrBackup Restore" \
          --iso-preparer="Martin Raiber <martin@urbackup.org>" \
          --iso-publisher="Martin Raiber <martin@urbackup.org>" \
          --zsync false --iso-volume "UrBackup Restore" \
          --archive-areas "main contrib non-free non-free-firmware" \
          --parent-archive-areas "main contrib non-free non-free-firmware" \
          --parent-distribution bookworm --initsystem systemd \
          --firmware-chroot true --security false

# Step 5: Build the image
lb build
