TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeviceIDSpoofer

DeviceIDSpoofer_FILES = Tweak.x FloatingWindow.m DeviceIDManager.m UIManager.m
DeviceIDSpoofer_CFLAGS = -fobjc-arc
DeviceIDSpoofer_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
