QUAYUSER := $(shell echo $(USER))

bootc-fedora:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-fedora:latest -f bootc-agent-images/fedora/Containerfile bootc-agent-images/fedora/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-fedora:latest

bootc-centos:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	@echo "Requires RH's VPN"
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-centos:latest -f bootc-agent-images/centos/Containerfile bootc-agent-images/centos/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-centos:latest

qcow2-bootc:
	@echo "Building FlightCtl Agent qcow2 image..."
	mkdir -p output
	sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
        -v $(PWD)/output:/output \
        quay.io/centos-bootc/bootc-image-builder:latest \
        quay.io/$(QUAYUSER)/flightctl-agent-$(flavor):latest
