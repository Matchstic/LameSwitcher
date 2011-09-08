include theos/makefiles/common.mk

TWEAK_NAME = CardSwitcher
CardSwitcher_FILES = Tweak.xm CSApplicationController.m CSApplication.m CSResources.m CSScrollView.m
CardSwitcher_FRAMEWORKS = Foundation UIKit QuartzCore CoreGraphics
CardSwitcher_PRIVATE_FRAMEWORKS = GraphicsServices
CardSwitcher_LDFLAGS = -lactivator

TARGET_IPHONEOS_DEPLOYMENT_VERSION = 4.0

include $(THEOS_MAKE_PATH)/tweak.mk
