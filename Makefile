QUAYUSER ?= $(shell echo $(USER))

bootc-fedora:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-fedora:latest -f images/bootc/fedora-bootc/Containerfile images/bootc/fedora-bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-fedora:latest

bootc-centos:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	@echo "Requires RH's VPN"
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-centos:latest -f images/bootc/centos-bootc/Containerfile images/bootc/centos-bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-centos:latest

bootc-rhel:
	@echo "Building RHEL9 FlightCtl Agent bootc image..."
	@echo "Requires RH's VPN"
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-rhel:latest -f images/bootc/rhel-bootc/Containerfile images/bootc/rhel-bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-rhel:latest

basic-nginx:
	@echo "Building Flightctl demo with microshift and nginx..."
	sudo podman pull quay.io/${QUAYUSER}/flightctl-agent-centos:bootstrap
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-basic-nginx:latest -f demos/basic-nginx-demo/bootc/Containerfile demos/basic-nginx-demo/bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-basic-nginx:latest

extra-rhel:
	@echo "Building Flightctl demo with microshift and otel-collector..."
	sudo podman pull quay.io/${QUAYUSER}/flightctl-agent-rhel:latest
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-extra-rhel:latest -f demos/basic-extra-rhel/bootc/Containerfile demos/basic-extra-rhel/bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-extra-rhel:latest

qcow2-bootc:
	@echo "Building FlightCtl Agent qcow2 image..."
	mkdir -p output
	sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
        -v $(PWD)/output:/output \
        quay.io/centos-bootc/bootc-image-builder:latest \
        quay.io/$(QUAYUSER)/flightctl-agent-$(flavor):latest

raw-bootc:
	@echo "Building FlightCtl Agent raw image..."
	mkdir -p output
	sudo podman run --rm -it --privileged --pull=newer \
        --security-opt label=type:unconfined_t \
		-v $(PWD)/config.json:/config.json \
        -v $(PWD)/output:/output \
        quay.io/centos-bootc/bootc-image-builder:latest \
		--type raw \
		--config /config.json \
		quay.io/$(QUAYUSER)/$(image):latest
