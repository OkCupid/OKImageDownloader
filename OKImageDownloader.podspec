#
# Be sure to run `pod lib lint OKImageDownloader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OKImageDownloader'
  s.version          = '0.2.0'
  s.summary          = 'Image downloading made easy'
  s.description      = 'A simple framework to manage the downloading, decompressing, caching and cancelling of images.'
  s.homepage         = 'https://github.com/okcupid/OKImageDownloader'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jordan Guggenheim' => 'jordan@okcupid.com' }
  s.source           = { :git => 'https://github.com/okcupid/OKImageDownloader.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/okcupid'

  s.ios.deployment_target = '9.0'

  s.swift_version = '4.2'
  s.source_files = 'OKImageDownloader/Classes/**/*'
  
end
