#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cloudproof.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cloudproof'
  s.version          = '7.0.0'
  s.summary          = 'Cloudproof plugin.'
  s.description      = <<-DESC
Cloudproof plugin.
                       DESC
  s.homepage         = 'https://github.com/Cosmian/cloudproof_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cosmian' => 'tech@cosmian.com' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
