lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "itamae/plugin/recipe/redmine/version"

Gem::Specification.new do |spec|
  spec.name          = "itamae-plugin-recipe-redmine"
  spec.version       = Itamae::Plugin::Recipe::Redmine::VERSION
  spec.authors       = ["y-matsuda"]
  spec.email         = ["matsuda@lab.acs-jp.com"]

  spec.summary       = %q{itamae recipe to ease redmine installation}
  spec.description   = %q{itamae recipe to ease redmine installation}
  spec.homepage      = "https://github.com/maedadev/itamae-plugin-recipe-redmine"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'itamae', '~> 1.10', '>= 1.10.2'
  spec.add_dependency 'itamae-plugin-recipe-postgresql', '~> 0', '>= 0.0.1'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
