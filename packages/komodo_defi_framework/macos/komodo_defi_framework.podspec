#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint komodo_defi_framework.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'komodo_defi_framework'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.public_header_files = 'Classes/**/*.h'

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  # s.vendored_libraries = 'Frameworks/libmm2.a'
  # s.vendored_libraries = ['Frameworks/libkdflib.a']
  s.vendored_libraries = ['Frameworks/*.a']
  # Exclude i386 and arm64 from iOS Simulator build
  
  # s.pod_target_xcconfig = { "OTHER_LDFLAGS" => "$(inherited) -force_load $(PODS_TARGET_SRCROOT)/Frameworks/libkdflib.a -lstdc++" }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=macosx*]' => 'i386 x86_64',
    'OTHER_LDFLAGS' => '-force_load $(PODS_TARGET_SRCROOT)/Frameworks/libkdflib.a -lstdc++ -framework SystemConfiguration'
  }
  

  s.platform = :osx, '14.0'
  s.swift_version = '5.0'
end