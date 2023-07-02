#!/bin/bash

CURR_VERSION=backbone-v`awk '/^version: /{print $2}' packages/backbone/pubspec.yaml`

# iOS & macOS
APPLE_HEADER="release_tag_name = '$CURR_VERSION' # generated; do not edit"
sed -i.bak "1 s/.*/$APPLE_HEADER/" packages/flutter_backbone/ios/flutter_backbone.podspec
sed -i.bak "1 s/.*/$APPLE_HEADER/" packages/flutter_backbone/macos/flutter_backbone.podspec
rm packages/flutter_backbone/macos/*.bak packages/flutter_backbone/ios/*.bak

# CMake platforms (Linux, Windows, and Android)
CMAKE_HEADER="set(LibraryVersion \"$CURR_VERSION\") # generated; do not edit"
for CMAKE_PLATFORM in android linux windows
do
    sed -i.bak "1 s/.*/$CMAKE_HEADER/" packages/flutter_backbone/$CMAKE_PLATFORM/CMakeLists.txt
    rm packages/flutter_backbone/$CMAKE_PLATFORM/*.bak
done

git add packages/flutter_backbone/
