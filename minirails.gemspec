# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minirails/version'

Gem::Specification.new do |spec|
  spec.name          = "minirails"
  spec.version       = Minirails::VERSION
  spec.authors       = ["Tymon Tobolski"]
  spec.email         = ["i@teamon.eu"]

  spec.summary       = %q{Smallest Rails Apps launcher}
  spec.description   = %q{Smallest Rails Apps launcher}
  spec.homepage      = "http://github.com/teamon/minirails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "foreman",      "~> 0.78.0"
  spec.add_dependency "rack",         "~> 1.6.4"
  spec.add_dependency "railties",     "~> 4.2.4"
  spec.add_dependency "activerecord", "~> 4.2.4"
  spec.add_dependency "pg",           "~> 0.18.3"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
