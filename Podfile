source 'https://cdn.cocoapods.org/'

platform :ios, '12.3'

inhibit_all_warnings!
use_frameworks!

abstract_target 'BasePods' do
  # pods
	pod 'AFNetworking', '2.7.0'
	pod 'Mantle', '2.1.6'
	pod 'MWPhotoBrowser', :git => 'https://github.com/8ofproject/MWPhotoBrowser.git'
	pod 'PureLayout', '3.1.8'
	pod 'Texture', '2.8.1'
	pod 'TUSafariActivity', '1.0.4'
	pod 'YapDatabase', '3.1.4'

	# targets
  target 'dvach-browser'
  target 'dvach-browserTests'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'

      # Fixes Xcode 12 bug for Texture internal dependency
      if target.name == "PINCache" or target.name == "PINRemoteImage"
          puts "Updating #{target.name} OTHER_CFLAGS"
          target.build_configurations.each do |config|
              config.build_settings['OTHER_CFLAGS'] = '-Xclang -fcompatibility-qualified-id-block-type-checking'
          end
      end
    end
  end
end
