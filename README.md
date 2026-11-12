<!--
SPDX-FileCopyrightText: The PerleOS Project
SPDX-License-Identifier: Apache-2.0
-->

# vendor/microg

microG and F-Droid for PerleOS, installed to `product`:

| Module | Package | Install |
|---|---|---|
| GmsCore | `com.google.android.gms` (microG Services) | `priv-app` |
| FakeStore | `com.android.vending` (microG Companion) | `priv-app` |
| FDroid | `org.fdroid.fdroid` | `app`, with the microG repository preset |
| FDroidPrivilegedExtension | `org.fdroid.fdroid.privileged` | `priv-app` |

The APKs are the official builds, signed by the microG team and by F-Droid. They are not stored in this repository: `fetch-apks.sh` downloads them into `prebuilt/` and checks each against the SHA-256 pinned in `prebuilt/apks.txt` (F-Droid APKs are also looked up in `archive/` once F-Droid has moved them there). `vendorsetup.sh` runs it from `source build/envsetup.sh`, so a tree that has the APKs needs no network.

The package manager does not extract native libraries from a system app. GmsCore stores its libraries compressed, so `fetch-apks.sh` extracts the arm64 ones to `prebuilt/GmsCore/lib/arm64/` and `Android.mk` installs them to `priv-app/GmsCore/lib/arm64/`. F-Droid stores its libraries uncompressed (`extractNativeLibs="false"`) and loads them from the APK.

Default grants (`etc/default-permissions-microg.xml`): GmsCore gets location, accounts and notifications at first boot, and microG Companion accounts and notifications, so that network location and push work after setup. The user can revoke them; every other permission is asked for by the app.

Signature spoofing: LineageOS lets `com.google.android.gms` and `com.android.vending` report the Google signature only when they are signed with the microG certificate, on debuggable builds. PerleOS `frameworks/base` removes the debuggable condition so that `user` builds get the same restricted spoofing. The APKs are therefore installed byte for byte (`preprocessed: true`).

Use: `$(call inherit-product, vendor/microg/microg.mk)`.

## Updating an APK

1. Download the new APK and check its signing certificate:
   `java -jar prebuilts/sdk/tools/linux/lib/apksigner.jar verify --print-certs <apk>` must print the certificate SHA-256 in the header of `prebuilt/apks.txt`.
2. Replace the URL and SHA-256 in `prebuilt/apks.txt`.
3. Compare the privileged permissions the APK requests (`aapt2 dump permissions`) with `etc/privapp-permissions-microg.xml`: a missing entry stops `system_server` at boot; an entry the APK no longer requests is harmless.
4. If the APK declares other `uses-library` entries (`aapt2 dump badging`), update `Android.bp` (`Android.mk` for GmsCore).
5. If a new APK has compressed native libraries and `extractNativeLibs="true"`, add it to `jni_modules` in `fetch-apks.sh` and give it an `Android.mk` module like GmsCore.
