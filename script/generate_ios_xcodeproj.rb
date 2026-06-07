#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest/md5"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT_NAME = "Revoxa"
TARGET_NAME = "Revoxa iOS"
PRODUCT_NAME = "Revoxa"
PROJECT_DIR = File.join(ROOT, "#{PROJECT_NAME}.xcodeproj")
SCHEME_DIR = File.join(PROJECT_DIR, "xcshareddata", "xcschemes")

def uuid(seed)
  Digest::MD5.hexdigest(seed).upcase[0, 24]
end

def q(value)
  value.match?(/\A[A-Za-z0-9_.$\/-]+\z/) ? value : "\"#{value}\""
end

source_files = Dir
  .glob(File.join(ROOT, "Sources", "Revoxa", "**", "*.swift"))
  .map { |path| path.delete_prefix("#{ROOT}/") }
  .sort

resource_files = [
  "Sources/Revoxa/Resources/Assets.xcassets",
  "Sources/Revoxa/Resources/Localizable.xcstrings",
  "Sources/Revoxa/Resources/PrivacyInfo.xcprivacy"
]

config_files = [
  "Configurations/Revoxa-iOS/Info.plist",
  "Configurations/Revoxa-iOS/Revoxa-iOS.entitlements"
]

all_files = source_files + resource_files + config_files
target_id = uuid("target:#{TARGET_NAME}")
project_id = uuid("project:#{PROJECT_NAME}")
main_group_id = uuid("group:main")
sources_group_id = uuid("group:sources")
resources_group_id = uuid("group:resources")
configs_group_id = uuid("group:configs")
products_group_id = uuid("group:products")
product_ref_id = uuid("product:#{PRODUCT_NAME}.app")
sources_phase_id = uuid("phase:sources")
resources_phase_id = uuid("phase:resources")
frameworks_phase_id = uuid("phase:frameworks")
target_config_list_id = uuid("config-list:target")
project_config_list_id = uuid("config-list:project")

file_ref_ids = all_files.to_h { |path| [path, uuid("file:#{path}")] }
build_file_ids = (source_files + resource_files).to_h { |path| [path, uuid("build:#{path}")] }

def file_type(path)
  case File.extname(path)
  when ".swift"
    "sourcecode.swift"
  when ".xcassets"
    "folder.assetcatalog"
  when ".xcstrings"
    "text.json.xcstrings"
  when ".xcprivacy"
    "text.xml"
  when ".plist"
    "text.plist.xml"
  when ".entitlements"
    "text.plist.entitlements"
  else
    "text"
  end
end

project_debug_id = uuid("config:project:Debug")
project_release_id = uuid("config:project:Release")
target_debug_id = uuid("config:target:Debug")
target_release_id = uuid("config:target:Release")

project_build_settings = {
  "ALWAYS_SEARCH_USER_PATHS" => "NO",
  "CLANG_ANALYZER_NONNULL" => "YES",
  "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION" => "YES_AGGRESSIVE",
  "CLANG_CXX_LANGUAGE_STANDARD" => "\"gnu++20\"",
  "CLANG_ENABLE_MODULES" => "YES",
  "CLANG_ENABLE_OBJC_ARC" => "YES",
  "CLANG_ENABLE_OBJC_WEAK" => "YES",
  "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING" => "YES",
  "CLANG_WARN_BOOL_CONVERSION" => "YES",
  "CLANG_WARN_COMMA" => "YES",
  "CLANG_WARN_CONSTANT_CONVERSION" => "YES",
  "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS" => "YES",
  "CLANG_WARN_DIRECT_OBJC_ISA_USAGE" => "YES_ERROR",
  "CLANG_WARN_DOCUMENTATION_COMMENTS" => "YES",
  "CLANG_WARN_EMPTY_BODY" => "YES",
  "CLANG_WARN_ENUM_CONVERSION" => "YES",
  "CLANG_WARN_INFINITE_RECURSION" => "YES",
  "CLANG_WARN_INT_CONVERSION" => "YES",
  "CLANG_WARN_NON_LITERAL_NULL_CONVERSION" => "YES",
  "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF" => "YES",
  "CLANG_WARN_OBJC_LITERAL_CONVERSION" => "YES",
  "CLANG_WARN_OBJC_ROOT_CLASS" => "YES_ERROR",
  "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER" => "YES",
  "CLANG_WARN_RANGE_LOOP_ANALYSIS" => "YES",
  "CLANG_WARN_STRICT_PROTOTYPES" => "YES",
  "CLANG_WARN_SUSPICIOUS_MOVE" => "YES",
  "CLANG_WARN_UNGUARDED_AVAILABILITY" => "YES_AGGRESSIVE",
  "CLANG_WARN_UNREACHABLE_CODE" => "YES",
  "CLANG_WARN__DUPLICATE_METHOD_MATCH" => "YES",
  "COPY_PHASE_STRIP" => "NO",
  "ENABLE_STRICT_OBJC_MSGSEND" => "YES",
  "ENABLE_TESTABILITY" => "YES",
  "GCC_C_LANGUAGE_STANDARD" => "gnu17",
  "GCC_NO_COMMON_BLOCKS" => "YES",
  "GCC_WARN_64_TO_32_BIT_CONVERSION" => "YES",
  "GCC_WARN_ABOUT_RETURN_TYPE" => "YES_ERROR",
  "GCC_WARN_UNDECLARED_SELECTOR" => "YES",
  "GCC_WARN_UNINITIALIZED_AUTOS" => "YES_AGGRESSIVE",
  "GCC_WARN_UNUSED_FUNCTION" => "YES",
  "GCC_WARN_UNUSED_VARIABLE" => "YES",
  "IPHONEOS_DEPLOYMENT_TARGET" => "17.0",
  "LOCALIZATION_PREFERS_STRING_CATALOGS" => "YES",
  "SDKROOT" => "iphoneos"
}

