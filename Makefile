TARGET := iphone:clang:latest:14.0
ARCHS = arm64
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeviceIDSpoofer

DeviceIDSpoofer_FILES = Tweak.x \
	DeviceIDManager.m \
	FloatingButton.m \
	UIManager.m

DeviceIDSpoofer_CFLAGS = -fobjc-arc
DeviceIDSpoofer_FRAMEWORKS = UIKit Foundation
DeviceIDSpoofer_PRIVATE_FRAMEWORKS = AdSupport

include $(THEOS_MAKE_PATH)/tweak.mk
