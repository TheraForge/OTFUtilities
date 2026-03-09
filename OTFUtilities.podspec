#
# Be sure to run `pod lib lint OTFTemplateBox.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OTFUtilities'
  s.version          = '2.0.0'
  s.summary          = 'OTFUtilities is a parent framework for multiple other frameworks.'
  s.homepage         = 'https://github.com/TheraForge/OTFUtilities'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hippocrates Technologies' => 'hippocratestech-dev@googlegroups.com' }
  s.source           = { :git => 'https://github.com/TheraForge/OTFUtilities.git', :tag => s.version.to_s }

  # Platforms support
  s.ios.deployment_target     = '16.0'
  s.watchos.deployment_target = '9.0'

  # Swift module
  s.swift_version = '5.0'

  # Source files
  s.source_files = 'OTFUtilities/**/*.{swift}'

  # Restricted Dependencies
  s.ios.dependency 'Sodium', '0.9.1'
end