target_build_settings = {
  "ASSETCATALOG_COMPILER_APPICON_NAME" => "AppIcon",
  "CODE_SIGN_ENTITLEMENTS" => "Configurations/Revoxa-iOS/Revoxa-iOS.entitlements",
  "CODE_SIGN_STYLE" => "Automatic",
  "CURRENT_PROJECT_VERSION" => "1",
  "DEVELOPMENT_ASSET_PATHS" => "\"\"",
  "DEVELOPMENT_TEAM" => "\"\"",
  "GENERATE_INFOPLIST_FILE" => "NO",
  "INFOPLIST_FILE" => "Configurations/Revoxa-iOS/Info.plist",
  "IPHONEOS_DEPLOYMENT_TARGET" => "17.0",
  "LD_RUNPATH_SEARCH_PATHS" => "\"$(inherited) @executable_path/Frameworks\"",
  "MARKETING_VERSION" => "0.1",
  "PRODUCT_BUNDLE_IDENTIFIER" => "com.revoxa.app",
  "PRODUCT_NAME" => "Revoxa",
  "SUPPORTED_PLATFORMS" => "\"iphoneos iphonesimulator\"",
  "SUPPORTS_MACCATALYST" => "NO",
  "SWIFT_EMIT_LOC_STRINGS" => "YES",
  "SWIFT_VERSION" => "5.0",
  "TARGETED_DEVICE_FAMILY" => "\"1,2\""
}

def format_settings(settings, extra = {})
  settings.merge(extra).sort.map { |key, value| "\t\t\t\t#{key} = #{value};" }.join("\n")
end

file_references = all_files.map do |path|
  "#{file_ref_ids[path]} /* #{File.basename(path)} */ = {isa = PBXFileReference; lastKnownFileType = #{file_type(path)}; path = #{q(path)}; sourceTree = \"<group>\"; };"
end

file_references << "#{product_ref_id} /* #{PRODUCT_NAME}.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = #{PRODUCT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; };"

build_files = (source_files + resource_files).map do |path|
  "#{build_file_ids[path]} /* #{File.basename(path)} in #{source_files.include?(path) ? "Sources" : "Resources"} */ = {isa = PBXBuildFile; fileRef = #{file_ref_ids[path]} /* #{File.basename(path)} */; };"
end

source_children = source_files.map { |path| "\t\t\t\t#{file_ref_ids[path]} /* #{File.basename(path)} */," }.join("\n")
resource_children = resource_files.map { |path| "\t\t\t\t#{file_ref_ids[path]} /* #{File.basename(path)} */," }.join("\n")
config_children = config_files.map { |path| "\t\t\t\t#{file_ref_ids[path]} /* #{File.basename(path)} */," }.join("\n")

source_build_children = source_files.map { |path| "\t\t\t\t#{build_file_ids[path]} /* #{File.basename(path)} in Sources */," }.join("\n")
resource_build_children = resource_files.map { |path| "\t\t\t\t#{build_file_ids[path]} /* #{File.basename(path)} in Resources */," }.join("\n")

