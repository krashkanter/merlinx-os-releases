# Integration for future source builds; never include this on a production user build.
ifneq ($(filter userdebug eng,$(TARGET_BUILD_VARIANT)),)
PRODUCT_COPY_FILES += \
    device/xiaomi/merlinx/phone-services/phone-services.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/phone-services.rc \
    device/xiaomi/merlinx/phone-services/phone-services:$(TARGET_COPY_OUT_SYSTEM_EXT)/bin/phone-services
endif
