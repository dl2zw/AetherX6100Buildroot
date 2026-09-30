################################################################################
# DRM Panel Jinglitai JLT4013A - Direct Linux Kernel Patch
################################################################################

define JLT4013A_PREPARE_KERNEL
	@echo "================================================================"
	@echo "== RUNNING: JLT4013A kernel integration                       =="
	@echo "================================================================"

	mkdir -p $(LINUX_DIR)/drivers/gpu/drm/panel/
	cp $(BR2_EXTERNAL_X6100_PATH)/board/X6100/drivers/panel-jinglitai-jlt4013a.c \
		$(LINUX_DIR)/drivers/gpu/drm/panel/


	if ! grep -q "CONFIG_DRM_PANEL_JINGLITAI_JLT4013A" $(LINUX_DIR)/drivers/gpu/drm/panel/Kconfig; then \
		sed -i '/^endmenu/i \ \
config DRM_PANEL_JINGLITAI_JLT4013A\n\ttristate "Jinglitai JLT4013A electronic panel"\n\tdepends on OF && DRM_PANEL\n\thelp\n\t  Say Y here if you want to enable support for Jinglitai JLT4013A panel.\n' \
		$(LINUX_DIR)/drivers/gpu/drm/panel/Kconfig; \
	else \
		echo "--> JLT4013A config already present in Kconfig, skipping patch."; \
	fi

	if ! grep -q "panel-jinglitai-jlt4013a.o" $(LINUX_DIR)/drivers/gpu/drm/panel/Makefile; then \
		echo "obj-\$$(CONFIG_DRM_PANEL_JINGLITAI_JLT4013A) += panel-jinglitai-jlt4013a.o" \
			>> $(LINUX_DIR)/drivers/gpu/drm/panel/Makefile; \
	fi
endef

LINUX_POST_PATCH_HOOKS += JLT4013A_PREPARE_KERNEL
