#!/bin/bash
set -euo pipefail

echo "Enabling kiosk autologin..."

# Enable autologin in GDM custom.conf
GDM_CONF=/etc/gdm/custom.conf
mkdir -p "$(dirname "$GDM_CONF")"
touch "$GDM_CONF"
if ! grep -q '^\[daemon\]' "$GDM_CONF"; then
  printf '[daemon]\n' >> "$GDM_CONF"
fi
if ! grep -q '^AutomaticLoginEnable=True' "$GDM_CONF"; then
  sed -i '/^\[daemon\]/aAutomaticLoginEnable=True\nAutomaticLogin=root' "$GDM_CONF"
fi
grep -q '^AutomaticLoginEnable=True' "$GDM_CONF"
grep -q '^AutomaticLogin=root' "$GDM_CONF"

# Add user session info
mkdir -p /var/lib/AccountsService/users
chmod 700 /var/lib/AccountsService/users
cat <<EOF > /var/lib/AccountsService/users/root
[User]
Session=gnome-kiosk-script
SystemAccount=false
EOF

# Marker file to ensure this only runs once
touch /etc/gdm/kiosk-autologin-configured
