# Flight Control kiosk demo — UI walkthrough

## Story and sequence

1. Onboard device1 with `type=kiosk` and `region=useast` already assigned.
2. Create the fleet through GitOps. Device1 automatically joins because its
   existing labels match the newly created fleet.
3. Show device1's US East content and explain the regional template.
4. Onboard device2 with `type=kiosk,region=uswest`. It automatically joins the
   existing fleet and receives US West content.

No device label edits are needed after approval. The demonstration shows both
orders: an existing device finds a new fleet, and a new device finds an existing
fleet.

## Before sharing your screen

- Open the [Flight Control UI](http://10.100.102.160.nip.io:9001) and log in with
  the Kubernetes service-account token from
  `/home/atraeger/.local/share/flightctl/demo-2026-10/ui-login-token.txt`.
  It expires about 24 hours after creation; refresh it before the demo if needed.
- Set `XDG_RUNTIME_DIR=/run/user/$(id -u)` in your terminal. Start device1
  with `virsh --connect qemu:///session start device1` if it is off, then open
  `virt-viewer --connect qemu:///session device1`. Leave device2 powered off.
- Keep the web UI, device consoles, and this walkthrough ready to switch between.
- Confirm the UI has one pending request for device1, no enrolled devices, no
  `kiosks` fleet, and no demo repositories or ResourceSync. If a previous
  rehearsal populated these, reset the disposable environment before presenting.
- Device1 should already be running. Before fleet assignment, its screen shows
  the desktop; Firefox waits for the catalog application before opening.

Use the web UI for enrollment, repositories, and ResourceSync. Use `virsh`
for VM power control and `virt-viewer` for graphical consoles. For initial
boot-image and VM creation, see [Boot images and VM setup](BOOT-IMAGES.md).

## 1. Onboard device1 — US East

1. Open the pending enrollment requests in the web UI.
2. Identify device1 by its hostname and open its approval form.
3. Set these labels during approval:

   | Label | Value |
   | --- | --- |
   | `alias` | `device1` |
   | `type` | `kiosk` |
   | `region` | `useast` |

4. Approve the request.
5. Open device1 in the device inventory. Show its labels and that it has no
   fleet owner yet. Wait for it to be online.

**Show:** device1 already has `type=kiosk`; there is simply no matching fleet yet.

**Say:** “This device is a kiosk in US East. We have described what it is with
labels, but we have not created a fleet yet.”

## 2. Create the fleet using GitOps

### Create the content repository

In the web UI's repository management view, create a Git repository with:

| Field | Value |
| --- | --- |
| Name | `kiosk-content` |
| Type | Git |
| URL | `https://github.com/avishayt/fc-kiosk.git` |
| Authentication | None — public repository |

This repository supplies the regional catalogs. Save it.

### Create the fleet repository

Create a second Git repository with:

| Field | Value |
| --- | --- |
| Name | `flightctl-demos` |
| Type | Git |
| URL | `https://github.com/flightctl/flightctl-demos.git` |
| Authentication | None — public repository |

This repository supplies the fleet definition and kiosk script. Save it and
confirm both repositories become accessible.

The branch/tag is selected by the ResourceSync or a fleet `gitRef`, not by the
Repository itself. The exact Repository definitions are included below for
reference when reviewing the saved resources:

```yaml
apiVersion: flightctl.io/v1beta1
kind: Repository
metadata:
  name: kiosk-content
spec:
  type: git
  url: https://github.com/avishayt/fc-kiosk.git
---
apiVersion: flightctl.io/v1beta1
kind: Repository
metadata:
  name: flightctl-demos
spec:
  type: git
  url: https://github.com/flightctl/flightctl-demos.git
```

### Create one ResourceSync

In the web UI's ResourceSync creation flow, use:

| Field | Value |
| --- | --- |
| Name | `kiosk-fleet-sync` |
| Repository | `flightctl-demos` |
| Target revision | `fc-kiosk` |
| Path | `kiosk/deployment/fleet.yaml` |

The exact resource definition is:

```yaml
apiVersion: flightctl.io/v1beta1
kind: ResourceSync
metadata:
  name: kiosk-fleet-sync
spec:
  repository: flightctl-demos
  path: kiosk/deployment/fleet.yaml
  targetRevision: fc-kiosk
```

Save it, then wait for the sync to report accessible and synchronized. Open the
fleet inventory and show that `kiosks` appears automatically.

Do not create the fleet manually. Do not create a second ResourceSync for
content: the fleet's configuration reads that through the `kiosk-content`
repository.

Open the new fleet and its devices. **Device1 joins automatically**, because it
already has the `type=kiosk` label. Do not edit its labels in this step.

**Say:** “Creating the fleet was enough. The existing device already matched
its selector, so Flight Control assigned it automatically.”

## 3. Show device1's US East content

Open the fleet's definition in the UI. Highlight the selector:

```yaml
selector:
  matchLabels:
    type: kiosk
```

Then highlight the regional content configuration:

```yaml
- name: kiosk-content
  gitRef:
    repository: kiosk-content
    targetRevision: v1
    path: /{{ .metadata.labels.region }}
```

You can also show the
[fleet definition in GitHub](https://github.com/flightctl/flightctl-demos/blob/fc-kiosk/kiosk/deployment/fleet.yaml).

Return to device1. Wait for its fleet owner to be `kiosks`, system status Online,
update status UpToDate, and application status Healthy. Switch to its graphical
console: Firefox opens the catalog automatically.

The US East catalog contains:

- Transportation & Logistics
- Smart Cities
- Telecom

**Say:** “The type label chose the fleet. The region label rendered the content
path as `/useast`, so this device received the US East catalog.”

The files are placed under `/var/kiosk/catalog`. The fleet's Python container
serves them on port 8080; Firefox displays that local application.

## 4. Onboard device2 — US West

1. Start device2 and open its console:

   ```bash
   virsh --connect qemu:///session start device2
   virt-viewer --connect qemu:///session device2
   ```
2. Return to the web UI and wait for device2's enrollment request.
3. Approve it with these labels:

   | Label | Value |
   | --- | --- |
   | `alias` | `device2` |
   | `type` | `kiosk` |
   | `region` | `uswest` |

4. Open device2 and show that its fleet owner becomes `kiosks` automatically.
   No subsequent label edit or fleet change is needed.
5. Wait for Online / UpToDate / Healthy, then show its graphical console.

The US West catalog contains:

- Industrial / Manufacturing
- Retail
- Healthcare

Finish with the two catalogs side by side, then show both devices in the same
fleet in the web UI.

**Say:** “The second device joined the existing fleet and received US West
content from its labels. We did not create another fleet or write a separate
device configuration.”

Automatic assignment requires no additional operator action; reconciliation,
image downloads, and application startup still take time. Show status while
waiting.

## Quick troubleshooting in the UI

| Symptom | Check |
| --- | --- |
| Device1 does not join when the fleet appears | Its labels must include `type=kiosk`; inspect the fleet selector and device status. |
| Fleet does not appear | Both repositories should be accessible; inspect `kiosk-fleet-sync`, its path, revision, and sync status. |
| Content rendering fails | Region must be exactly `useast` or `uswest`; content revision stays `v1`. Existing `v2` uses an incompatible layout. |
| Device remains Updating | Inspect its status message. The first Python image pull can take tens of seconds. |
| Login prompt covering the kiosk | Confirm the fleet has applied its screen-lock configuration. |
| Blank desktop | Firefox is waiting for the catalog application. Check device/application status. |
| No new enrollment request on restart | The VM is already enrolled. A fresh demo needs fresh writable disks/identity, not just a restart. |

## Fleet definition and initial setup

The maintained fleet is [deployment/fleet.yaml](deployment/fleet.yaml).
ResourceSync imports it; do not create it manually. It includes Xfce screen-lock
settings applied after updates and at graphical login, so the kiosk stays visible.

See [Boot images and VM setup](BOOT-IMAGES.md) to create the initial boot disks,
inject enrollment configuration, and define both VMs.

Refresh the UI login token if expired:

```bash
kubectl --context kind-kind -n flightctl-external create token flightctl-admin --duration=24h
```
