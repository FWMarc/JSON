Pod::Spec.new do |s|
s.name         = "JSON"
s.version      = "1.2"
s.summary      = "Simple Swift library for working with JSON data."
s.description  = "JSON is a simple Swift library for working with JSON data. It can be initialized with either a string, NSData, or a JSON object returned by NSJSONSerialization. It provides a lightweight fast API that removes the need to cast untyped values typically returned by NSJSONSerialization."

s.homepage     = "https://github.com/storehouse/JSON"

s.license      = "BSD 2-clause \"Simplified\" License"

s.authors      = "Storehouse", "Joel Levin"
s.social_media_url = 'http://twitter.com/storehousehq'

s.source       = { :git => "https://github.com/FWMarc/JSON.git", :tag => "1.1" }

s.source_files = "JSON/**/*.swift"

s.ios.deployment_target = "8.0"
end
