# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains demos for [Flight Control](https://github.com/flightctl/flightctl), an edge device management system. Each demo showcases different edge computing use cases by providing pre-configured OS images that include the Flight Control agent and application-specific components.

## Repository Structure

The repository is organized into two main categories:

### Base Images

- [base/centos-bootc/](base/centos-bootc/) - CentOS Stream 9 bootc base image
- [base/fedora-bootc/](base/fedora-bootc/) - Fedora 41 bootc base image

Both base images include:

- Flight Control agent (from `rpm.flightctl.io`)
- podman and podman-compose
- cloud-init and open-vm-tools for provisioning

### Demo Images
The [demos/](demos/) directory contains more specialized demos that build upon base images:

- `basic-nginx-demo` - MicroShift with NGINX deployment
- `quadlet-wordpress-demo` - WordPress using Podman Quadlet
- `mlops-pins-fleet` - ML operations demo
- `inverter-fleet` - IoT inverter management demo
- `basic-extra-rhel` - Additional RHEL-based demo

### Directory Structure Per Image
Each image (base or demo) follows this structure:

```console
image-name/
├── bootc/
│   ├── Containerfile.amd64    # x86_64 container build definition
│   ├── Containerfile.arm64    # ARM64 container build definition
│   └── etc/                   # (demos only) Additional files to include
├── deploy/
│   └── fleet.yaml             # Flight Control fleet definition
└── configuration/             # (demos only) Runtime configuration
    └── etc/
```

## Building Images

All image builds are performed via GitHub Actions workflows. There are no local build scripts.

### Automated Builds (CI)

The workflow [build-changed-bootc-images.yaml](.github/workflows/build-changed-bootc-images.yaml) automatically runs on pull requests and:

1. Detects which bootc images changed (by looking for changes in `**/bootc/**`)
2. Builds both the bootc image and disk images for changed demos
3. Supports both amd64 and arm64 architectures
4. Creates multi-architecture manifest lists
5. Signs all images with Sigstore

### Image Output

Built images are pushed to the OCI registry with the following structure:

- Bootc image: `quay.io/flightctl-demos/DEMO_NAME:TAG`
- Disk images:
  - ISO: `quay.io/flightctl-demos/DEMO_NAME/diskimage-iso:TAG` (OCI artifact)
  - RAW: `quay.io/flightctl-demos/DEMO_NAME/diskimage-raw:TAG` (OCI artifact)
  - QCoW2: `quay.io/flightctl-demos/DEMO_NAME/diskimage-qcow2:TAG` (OCI image for KubeVirt)

ISO and RAW formats are stored as OCI artifacts and must be downloaded using [ORAS](https://oras.land/):

```bash
oras pull quay.io/flightctl-demos/centos-bootc/diskimage-iso:latest
```

## Architecture & Key Concepts

### bootc Technology

- bootc = "bootable container" - containers that can boot as operating systems
- Images are built as standard OCI containers but contain a full OS filesystem
- bootc-image-builder converts bootc images to bootable disk images
- Each Containerfile installs packages, configures systemd services, and runs `bootc container lint`

### Multi-Architecture Support

- All images support both amd64 and arm64 architectures
- Separate Containerfiles per architecture allow arch-specific customization
- GitHub Actions matrix builds both architectures in parallel
- Final manifest lists reference both architectures

### Flight Control Integration

- **Agent enrollment**: Images can include pre-baked agent config (early binding) or enroll at runtime (late binding)
- **Fleet**: A collection of devices with shared configuration defined in `deploy/fleet.yaml`
- Fleet spec includes:
  - `os.image`: The bootc image to deploy
  - `config`: Inline files, git-sourced configuration, or secrets
  - `systemd.matchPatterns`: Services to monitor

### Disk Image Formats

- **ISO**: Bootable installation media for physical provisioning
- **RAW**: Raw disk image for direct writes (dd, Raspberry Pi Imager, etc.)
- **QCoW2**: QEMU copy-on-write format, packaged as "containerdisk" for KubeVirt

## Working with Containerfiles

When modifying Containerfile.amd64 or Containerfile.arm64:

1. **Package installation**: Always install minimal and clean up package metadata to reduce image size:

   ```dockerfile
   RUN dnf -y install PACKAGE \
         --nodocs --setopt=install_weak_deps=False && \
       dnf clean all && \
       rm -rf /var/{cache,log}
   ```

2. **Enable systemd services**: Use `systemctl enable` to ensure services start on boot:

   ```dockerfile
   RUN systemctl enable SERVICE_NAME.service
   ```

3. **Agent configuration**: The build workflow can inject agent config by appending:

   ```dockerfile
   ADD config.yaml /etc/flightctl/
   ```

4. **Linting**: Always include `RUN bootc container lint` as the final step to validate

5. **Keep architecture variants in sync**: Changes to one architecture should typically be mirrored to the other unless there's an architecture-specific reason

## Flight Control Fleet Definitions

Fleet YAML files in `deploy/` directories define how devices are managed:

```yaml
apiVersion: flightctl.io/v1beta1
kind: Fleet
metadata:
  name: fleet-name
spec:
  selector:
    matchLabels:
      fleet: fleet-name
  template:
    spec:
      os:
        image: quay.io/flightctl-demos/IMAGE_NAME:latest
      config:
        - name: config-name
          inline:
            - path: "/etc/file"
              content: "content"
              mode: 0644
        - name: git-config
          gitRef:
            repository: repo-name
            targetRevision: main
            path: /path/to/config
      systemd:
        matchPatterns:
          - "service-name.service"
```

Apply fleets using the `flightctl` CLI:

```bash
flightctl apply -f deploy/fleet.yaml
```

## Adding a New Demo

To add a new demo image:

1. Create directory structure:

   ```bash
   mkdir -p NEW_DEMO/{bootc,deploy,configuration/etc}
   ```

2. Create `bootc/Containerfile.amd64` and `bootc/Containerfile.arm64`:

   - Start FROM an existing base image or upstream bootc image
   - Install required packages
   - Add configuration files with `ADD` statements
   - Enable systemd services
   - Run `bootc container lint`

3. Create `deploy/fleet.yaml` with appropriate fleet configuration

4. (Optional) Add runtime configuration in `configuration/`

5. Open a PR - the CI workflow will automatically build and publish your new image

## Prerequisites for Building Custom Images

If you need to fork this repo and build images with your own Flight Control enrollment:

- GitHub account
- OCI registry account (Quay.io recommended) with robot credentials
- `skopeo` 1.16+ installed locally
- `flightctl` CLI configured and authenticated

Follow the detailed steps in the main [README.md](README.md) "Building your own bootc and disk images" section to:

1. Generate agent enrollment config
2. Create Sigstore signing keys
3. Configure GitHub secrets
4. Trigger workflow builds
