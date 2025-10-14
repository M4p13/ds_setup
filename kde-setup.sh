#!/bin/bash
# Install yay if not present
if ! command -v yay 2>&1 > /dev/null
then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ../
fi
yay
# Install packages - KDE Plasma with productivity tools
yay -S plasma sddm openssh tmux kitty wayvnc avahi nss-mdns tailscale \
  firefox libreoffice-fresh dolphin kwallet \
  thunderbird \
  spectacle \
  okular \
  ark \
  vlc \
  kate \
  kcalc \
  plasma-systemmonitor \
  kdeconnect \
  print-manager cups \
  packagekit-qt5 \
  bluedevil \
  chromium \
  keepassxc \
  remmina freerdp \
  ttf-liberation ttf-dejavu noto-fonts noto-fonts-emoji \
  pipewire pipewire-pulse pipewire-alsa wireplumber
# Enable services
sudo systemctl enable sddm.service
sudo systemctl enable sshd
sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service
sudo systemctl enable --now tailscaled.service
sudo systemctl enable cups.service
sudo systemctl enable bluetooth.service
# Configure SDDM autologin
sudo mkdir -p /etc/sddm.conf.d
u="$USER"
if [ ! -e /etc/sddm.conf.d/autologin.conf ]; then
  sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<  EOF
[Autologin]
User=$u
Session=plasma
EOF
fi
# Configure passwordless login
PAM_FILE="/etc/pam.d/sddm"
if [ ! -f "$PAM_FILE" ]; then
  echo "Error: PAM file $PAM_FILE not found."
  exit 1
fi
sudo cp "$PAM_FILE" "$PAM_FILE.bak"
if grep -q "pam_succeed_if.so user ingroup nopasswdlogin" "$PAM_FILE"; then
  echo "Passwordless login already enabled"
else
  sudo sed -i "1a auth sufficient pam_succeed_if.so user ingroup nopasswdlogin" "$PAM_FILE"
fi
sudo groupadd -r nopasswdlogin
sudo gpasswd -a $u nopasswdlogin
# Configure Avahi
AVAHI_CONF="/etc/avahi/avahi-daemon.conf"
if grep -q "publish-workstation" "$AVAHI_CONF"; then
  sudo sed -i 's/publish-workstation=.*/publish-workstation=yes/' "$AVAHI_CONF"
  echo "Updated publish-workstation to yes"
else
  if grep -q "\[publish\]" "$AVAHI_CONF"; then
    sudo sed -i '/\[publish\]/a publish-workstation=yes' "$AVAHI_CONF"
    echo "Added publish-workstation=yes to existing [publish] section"
  else
    sudo tee -a "$AVAHI_CONF" > /dev/null << EOF
[publish]
publish-workstation=yes
EOF
    echo "Created [publish] section with publish-workstation=yes"
  fi
fi
sudo systemctl restart avahi-daemon.service
if [ -f "./setup-keys.sh" ]; then
  echo ""
  echo "Configuring SSH..."
  bash ./setup-keys.sh
else
  echo ""
  echo "WARNING: setup-ssh.sh not found in current directory"
  echo "SSH key authentication not configured"
fi


echo "Installation complete!"
echo "Note: Tailscale installed but not configured. Run 'sudo tailscale up' to connect."
echo "KWallet will prompt for password setup on first use."
echo "For printing, add printers through System Settings > Printers"
echo ""
