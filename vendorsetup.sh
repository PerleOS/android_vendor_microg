# SPDX-FileCopyrightText: The PerleOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Sourced by build/envsetup.sh. Runs in a subshell so that a failure does not
# change the options of the calling shell.

(bash "$(gettop)/vendor/microg/fetch-apks.sh") ||
    echo "vendor/microg: some APKs are missing; the build will fail until fetch-apks.sh succeeds" >&2
