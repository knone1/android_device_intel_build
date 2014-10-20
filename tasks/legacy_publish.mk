ifeq ($(LEGACY_PUBLISH),true)
# checkapi is only called if droid is among the cmd goals, or no cmd goal is given
# We add it here to be called for other targets as well
#droid: checkapi

FASTBOOT_FLASHFILE_DEPS := bootimage

ifeq ($(ENABLE_FRU),yes)
bootimage: build_fru
endif
ifneq ($(FLASHFILE_BOOTONLY),true)
FASTBOOT_FLASHFILE_DEPS += firmware recoveryimage
ifeq ($(TARGET_USE_DROIDBOOT),true)
FASTBOOT_FLASHFILE_DEPS += droidbootimage
endif
ifeq ($(TARGET_USE_RAMDUMP),true)
FASTBOOT_FLASHFILE_DEPS += ramdumpimage
endif
FASTBOOT_FLASHFILE_DEPS += systemimage
endif
ifeq ($(TARGET_BIOS_TYPE),"uefi")
FASTBOOT_FLASHFILE_DEPS += espimage
endif
FASTBOOT_FLASHFILE_DEPS += updatepackage

ifeq ($(INTEL_FEATURE_SILENTLAKE),true)
FASTBOOT_FLASHFILE_DEPS += $(PRODUCT_OUT)/sl_vmm.bin
endif

#ifeq ($(USE_GMS_ALL),true)
#PUBLISH_TARGET_BUILD_VARIANT := $(TARGET_BUILD_VARIANT)_gms
#else
PUBLISH_TARGET_BUILD_VARIANT := $(TARGET_BUILD_VARIANT)
#endif

TARGET_PUBLISH_PATH ?= $(shell echo $(TARGET_PRODUCT) | tr '[:lower:]' '[:upper:]')
GENERIC_TARGET_NAME ?= $(TARGET_PRODUCT)

.PHONY: flashfiles
flashfiles: fastboot_flashfile ota_flashfile

.PHONY: fastboot_flashfile
fastboot_flashfile: $(FASTBOOT_FLASHFILE_DEPS)
	PUBLISH_PATH=$(PUBLISH_PATH) \
	TARGET_PUBLISH_PATH=$(PUBLISH_PATH)/$(TARGET_PUBLISH_PATH) \
	GENERIC_TARGET_NAME=$(GENERIC_TARGET_NAME) \
	TARGET_USE_DROIDBOOT=$(TARGET_USE_DROIDBOOT) \
	TARGET_USE_RAMDUMP=$(TARGET_USE_RAMDUMP) \
	FLASHFILE_BOOTONLY=$(FLASHFILE_BOOTONLY) \
	FLASHFILE_NO_OTA=$(FLASHFILE_NO_OTA) \
	ULPMC_BINARY=$(ULPMC_BINARY) \
	TARGET_BIOS_TYPE=$(TARGET_BIOS_TYPE) \
	TARGET_PARTITIONING_SCHEME=$(TARGET_PARTITIONING_SCHEME) \
	INTEL_FEATURE_SILENTLAKE=$(INTEL_FEATURE_SILENTLAKE) \
	BOARD_USE_64BIT_KERNEL=$(BOARD_USE_64BIT_KERNEL) \
	$(SUPPORT_PATH)/publish_build.py '$@' $(REF_PRODUCT_NAME) $(TARGET_DEVICE) $(PUBLISH_TARGET_BUILD_VARIANT) $(FILE_NAME_TAG) $(TARGET_BOARD_SOC) $(TARGET_USE_XEN)

.PHONY: flashfiles_nozip
flashfiles_nozip: $(FASTBOOT_FLASHFILE_DEPS)
	FLASHFILE_ZIP=0 \
	PUBLISH_PATH=$(PUBLISH_PATH) \
	TARGET_PUBLISH_PATH=$(PUBLISH_PATH)/$(TARGET_PUBLISH_PATH) \
	GENERIC_TARGET_NAME=$(GENERIC_TARGET_NAME) \
	TARGET_USE_DROIDBOOT=$(TARGET_USE_DROIDBOOT) \
	FLASHFILE_BOOTONLY=$(FLASHFILE_BOOTONLY) \
	FLASHFILE_NO_OTA=$(FLASHFILE_NO_OTA) \
	ULPMC_BINARY=$(ULPMC_BINARY) \
	TARGET_BIOS_TYPE=$(TARGET_BIOS_TYPE) \
	TARGET_PARTITIONING_SCHEME=$(TARGET_PARTITIONING_SCHEME) \
	BOARD_USE_64BIT_KERNEL=$(BOARD_USE_64BIT_KERNEL) \
	$(SUPPORT_PATH)/publish_build.py 'fastboot_flashfile' $(REF_PRODUCT_NAME) $(TARGET_DEVICE) $(PUBLISH_TARGET_BUILD_VARIANT) $(FILE_NAME_TAG) $(TARGET_BOARD_SOC) $(TARGET_USE_XEN)

