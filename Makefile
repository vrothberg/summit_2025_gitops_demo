OCI_IMAGE ?= quay.io/vrothberg/summit-2025:demo
DISK_TYPE ?= qcow2
ROOTFS ?= xfs
ARCH ?= amd64
BIB_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest

.PHONY: oci-image
oci-image:
	podman build --pull=newer --platform linux/$(ARCH) -t $(OCI_IMAGE) .

.PHONY: push-oci-image
push-oci-image:
	podman push $(OCI_IMAGE)

# See https://github.com/osbuild/bootc-image-builder
.PHONY: disk-image
disk-image:
	mkdir -p ./output
	sed -e 's;@@IMAGE@@;$(OCI_IMAGE);g' config.toml.in > config.toml
	podman run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v ./config.toml:/config.toml:ro \
		-v ./output:/output \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		$(BIB_IMAGE) \
		--target-arch $(ARCH) \
		--type $(DISK_TYPE) \
		--rootfs $(ROOTFS) \
		--local \
		--use-librepo \
		$(OCI_IMAGE)
