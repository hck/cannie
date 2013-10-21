# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cannie/version'

Gem::Specification.new do |spec|
  spec.name          = "cannie"
  spec.version       = Cannie::VERSION
  spec.authors       = ["hck"]
  spec.description   = %q{Cannie is a gem for authorization/permissions checking on per-controller/per-action basis.}
  spec.summary       = %q{Simple gem for checking permissions on per-action basis}
  spec.homepage      = "http://guthub.com/hck/cannie"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rails", ">= 4.0"
end
