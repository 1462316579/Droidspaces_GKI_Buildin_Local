#!/bin/bash
# GKI Kernel 5.10.256 Compile Script for Android 12 with Droidspaces

set -euo pipefail

# Configuration
KERNEL_VERSION="256"
ANDROID_VERSION="android12"
KSU_VARIANT="${KSU_VARIANT:-None}"
DROIDSPACES="${DROIDSPACES:-678}"  # Default: slot 678
RELEASE_TAG="all-kernel-sources-20260608-27112872553"
REPO="404-GCross/GKI-Kernel-Source_Fetch"

echo "=========================================="
echo "GKI Kernel 5.10.${KERNEL_VERSION} Compile"
echo "Android Version: ${ANDROID_VERSION}"
echo "KernelSU Variant: ${KSU_VARIANT}"
echo "Droidspaces Slot: ${DROIDSPACES}"
echo "=========================================="

# Create build directory
BUILD_DIR="build_5.10.${KERNEL_VERSION}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Download kernel source
ARCHIVE_NAME="kernel-source-${ANDROID_VERSION}-5.10-${KERNEL_VERSION}.tar.gz"
echo "Downloading kernel source..."
curl -fSL -o "${ARCHIVE_NAME}.sha256" "https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE_NAME}.sha256"
curl -fSL -o "${ARCHIVE_NAME}.partaa" "https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE_NAME}.partaa" || {
    echo "ERROR: Failed to download kernel source!"
    exit 1
}
curl -fSL -o "${ARCHIVE_NAME}.partab" "https://github.com/${REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE_NAME}.partab" || true

# Merge and verify
cat "${ARCHIVE_NAME}".part* > "${ARCHIVE_NAME}" 2>/dev/null || cat "${ARCHIVE_NAME}.partaa" "${ARCHIVE_NAME}.partab" 2>/dev/null > "${ARCHIVE_NAME}" || true
sha256sum -c "${ARCHIVE_NAME}.sha256" --quiet || {
    echo "ERROR: SHA256 verification failed!"
    exit 1
}

# Extract
echo "Extracting kernel source..."
tar -xzf "${ARCHIVE_NAME}"
SOURCE_DIR="kernel-source-${ANDROID_VERSION}-5.10-${KERNEL_VERSION}"

# Copy build scripts
cp -r ../build-scripts/* . 2>/dev/null || true

# Configure build
cat > .build_config << CONFEOF
APP_LANG=zh
ANDROID_VERSION=${ANDROID_VERSION}
KERNEL_VERSION=5.10
SUB_LEVEL=${KERNEL_VERSION}
OS_PATCH_LEVEL=2026-07
REVISION=
KSU_VARIANT=${KSU_VARIANT}
KSU_BRANCH=Stable(标准)
CUSTOM_VERSION=
BUILD_TIME=
USE_ZRAM=false
USE_KPM=disabled
USE_REKERNEL=false
CVE_2026_43499_PATCH=false
DROIDSPACES=${DROIDSPACES}
KERNEL_SOURCE=${PWD}/${SOURCE_DIR}
OUTPUT_DIR=${PWD}/out
PACKAGE_BOOT=true
CONFEOF

echo "Build configuration:"
cat .build_config

# Run compile
chmod +x ../build_kernel.sh
./../build_kernel.sh --quick

echo "=========================================="
echo "Build completed!"
echo "Output: ${BUILD_DIR}/out/"
echo "=========================================="
