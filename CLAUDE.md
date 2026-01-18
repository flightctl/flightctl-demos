# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains demos for [Flight Control](https://github.com/flightctl/flightctl), an edge device management system. Each demo showcases different edge computing use cases by providing pre-configured OS images that include the Flight Control agent and application-specific components.

## Repository Structure

The repository is organized into two main categories:

### Base Images

- [base/centos-bootc/](base/centos-bootc/) - CentOS Stream 9 bootc base image
- [base/fedora-bootc/](base/fedora-bootc/) - Fedora 43 bootc base image

Both base images include:

- Flight Control agent (from `rpm.flightctl.io`)
- podman and podman-compose
- cloud-init and open-vm-tools for provisioning

### Demo Images

The [demos/](demos/) directory contains more specialized demos that build upon base images:

- `quadlet-wordpress-demo` - WordPress using Podman Quadlet
- `mlops-pins-fleet` - ML operations demo
- `inverter-fleet` - IoT inverter management demo

### Directory Structure Per Image

Each image (base or demo) follows this structure:

```console
image-name/
├── bootc/
│   ├── Containerfile.amd64    # x86_64 container build definition
│   ├── Containerfile.arm64    # ARM64 container build definition
│   ├── Containerfile.tags     # Custom tags to apply (e.g., timestamped versions)
│   └── etc/                   # (demos only) Additional files to include
├── deploy/
│   └── fleet.yaml             # Flight Control fleet definition
└── configuration/             # (demos only) Runtime configuration
    └── etc/
```

## Building Images

All image builds are performed via GitHub Actions workflows. There are no local build scripts.

### CI/CD Workflows

The repository uses the following GitHub Actions workflows for building and publishing images:

#### 1. Build & Publish bootc image ([build-bootc-image.yaml](.github/workflows/build-bootc-image.yaml))

**Trigger:** Called manually or from other workflows

**Purpose:** Reusable workflow for building and (optionally) publishing a bootc image.

**What it does:**

- Builds a bootc image for the specified demo for both amd64 and arm64 architectures (`demos/DEMO_NAME/bootc/**`)
- Optionally, adds a specified agent config to the image.
- If `dry_run` is not specified or is `false`, creates a multi-architecture manifest list.
- If `dry_run` is not specified or is `false`, signs and publishes the manifest list and images to the specified registry.

**Build time:** ~5-10 minutes

### 2. Build & Publish disk images ([build-bootc-diskimage.yaml](.github/workflows/build-bootc-diskimage.yaml))

**Trigger:** Called manually or from other workflows

**Purpose:** Reusable workflow for building and publishing `.raw`, `.iso`, and `.qcow2` disk images for the specified bootc image.

**What it does:**

- Pulls the specified bootc image for both amd64 and arm64 architectures.
- Uses bootc image builder to build `.raw`, `.qcow2`, and `.iso` artifacts for both amd64 and arm64 architectures.
- Signs and publishes these artifacts to the specified registry.

**Build time:** ~5-10 minutes

#### 3. Build & Test ([build-and-test.yaml](.github/workflows/build-and-test.yaml))

**Trigger:** Pull requests (opened, synchronize, reopened)

**Purpose:** Fast feedback for PRs without publishing to registry

**What it does:**

- Detects which bootc images changed (by looking for changes in `**/bootc/**`)
- Builds changed bootc images for both amd64 and arm64 architectures
- Runs `bootc container lint --fatal-warnings` on built images
- **Does NOT** build disk images (too slow for PR validation)
- **Does NOT** push images to registry

**Build time:** ~5-10 minutes

#### 4. Publish on Merge ([publish-on-merge.yaml](.github/workflows/publish-on-merge.yaml))

**Trigger:** Push to main branch (after PR merge)

**Purpose:** Automatically build and publish validated changes

**What it does:**

- Detects which bootc images changed in the merge
- Builds changed bootc images for both amd64 and arm64 architectures
- Runs `bootc container lint --fatal-warnings` on built images
- Builds disk images (ISO, RAW, QCoW2) for all architectures
- Creates multi-architecture manifest lists
- Signs all images with Sigstore
- Publishes to quay.io/flightctl-demos with tags: `latest` and `<commit-sha>`

**Build time:** ~30+ minutes (includes disk images)

#### 5. Update Dependencies ([update-dependencies.yaml](.github/workflows/update-dependencies.yaml))

**Trigger:** Nightly at 2 AM UTC, or manually via workflow_dispatch

**Purpose:** Automatically detect and update upstream dependencies

**What it does:**

- **Checks base images**: Uses `skopeo` to query OCI registries for new digests of upstream base images
  - CentOS: `quay.io/centos-bootc/centos-bootc:stream9`
  - Fedora: `quay.io/fedora/fedora-bootc:43`
