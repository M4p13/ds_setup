#!/bin/bash

# SSH Setup Script - Add authorized key and disable password authentication
# Run this script to configure SSH key-based authentication

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Your SSH public key
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBcWd2YSlRNey8/5y+Fp351c2p/km77PyTEIFHg2HwJyU0ln9Tl7StnSevKZNWITvTEyDkB1dz23KCGN/M/9dGl6duxw4+fLq6clhQSGFAIsiN7AcvBwv85Lgv0PJx2FgyHUfmFyIFG0e4qd9CvsV04bkagUDntcfBMgt0gyy3VH2Xcq7Aqp0RIgcb7e4MF/oLJJ1j9t5TDBQ8FbzfJc0HRuRjfoGTgX52rcle99Wxv5iPBvF7EZfwmdjoilJwqh/vyaZfiff2MAkGIilrOzwiZnXw7mKqdDiuKEIjh6NYem3aiMSfZgPbYhO3BG7peIoaOVGYgh3bcn07TvBG6g8axakVXwbFhmv5zpqBXQ8bykGMS0+6U8Azt6aQ/5Yo2N7lnWxQ06JsgmG7Q1nBxSJUAnoqZVTsI5KUSHUPryb0G7kcHi4NF+fhA4Ob72omVRODUN+nQg6O2GeUY6ch1HSAilKzaJb6zGbza3ftur3PK81ouQGCSDat3DTanN9z02M= Admin@DESKTOP-GML1E2U"

echo -e "${YELLOW}=== SSH Setup for $(whoami) ===${NC}"
echo

# Step 1: Add SSH key to authorized_keys
echo -e "${YELLOW}[1/3] Adding SSH key to authorized_keys...${NC}"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

if grep -qF "$SSH_PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo -e "${GREEN}✓ SSH key already exists in authorized_keys${NC}"
else
    echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
    echo -e "${GREEN}✓ SSH key added successfully${NC}"
fi

# Step 2: Configure SSH to disable password authentication
echo -e "${YELLOW}[2/3] Configuring SSH daemon...${NC}"
SSHD_CONFIG="/etc/ssh/sshd_config"

if [ ! -f "$SSHD_CONFIG" ]; then
    echo -e "${RED}Error: $SSHD_CONFIG not found${NC}"
    exit 1
fi

# Backup original config
sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%Y%m%d_%H%M%S)"

# Disable password authentication
if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
    echo -e "${GREEN}✓ Updated PasswordAuthentication to no${NC}"
else
    echo "PasswordAuthentication no" | sudo tee -a "$SSHD_CONFIG" > /dev/null
    echo -e "${GREEN}✓ Added PasswordAuthentication no${NC}"
fi

# Ensure PubkeyAuthentication is enabled
if grep -q "^PubkeyAuthentication" "$SSHD_CONFIG"; then
    sudo sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PubkeyAuthentication yes" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi
echo -e "${GREEN}✓ PubkeyAuthentication enabled${NC}"

# Disable root password login
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin prohibit-password" | sudo tee -a "$SSHD_CONFIG" > /dev/null
fi
echo -e "${GREEN}✓ Root password login disabled${NC}"

# Step 3: Restart SSH service
echo -e "${YELLOW}[3/3] Restarting SSH service...${NC}"
sudo systemctl restart sshd

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSH service restarted successfully${NC}"
else
    echo -e "${RED}✗ Failed to restart SSH service${NC}"
    exit 1
fi

echo
echo -e "${GREEN}=== SSH Setup Complete ===${NC}"
echo -e "${GREEN}✓ SSH key added for user: $(whoami)${NC}"
echo -e "${GREEN}✓ Password authentication disabled${NC}"
echo -e "${GREEN}✓ Only key-based authentication is now allowed${NC}"
echo
echo -e "${YELLOW}IMPORTANT: Make sure you can connect with your SSH key before closing this session!${NC}"
echo -e "${YELLOW}Test with: ssh $(whoami)@$(hostname)${NC}"
