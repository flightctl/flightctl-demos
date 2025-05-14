#!/bin/bash
set -e

echo "Enabling kiosk autologin..."

# Enable autologin in GDM custom.conf
if ! grep -q "AutomaticLoginEnable=True" /etc/gdm/custom.conf; then
  sed -i '/^\[daemon\]/aAutomaticLoginEnable=True\nAutomaticLogin=root' /etc/gdm/custom.conf
fi

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
