# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'HowlTalk' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HowlTalk

  pod 'SnapKit', '~> 4.0.0'
  pod 'Firebase/Core'
  pod 'Firebase/RemoteConfig'
  pod 'TextFieldEffects'

  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage'

  # 객체 JSON매핑
  pod 'ObjectMapper', '~> 3.3'

  # 푸시메시지 관련
  pod 'Alamofire', '~> 4.7'
  pod 'Firebase/Messaging'

  # 이미지 속도개선 라이브러리
  pod 'Kingfisher', '~> 4.0'


  # 체크박스 관련 라이브러리 (objc로 구성되어 있음)
  pod 'BEMCheckBox'


  # Workaround for Cocoapods issue #7606
  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings.delete('CODE_SIGNING_ALLOWED')
      config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
  end

end
