source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target 'ARKit+CoreLocation' do
    pod 'ARCL', :path => '.'
    pod ‘GeoFire’, :git => ‘https://github.com/firebase/geofire-objc.git'
    pod 'Firebase/Core'
    pod 'Firebase/Auth'
    pod 'SnapSDK', '> 1.3' 
    pod 'TwilioVideo'    
    pod 'Alamofire'
    pod 'VerticalCardSwiper'
    pod 'GooglePlacePicker'
    target 'ARCLTests' do
  
    end
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
        end
    end
end
