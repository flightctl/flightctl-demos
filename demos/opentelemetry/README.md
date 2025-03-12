# OpenTelemetry flightctl demo

`config.json`
```json
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

```bash
qcow2-bootc:
	@echo "Building FlightCtl Agent qcow2 image..."
	mkdir -p output
	sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
        -v $(PWD)/output:/output \
        -v $(PWD)/config.json:/config.json \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --config /config.json \
        quay.io/$(QUAYUSER)/flightctl-agent-$(flavor):latest


make  qcow2-bootc flavor=centos   QUAYUSER=ploffay
sudo virt-install  --name flightctl  --memory 3000  --vcpus 2  --disk output/qcow2/disk.qcow2  --import  --os-variant centos-stream9
```