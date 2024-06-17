lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_state_machine/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_state_machine'
  spec.version       = RailsStateMachine::VERSION
  spec.authors       = ['Arne Hartherz', 'Emanuel Denzel']
  spec.email         = ['arne.hartherz@makandra.de']

  spec.summary       = %q{ActiveRecord-bound state machine}
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/makandra/rails_state_machine'
  spec.license       = 'MIT'
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
end
