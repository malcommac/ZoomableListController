#
# Be sure to run `pod lib lint ZoomableListController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ZoomableListController"
  s.version          = "0.1.0"
  s.summary          = "Apple's iOS Weather App List Imitation written in Swift"
  s.description      = <<-DESC
                       This control allows you to imitate the behaviour of the Apple's built-in weather app with a tabular list and pinch to expand feature to perform a live transition to a page-scrollview data representation.
                       DESC
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/ZoomableListController"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "daniele margutti" => "me@danielemargutti.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/ZoomableListController.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'ZoomableListController' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'CircularScrollView'
end
