platform :ios
link_with %w{ObjectiveFaye ObjectiveFayeTests}

pod 'SocketRocket', '~>0.2'

post_install do |installer|
  default_target_installer = installer.target_installers.find { |i| i.target_definition.name == :default }
  config_file_path = File.join("Pods", default_target_installer.target_definition.xcconfig_name)

  File.open("config.tmp", "w") do |io|
    io << File.read(config_file_path).gsub(/ -licucore/, '')
  end

  FileUtils.mv("config.tmp", config_file_path)
end