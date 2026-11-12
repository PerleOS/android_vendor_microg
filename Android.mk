# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# GmsCore is a Make module because Soong cannot install the native libraries
# of an imported APK. The package manager does not extract them from a system
# app, so fetch-apks.sh extracts the arm64 ones and they are installed to
# priv-app/GmsCore/lib/arm64/. The APK itself is installed unchanged.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := GmsCore
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_SRC_FILES := prebuilt/GmsCore.apk
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/prebuilt/GmsCore.apk
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_PRIVILEGED_MODULE := true
LOCAL_PRODUCT_MODULE := true
LOCAL_DEX_PREOPT := false
LOCAL_MULTILIB := 64
LOCAL_PREBUILT_JNI_LIBS_arm64 := \
    $(patsubst $(LOCAL_PATH)/%,%,$(wildcard $(LOCAL_PATH)/prebuilt/GmsCore/lib/arm64/*.so))
ifeq ($(LOCAL_PREBUILT_JNI_LIBS_arm64),)
    $(error vendor/microg: GmsCore native libraries missing, run vendor/microg/fetch-apks.sh)
endif
LOCAL_USES_LIBRARIES := com.android.location.provider
# Same order as in the manifest: the check compares the lists in order.
LOCAL_OPTIONAL_USES_LIBRARIES := \
    org.apache.http.legacy \
    androidx.window.extensions \
    androidx.window.sidecar
LOCAL_REQUIRED_MODULES := \
    default-permissions-microg.xml \
    privapp-permissions-microg.xml \
    sysconfig-microg.xml
include $(BUILD_PREBUILT)
