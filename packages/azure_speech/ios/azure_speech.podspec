#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'azure_pronunciation_assessment'
  s.version          = '0.1.0'
  s.summary          = 'Azure Speech pronunciation assessment'
  s.description      = <<-DESC
Wraps Microsoft Cognitive Services Speech SDK for pronunciation assessment.
                       DESC
  s.homepage         = 'https://github.com/enjoy'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Enjoy Player' => 'https://github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'MicrosoftCognitiveServicesSpeech-iOS', '~> 1.49.0'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
