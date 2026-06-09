#!/bin/sh
set -euo pipefail

# Keep Revoxa.xcodeproj in sync with Sources/Revoxa/**/*.swift for Xcode Cloud builds.
cd "${CI_PRIMARY_REPOSITORY_PATH:-.}"
ruby script/generate_ios_xcodeproj.rb
