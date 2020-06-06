#!/usr/bin/env ruby

require 'xcodeproj'

### This script creates an Xcode project using Swift Package Manager
### and then applies every needed configurations and other changes.
###
### Written by Shai Mishali, June 1st 2019.

project_name = "CombineExt"
project_file = "#{project_name}.xcodeproj"
podspec = "#{project_name}.podspec"
plist_file = "#{project_file}/#{project_name}_Info.plist"
core_targets = [project_name, "#{project_name}Tests", "#{project_name}PackageDescription", "#{project_name}PackageTests"]

# Make sure SPM is Installed
system("swift package > /dev/null 2>&1")
abort("SPM is not installed") unless $?.exitstatus == 0

# Make sure PlistBuddy is Installed
abort("PlistBuddy is not installed") unless File.file?("/usr/libexec/PlistBuddy")

# Make sure we have a Package.swift file
abort("Can't locate Package.swift") unless File.exist?("Package.swift")

# Make sure Podspec exists and we can find a version
abort("Can't locate #{podspec}") unless File.exist?(podspec)
podspec_version = nil
File.open(podspec).each do |line|
    version = line[/^\s+s\.version\s+=\s+\"(.*?)\"$/, 1]
    unless version.nil?
        podspec_version = version
        break
    end
end

abort("Can't find podspec vesrion") if podspec_version.nil?

# Attempt generating Xcode Project
system("rf -rf #{project_file}")
system("swift package generate-xcodeproj --enable-code-coverage")

# Apply CFBundleVersion and CFBundleShortVersionString
fail("Can't find project #{project_file}") unless File.directory?(project_file)
fail("Can't find plist #{plist_file}") unless File.file?(plist_file)

system("/usr/libexec/PlistBuddy -c \"Set :CFBundleVersion #{podspec_version}\" #{plist_file}")
system("/usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString #{podspec_version}\" #{plist_file}")

# Apply SwiftLint and other configurations to targets
project = Xcodeproj::Project.open(project_file)
project.targets.each do |target|
    if core_targets.include?(target.name)
        swiftlint = target.new_shell_script_build_phase('SwiftLint')
        swiftlint.shell_script = <<-SwiftLint
if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed"
fi       
        SwiftLint

        index = target.build_phases.index { |phase| (defined? phase.name) && phase.name == 'SwiftLint' }
        target.build_phases.move_from(index, 0)
    else
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
            config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -suppress-warnings'
        end
    end
end

project::save()