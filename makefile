KAS_IMAGE := ghcr.io/siemens/kas/kas:5.2

WORKSPACE := /yocto-workspace
CACHE := /yocto-cache

DOCKER_RUN := docker run --rm -it \
	--user $$(id -u):$$(id -g) \
	-v $(CURDIR):$(WORKSPACE) \
	-v $(CURDIR)/../yocto-cache:$(CACHE) \
	-w $(WORKSPACE) \
	$(KAS_IMAGE)

.DEFAULT_GOAL := help

.PHONY: build qemu qemu-wic clean distclean rebuild dump shell

# Build the image defined in kas/base.yml.
build:
	$(DOCKER_RUN) build kas/base.yml

# Open an interactive shell inside the kas container.
shell:
	$(DOCKER_RUN) shell kas/base.yml

# Regenerate build environment from scratch.
rebuild: clean build

# Validate kas configuration without building.
dump:
	$(DOCKER_RUN) dump kas/base.yml

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
qemu:
	$(DOCKER_RUN) shell kas/base.yml -c "\
		runqemu company-qemuarm64 company-image wic nographic slirp \
	"

# Boot latest built WIC disk image using QEMU + U-Boot.
qemu-wic:
		$(DOCKER_RUN) shell kas/base.yml -c '\
					set -eu; \
					deploy="$${BUILDDIR}/tmp-glibc/deploy/images/company-qemuarm64"; \
					wic=$$(ls -t "$$deploy"/company-image-company-qemuarm64.rootfs*.wic 2>/dev/null | head -n1 || true); \
					qemuboot="$$deploy/company-image-company-qemuarm64.rootfs.qemuboot.conf"; \
					uboot="$$deploy/u-boot.bin"; \
					echo "Deploy dir: $$deploy"; \
					echo "WIC image:  $$wic"; \
					echo "QEMU boot:  $$qemuboot"; \
					echo "U-Boot:     $$uboot"; \
					if [ -z "$$wic" ]; then \
							echo "No .wic image found in $$deploy"; \
							echo "Run make build first"; \
							exit 1; \
					fi; \
					if [ ! -f "$$qemuboot" ]; then \
							echo "No qemuboot config found at $$qemuboot"; \
							exit 1; \
					fi; \
					if [ ! -f "$$uboot" ]; then \
							echo "No U-Boot binary found at $$uboot"; \
							echo "Make sure WKS_FILE_DEPENDS includes u-boot"; \
							exit 1; \
					fi; \
					runqemu company-qemuarm64 company-image wic nographic slirp serialstdio qemuparams="-bios $$uboot" \
		'

# Remove QEMU tmp/runtime state.
qemu-clean:
	rm -rf build/tmp-glibc/deploy/images/company-qemuarm64/*.qemuboot.*.pid

# Show available targets.
help:
	@echo "help TBU"
