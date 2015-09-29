Pod::Spec.new do |s|

  s.platform = :ios
  s.ios.deployment_target = '8.0'

  s.name         = "SRSlideSwitchView"
  s.version      = "0.1.0"
  s.summary      = "A UIView support switching between uiviewcontrollers in it by panning gestures."

  s.description  = "A UIView support switching between uiviewcontrollers in it by panning gestures, also comes with a segemented control bar indicating the title of selected viewcontroller."

  s.license = { :type => "MIT", :file => "LICENSE" }
  s.homepage = "https://github.com/shengrong1987/SRSlideSwitchView"

  s.author       = { "ShengRong" => "aimbebe.r@gmail.com" }
  s.source       = { :git => "https://github.com/shengrong1987/SRSlideSwitchView.git", :tag => "0.1.0" }

  s.source_files  = "SRSlideSwitchView/**/*.{swift}"
  s.framework = "UIKit"

end