# Buildbot override to force OTA on UI demand (maintainers/engineering builds)
ifeq ($(FORCE_OTA),true)
override FLASHFILE_NO_OTA:=false
endif

.PHONY: ota_flashfile
ifneq (,$(filter true,$(FLASHFILE_NO_OTA) $(FLASHFILE_BOOTONLY)))
ota_flashfile:
	@echo "Do not generate ota_flashfile"
else
ifeq ($(TARGET_BIOS_TYPE),"uefi")
ota_flashfile: espimage
endif
ota_flashfile: otapackage
	PUBLISH_PATH=$(PUBLISH_PATH) \
	TARGET_PUBLISH_PATH=$(PUBLISH_PATH)/$(TARGET_PUBLISH_PATH) \
	GENERIC_TARGET_NAME=$(GENERIC_TARGET_NAME) \
	TARGET_USE_DROIDBOOT=$(TARGET_USE_DROIDBOOT) \
	FLASHFILE_BOOTONLY=$(FLASHFILE_BOOTONLY) \
	FLASHFILE_NO_OTA=$(FLASHFILE_NO_OTA) \
	TARGET_BIOS_TYPE=$(TARGET_BIOS_TYPE) \
        BOARD_USE_64BIT_KERNEL=$(BOARD_USE_64BIT_KERNEL) \
	ULPMC_BINARY=$(ULPMC_BINARY) \
	$(SUPPORT_PATH)/publish_build.py '$@' $(REF_PRODUCT_NAME) $(TARGET_DEVICE) $(PUBLISH_TARGET_BUILD_VARIANT) $(FILE_NAME_TAG) $(TARGET_BOARD_SOC) $(TARGET_USE_XEN)
endif #$(FLASHFILE_NO_OTA) || $(FLASHFILE_BOOTONLY)

ifneq ($(FLASHFILE_BOOTONLY),true)
blank_flashfiles: firmware
ifeq ($(TARGET_USE_DROIDBOOT),true)
blank_flashfiles: droidbootimage
else
blank_flashfiles: recoveryimage
endif
ifeq ($(TARGET_BIOS_TYPE),"uefi")
blank_flashfiles: espimage
endif
.PHONY: blank_flashfiles
blank_flashfiles:
	PUBLISH_PATH=$(PUBLISH_PATH) \
	TARGET_PUBLISH_PATH=$(PUBLISH_PATH)/$(TARGET_PUBLISH_PATH) \
	GENERIC_TARGET_NAME=$(GENERIC_TARGET_NAME) \
	TARGET_USE_DROIDBOOT=$(TARGET_USE_DROIDBOOT) \
	FRU_CONFIGS=$(FRU_CONFIGS) \
	FRU_TOKEN_DIR=$(FRU_TOKEN_DIR) \
	TARGET_BIOS_TYPE=$(TARGET_BIOS_TYPE) \
	TARGET_PARTITIONING_SCHEME=$(TARGET_PARTITIONING_SCHEME) \
	BOARD_USE_64BIT_KERNEL=$(BOARD_USE_64BIT_KERNEL) \
	ULPMC_BINARY=$(ULPMC_BINARY) \
	CONFIG_LIST="$(CONFIG_LIST)" \
	BOARD_GPFLAG=$(BOARD_GPFLAG) \
	SINGLE_DNX=$(SINGLE_DNX) \
	$(SUPPORT_PATH)/publish_build.py 'blankphone' $(REF_PRODUCT_NAME) $(TARGET_DEVICE) $(PUBLISH_TARGET_BUILD_VARIANT) $(FILE_NAME_TAG) $(TARGET_BOARD_SOC) $(TARGET_USE_XEN)
else
blank_flashfiles:
	@echo "No blank_flashfiles for this target - FLASHFILE_BOOTONLY set to TRUE"
endif

endif
