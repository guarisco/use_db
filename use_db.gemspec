# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "use_db/version"

Gem::Specification.new do |s|
  s.name        = "use_db"
  s.version     = UseDb::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ron Guarisco"]
  s.email       = ["ron.guarisco@gmail.com"]
  s.homepage    = "https://github.com/guarisco/use_db"
  s.summary     = %q{Multi-database AR connections for Rails 3,4}
  s.description = %q{Multi-database AR connections for Rails 3,4 models, tests, and migrations.}

  s.rubyforge_project = "use_db"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
