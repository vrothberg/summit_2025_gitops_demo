OCI_IMAGE ?= quay.io/vrothberg/summit-2025:demo
DISK_TYPE ?= qcow2
ROOTFS ?= xfs
ARCH ?= amd64
BIB_IMAGE ?= quay.io/centos-bootc/bootc-image-builder:latest

.PHONY: oci-image
oci-image:
	podman build --pull=newer --platform linux/$(ARCH) -t $(OCI_IMAGE) .

.PHONY: original
original:
	rm -f Containerfile
	ln -s Containerfile.original Containerfile

.PHONY: patched
patched:
	rm -f Containerfile
	ln -s Containerfile.patched Containerfile

.PHONY: push-oci-image
push-oci-image:
	podman push $(OCI_IMAGE)

# See https://github.com/osbuild/bootc-image-builder
.PHONY: disk-image
disk-image:
	mkdir -p ./output
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

.PHONY: boot
boot:
	qemu-system-x86_64 -enable-kvm \
		-m 4096 -M accel=kvm \
		-cpu host -smp 2 \
		-nographic \
		-hda ./output/qcow2/disk.qcow2
