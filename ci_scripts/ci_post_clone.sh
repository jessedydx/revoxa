#!/bin/sh
set -euo pipefail

# Keep Revoxa.xcodeproj in sync for Xcode Cloud builds.
# generate_ios_xcodeproj.rb uses CI_BUILD_NUMBER as CURRENT_PROJECT_VERSION
# so each push can produce a unique TestFlight build number.
cd "${CI_PRIMARY_REPOSITORY_PATH:-.}"
ruby script/generate_ios_xcodeproj.rb
