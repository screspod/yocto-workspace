# Container image used for Yocto builds.
# Pinning a specific version improves reproducibility.
KAS_IMAGE := ghcr.io/siemens/kas/kas:5.2

# Workspace and cache mount locations inside container.
WORKSPACE := /workspace
CACHE := /cache

# Docker runtime wrapper.
#
# --user
#   Prevents root-owned build artifacts on host.
#
# -v $(CURDIR):$(WORKSPACE)
#   Mounts project workspace into container.
#
# -v ../yocto-cache:$(CACHE)
#   Mounts persistent Yocto caches.
#
# -w $(WORKSPACE)
#   Sets working directory inside container.
DOCKER_RUN := docker run --rm -it \
	--user $$(id -u):$$(id -g) \
	-v $(CURDIR):$(WORKSPACE) \
	-v $(CURDIR)/../yocto-cache:$(CACHE) \
	-w $(WORKSPACE) \
	$(KAS_IMAGE)

# Default target.
.DEFAULT_GOAL := help

.PHONY: build qemu qemu-wic clean distclean rebuild dump shell

# Build the image defined in kas/base.yml.
build:
	$(DOCKER_RUN) build kas/base.yml

# Open an interactive shell inside the kas container.
#
# Useful for:
# - debugging
# - manual bitbake commands
# - inspecting build state
shell:
	$(DOCKER_RUN) shell kas/base.yml

# Completely remove generated build artifacts.
#
# Does NOT remove:
# - downloads cache
# - sstate cache
clean:
	rm -rf build

# Remove all build artifacts and caches.
#
# Useful when recovering from corrupted cache state
# or major metadata changes.
distclean:
	rm -rf build
	rm -rf ../yocto-cache/downloads/*
	rm -rf ../yocto-cache/sstate/*

# Regenerate build environment from scratch.
rebuild: clean build

# Validate kas configuration without building.
#
# Useful for:
# - YAML validation
# - repo/layer validation
# - debugging configuration issues
dump:
	$(DOCKER_RUN) dump kas/base.yml

# Show generated BitBake layer configuration.
bblayers:
	cat build/conf/bblayers.conf

# Show generated local.conf.
localconf:
	cat build/conf/local.conf

# Run BitBake manually inside the container.
#
# Example:
# make bitbake CMD="core-image-minimal -c clean"
bitbake:
	$(DOCKER_RUN) shell kas/base.yml -c "bitbake $(CMD)"

# Create cache directories if missing.
init-cache:
	mkdir -p ../yocto-cache/downloads
	mkdir -p ../yocto-cache/sstate

# Boot latest built image using QEMU.
#
# Uses:
# - generated Yocto qemuboot config
# - SLIRP user-mode networking
#
# SLIRP avoids:
# - TAP devices
# - sudo
# - privileged networking
# - host bridge setup
#
# This is much simpler and more portable for:
# - containers
# - CI
# - local development
qemu:
	$(DOCKER_RUN) shell kas/base.yml -c "\
		runqemu qemuarm64 nographic slirp \
	"

# Boot latest built WIC disk image using QEMU.
#
# Unlike `make qemu`, this boots the full partitioned disk image
# so tools inside the guest can inspect partitions with lsblk/fdisk.
qemu-wic:
	$(DOCKER_RUN) shell kas/base.yml -c '\
				set -eu; \
				deploy="build/tmp-glibc/deploy/images/qemuarm64"; \
				wic=$$(ls -t "$$deploy"/company-image-qemuarm64.rootfs*.wic 2>/dev/null | head -n1 || true); \
				if [ -z "$$wic" ]; then \
						echo "No .wic image found in $$deploy"; \
						echo "Build WIC output first, e.g. enable IMAGE_FSTYPES += \"wic\" and run make build"; \
						exit 1; \
				fi; \
				echo "Booting $$wic"; \
				runqemu "$$wic" nographic slirp serialstdio \
	'

# Remove QEMU tmp/runtime state.
#
# Useful if QEMU networking or locks become stale.
qemu-clean:
	rm -rf build/tmp/deploy/images/qemuarm64/*.qemuboot.*.pid

# Show available targets.
help:
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make build        Build the Yocto image"
	@echo "  make shell        Open interactive kas shell"
	@echo "  make clean        Remove build directory"
	@echo "  make distclean    Remove build + caches"
	@echo "  make rebuild      Clean and rebuild"
	@echo "  make dump         Validate/render kas config"
	@echo "  make bblayers     Show generated BBLAYERS"
	@echo "  make localconf    Show generated local.conf"
	@echo "  make bitbake CMD=\"...\""
	@echo "                    Run manual BitBake command"
	@echo "  make init-cache   Create cache directories"
	@echo "  make qemu         Boot latest built image using QEMU"
	@echo "  make qemu-wic     Boot latest WIC disk image"
	@echo ""