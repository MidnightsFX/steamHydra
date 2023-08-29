# frozen_string_literal: true

require_relative 'lib/steamhydra/configuration'

Gem::Specification.new do |spec|
  spec.name          = 'steamhydra'
  spec.version       = SteamHydra::VERSION
  spec.authors       = ['Carl Stutz']
  spec.email         = ['carl.stutz@gmail.com']

  spec.summary       = 'Steamcmd managed gameserver management'
  spec.description   = 'SteamHydra is designed to manage steam game servers on linux.'
  spec.homepage      = 'https://github.com/MidnightsFX/steamhydra'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.3')

  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/MidnightsFX/steamhydra'
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sqlite3', '~> 1.3'
  spec.add_runtime_dependency 'steam-condenser', '~> 1.3.11'
  spec.add_runtime_dependency 'thor', '1.1.0'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock'
end
