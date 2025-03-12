# OpenTelemetry flightctl demo

## Build bootc image

```bash
sudo podman build -t quay.io/user/flightctl-opentelemetry:latest -f demos/opentelemetry/bootc/Containerfile demos/opentelemetry/bootc
```

## Create virtual machine

```bash
cat config.json
{
    "blueprint": {
      "customizations": {
        "user": [
          {
            "name": "user",
            "password": "password",
            "key": "ssh-ed25519 AAAAC...",
            "groups": [
              "wheel"
            ]
          }
        ]
      }
    }
}
```

Create qcow2: 

```bash
sudo podman run --rm -it --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v $PWD/output:/output \
  -v $PWD/config.json:/config.json \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --config /config.json \
  quay.io/user/flightctl-opentelemetry:2
```

Create a virtual machine:
```bash
sudo virt-install  --name flightctl  --memory 3000  --vcpus 2  --disk output/qcow2/disk.qcow2  --import  --os-variant centos-stream9
```

Access the virtual machine and login with user@password:
```bash
virt-manager
```

Get collector logs:
```bash
journalctl -u opentelemetry-collector.service
```