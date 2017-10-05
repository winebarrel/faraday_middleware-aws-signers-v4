# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = 'faraday_middleware-aws-signers-v4'
  spec.version       = '0.1.9'
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']

  spec.summary       = %q{Faraday middleware for AWS Signature Version 4.}
  spec.description   = %q{Faraday middleware for AWS Signature Version 4.}
  spec.homepage      = 'https://github.com/winebarrel/faraday_middleware-aws-signers-v4'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 0.9'
  spec.add_dependency 'aws-sdk-resources', '>= 2', '< 3'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'faraday_middleware'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'webmock'
end
