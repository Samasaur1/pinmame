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
    -DCMAKE_INSTALL_PREFIX=libpinmame-android.artifactbundle \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_TOOLCHAIN" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-28
cmake --build build/android
cmake --install build/android

cat > "libpinmame-android.artifactbundle/info.json" << 'EOF'
{
  "schemaVersion": "1.0",
  "artifacts": {
    "libpinmame": {
      "version": "1.0.0",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "lib/libpinmame.a",
          "supportedTriples": ["aarch64-unknown-linux-android"],
          "staticLibraryMetadata": {
            "headerPaths": ["include/pinmame"],
            "moduleMapPath": "include/pinmame/module.modulemap"
          }
        }
      ]
    }
  }
}
EOF

# macOS

cmake \
    -B build/macos \
    -DPLATFORM=macos \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame-macos.artifactbundle
cmake --build build/macos
cmake --install build/macos

cat > "libpinmame-macos.artifactbundle/info.json" << 'EOF'
{
  "schemaVersion": "1.0",
  "artifacts": {
    "libpinmame": {
      "version": "1.0.0",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "lib/libpinmame.a",
          "supportedTriples": ["arm64-apple-macosx"],
          "staticLibraryMetadata": {
            "headerPaths": ["include/pinmame"],
            "moduleMapPath": "include/pinmame/module.modulemap"
          }
        }
      ]
    }
  }
}
EOF

# iOS

cmake \
    -B build/ios \
    -DPLATFORM=ios \
    -DARCH=arm64 \
    -DBUILD_STATIC=ON \
    -DBUILD_SHARED=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_LTO=OFF \
    -DCMAKE_INSTALL_PREFIX=libpinmame-ios.artifactbundle
cmake --build build/ios
cmake --install build/ios

cat > "libpinmame-ios.artifactbundle/info.json" << 'EOF'
{
  "schemaVersion": "1.0",
  "artifacts": {
    "libpinmame": {
      "version": "1.0.0",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "lib/libpinmame.a",
          "supportedTriples": ["arm64-apple-ios"],
          "staticLibraryMetadata": {
            "headerPaths": ["include/pinmame"],
            "moduleMapPath": "include/pinmame/module.modulemap"
          }
        }
      ]
    }
  }
}
EOF

# Create artifactbundleindex

cat > "libpinmame.artifactbundleindex" << 'EOF'
{
    "schemaVersion": "1.0",
    "archives": [
    ]
}
EOF

for f in *.artifactbundle; do
    cp module.modulemap "$f/include/pinmame/"

    zip -vry "${f}.zip" "$f"

    triples=$(jq ".artifacts.libpinmame.variants.[0].supportedTriples" "${f}/info.json")
    checksum=$(swift package compute-checksum "${f}.zip")

    tmpfile=$(mktemp)

    jq \
        --arg file "${f}.zip" \
        --arg checksum "$checksum" \
        --argjson supportedTriples "$triples" \
        '.archives += [{"fileName": $file, "checksum": $checksum, "supportedTriples": $supportedTriples}]' \
        libpinmame.artifactbundleindex > "$tmpfile"

    mv "$tmpfile" libpinmame.artifactbundleindex
done

echo "Created 'libpinmame.artifactbundleindex' with checksum $(shasum -a 256 libpinmame.artifactbundleindex | cut -d ' ' -f 1)"
