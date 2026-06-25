KAS_IMAGE := ghcr.io/siemens/kas/kas:5.2

WORKSPACE     := /yocto-workspace
WORKSPACE_VOL := yocto-workspace
DOWNLOADS_VOL := yocto-downloads
SSTATE_VOL    := yocto-sstate
SOURCES_VOL   := yocto-sources
TMP_VOL       := yocto-tmp

DOCKER_RUN := docker run --rm -it \
	--user $$(id -u):$$(id -g) \
	-v $(WORKSPACE_VOL):$(WORKSPACE) \
	-v $(DOWNLOADS_VOL):/yocto-downloads \
	-v $(SSTATE_VOL):/yocto-sstate \
	-v $(SOURCES_VOL):$(WORKSPACE)/sources \
	-v $(TMP_VOL):/yocto-tmp \
	-w $(WORKSPACE) \
	$(KAS_IMAGE)

.DEFAULT_GOAL := help

.PHONY: build qemu qemu-wic clean distclean rebuild dump shell sync clean-downloads extract

# Copy workspace into the named volume. Run after any source change before building.
sync:
	tar -czf - -C $(CURDIR) --exclude='.git' --exclude='build' --exclude='sources' . | \
		docker run --rm -i \
			-v $(WORKSPACE_VOL):$(WORKSPACE) \
			alpine sh -c "tar -xzf - -C $(WORKSPACE)"

# Build the image defined in kas/base.yml.
build: sync
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

# Initialize Docker volumes. Safe to re-run — skips volumes that already exist.
init-cache:
	docker volume inspect $(WORKSPACE_VOL) > /dev/null 2>&1 || { \
		docker volume create $(WORKSPACE_VOL) && \
		docker run --rm -v $(WORKSPACE_VOL):$(WORKSPACE) alpine \
			chown $$(id -u):$$(id -g) $(WORKSPACE); \
	}
	docker volume inspect $(DOWNLOADS_VOL) > /dev/null 2>&1 || { \
		docker volume create $(DOWNLOADS_VOL) && \
		docker run --rm -v $(DOWNLOADS_VOL):/yocto-downloads alpine \
			chown $$(id -u):$$(id -g) /yocto-downloads; \
	}
	docker volume inspect $(SSTATE_VOL) > /dev/null 2>&1 || { \
		docker volume create $(SSTATE_VOL) && \
		docker run --rm -v $(SSTATE_VOL):/yocto-sstate alpine \
			chown $$(id -u):$$(id -g) /yocto-sstate; \
	}
	docker volume inspect $(SOURCES_VOL) > /dev/null 2>&1 || { \
		docker volume create $(SOURCES_VOL) && \
		docker run --rm -v $(SOURCES_VOL):$(WORKSPACE)/sources alpine \
			chown $$(id -u):$$(id -g) $(WORKSPACE)/sources; \
	}
	docker volume inspect $(TMP_VOL) > /dev/null 2>&1 || { \
		docker volume create $(TMP_VOL) && \
		docker run --rm -v $(TMP_VOL):/yocto-tmp alpine \
			chown $$(id -u):$$(id -g) /yocto-tmp; \
	}

# Copy built images from the Docker volume to ./deploy on the host.
extract:
	mkdir -p deploy
	docker run --rm \
		-v $(TMP_VOL):/yocto-tmp \
		-v $(CURDIR)/deploy:/output \
		alpine sh -c "\
			src=\$$(ls -d /yocto-tmp/tmp*/deploy/images/company-qemuarm64 | head -n1); \
			cp -rL \$$src/* /output/ \
		"

# Remove corrupt/stale downloads so they are re-fetched on next build.
clean-downloads:
	docker run --rm -v $(DOWNLOADS_VOL):/yocto-downloads alpine \
		sh -c "rm -rf /yocto-downloads/*"

# Boot latest built image using QEMU.
qemu:
	$(DOCKER_RUN) shell kas/base.yml -c "\
		qb=\$$(ls -t /yocto-tmp/tmp*/deploy/images/company-qemuarm64/*.qemuboot.conf 2>/dev/null | head -n1); \
		runqemu \$${qb} nographic slirp \
	"

# Boot latest built WIC disk image using QEMU + U-Boot.
qemu-wic:
	$(DOCKER_RUN) shell kas/base.yml -c '\
		set -eu; \
		deploy=$$(ls -td /yocto-tmp/tmp*/deploy/images/company-qemuarm64 2>/dev/null | head -n1); \
		wic=$$(ls -t "$$deploy"/company-image-company-qemuarm64.rootfs*.wic 2>/dev/null | head -n1 || true); \
		qemuboot=$$(ls -t "$$deploy"/*.qemuboot.conf 2>/dev/null | head -n1 || true); \
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
		if [ -z "$$qemuboot" ] || [ ! -f "$$qemuboot" ]; then \
			echo "No qemuboot config found in $$deploy"; \
			exit 1; \
		fi; \
		if [ ! -f "$$uboot" ]; then \
			echo "No U-Boot binary found at $$uboot"; \
			echo "Make sure WKS_FILE_DEPENDS includes u-boot"; \
			exit 1; \
		fi; \
		runqemu "$$qemuboot" "$$wic" nographic slirp serialstdio qemuparams="-bios $$uboot" \
	'

# Remove QEMU tmp/runtime state.
qemu-clean:
	rm -rf build/tmp-glibc/deploy/images/company-qemuarm64/*.qemuboot.*.pid

# Show available targets.
help:
	@echo "help TBU"
