# Kiosk boot images and VM setup

These instructions describe the Fedora/Xfce demo rehearsed on 8 October 2026.
Use [the walkthrough](DEMO-WALKTHROUGH.md) once device1 is awaiting approval.
Commands here are preparation; fleet management during the demo uses the UI.

## Prerequisites and paths

Use a Linux host with KVM, Podman, qemu-img, qemu-nbd, libvirt user sessions,
virsh, virt-install, virt-viewer, Python 3, and sudo. The Flight Control service
must already be deployed and reachable from the VMs, with matching backend/UI
versions. The tested backend is `3ad5e1b6a`, UI `d0d337bb`.

```bash
set -euo pipefail
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export LIBVIRT_DEFAULT_URI=qemu:///session
FC_SRC=$HOME/work/flightctl-demo
DEMOS=$HOME/work/flightctl-demos
DEMO_STATE=$HOME/.local/share/flightctl/demo-2026-10
DEMO_BASE=$FC_SRC/bin/output/qcow2/demo-base.qcow2
mkdir -p "$DEMO_STATE"
chmod 700 "$DEMO_STATE"
```

On the prepared host these paths already exist. Device1 and device2 are already
defined; do not recreate their disks while either VM is running. Always use the
same user session and runtime directory as the desktop.

## 1. Obtain the desktop OS container image

The fleet currently references:

```text
quay.io/flightctl/flightctl-device:base-fedora-bootc-v1.4.0-main-86-g9a4353536
```

This is the Fedora desktop variant built with `FLIGHTCTL_DESKTOP=true`. It
contains the agent, Firefox, Xfce, LightDM, autologin for `user`, and the demo
account (`user` / `user`). The Containerfile under `kiosk/bootc` builds a different
GNOME kiosk image and is not the source of the tested disk.

The image is cached in **root's** Podman storage on the prepared host. Verify it:

```bash
OS_IMAGE=quay.io/flightctl/flightctl-device:base-fedora-bootc-v1.4.0-main-86-g9a4353536
sudo podman image inspect "$OS_IMAGE" >/dev/null
```

On another host, obtain that image from a registry you can access, or transfer
it from the prepared host with `sudo podman save` / `sudo podman load`. The
original Quay pull returned unauthorized during preparation; do not assume it
is publicly downloadable. A container archive is input to disk creation, not
a bootable disk. If you build a replacement OS image, include the desktop and
autologin configuration above and update the fleet's OS image reference too.

The prepared VMs remap this Quay namespace to the local TLS registry at
`10.100.102.160:5000`. That registry contains the same image. For another host,
populate an accessible registry and use its address and trusted CA below.

## 2. Create a bootable QCOW2 with bootc-image-builder

The current Flight Control checkout contains the disk-building helper:

```bash
cd "$FC_SRC"
OS_ID=fedora-bootc \
TAG=v1.4.0-main-86-g9a4353536 \
ROOTFS=ext4 \
OUTPUT_DIR="$FC_SRC/bin/output/rebuilt-demo" \
  test/scripts/agent-images/scripts/qcow2.sh
```

It runs bootc-image-builder to create partitions, a bootloader, and the installed
OS at `bin/output/rebuilt-demo/qcow2/disk.qcow2`. Fedora needs `ROOTFS=ext4`.
This rebuild command was inspected against the helper; the successful demo
used the already-built desktop disk, sanitized into `demo-base.qcow2`.

For a new base, copy the **never-booted** output to a new filename:

```bash
DEMO_BASE=$FC_SRC/bin/output/qcow2/demo-base-new.qcow2
cp --reflink=auto "$FC_SRC/bin/output/rebuilt-demo/qcow2/disk.qcow2" "$DEMO_BASE"
```

Never overwrite a base that existing overlays depend on. Do not boot the base
itself: each device must generate its own identity in a writable overlay.

## 3. Inject enrollment credentials and registry trust

For the existing deployment, the helper can use its generated agent config:

```bash
cd "$FC_SRC"
QCOW="$DEMO_BASE" \
AGENT_DIR="$FC_SRC/bin/agent/etc/flightctl" \
REGISTRY_ADDRESS=10.100.102.160:5000 \
  test/scripts/inject_agent_files_into_qcow.sh
```

The helper uses sudo and qemu-nbd, resolves the OSTree deployment's `/etc`,
and injects agent configuration, certificates, registry remapping, and CA trust.
Run it only with no other NBD disk operations in progress. Its default registry
CA is `bin/e2e-certs/pki/CA/ca.crt`; set `E2E_CA` for another registry.
Use enrollment credentials for the current service, never a previous cluster.
Keep generated configuration private and outside Git.

