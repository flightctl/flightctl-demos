# Kiosk demo

This demo boots a device with Firefox in kiosk mode for a retail use case.

## Device image

You can build the image in the bootc directory yourself, or use the latest
version of ```quay.io/atraeger/rhel-kiosk-demo```

## Application

The application runs a simple webserver that mounts the
```/var/kiosk/catalog``` directory from the device's file system. Add your
kiosk content there. You can optionally have FC sync this content from a git
repo.

## Kiosk script

The gnome-kiosk-script script needs to be placed in
```/home/kiosk/.local/bin/``` .
