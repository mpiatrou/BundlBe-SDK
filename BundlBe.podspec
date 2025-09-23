Pod::Spec.new do |s|
  s.name             = 'BundlBe'
  s.version          = '1.0'
  s.summary          = 'Lightweight iOS SDK for subscription activation and paywall management.'
  s.description      = 'BundlBe is a lightweight iOS SDK that provides Login, Logout, and Paywall Suppressor functions for subscription handling.'
  s.homepage         = 'https://github.com/mpiatrou/BundlBe-SDK'
  s.source           = { :git => 'https://github.com/mpiatrou/BundlBe-SDK.git', :tag => s.version.to_s }
  s.authors          = { 'KlavaApps' => 'support@bundlbe.com' }
  s.license          = { :type => 'MIT', :file => 'LICENSE' }

  s.ios.deployment_target = '15.0'

  s.source_files = 'BundlBe/**/*.{swift}'
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6']

  s.frameworks = 'Foundation', 'StoreKit'
end
