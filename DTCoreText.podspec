Pod::Spec.new do |spec|
  spec.name         = 'DTCoreText'
  spec.version      = '3.3.0-dev'

  spec.license      = 'BSD'
  spec.source       = { :git => 'https://github.com/sprylab/DTCoreText.git', :tag => spec.version.to_s }

  spec.ios.deployment_target = '9.0'
  spec.osx.deployment_target = '10.8'

  spec.ios.source_files = 'Core/Source/*.{h,m,c}', 'Core/Source/iOS/*.{h,m,c}'
  spec.osx.source_files = 'Core/Source/*.{h,m,c}', 'Core/Source/OSX/*.{h,m,c}', 'Core/Source/CrossPlatform/*.{h,m,c}'

  spec.ios.dependency 'DTFoundation/UIKit', '2.3.0-dev'

  spec.dependency 'DTFoundation/Core', '2.3.0-dev'
  spec.dependency 'DTFoundation/DTHTMLParser', '2.3.0-dev'

  spec.ios.frameworks   = 'MediaPlayer', 'QuartzCore', 'CoreText', 'CoreGraphics', 'ImageIO'
  spec.osx.frameworks   = 'QuartzCore', 'CoreText', 'CoreGraphics', 'ImageIO', 'AppKit'

  spec.requires_arc = true
  spec.homepage     = 'https://github.com/Cocoanetics/DTCoreText'
  spec.summary      = 'Methods to allow using HTML code with CoreText.'
  spec.author       = { 'Oliver Drobnik' => 'oliver@cocoanetics.com' }
  spec.prefix_header_contents = '#import <CoreText/CoreText.h>'
  spec.prepare_command = <<-CMD
     cd ./Core/Source
     /usr/bin/xxd -i default.css default.css.c
  CMD
end
