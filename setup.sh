#!/bin/bash
if ! command -v yay 2p>&1 > /dev/null
then
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si
  cd ../
fi
yay
yay -S hyprland sddm openssh tmux kitty wayvnc avahi nss-mdns

sudo systemctl enable sddm.service
sudo systemctl enable sshd
sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service

sudo mkdir -p /etc/sddm.conf.d
u="$USER"
if [ ! -e /etc/sddm.conf.d/autologin.conf ]; then
  sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null <<  EOF
[Autologin]
User=$u
Session=hyprland
EOF
fi
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

HYPRLAND_DIR="$HOME/.config/hypr"
HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf" 

if [ ! -d "$HYPRLAND_DIR" ]; then
  mkdir -p "$HYPRLAND_DIR"
fi

#if [ -f "$HYPRLAND_CONFIG" ]; then
#  echo "Hyprland config already exists at $HYPRLAND_CONFIG"
#  exit 1
#fi

sudo cp ./hyprland.conf $HYPRLAND_CONFIG
touch $HOME/.config/hypr/run.sh
chmod +x $HOME/.config/hypr/run.sh

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
