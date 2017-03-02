source 'https://github.com/CocoaPods/Specs.git'
# This line is needed until OGVKit is fully published to CocoaPods
# Remove once packages published:
source 'https://github.com/Serkora/OGVKit-Specs.git'

platform :ios, '8.2'

inhibit_all_warnings!
use_frameworks!

abstract_target 'BasePods' do
  # pods
	pod 'AFNetworking', '2.6.3'
	pod 'AsyncDisplayKit', :git => 'https://github.com/facebook/AsyncDisplayKit.git', :tag => '2.2'
	pod 'Crashlytics', '3.8.4'
	pod 'Fabric', '1.6.11'
	pod 'Mantle', '2.1.0'
	pod 'MWPhotoBrowser', :git => 'https://github.com/8ofproject/MWPhotoBrowser.git'
	pod 'OGVKit', '0.5pre'
	pod 'PureLayout', '3.0.2'
	pod 'Reachability', '3.2'
	pod 'TUSafariActivity', '1.0.4'
	pod 'YapDatabase', '2.9.2'

	# targets
  target 'dvach-browser'
  target 'dvach-browserTests'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
