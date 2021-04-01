Pod::Spec.new do |s|
  s.name     = 'ZrxImagePicker'
  s.version  = '1.0.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'Whatsapp like image picker written in Swift.'
  s.homepage = 'https://github.com/ZoomRx/ZrxImagePicker-iOS'
  s.author   = 'ZoomRx'
  s.source   = { :git => 'https://github.com/ZoomRx/ZrxImagePicker-iOS.git', :tag => s.version }
  s.platform = :ios, '11.0'
  s.source_files = 'ZrxImagePicker/**/*.{h,swift,xib}'
  s.resources = "ZrxImagePicker/**/*.xcassets"
  s.swift_version = '5.0'
  s.dependency 'ZrxCropViewController'
  s.dependency 'ZrxCameraViewController'
  s.dependency 'BSImagePicker', '~> 3.1'
end
