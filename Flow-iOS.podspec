#
# Be sure to run `pod lib lint Flow.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Flow-iOS'
  s.version          = '1.0.1'
  s.summary          = 'Make your logic flow and data flow clean and human readable.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Flow is an utility/ design pattern that help developers to write simple and readable codes. There are two main concerns: Flow of operations and Flow of data.
                       DESC

  s.homepage         = 'https://github.com/roytornado/Flow-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Roy Ng' => 'roytornado@gmail.com' }
  s.source           = { :git => 'https://github.com/roytornado/Flow-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Flow/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Flow' => ['Flow/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
