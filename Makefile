QUAYUSER ?= $(shell echo $(USER))

bootc-fedora:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-fedora:latest -f bootc-agent-images/fedora/Containerfile bootc-agent-images/fedora/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-fedora:latest

bootc-centos:
	@echo "Building Fedora FlightCtl Agent bootc image..."
	@echo "Requires RH's VPN"
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-centos:latest -f bootc-agent-images/centos/Containerfile bootc-agent-images/centos/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-centos:latest

bootc-rhel:
	@echo "Building RHEL9 FlightCtl Agent bootc image..."
	@echo "Requires RH's VPN"
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-rhel:latest -f bootc-agent-images/rhel/Containerfile bootc-agent-images/rhel/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-rhel:latest

basic-nginx:
	@echo "Building Flightctl demo with microshift and nginx..."
	sudo podman pull quay.io/${QUAYUSER}/flightctl-agent-centos:bootstrap
	sudo podman build -t quay.io/${QUAYUSER}/flightctl-agent-basic-nginx:latest -f basic-nginx-demo/bootc/Containerfile basic-nginx-demo/bootc/
	sudo podman push quay.io/${QUAYUSER}/flightctl-agent-basic-nginx:latest

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
		quay.io/$(QUAYUSER)/flightctl-agent-$(flavor):latest