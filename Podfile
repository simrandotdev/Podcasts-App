platform :ios, '16.0'

target 'Podcasts App' do
  use_frameworks!
  pod 'FeedKit', '~> 9.0'
  pod 'Resolver'

  target 'Podcasts App Unit Tests' do
    inherit! :search_paths
  end
end

# Keep dependency targets compatible with the SDK used by the app.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
