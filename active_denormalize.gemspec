# frozen_string_literal: true

require_relative "lib/active_denormalize/version"

Gem::Specification.new do |spec|
  spec.name        = "active_denormalize"
  spec.version     = ActiveDenormalize::VERSION
  spec.authors     = ["Garrett Bjerkhoel"]
  spec.email       = ["me@garrettbjerkhoel.com"]
  spec.homepage    = "https://github.com/dewski/active_denormalize"
  spec.summary     = "Summary of ActiveDenormalize."
  spec.description = "Description of ActiveDenormalize."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dewski/active_denormalize"
  spec.metadata["changelog_uri"] = "https://github.com/dewski/active_denormalize/blob/main/CODE_OF_CONDUCT.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.6"
end
