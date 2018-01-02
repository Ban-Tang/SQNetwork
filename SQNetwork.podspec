#
#  Be sure to run `pod spec lint SQNetwork.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SQNetwork"
  s.version      = "0.1"
  s.summary      = "Network lib."
  s.description  = <<-DESC
                   A network lib based on AFNetworking.
                   DESC
  s.homepage     = "https://coding.net/u/roylee/p/SQNetwork/git"

  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Roylee" => "roylee-stillway@163.com" }

  s.platform     = :ios
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://git.coding.net/roylee/SQNetwork.git", :tag => "#{s.version}" }
  s.source_files  = "SQNetwork/**/*.{h,m}"
  s.public_header_files = "SQNetwork/SQNetwork.h"

  s.requires_arc = true

  s.dependency "AFNetworking", "~> 3.0"

end