- **Checks RPM packages**: Parses repository metadata from `rpm.flightctl.io` for flightctl-agent updates
  - EPEL 9 (for CentOS): `https://rpm.flightctl.io/epel/9/x86_64`
  - Fedora 43: `https://rpm.flightctl.io/fedora/43/x86_64`
- **Updates files** when changes detected:
  - Updates `Containerfile.{amd64,arm64}` with new image digests
  - Updates `ARG FLIGHTCTL_VERSION` with new RPM package versions
  - Creates timestamped tags in `Containerfile.tags` (format: `stream9-202601171430`)
  - Updates demo Containerfiles that reference base images to use the new timestamped tags
- **Creates a single PR** with all updates bundled together for easy review

**Build time:** ~2-3 minutes

### Automated Dependency Management

#### Containerfile.tags

Each image directory contains a `Containerfile.tags` file that specifies custom tags to apply when building that image. This enables:

- **Timestamped versions**: Base images get dated tags (e.g., `stream9-202601171430`) when upstream updates are detected
- **Reproducible builds**: Demo images can reference specific timestamped base image versions
- **Audit trail**: Each update creates a unique tag, making it easy to track which version was deployed when

**Format:** Comma-separated list of tags, one per line or all on one line:

```text
stream9-202601171430
latest
```

**How it works:**

1. Build workflows automatically read `Containerfile.tags` when building images
2. Tags from the file are merged with workflow-provided tags (like `latest` and `${GITHUB_SHA}`)
3. All tags are applied to both the bootc image and its disk image artifacts

**Nightly update process:**

1. Workflow detects new upstream base image digest using `skopeo inspect`
2. Updates `Containerfile.{amd64,arm64}` with new `@sha256:...` digest
3. Generates timestamped tag: `<base-tag>-<YYYYMMDDHHmm>` (e.g., `stream9-202601171430`)
4. Writes timestamped tag to `Containerfile.tags`
5. Updates demo images that depend on this base to use the new timestamped tag
6. Creates PR with all changes

**Example workflow:**

- Upstream `centos-bootc:stream9` gets a new digest
- Nightly workflow updates `base/centos-bootc/bootc/Containerfile.tags` to `stream9-202601171430`
- On next build, centos-bootc image gets tagged with both `stream9-202601171430` and `latest`
- Any demos with bootc images that reference the base would be updated to use the timestamped version

### Image Output

Built images are pushed to the OCI registry with the following structure:

- Bootc image: `quay.io/flightctl-demos/DEMO_NAME:TAG`
- Disk images:
  - ISO: `quay.io/flightctl-demos/DEMO_NAME/diskimage-iso:TAG` (OCI artifact)
  - RAW: `quay.io/flightctl-demos/DEMO_NAME/diskimage-raw:TAG` (OCI artifact)
  - QCoW2: `quay.io/flightctl-demos/DEMO_NAME/diskimage-qcow2:TAG` (OCI image for KubeVirt)

**Available tags:**

- `latest` - Always points to the most recent build from main branch
- `<commit-sha>` - Git commit SHA (first 8 chars) for the build
- `<base-tag>-<timestamp>` - Timestamped versions for base images (e.g., `stream9-202601171430`)
  - Only present when upstream base image was updated
  - Timestamp format: YYYYMMDDHHmm (year, month, day, hour, minute in UTC)
  - Allows pinning to specific base image versions for reproducibility

**Example tags for centos-bootc:**

```text
quay.io/flightctl-demos/centos-bootc:latest
quay.io/flightctl-demos/centos-bootc:abc12345
quay.io/flightctl-demos/centos-bootc:stream9-202601171430
```

ISO and RAW formats are stored as OCI artifacts and must be downloaded using [ORAS](https://oras.land/):

```bash
oras pull quay.io/flightctl-demos/centos-bootc/diskimage-iso:latest
# Or pull a specific timestamped version
oras pull quay.io/flightctl-demos/centos-bootc/diskimage-iso:stream9-202601171430
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

4. **Linting**: Including `RUN bootc container lint` as the final step is recommended for early feedback during local builds. However, CI workflows enforce linting automatically, so forgotten lints won't slip through

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

   - **Demos must use local base images** (they include the flightctl-agent):
     - CentOS-based: `FROM quay.io/flightctl-demos/centos-bootc:latest`
     - Fedora-based: `FROM quay.io/flightctl-demos/fedora-bootc:latest`
   - Install required packages
   - Add configuration files with `ADD` statements
   - Enable systemd services
   - Run `bootc container lint`

3. Create `bootc/Containerfile.tags` with initial tags:

   ```bash
   echo "latest" > NEW_DEMO/bootc/Containerfile.tags
   ```

4. Create `deploy/fleet.yaml` with appropriate fleet configuration

5. (Optional) Add runtime configuration in `configuration/`

6. Open a PR - the PR validation workflow will automatically build and test your new image. After merge, it will be published to the registry

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
