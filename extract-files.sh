#!/bin/bash
#
# Copyright (C) 2018-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ARROW_ROOT="${MY_DIR}"/../../..

HELPER="${ARROW_ROOT}/vendor/arrow/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/lib64/hw/camera.qcom.so)
        patchelf --remove-needed "libMegviiFacepp-0.5.2.so" "${2}"
        patchelf --remove-needed "libmegface.so" "${2}"
        patchelf --add-needed "libshim_megvii.so" "${2}"
        ;;

    lib64/libwfdnative.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;
    
    lib/libwfdcommonutils.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;
    
    lib/libwfdmmsrc.so)
        patchelf --add-needed "libshim_wfdservice.so" "${2}"
        ;;
    esac
}

# Initialize the helper for common device
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ARROW_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

if [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ARROW_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" \
            "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
