#!/usr/bin/env bash

set -e

cp cmake/libpinmame/CMakeLists.txt .

# Android

# TODO: should this be ARCH=arm64-v8a like libpinmame does in GHA? doesn't seem necessary since I copied ANDROID_ABI=arm64-v8a from swift-android-examples
cmake \
    -B build/android \
    -DPLATFORM=android \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame.artifactbundle/android \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_TOOLCHAIN" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-28
cmake --build build/android
cmake --install build/android

# macOS

cmake \
    -B build/macos \
    -DPLATFORM=macos \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame.artifactbundle/macos
cmake --build build/macos
cmake --install build/macos

# iOS

cmake \
    -B build/ios \
    -DPLATFORM=ios \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame.artifactbundle/ios
cmake --build build/ios
cmake --install build/ios

# iOS simulator

cmake \
    -B build/ios-simulator \
    -DPLATFORM=ios-simulator \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame.artifactbundle/ios-simulator
cmake --build build/ios-simulator
cmake --install build/ios-simulator

# Wrap in artifactbundle

for f in android macos ios ios-simulator; do
    cp module.modulemap libpinmame.artifactbundle/$f/include/pinmame/
done

cat > "libpinmame.artifactbundle/info.json" << 'EOF'
{
  "schemaVersion": "1.0",
  "artifacts": {
    "libpinmame": {
      "version": "1.0.0",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "android/lib/libpinmame.a",
          "supportedTriples": ["aarch64-unknown-linux-android"],
          "staticLibraryMetadata": {
            "headerPaths": ["android/include/pinmame"],
            "moduleMapPath": "android/include/pinmame/module.modulemap"
          }
        },
        {
          "path": "macos/lib/libpinmame.a",
          "supportedTriples": ["arm64-apple-macosx", "arm64-apple-macos", "arm64-apple-macos27.0"],
          "staticLibraryMetadata": {
            "headerPaths": ["macos/include/pinmame"],
            "moduleMapPath": "macos/include/pinmame/module.modulemap"
          }
        },
        {
          "path": "ios/lib/libpinmame.a",
          "supportedTriples": ["arm64-apple-ios", "arm64-apple-ios15.0"],
          "staticLibraryMetadata": {
            "headerPaths": ["ios/include/pinmame"],
            "moduleMapPath": "ios/include/pinmame/module.modulemap"
          }
        },
        {
          "path": "ios-simulator/lib/libpinmame.a",
          "supportedTriples": ["arm64-apple-ios-simulator"],
          "staticLibraryMetadata": {
            "headerPaths": ["ios-simulator/include/pinmame"],
            "moduleMapPath": "ios-simulator/include/pinmame/module.modulemap"
          }
        }
      ]
    }
  }
}
EOF

zip -vry libpinmame.artifactbundle.zip libpinmame.artifactbundle
echo "Created 'libpinmame.artifactbundle' with checksum $(swift package compute-checksum libpinmame.artifactbundle.zip)"
