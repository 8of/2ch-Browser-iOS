source 'https://github.com/CocoaPods/Specs.git'
# This line is needed until OGVKit is fully published to CocoaPods
# Remove once packages published:
source 'https://github.com/brion/OGVKit-Specs.git'

platform :ios, '8.2'

inhibit_all_warnings!
use_frameworks!

abstract_target 'BasePods' do
  # pods
	pod 'AFNetworking', '2.6.3'
	pod 'Mantle', '2.1.0'
	pod 'MWPhotoBrowser', :git => 'https://github.com/8ofproject/MWPhotoBrowser.git'
	pod 'OGVKit/WebM', '0.5.13'
	pod 'PureLayout', '3.0.2'
	pod 'Texture', '2.5.1'
	pod 'TUSafariActivity', '1.0.4'
	pod 'YapDatabase', '3.0.2'

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
