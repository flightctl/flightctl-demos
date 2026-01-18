# Flight Control Demos

This repo contains demos showcasing the edge management capabilities of the [Flight Control](https://github.com/flightctl/flightctl) project.

## Base Images

The repository includes base bootc images that can be used as foundations for custom demos:

| Image | Description |
|-------|-------------|
| [`base/centos-bootc`](base/centos-bootc/) | CentOS Stream 9 bootc base image with Flight Control agent and podman-compose installed. |
| [`base/fedora-bootc`](base/fedora-bootc/) | Fedora 43 bootc base image with Flight Control agent and podman-compose installed. |

## Demo Applications

See the [`demos/`](demos/) directory for complete demo applications that showcase specific use cases.

## Running a demo

See the demo's README for a description of the demo and its specifc pre-requisites and procedures.

Common to all demos is that you need to ensure the following prerequisites:

* Access to a running Flight Control service instance of the latest stable version (see [Flight Control user documentation](https://github.com/flightctl/flightctl/tree/main/docs/user)).
* A physical or virtual device that you can provision with the appropriate OS image and that has network connectivity to the Flight Control service.
* The `flightctl` CLI installed and logged in to the service.

The demo's README will list the OS image to provision the device with, which may be specific to the demo or reuse another demo's OS image.

Pre-built OS images and disk images for both `amd64` and `arm64` CPU architectures are available on Quay:

* OS images (bootc) are available at `quay.io/flightctl-demos/$DEMO_NAME:latest`.
* OS disk images in ISO, RAW, and QCoW2 formats are available at `quay.io/flightctl-demos/$DEMO_NAME/diskimage-$FORMAT:latest`, whereby $FORMAT is one of `iso`, `raw`, or `qcow2`.

> [!IMPORTANT]
> These pre-built images do not contain the enrollment configuration for the agent, i.e. they can only be used by provisioning methods supporting *late binding* (see the [docs](https://github.com/flightctl/flightctl/blob/main/docs/user/building-images.md#choosing-an-enrollment-method) for details). If you need _early binding_, you can [build your own images](#building-your-own-bootc-and-disk-images) containing the enrollment credentials to your service.

Disk iamges in formats `raw` and `iso` are stored as OCI artifacts, not OCI images, so you need to use a tool like [ORAS](https://oras.land/) to download them, e.g.:

```console
oras pull quay.io/flightctl-demos/centos-bootc/diskimage-iso:latest
```

### Provisioning devices

Please refer to the [Provisioning devices]() section of the Flight Control project.

### Building your own bootc and disk images

If you cannot inject enrollment configuration during provisioning, you can instead build images that contain the enrollment configuration for your Flight Control service as follows.

Additional prerequisites:

* You have an account on GitHub and are logged in to that account.
* You have an account on Quay (or other OCI-compliant container registry) and are logged in to that account. ideally, you have created a "robot account", so you have throw-away credentials just for this demo.
* You have installed `skopeo` version 1.16 or higher.

Follow these steps:

1. Using the `flightctl` CLI, request an agent config with enrollment information and store it base64-encoded in a file `config.yaml.b64`:

   ```console
   flightctl certificate request --signer=enrollment --expiration=365d --output=embedded | base64 -w0 > config.yaml.b64
   ```

2. Generate a Sigstore-compatible cryptographic key pair (`signingkey.pub` and `signgingkey.private`):

   ```console
   skopeo generate-sigstore-key --output-prefix signingkey
   ```

3. In your OCI registry and org, create the following repositories:

   ```console
   $DEMO_NAME
   $DEMO_NAME/diskimage-iso
   $DEMO_NAME/diskimage-qcow2
   $DEMO_NAME/diskimage-raw
   ```

4. Fork this GitHub repository into your own GitHub account: Click the "Fork" button and in the following dialog leave all settings as his and click "Create fork". This will take a few seconds to complete.

5. Go to "Settings", "Security" section, "Secrets and variables", "Actions".

6. Add the following secrets by clicking on "New repository secret", filling in the secret name and value, then clicking "Add secret":

    | Secret | Value | Example |
    |--------|-------|---------|
    | OCI_REGISTRY | Your registry's domain. | quay.io |
    | OCI_REGISTRY_ORG | Your organisation within the registry. | my_quay_org |
    | OCI_REGISTRY_USERNAME | The username of your robot account. | my_robot_user |
    | OCI_REGISTRY_PASSWORD | The password of your robot account. | my_robot_password |
    | SIGNING_KEY_PRIVATE | The content of the `signingkey.private` you created. | -----BEGIN ENCRYPTED COSIGN PRIVATE KEY-----... |
    | AGENT_CONFIG | The content of the `config.yaml.b64` you created. | ZW5yb2xsbWVudC1zZXJ2... |

7. Go to the "Actions" tab and confirm that you want to enable the forked workflows.

8. Click "Build & publish bootc image", then the "Run workflow" button. Enter the `$DEMO_NAME` and update the OCI registry and org information. You can leave the agent config empty and it will be taken from the repository secrets. Click "Run workflow" and wait for the image build and push to complete.

9. Click "Build & publish bootc disk images", then the "Run workflow" button. Enter the `$DEMO_NAME` and update the OCI registry and org information. You can leave the agent config empty and it will be taken from the repository secrets. Click "Run workflow" and wait for the image build and push to complete.

## Contributing a demo

Do you have a demo for Flight Control that shows off a specific use case or "how to" for solving a specific practical problem? Do you have a fix or improvement suggestion for an existing demo or the demo infrastructure? Please open an issue and tell us about it! We also plan on accepting PRs, but need to work on guidelines around that still.