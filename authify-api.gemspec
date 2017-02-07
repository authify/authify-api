# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'authify/api/version'

Gem::Specification.new do |spec|
  spec.name          = 'authify-api'
  spec.version       = Authify::API::VERSION
  spec.authors       = ['Jonathan Gnagy']
  spec.email         = ['jgnagy@knuedge.com']

  spec.summary       = 'Authify API Server library'
  spec.homepage      = 'https://github.com/knuedge/authify-api'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency 'authify-core'
  spec.add_runtime_dependency 'authify-middleware'
  spec.add_runtime_dependency 'connection_pool', '~> 2.2'
  spec.add_runtime_dependency 'sinatra', '~> 1.4'
  spec.add_runtime_dependency 'sinatra-activerecord', '~> 2.0'
  spec.add_runtime_dependency 'moneta', '~> 0.8'
  # spec.add_runtime_dependency 'omniauth', '~> 1.3'
  # spec.add_runtime_dependency 'omniauth-github', '~> 1.2'
  spec.add_runtime_dependency 'mysql2', '~> 0.4'
  spec.add_runtime_dependency 'jsonapi-serializers', '~> 0.16'
  spec.add_runtime_dependency 'sinja', '~> 1.2'
  spec.add_runtime_dependency 'puma', '~> 3.7'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rubocop', '~> 0.35'
  spec.add_development_dependency 'yard',    '~> 0.8'
  spec.add_development_dependency 'travis', '~> 1.8'
  spec.add_development_dependency 'simplecov', '~> 0.13'
end
