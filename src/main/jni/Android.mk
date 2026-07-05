LOCAL_PATH := $(call my-dir)

# Complete static PDFium archive (includes its bundled third-party libraries).
include $(CLEAR_VARS)
LOCAL_MODULE := aospPdfium

ARCH_PATH = $(TARGET_ARCH_ABI)

LOCAL_SRC_FILES := $(LOCAL_PATH)/static/$(ARCH_PATH)/libpdfium.a

include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := chromiumCxx
LOCAL_SRC_FILES := $(LOCAL_PATH)/static/$(ARCH_PATH)/libchromium_cxx.a
include $(PREBUILT_STATIC_LIBRARY)

#Main JNI library
include $(CLEAR_VARS)
LOCAL_MODULE := jniPdfium
LOCAL_CFLAGS += -DHAVE_PTHREADS
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include
LOCAL_STATIC_LIBRARIES := aospPdfium chromiumCxx
LOCAL_LDLIBS += -llog -landroid -ljnigraphics -ldl -lm
LOCAL_LDFLAGS += -Wl,--no-undefined -Wl,-z,max-page-size=16384 -Wl,--exclude-libs,ALL
LOCAL_SRC_FILES := $(LOCAL_PATH)/src/mainJNILib.cpp
LOCAL_CPPFLAGS += -stdlib=libc++
LOCAL_CPP_FEATURES += rtti exceptions
include $(BUILD_SHARED_LIBRARY)