If the generated config is unavailable, an authenticated CLI can request an
embedded enrollment config for an empty private agent directory:

```bash
mkdir -p "$DEMO_STATE/agent/certs"
chmod 700 "$DEMO_STATE/agent"
"$FC_SRC/bin/flightctl" certificate request \
  --signer=enrollment --expiration=365d --output=embedded \
  > "$DEMO_STATE/agent/config.yaml"
chmod 600 "$DEMO_STATE/agent/config.yaml"
```

Then use `AGENT_DIR="$DEMO_STATE/agent"` in the injection command.

## 4. Create the two writable disks and prepare their desktop launcher

To reuse the prepared, sanitized base, set `DEMO_BASE` back to
`$FC_SRC/bin/output/qcow2/demo-base.qcow2`. Its enrollment credentials already
match the current service. Create new disk paths; these commands refuse to
replace existing disks:

```bash
for vm in device1 device2; do
  test ! -e "$DEMO_STATE/$vm.qcow2" || exit 1
  qemu-img create -f qcow2 -F qcow2 -b "$DEMO_BASE" "$DEMO_STATE/$vm.qcow2"
done
```

Each overlay needs its hostname set before boot. For the tested disk layout,
root is partition 4 and the OSTree stateroot is `default`. Confirm the layout
with `lsblk` before mounting if using a different image. Choose a free NBD
node; do not disconnect a node in use by another task.

```bash
sudo modprobe nbd max_part=16
# Confirm /dev/nbd0 is unused before continuing.
lsblk /dev/nbd0
sudo mkdir -p /mnt/kiosk-disk
for vm in device1 device2; do
  sudo qemu-nbd --connect /dev/nbd0 "$DEMO_STATE/$vm.qcow2"
  sudo udevadm settle
  sudo mount /dev/nbd0p4 /mnt/kiosk-disk
  sudo bash -c 'for d in /mnt/kiosk-disk/ostree/deploy/default/deploy/*.0; do
    printf "%s\n" "$1" > "$d/etc/hostname"
  done' _ "$vm"
  sudo install -D -o 1000 -g 1000 -m 755 \
    "$DEMOS/kiosk/setup/flightctl-kiosk-wait" \
    /mnt/kiosk-disk/ostree/deploy/default/var/home/user/.local/bin/flightctl-kiosk-wait
  sudo install -D -o 1000 -g 1000 -m 644 \
    "$DEMOS/kiosk/setup/flightctl-kiosk.desktop" \
    /mnt/kiosk-disk/ostree/deploy/default/var/home/user/.config/autostart/flightctl-kiosk.desktop
  sudo umount /mnt/kiosk-disk
  sudo qemu-nbd --disconnect /dev/nbd0
done
```

Stop on any error and unmount/disconnect before retrying. The launcher waits for
`/products.json` before opening Firefox and disables Xfce locking. The fleet
also manages screen-lock settings after enrollment.

## 5. Define the VMs and boot device1

On the prepared host, skip VM definition: `virsh list --all` should show both
names. On a new host, define graphical VMs with user networking and local SSH
forwarding (2222 for device1, 2223 for device2):

```bash
for vm in device1 device2; do
  port=2222
  [ "$vm" = device1 ] || port=2223
  virt-install --connect qemu:///session \
    --name "$vm" --memory 4096 --vcpus 2 \
    --import --osinfo detect=on,require=off --boot uefi \
    --disk "path=$DEMO_STATE/$vm.qcow2,format=qcow2,bus=virtio" \
    --network none --graphics vnc,listen=127.0.0.1 --video virtio \
    --qemu-commandline="-netdev user,id=n0,hostfwd=tcp:127.0.0.1:$port-:22 -device virtio-net-pci,netdev=n0" \
    --print-xml > "$DEMO_STATE/$vm.xml"
  virsh define "$DEMO_STATE/$vm.xml"
done
virsh start device1
virt-viewer --connect qemu:///session device1
```

The generic `virt-install` definition above is for a new host and was not used
in the rehearsal. The prepared host uses saved, boot-tested XML definitions in
`$DEMO_STATE`. Both approaches require working UEFI firmware packages on the
host. The standard Flight Control development VM helper omits graphical video;
keep VNC and virtio video for this demo.

Leave device2 off. Verify device1 appears as **Pending** in the UI. Then follow
[the walkthrough](DEMO-WALKTHROUGH.md). At step 4:

```bash
virsh start device2
virt-viewer --connect qemu:///session device2
```

For a later reset, stop both VMs before replacing their overlays. Remove the
ResourceSync first, then the fleet, repositories, old devices, and enrollment
requests. Recreate overlays from the clean base and start only device1. A normal
VM restart retains enrollment and is not a demo reset.
