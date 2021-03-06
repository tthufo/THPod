#
# Be sure to run `pod lib lint THPod.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'THPod'
  s.version          = '1.1.6'
  s.summary          = 'A short description of THPod.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
         Bundles of custom class and utilities which helping you saving a lot of time
                       DESC

  s.homepage         = 'https://github.com/tthufo/THPod'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tthufo' => 'tthufo@gmail.com' }
  s.source           = { :git => 'https://github.com/tthufo/THPod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/tthufo'

  s.ios.deployment_target = '7.0'

  s.source_files = 'THPod/Classes'

  s.requires_arc = true

#    s.subspec 'no-arc' do |sp|
#    sp.source_files = 'THPod/IFTweetLabel.{h,m}','THPod/RegexKitLite.{h,m}','THPod/RKLMatchEnumerator.{h,m}'
#    sp.requires_arc = false
#,'libicucore'

#end

  s.resource_bundles = {
    'THPod' => ['THPod/Assets/*']
  }

  s.resources = 'THPod/Assets/*'

  s.frameworks = 'CoreData'

  s.public_header_files = 'THPod/Classes/*.h'

s.dependency 'FBSDKCoreKit', '~> 4.4'
s.dependency 'FBSDKLoginKit', '~> 4.4'
s.dependency 'FBSDKShareKit', '~> 4.4'
s.dependency 'AVHexColor', '~> 2.0'
s.dependency 'SVProgressHUD'
s.dependency 'Toast', '~> 4.0.0'
s.dependency 'Reachability', '~> 3.2'
s.dependency 'AFNetworking', '~> 3.1'
s.dependency 'JSONKit-NoWarning', '~> 1.2'
s.dependency 'SDWebImage', '~> 3.7'
s.dependency 'hpple', '~> 0.2'
s.dependency 'JCNotificationBannerPresenter', '~> 1.1'

end