pbxproj = <<~PBX
// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {

/* Begin PBXBuildFile section */
\t\t#{build_files.join("\n\t\t")}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t#{file_references.join("\n\t\t")}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t#{frameworks_phase_id} /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t#{main_group_id} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t#{sources_group_id} /* Sources */,
\t\t\t\t#{resources_group_id} /* Resources */,
\t\t\t\t#{configs_group_id} /* Configurations */,
\t\t\t\t#{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t};
\t\t#{sources_group_id} /* Sources */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
#{source_children}
\t\t\t);
\t\t\tname = Sources;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t#{resources_group_id} /* Resources */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
#{resource_children}
\t\t\t);
\t\t\tname = Resources;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t#{configs_group_id} /* Configurations */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
#{config_children}
\t\t\t);
\t\t\tname = Configurations;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t#{products_group_id} /* Products */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t#{product_ref_id} /* #{PRODUCT_NAME}.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t#{target_id} /* #{TARGET_NAME} */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = #{target_config_list_id} /* Build configuration list for PBXNativeTarget "#{TARGET_NAME}" */;
\t\t\tbuildPhases = (
\t\t\t\t#{sources_phase_id} /* Sources */,
\t\t\t\t#{frameworks_phase_id} /* Frameworks */,
\t\t\t\t#{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = #{q(TARGET_NAME)};
\t\t\tproductName = #{PRODUCT_NAME};
\t\t\tproductReference = #{product_ref_id} /* #{PRODUCT_NAME}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t#{project_id} /* Project object */ = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 2650;
\t\t\t\tLastUpgradeCheck = 2650;
\t\t\t\tTargetAttributes = {
\t\t\t\t\t#{target_id} = {
\t\t\t\t\t\tCreatedOnToolsVersion = 26.5;
\t\t\t\t\t};
\t\t\t\t};
\t\t\t};
\t\t\tbuildConfigurationList = #{project_config_list_id} /* Build configuration list for PBXProject "#{PROJECT_NAME}" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\ttr,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = #{main_group_id};
\t\t\tproductRefGroup = #{products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t#{target_id} /* #{TARGET_NAME} */,
\t\t\t);
\t\t};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t#{resources_phase_id} /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
#{resource_build_children}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t#{sources_phase_id} /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
#{source_build_children}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t#{project_debug_id} /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
#{format_settings(project_build_settings, "DEBUG_INFORMATION_FORMAT" => "dwarf", "GCC_OPTIMIZATION_LEVEL" => "0", "ONLY_ACTIVE_ARCH" => "YES", "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "DEBUG")}
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t#{project_release_id} /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
#{format_settings(project_build_settings, "DEBUG_INFORMATION_FORMAT" => "\"dwarf-with-dsym\"", "ENABLE_NS_ASSERTIONS" => "NO", "SWIFT_COMPILATION_MODE" => "wholemodule", "VALIDATE_PRODUCT" => "YES")}
\t\t\t};
\t\t\tname = Release;
\t\t};
\t\t#{target_debug_id} /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
#{format_settings(target_build_settings)}
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\t#{target_release_id} /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
#{format_settings(target_build_settings)}
\t\t\t};
\t\t\tname = Release;
\t\t};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t#{project_config_list_id} /* Build configuration list for PBXProject "#{PROJECT_NAME}" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t#{project_debug_id} /* Debug */,
\t\t\t\t#{project_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
\t\t#{target_config_list_id} /* Build configuration list for PBXNativeTarget "#{TARGET_NAME}" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t#{target_debug_id} /* Debug */,
\t\t\t\t#{target_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
/* End XCConfigurationList section */
\t};
\trootObject = #{project_id} /* Project object */;
}
PBX

xcscheme = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2650"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{target_id}"
               BuildableName = "#{PRODUCT_NAME}.app"
               BlueprintName = "#{TARGET_NAME}"
               ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target_id}"
            BuildableName = "#{PRODUCT_NAME}.app"
            BlueprintName = "#{TARGET_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{target_id}"
            BuildableName = "#{PRODUCT_NAME}.app"
            BlueprintName = "#{TARGET_NAME}"
            ReferencedContainer = "container:#{PROJECT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
XML

FileUtils.mkdir_p(PROJECT_DIR)
FileUtils.mkdir_p(SCHEME_DIR)
File.write(File.join(PROJECT_DIR, "project.pbxproj"), pbxproj)
File.write(File.join(SCHEME_DIR, "#{TARGET_NAME}.xcscheme"), xcscheme)
